import { admin } from "./supabase.ts";
import { embed, toPgVector } from "./embeddings.ts";
import { env } from "./env.ts";

export interface RetrievedAyah {
  verse_key: string; // "2:153"
  ayah_id: number;
  surah_id: number;
  ayah_number: number;
  surah_name_ar: string;
  surah_name_en: string;
  arabic: string;
  translation: string | null;
  tafsir: string | null;
  tafsir_source: string | null;
  similarity: number;
}

export interface RetrievedHadith {
  hadith_id: number;
  reference: string;
  collection: string;
  grade: string | null;
  text_ar: string;
  text_en: string | null;
  similarity: number;
}

export interface RetrievalResult {
  ayahs: RetrievedAyah[];
  hadiths: RetrievedHadith[];
}

export interface RetrieveOptions {
  locale: string;
  translationId?: number;
  includeHadith?: boolean;
  maxAyahs?: number;
  maxHadiths?: number;
}

const TAFSIR_EXCERPT_CHARS = 700;

export async function retrieve(query: string, opts: RetrieveOptions): Promise<RetrievalResult> {
  const db = admin();
  const [vector] = await embed([query], "query");
  const types = opts.includeHadith === false ? ["ayah", "tafsir"] : ["ayah", "tafsir", "hadith"];
  const { data: matches, error } = await db.rpc("match_content", {
    p_embedding: toPgVector(vector),
    p_types: types,
    p_count: 30,
    p_min_similarity: 0.3,
  });
  if (error) throw error;

  // Best similarity per ayah across its ayah-text and tafsir chunks; best per hadith.
  const ayahScore = new Map<number, number>();
  const hadithScore = new Map<number, number>();
  for (const m of matches as { source_type: string; source_id: number; similarity: number }[]) {
    const id = Number(m.source_id);
    const target = m.source_type === "hadith" ? hadithScore : ayahScore;
    target.set(id, Math.max(target.get(id) ?? 0, m.similarity));
  }
  const topAyahIds = [...ayahScore.entries()].sort((a, b) => b[1] - a[1]).slice(0, opts.maxAyahs ?? 8).map((
    [id],
  ) => id);
  const topHadithIds = [...hadithScore.entries()].sort((a, b) => b[1] - a[1]).slice(0, opts.maxHadiths ?? 5)
    .map((
      [id],
    ) => id);

  const translationId = opts.translationId ?? env.defaultTranslationId();
  const tafsirId = opts.locale === "ar" ? env.defaultTafsirArId() : env.defaultTafsirEnId();

  const [ayahRows, translationRows, tafsirRows, hadithRows] = await Promise.all([
    topAyahIds.length
      ? db.from("ayahs").select("id, surah_id, ayah_number, text_uthmani, surahs(name_ar, name_en)").in(
        "id",
        topAyahIds,
      )
      : Promise.resolve({ data: [], error: null }),
    topAyahIds.length
      ? db.from("ayah_translations").select("ayah_id, text").eq("translation_id", translationId).in(
        "ayah_id",
        topAyahIds,
      )
      : Promise.resolve({ data: [], error: null }),
    topAyahIds.length
      ? db.from("ayah_tafsir").select("ayah_id, text, tafsir_sources(name)").eq("tafsir_id", tafsirId).in(
        "ayah_id",
        topAyahIds,
      )
      : Promise.resolve({ data: [], error: null }),
    topHadithIds.length
      ? db.from("hadiths").select("id, reference, grade, text_ar, text_en, hadith_collections(name_en)").in(
        "id",
        topHadithIds,
      )
      : Promise.resolve({ data: [], error: null }),
  ]);
  for (const r of [ayahRows, translationRows, tafsirRows, hadithRows]) if (r.error) throw r.error;

  const tr = new Map((translationRows.data as any[]).map((r) => [r.ayah_id, r.text]));
  const tf = new Map((tafsirRows.data as any[]).map((r) => [r.ayah_id, r]));

  const ayahs: RetrievedAyah[] = (ayahRows.data as any[]).map((a) => ({
    verse_key: `${a.surah_id}:${a.ayah_number}`,
    ayah_id: a.id,
    surah_id: a.surah_id,
    ayah_number: a.ayah_number,
    surah_name_ar: a.surahs?.name_ar ?? "",
    surah_name_en: a.surahs?.name_en ?? "",
    arabic: a.text_uthmani,
    translation: tr.get(a.id) ?? null,
    tafsir: tf.get(a.id)?.text?.slice(0, TAFSIR_EXCERPT_CHARS) ?? null,
    tafsir_source: tf.get(a.id)?.tafsir_sources?.name ?? null,
    similarity: Math.round((ayahScore.get(a.id) ?? 0) * 1000) / 1000,
  })).sort((a, b) => b.similarity - a.similarity);

  const hadiths: RetrievedHadith[] = (hadithRows.data as any[]).map((h) => ({
    hadith_id: Number(h.id),
    reference: h.reference,
    collection: h.hadith_collections?.name_en ?? "",
    grade: h.grade,
    text_ar: h.text_ar,
    text_en: h.text_en,
    similarity: Math.round((hadithScore.get(Number(h.id)) ?? 0) * 1000) / 1000,
  })).sort((a, b) => b.similarity - a.similarity);

  return { ayahs, hadiths };
}
