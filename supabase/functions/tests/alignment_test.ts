import { assert, assertEquals } from "@std/assert";
import { analyzeRecitation, type ExpectedWord, type HeardWord, scoreToGrade } from "../_shared/alignment.ts";
import { normalizeArabic, wordSimilarity } from "../_shared/arabic.ts";

const FATIHA_1_2: ExpectedWord[] = [
  [1, 1, "بِسْمِ", "بسم"],
  [1, 2, "ٱللَّهِ", "الله"],
  [1, 3, "ٱلرَّحْمَٰنِ", "الرحمن"],
  [1, 4, "ٱلرَّحِيمِ", "الرحيم"],
  [2, 1, "ٱلْحَمْدُ", "الحمد"],
  [2, 2, "لِلَّهِ", "لله"],
  [2, 3, "رَبِّ", "رب"],
  [2, 4, "ٱلْعَٰلَمِينَ", "العالمين"],
].map(([ayahId, position, uthmani, simple]) => ({
  ayahId: ayahId as number,
  position: position as number,
  uthmani: uthmani as string,
  simple: simple as string,
}));

function heard(words: string[], step = 0.6): HeardWord[] {
  return words.map((w, i) => ({ word: w, start: i * step, end: i * step + step * 0.9, probability: 0.95 }));
}

Deno.test("normalization unifies alef forms and strips harakat", () => {
  assertEquals(normalizeArabic("ٱلرَّحْمَٰنِ"), "الرحمن");
  assertEquals(normalizeArabic("إِيَّاكَ"), "اياك");
  assertEquals(normalizeArabic("رَحْمَةٌ"), "رحمه");
  assert(wordSimilarity("العالمين", "العلمين") >= 0.85);
});

Deno.test("perfect recitation scores 100 with no mistakes", () => {
  const r = analyzeRecitation(
    FATIHA_1_2,
    heard(["بِسْمِ", "اللَّهِ", "الرَّحْمَنِ", "الرَّحِيمِ", "الْحَمْدُ", "لِلَّهِ", "رَبِّ", "الْعَالَمِينَ"]),
  );
  assertEquals(r.wordsCorrect, 8);
  assertEquals(r.mistakes.filter((m) => m.type !== "possible_short_madd").length, 0);
  assertEquals(r.accuracy, 100);
  assert(r.completed);
});

Deno.test("skipped word is detected in the middle", () => {
  const r = analyzeRecitation(FATIHA_1_2, heard(["بسم", "الله", "الرحيم", "الحمد", "لله", "رب", "العالمين"]));
  const skipped = r.mistakes.filter((m) => m.type === "skipped");
  assertEquals(skipped.length, 1);
  assertEquals(skipped[0].ayahId, 1);
  assertEquals(skipped[0].position, 3);
  assert(r.accuracy < 100);
});

Deno.test("mispronounced and wrong words are distinguished", () => {
  // الرحيم -> الرحين (one letter off: mispronounced); رب -> ملك (wrong word)
  const r = analyzeRecitation(
    FATIHA_1_2,
    heard(["بسم", "الله", "الرحمن", "الرحين", "الحمد", "لله", "ملك", "العالمين"]),
  );
  const byPos = Object.fromEntries(r.words.map((w) => [`${w.ayahId}:${w.position}`, w.status]));
  assertEquals(byPos["1:4"], "mispronounced");
  assertEquals(byPos["2:3"], "wrong");
});

Deno.test("stopping early is not counted as skipping", () => {
  const r = analyzeRecitation(FATIHA_1_2, heard(["بسم", "الله", "الرحمن", "الرحيم"]));
  assertEquals(r.mistakes.filter((m) => m.type === "skipped").length, 0);
  assertEquals(r.words.filter((w) => w.status === "not_recited").length, 4);
  assertEquals(r.accuracy, 100);
  assertEquals(r.completed, false);
  assert(scoreToGrade(r.overall, r.completed) <= 2);
});

Deno.test("repetition and added words are reported", () => {
  const r = analyzeRecitation(
    FATIHA_1_2,
    heard(["بسم", "الله", "الله", "الرحمن", "الرحيم", "الحمد", "لله", "رب", "العالمين"]),
  );
  assertEquals(r.mistakes.filter((m) => m.type === "repetition").length, 1);
  assertEquals(r.wordsCorrect, 8);
});

Deno.test("low-confidence wrong word becomes unclear", () => {
  const h = heard(["بسم", "الله", "الرحمن", "الرحيم", "الحمد", "لله", "رب", "العالمين"]);
  h[6] = { ...h[6], word: "ملك", probability: 0.2 };
  const r = analyzeRecitation(FATIHA_1_2, h);
  assertEquals(r.words[6].status, "unclear");
});

Deno.test("long pause inside an ayah is flagged", () => {
  const h = heard(["بسم", "الله", "الرحمن", "الرحيم", "الحمد", "لله", "رب", "العالمين"]);
  for (let i = 7; i < h.length; i++) h[i] = { ...h[i], start: h[i].start + 4, end: h[i].end + 4 };
  const r = analyzeRecitation(FATIHA_1_2, h);
  assertEquals(r.mistakes.filter((m) => m.type === "long_pause").length, 1);
  assert(r.fluency < 100);
});

Deno.test("grades map to SM-2 range", () => {
  assertEquals(scoreToGrade(99, true), 5);
  assertEquals(scoreToGrade(72, true), 3);
  assertEquals(scoreToGrade(10, true), 0);
});
