// Loads the six major collections + Nawawi's 40 from the open hadith-api dataset
// (github.com/fawazahmed0/hadith-api, served by jsDelivr). Grades are stored as given.
// Usage: deno task hadith
import { getJson, upsertChunks } from "./lib.ts";

const CDN = "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions";
const COLLECTIONS = [
  {
    id: 1,
    slug: "bukhari",
    name_en: "Sahih al-Bukhari",
    name_ar: "صحيح البخاري",
  },
  { id: 2, slug: "muslim", name_en: "Sahih Muslim", name_ar: "صحيح مسلم" },
  {
    id: 3,
    slug: "abudawud",
    name_en: "Sunan Abi Dawud",
    name_ar: "سنن أبي داود",
  },
  {
    id: 4,
    slug: "tirmidhi",
    name_en: "Jami` at-Tirmidhi",
    name_ar: "جامع الترمذي",
  },
  { id: 5, slug: "nasai", name_en: "Sunan an-Nasa'i", name_ar: "سنن النسائي" },
  {
    id: 6,
    slug: "ibnmajah",
    name_en: "Sunan Ibn Majah",
    name_ar: "سنن ابن ماجه",
  },
  {
    id: 7,
    slug: "nawawi",
    name_en: "40 Hadith Nawawi",
    name_ar: "الأربعون النووية",
  },
];

await upsertChunks(
  "hadith_collections",
  COLLECTIONS.map((c) => ({ ...c, source: "fawazahmed0/hadith-api" })),
  "id",
);

for (const c of COLLECTIONS) {
  const [ar, en] = await Promise.all([
    getJson(`${CDN}/ara-${c.slug}.min.json`),
    getJson(`${CDN}/eng-${c.slug}.min.json`).catch(() => ({ hadiths: [] })),
  ]);
  const enByNo = new Map(
    (en.hadiths as any[]).map((h) => [String(h.hadithnumber), h]),
  );
  const seen = new Set<number>();
  const rows = (ar.hadiths as any[]).filter((h) => h.text?.trim()).map((h) => {
    const no = String(h.hadithnumber);
    // number*10 is the stable id; sub-numbers like 3604.02 collide with 3604, so those few get a
    // separate deterministic id range (+500000, number*100) instead of breaking the upsert batch.
    let id = c.id * 1_000_000 + Math.round(Number(h.hadithnumber) * 10);
    if (seen.has(id)) {
      id = c.id * 1_000_000 + 500_000 + Math.round(Number(h.hadithnumber) * 100) % 500_000;
    }
    seen.add(id);
    const e = enByNo.get(no);
    const grade = (h.grades?.[0] ?? e?.grades?.[0]) as {
      name: string;
      grade: string;
    } | undefined;
    return {
      id,
      collection_id: c.id,
      hadith_number: no,
      book: h.reference?.book != null ? String(h.reference.book) : null,
      text_ar: h.text.trim(),
      text_en: e?.text?.trim() || null,
      grade: grade?.grade ??
        (c.slug === "bukhari" || c.slug === "muslim" ? "Sahih" : null),
      grade_source: grade?.name ?? null,
      reference: `${c.name_en} ${no}`,
    };
  });
  await upsertChunks("hadiths", rows, "id");
  console.log(`${c.slug} ✓ ${rows.length}`);
}
