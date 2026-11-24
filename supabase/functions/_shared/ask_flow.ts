import { admin, type AuthedUser } from "./supabase.ts";
import { HttpError } from "./http.ts";
import { beginAiCall, cancelAiCall, finishAiCall, quotaInfo } from "./quota.ts";
import { type RetrievalResult, retrieve } from "./retrieval.ts";
import {
  ANSWER_MAX_TOKENS,
  formatSources,
  groundedAnswer,
  type HistoryTurn,
  SYSTEM_PROMPT,
} from "./grounded.ts";
import { track } from "./analytics.ts";
import { env } from "./env.ts";
import { claudeCostUsd, claudeReserveUsd, embeddingCostUsd, estimateTokens, roundUsd } from "./ai_cost.ts";

/** Input side of the cost reservation; sources are trimmed so the prompt never exceeds it. */
const MAX_INPUT_TOKENS = 16_000;

/** Drops the lowest-ranked hadith, then ayahs, until the prompt fits the reserved input budget. */
export function fitSources(sources: RetrievalResult, fixedTokens: number, maxTokens = MAX_INPUT_TOKENS) {
  const out = { ayahs: [...sources.ayahs], hadiths: [...sources.hadiths] };
  while (fixedTokens + estimateTokens(formatSources(out)) > maxTokens) {
    if (out.hadiths.length) out.hadiths.pop();
    else if (out.ayahs.length) out.ayahs.pop();
    else break;
  }
  return out;
}

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

  // Reserve the worst case before spending anything. Premium falls back to the cheaper
  // model when the full one no longer fits this month's budget (graceful degradation).
  const premiumModel = env.claudeModelPremium();
  const cheapModel = env.claudeModel();
  const reserve = (model: string) =>
    embeddingCostUsd() + claudeReserveUsd(model, MAX_INPUT_TOKENS, ANSWER_MAX_TOKENS);
  const ai = await beginAiCall(user.id, "ask", reserve(premiumModel), reserve(cheapModel));
  // Free users always get the cheaper model; premium gets it only when degraded.
  const model = ai.premium && !ai.degraded ? premiumModel : cheapModel;
  const degraded = ai.degraded;
  let spent = 0;
  const started = Date.now();
  try {
    // For follow-ups, retrieve on the last user turn + new question so context carries over.
    const lastUser = [...history].reverse().find((t) => t.role === "user")?.content ?? "";
    const retrieved = await retrieve(lastUser ? `${lastUser}\n${question}` : question, {
      locale,
      translationId,
      includeHadith: true,
      maxAyahs: kind === "ask_quran" ? 8 : 6,
      maxHadiths: 5,
    });
    spent += embeddingCostUsd();
    const fixed = estimateTokens(SYSTEM_PROMPT + question + history.map((t) => t.content).join("")) + 2_000;
    const sources = fitSources(retrieved, fixed);
    const answer = await groundedAnswer({ question, locale, sources, history, premium: ai.premium, model });
    spent += claudeCostUsd(answer.model, answer.usage);

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
      premium: ai.premium,
      degraded,
      cost_usd: roundUsd(spent),
    });
    await finishAiCall(ai, roundUsd(spent), answer.model, { kind, usage: answer.usage, degraded });

    return {
      conversation_id: conversationId,
      ...answer,
      quota: { ...quotaInfo(ai), degraded },
    };
  } catch (e) {
    await cancelAiCall(ai, roundUsd(spent));
    throw e;
  }
}
