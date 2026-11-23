import { admin, type AuthedUser } from "./supabase.ts";
import { HttpError } from "./http.ts";
import { consumeQuota, refundQuota } from "./quota.ts";
import { retrieve } from "./retrieval.ts";
import { groundedAnswer, type HistoryTurn } from "./grounded.ts";
import { track } from "./analytics.ts";

const SUPPORTED_LOCALES = new Set(["ar", "en", "ur", "id", "tr", "fr"]);

export interface AskRequest {
  question?: unknown;
  locale?: unknown;
  conversation_id?: unknown;
  translation_id?: unknown;
}

/** Shared pipeline for Ask the Quran (single question) and the assistant (multi-turn). */
export async function runAsk(user: AuthedUser, body: AskRequest, kind: "ask_quran" | "assistant") {
  const question = typeof body.question === "string" ? body.question.trim() : "";
  if (question.length < 3 || question.length > 600) throw new HttpError(400, "invalid_question");
  const locale = typeof body.locale === "string" && SUPPORTED_LOCALES.has(body.locale) ? body.locale : "ar";
  const translationId = typeof body.translation_id === "number" ? body.translation_id : undefined;
  const db = admin();

  // Load or create the conversation (owned by this user)
  let conversationId = typeof body.conversation_id === "string" ? body.conversation_id : null;
  let history: HistoryTurn[] = [];
  if (conversationId) {
    const { data: conv } = await db.from("ai_conversations").select("id").eq("id", conversationId).eq(
      "user_id",
      user.id,
    ).maybeSingle();
    if (!conv) throw new HttpError(404, "conversation_not_found");
    if (kind === "assistant") {
      const { data: msgs } = await db.from("ai_messages").select("role, content").eq(
        "conversation_id",
        conversationId,
      )
        .order("id", { ascending: false }).limit(6);
      history = ((msgs ?? []) as HistoryTurn[]).reverse();
    }
  }

  const quota = await consumeQuota(user.id, "ask");
  const started = Date.now();
  try {
    // For follow-ups, retrieve on the last user turn + new question so context carries over.
    const lastUser = [...history].reverse().find((t) => t.role === "user")?.content ?? "";
    const sources = await retrieve(lastUser ? `${lastUser}\n${question}` : question, {
      locale,
      translationId,
      includeHadith: true,
      maxAyahs: kind === "ask_quran" ? 8 : 6,
      maxHadiths: 5,
    });
    const answer = await groundedAnswer({ question, locale, sources, history });

    if (!conversationId) {
      const { data: conv, error } = await db.from("ai_conversations").insert({
        user_id: user.id,
        kind,
        title: question.slice(0, 80),
      }).select("id").single();
      if (error) throw error;
      conversationId = conv.id;
    } else {
      await db.from("ai_conversations").update({ updated_at: new Date().toISOString() }).eq(
        "id",
        conversationId,
      );
    }
    const { error: msgErr } = await db.from("ai_messages").insert([
      { conversation_id: conversationId, user_id: user.id, role: "user", content: question },
      {
        conversation_id: conversationId,
        user_id: user.id,
        role: "assistant",
        content: answer.explanation,
        structured: answer,
        model: answer.model,
        input_tokens: answer.usage.input_tokens,
        output_tokens: answer.usage.output_tokens,
      },
    ]);
    if (msgErr) console.error("store messages failed", msgErr);

    track(user.id, kind === "ask_quran" ? "ask_quran_answered" : "assistant_answered", {
      answer_type: answer.answer_type,
      quran_count: answer.quran.length,
      hadith_count: answer.hadith.length,
      latency_ms: Date.now() - started,
      locale,
      premium: quota.premium,
    });

    return {
      conversation_id: conversationId,
      ...answer,
      quota: { remaining: quota.remaining, limit: quota.limit, premium: quota.premium },
    };
  } catch (e) {
    await refundQuota(user.id, "ask");
    throw e;
  }
}
