// POST /functions/v1/recitation-analyze  { session_id: uuid }
// Flow: client uploads audio to storage "recitations/{uid}/{session_id}.m4a", inserts a
// pending recitation_sessions row, then calls this function. We transcribe with the
// Quran ASR service (word timestamps), align against the expected words, score, update
// hifz scheduling when mode = "hifz", award XP, and delete the audio.
import { handler, HttpError, json } from "../_shared/http.ts";
import { admin, requireUser } from "../_shared/supabase.ts";
import { consumeQuota, refundQuota } from "../_shared/quota.ts";
import { analyzeRecitation, type ExpectedWord, type HeardWord, scoreToGrade } from "../_shared/alignment.ts";
import { env } from "../_shared/env.ts";
import { track } from "../_shared/analytics.ts";

interface AsrResponse {
  text: string;
  duration: number;
  words: HeardWord[];
}

async function transcribe(audioUrl: string): Promise<AsrResponse> {
  const res = await fetch(`${env.asrUrl()}/v1/transcribe`, {
    method: "POST",
    headers: { "Authorization": `Bearer ${env.asrToken()}`, "Content-Type": "application/json" },
    body: JSON.stringify({ audio_url: audioUrl, language: "ar" }),
    signal: AbortSignal.timeout(120_000),
  });
  if (!res.ok) throw new Error(`asr ${res.status}: ${await res.text()}`);
  return await res.json();
}

Deno.serve(handler(async (req, body) => {
  const user = await requireUser(req);
  const sessionId = typeof body.session_id === "string" ? body.session_id : "";
  if (!/^[0-9a-f-]{36}$/i.test(sessionId)) throw new HttpError(400, "invalid_session_id");
  const db = admin();

  const { data: session, error } = await db.from("recitation_sessions").select("*").eq("id", sessionId).eq(
    "user_id",
    user.id,
  ).maybeSingle();
  if (error) throw error;
  if (!session) throw new HttpError(404, "session_not_found");
  if (session.status !== "pending") throw new HttpError(409, "already_processed");
  if (!String(session.audio_path).startsWith(`${user.id}/`)) throw new HttpError(403, "forbidden");

  const quota = await consumeQuota(user.id, "recitation");
  await db.from("recitation_sessions").update({ status: "processing" }).eq("id", sessionId);

  try {
    const { data: signed, error: signErr } = await db.storage.from("recitations").createSignedUrl(
      session.audio_path,
      300,
    );
    if (signErr || !signed) throw signErr ?? new Error("sign failed");

    const [asr, wordsRes] = await Promise.all([
      transcribe(signed.signedUrl),
      db.from("ayah_words").select("ayah_id, position, text_uthmani, text_simple")
        .gte("ayah_id", session.start_ayah_id).lte("ayah_id", session.end_ayah_id)
        .order("ayah_id").order("position").limit(2000),
    ]);
    if (wordsRes.error) throw wordsRes.error;
    const expected: ExpectedWord[] = (wordsRes.data as any[]).map((w) => ({
      ayahId: w.ayah_id,
      position: w.position,
      uthmani: w.text_uthmani,
      simple: w.text_simple,
    }));
    if (!expected.length) throw new Error("no expected words for range");

    const result = analyzeRecitation(expected, asr.words);

    const { error: updErr } = await db.from("recitation_sessions").update({
      status: "done",
      transcript: asr.text,
      words_total: result.wordsTotal,
      words_correct: result.wordsCorrect,
      accuracy_score: result.accuracy,
      fluency_score: result.fluency,
      tajweed_score: result.tajweed,
      overall_score: result.overall,
      mistakes: result.mistakes,
      duration_ms: Math.round((asr.duration ?? 0) * 1000),
      completed_at: new Date().toISOString(),
    }).eq("id", sessionId);
    if (updErr) throw updErr;

    // Gamification (server-awarded so it cannot be forged)
    const { data: activity } = await db.rpc("_log_activity", {
      p_user: user.id,
      p_kind: "recitation",
      p_units: 1,
      p_ref: sessionId,
    });

    // Hifz: grade each recited ayah that is part of a plan
    const hifzUpdates: unknown[] = [];
    if (session.mode === "hifz") {
      const { data: items } = await db.from("hifz_items").select("id, ayah_id").eq("user_id", user.id)
        .gte("ayah_id", session.start_ayah_id).lte("ayah_id", session.end_ayah_id);
      for (const item of (items ?? []) as { id: number; ayah_id: number }[]) {
        const ayahWords = result.words.filter((w) => w.ayahId === item.ayah_id);
        if (!ayahWords.length || ayahWords.every((w) => w.status === "not_recited")) continue;
        const ok = ayahWords.filter((w) => w.status === "correct").length;
        const partial = ayahWords.filter((w) =>
          w.status === "mispronounced" || w.status === "unclear"
        ).length;
        const ayahScore = ((ok + partial * 0.5) / ayahWords.length) * 100;
        const complete = ayahWords.every((w) => w.status !== "not_recited");
        const { data: upd, error: hErr } = await db.rpc("_hifz_apply_review", {
          p_user: user.id,
          p_item: item.id,
          p_score: scoreToGrade(ayahScore, complete),
          p_source: "ai",
          p_recitation: sessionId,
        });
        if (hErr) console.error("hifz update failed", hErr);
        else hifzUpdates.push(upd);
      }
    }

    await db.storage.from("recitations").remove([session.audio_path]);
    track(user.id, "recitation_analyzed", {
      mode: session.mode,
      overall: result.overall,
      words: result.wordsTotal,
      mistakes: result.mistakes.length,
      premium: quota.premium,
    });

    return json({
      session_id: sessionId,
      transcript: asr.text,
      scores: {
        overall: result.overall,
        accuracy: result.accuracy,
        fluency: result.fluency,
        tajweed: result.tajweed,
      },
      words_total: result.wordsTotal,
      words_correct: result.wordsCorrect,
      completed: result.completed,
      words: result.words,
      mistakes: result.mistakes,
      activity,
      hifz: hifzUpdates,
      quota: { remaining: quota.remaining, limit: quota.limit, premium: quota.premium },
    });
  } catch (e) {
    console.error("recitation analysis failed", e);
    await db.from("recitation_sessions").update({ status: "failed", error: String(e).slice(0, 500) }).eq(
      "id",
      sessionId,
    );
    await refundQuota(user.id, "recitation");
    throw new HttpError(502, "analysis_failed", "We couldn't analyse this recording. Please try again.");
  }
}));
