// Loads surahs, ayahs, words, one translation per language and tafsir from the Quran.com API v4.
// Usage: SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... deno task quran
// Licensing: Quran text is public domain; each translation/tafsir has its own licence and
// is recorded in the translations / tafsir_sources tables. Confirm before launch (BLOCKERS.md).
import { env, getJson, normalizeArabic, upsertChunks } from "./lib.ts";

const API = env("QURAN_API_BASE", "https://api.quran.com/api/v4");
// Quran.com resource ids (override via env if the catalogue changes)
const TRANSLATIONS = [
  {
    id: Number(env("QURAN_TRANSLATION_EN", "20")),
    language: "en",
    name: "Saheeh International",
    author: "Saheeh International",
  },
];
const TAFSIRS = [
  {
    id: Number(env("QURAN_TAFSIR_AR", "16")),
    dbId: 1,
    language: "ar",
    name: "التفسير الميسر",
    author: "King Fahd Complex",
  },
  {
    id: Number(env("QURAN_TAFSIR_EN", "169")),
    dbId: 2,
    language: "en",
    name: "Tafsir Ibn Kathir (abridged)",
    author: "Ibn Kathir",
  },
];

const chapters = (await getJson(`${API}/chapters?language=en`))
  .chapters as any[];
await upsertChunks(
  "surahs",
  chapters.map((c) => ({
    id: c.id,
    name_ar: c.name_arabic,
    name_en: c.translated_name.name,
    transliteration: c.name_simple,
    revelation_place: c.revelation_place === "madinah" ? "madinah" : "makkah",
    ayah_count: c.verses_count,
  })),
  "id",
);
await upsertChunks(
  "translations",
  TRANSLATIONS.map((t) => ({ ...t, source: "quran.com" })),
  "id",
);
await upsertChunks(
  "tafsir_sources",
  TAFSIRS.map((t) => ({
    id: t.dbId,
    language: t.language,
    name: t.name,
    author: t.author,
    source: "quran.com",
  })),
  "id",
);

let globalId = 0;
for (const c of chapters) {
  const ayahs: any[] = [];
  const words: any[] = [];
  const translations: any[] = [];
  let page = 1;
  while (true) {
    const url =
      `${API}/verses/by_chapter/${c.id}?language=en&words=true&per_page=50&page=${page}` +
      `&fields=text_uthmani,text_imlaei_simple,juz_number,page_number,rub_el_hizb_number` +
      `&word_fields=text_uthmani,text_imlaei_simple&translations=${
        TRANSLATIONS.map((t) => t.id).join(",")
      }`;
    const body = await getJson(url);
    for (const v of body.verses) {
      const id = ++globalId;
      ayahs.push({
        id,
        surah_id: c.id,
        ayah_number: v.verse_number,
        text_uthmani: v.text_uthmani,
        text_simple: normalizeArabic(v.text_imlaei_simple ?? v.text_uthmani),
        juz: v.juz_number,
        hizb_quarter: v.rub_el_hizb_number ?? null,
        page: v.page_number,
      });
      let pos = 0;
      for (const w of v.words.filter((w: any) => w.char_type_name === "word")) {
        words.push({
          ayah_id: id,
          position: ++pos,
          text_uthmani: w.text_uthmani,
          text_simple: normalizeArabic(w.text_imlaei_simple ?? w.text_uthmani),
        });
      }
      for (const t of v.translations ?? []) {
        translations.push({
          translation_id: t.resource_id,
          ayah_id: id,
          text: String(t.text).replace(/<sup[^>]*>.*?<\/sup>/g, "").replace(
            /<[^>]+>/g,
            "",
          ),
        });
      }
    }
    if (!body.pagination?.next_page) break;
    page = body.pagination.next_page;
  }
  await upsertChunks("ayahs", ayahs, "id");
  await upsertChunks("ayah_words", words, "ayah_id,position");
  await upsertChunks(
    "ayah_translations",
    translations,
    "translation_id,ayah_id",
  );

  for (const t of TAFSIRS) {
    const tafsir = await getJson(
      `${API}/tafsirs/${t.id}/by_chapter/${c.id}?per_page=300`,
    );
    const firstId = ayahs[0].id - 1;
    await upsertChunks(
      "ayah_tafsir",
      (tafsir.tafsirs as any[]).map((x) => ({
        tafsir_id: t.dbId,
        ayah_id: firstId + Number(String(x.verse_key).split(":")[1]),
        text: String(x.text).replace(/<[^>]+>/g, " ").replace(/\s+/g, " ")
          .trim(),
      })).filter((x) => x.text),
      "tafsir_id,ayah_id",
    );
  }
  console.log(`surah ${c.id} ✓ (${ayahs.length} ayahs, ${words.length} words)`);
}
if (globalId !== 6236) console.warn(`expected 6236 ayahs, loaded ${globalId}`);
