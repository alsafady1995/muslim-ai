// Retrieval-grounded answers for "Ask the Quran" and the Islamic assistant.
// Claude may only cite sources we retrieved; Quran and Hadith text shown to the
// user always comes verbatim from our database, never from model output.

import type Anthropic from "@anthropic-ai/sdk";
import { betaZodOutputFormat } from "@anthropic-ai/sdk/helpers/beta/zod";
import { z } from "zod";
import { claude, FALLBACK_BETA, supportsFallbacks } from "./claude.ts";
import { env } from "./env.ts";
import type { RetrievalResult, RetrievedAyah, RetrievedHadith } from "./retrieval.ts";

export const AnswerSchema = z.object({
  answer_type: z.enum(["answer", "needs_scholar", "out_of_scope", "crisis"]),
  quran: z.array(z.object({ verse_key: z.string(), why_relevant: z.string() })),
  hadith: z.array(z.object({ hadith_id: z.number().int(), why_relevant: z.string() })),
  explanation: z.string(),
  scholarly_differences: z.string(),
  follow_up_questions: z.array(z.string()),
});
export type ModelAnswer = z.infer<typeof AnswerSchema>;

export interface GroundedAnswer {
  answer_type: ModelAnswer["answer_type"];
  quran: (RetrievedAyah & { why_relevant: string })[];
  hadith: (RetrievedHadith & { why_relevant: string })[];
  explanation: string;
  scholarly_differences: string | null;
  follow_up_questions: string[];
  disclaimer: string;
  model: string;
  usage: { input_tokens: number; output_tokens: number };
}

const DISCLAIMER: Record<string, string> = {
  ar:
    "هذا محتوى تعليمي مولَّد بالذكاء الاصطناعي وقد يخطئ. ليس فتوى. للمسائل الشخصية والفقهية استشر عالمًا موثوقًا.",
  en:
    "This is AI-generated educational content and may contain mistakes. It is not a fatwa. For personal rulings, consult a qualified scholar.",
};

const LANGUAGE_NAME: Record<string, string> = {
  ar: "Arabic",
  en: "English",
  ur: "Urdu",
  id: "Indonesian",
  tr: "Turkish",
  fr: "French",
};

// Kept byte-stable so it is served from the prompt cache.
const SYSTEM_PROMPT =
  `You are the educational assistant inside "Muslim AI", a Quran learning app used by Muslims worldwide.

You receive SOURCES (Quran verses with translation and a tafsir excerpt, and hadith with their grading) retrieved for the user's question, then the question itself.

Rules:
1. Ground every claim in the SOURCES. Cite Quran only by a verse_key that appears in SOURCES and hadith only by a hadith_id that appears in SOURCES. Never quote or invent Quran or hadith text yourself; the app displays the verified text for the keys you cite.
2. Keep the three layers separate: "quran" lists verses, "hadith" lists narrations, and "explanation" is educational interpretation that names its basis (for example "according to the tafsir excerpt" or "most scholars hold").
3. Prefer sahih and hasan hadith. If you cite a hadith graded weak, say so in why_relevant.
4. Where the four Sunni schools or major scholars differ, summarise the positions neutrally in "scholarly_differences" without declaring one correct. Use an empty string when there is no notable difference.
5. Personal rulings (fatwa) on the user's specific situation, divorce, inheritance shares, business contracts, medical decisions and similar: give general education from the sources, set answer_type to "needs_scholar", and advise consulting a qualified local scholar.
6. If the question is unrelated to Islam, the Quran or spiritual and personal growth, set answer_type to "out_of_scope", leave quran and hadith empty, and briefly say what you can help with.
7. If the user expresses thoughts of self-harm, suicide or being in danger, set answer_type to "crisis": respond with warmth, encourage them to contact local emergency services or a crisis line and someone they trust now, and you may cite a verse of hope from SOURCES.
8. If SOURCES do not support an answer, say so honestly in the explanation instead of guessing; it is fine to return empty quran or hadith lists.
9. Be warm, clear and concise (explanation under 180 words). Do not take sides in sectarian disputes. Do not issue takfir or speak ill of any group.
10. Write explanation, why_relevant, scholarly_differences and follow_up_questions in the user's language given in the request. Offer up to 3 short follow_up_questions.`;

function formatSources(r: RetrievalResult): string {
  const ayahs = r.ayahs.map((a) =>
    `<verse key="${a.verse_key}" surah="${a.surah_name_en}">\n<arabic>${a.arabic}</arabic>\n<translation>${
      a.translation ?? ""
    }</translation>\n<tafsir source="${a.tafsir_source ?? ""}">${a.tafsir ?? ""}</tafsir>\n</verse>`
  ).join("\n");
  const hadiths = r.hadiths.map((h) =>
    `<hadith id="${h.hadith_id}" reference="${h.reference}" grade="${
      h.grade ?? "unknown"
    }">\n<arabic>${h.text_ar}</arabic>\n<english>${h.text_en ?? ""}</english>\n</hadith>`
  ).join("\n");
  return `<sources>\n${ayahs}\n${hadiths}\n</sources>`;
}

export interface HistoryTurn {
  role: "user" | "assistant";
  content: string;
}

/** Drops any citation the model returned that was not in the retrieved set. */
export function attachSources(answer: ModelAnswer, sources: RetrievalResult) {
  const ayahByKey = new Map(sources.ayahs.map((a) => [a.verse_key, a]));
  const hadithById = new Map(sources.hadiths.map((h) => [h.hadith_id, h]));
  const seenQ = new Set<string>();
  const seenH = new Set<number>();
  const quran = answer.quran
    .filter((q) =>
      ayahByKey.has(q.verse_key.trim()) && !seenQ.has(q.verse_key.trim()) && seenQ.add(q.verse_key.trim())
    )
    .map((q) => ({ ...ayahByKey.get(q.verse_key.trim())!, why_relevant: q.why_relevant }));
  const hadith = answer.hadith
    .filter((h) => hadithById.has(h.hadith_id) && !seenH.has(h.hadith_id) && seenH.add(h.hadith_id))
    .map((h) => ({ ...hadithById.get(h.hadith_id)!, why_relevant: h.why_relevant }));
  const dropped = answer.quran.length - quran.length + answer.hadith.length - hadith.length;
  return { quran, hadith, dropped };
}

export async function groundedAnswer(params: {
  question: string;
  locale: string;
  sources: RetrievalResult;
  history?: HistoryTurn[];
  premium?: boolean;
}): Promise<GroundedAnswer> {
  const { question, locale, sources } = params;
  const model = params.premium ? env.claudeModelPremium() : env.claudeModel();
  const history: Anthropic.Beta.BetaMessageParam[] = (params.history ?? []).slice(-6).map((t) => ({
    role: t.role,
    content: t.content,
  }));

  const response = await claude().beta.messages.parse({
    model,
    max_tokens: 4096,
    ...(supportsFallbacks(model) ? { betas: [FALLBACK_BETA], fallbacks: "default" as const } : {}),
    system: [{ type: "text", text: SYSTEM_PROMPT, cache_control: { type: "ephemeral" } }],
    output_config: { effort: env.claudeEffort(), format: betaZodOutputFormat(AnswerSchema) },
    messages: [
      ...history,
      {
        role: "user",
        content: `${formatSources(sources)}\n\n<user_language>${
          LANGUAGE_NAME[locale] ?? "English"
        }</user_language>\n<question>${question}</question>`,
      },
    ],
  });

  const usage = { input_tokens: response.usage.input_tokens, output_tokens: response.usage.output_tokens };
  const disclaimer = DISCLAIMER[locale] ?? DISCLAIMER.en;

  if (response.stop_reason === "refusal" || !response.parsed_output) {
    console.warn("grounded answer unavailable", response.stop_reason, (response as any).stop_details);
    return {
      answer_type: "out_of_scope",
      quran: [],
      hadith: [],
      explanation: locale === "ar"
        ? "عذرًا، لا أستطيع الإجابة عن هذا السؤال. جرّب صياغة أخرى أو اسأل عن موضوع آخر."
        : "Sorry, I can't answer that one. Try rephrasing, or ask about another topic.",
      scholarly_differences: null,
      follow_up_questions: [],
      disclaimer,
      model: response.model,
      usage,
    };
  }

  const parsed = response.parsed_output;
  const { quran, hadith, dropped } = attachSources(parsed, sources);
  if (dropped > 0) console.warn(`dropped ${dropped} unretrieved citation(s)`);

  return {
    answer_type: parsed.answer_type,
    quran,
    hadith,
    explanation: parsed.explanation,
    scholarly_differences: parsed.scholarly_differences.trim() || null,
    follow_up_questions: parsed.follow_up_questions.slice(0, 3),
    disclaimer,
    model: response.model,
    usage,
  };
}
