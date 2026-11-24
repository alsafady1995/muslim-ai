// POST /functions/v1/quran-search
// { query: string, locale?: string, mode?: "semantic"|"keyword", limit?: number, translation_id?: number }
// semantic: natural-language search ("verses about patience"), uses the daily "search" quota.
// keyword: free text match on Arabic / translation, no quota.
import { handler, HttpError, json } from "../_shared/http.ts";
import { admin, requireUser } from "../_shared/supabase.ts";
import { beginAiCall, cancelAiCall, finishAiCall, quotaInfo } from "../_shared/quota.ts";
import { embeddingCostUsd } from "../_shared/ai_cost.ts";
import { retrieve } from "../_shared/retrieval.ts";
import { env } from "../_shared/env.ts";
import { track } from "../_shared/analytics.ts";
import { keywordQuery } from "../_shared/arabic.ts";

Deno.serve(handler(async (req, body) => {
  const user = await requireUser(req);
  const query = typeof body.query === "string" ? body.query.trim() : "";
  if (query.length < 2 || query.length > 200) throw new HttpError(400, "invalid_query");
  const locale = typeof body.locale === "string" ? body.locale : "ar";
  const limit = Math.min(Math.max(Number(body.limit) || 10, 1), 20);
  const translationId = typeof body.translation_id === "number"
    ? body.translation_id
    : env.defaultTranslationId();

  if (body.mode === "keyword") {
    const { data, error } = await admin().rpc("search_ayahs_keyword", {
      p_query: keywordQuery(query),
      p_translation_id: translationId,
      p_limit: limit,
    });
    if (error) throw error;
    return json({ mode: "keyword", results: data });
  }

  const ai = await beginAiCall(user.id, "search", embeddingCostUsd());
  try {
    const { ayahs } = await retrieve(query, { locale, translationId, includeHadith: false, maxAyahs: limit });
    await finishAiCall(ai, embeddingCostUsd(), "embedding");
    track(user.id, "quran_search", { mode: "semantic", results: ayahs.length, locale });
    return json({
      mode: "semantic",
      results: ayahs.map((a) => ({
        verse_key: a.verse_key,
        ayah_id: a.ayah_id,
        surah_id: a.surah_id,
        ayah_number: a.ayah_number,
        surah_name_ar: a.surah_name_ar,
        surah_name_en: a.surah_name_en,
        arabic: a.arabic,
        translation: a.translation,
        explanation: a.tafsir,
        tafsir_source: a.tafsir_source,
        relevance: a.similarity,
      })),
      quota: quotaInfo(ai),
    });
  } catch (e) {
    await cancelAiCall(ai);
    throw e;
  }
}));
