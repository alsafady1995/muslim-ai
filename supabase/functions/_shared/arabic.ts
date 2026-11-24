// Arabic text normalization for comparing Quran text with ASR output.

const DIACRITICS = /[ؐ-ًؚ-ٰٟۖ-ۭ࣓-ࣿ]/g;
const TATWEEL = /ـ/g;
const NON_ARABIC = /[^ء-ي\s]/g;

/** Strips harakat, Quranic annotation marks and tatweel; unifies letter variants. */
export function normalizeArabic(input: string): string {
  return input
    .normalize("NFC")
    .replace(DIACRITICS, "")
    .replace(TATWEEL, "")
    .replace(/[ٱآأإ]/g, "ا") // ٱ آ أ إ -> ا
    .replace(/ى/g, "ي") // ى -> ي
    .replace(/ة/g, "ه") // ة -> ه
    .replace(/ؤ/g, "و") // ؤ -> و
    .replace(/ئ/g, "ي") // ئ -> ي
    .replace(NON_ARABIC, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export function tokenize(input: string): string[] {
  const n = normalizeArabic(input);
  return n ? n.split(" ") : [];
}

export function levenshtein(a: string, b: string): number {
  if (a === b) return 0;
  if (!a.length) return b.length;
  if (!b.length) return a.length;
  let prev = Array.from({ length: b.length + 1 }, (_, i) => i);
  for (let i = 1; i <= a.length; i++) {
    const cur = [i];
    for (let j = 1; j <= b.length; j++) {
      cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
    }
    prev = cur;
  }
  return prev[b.length];
}

/** 0..1 character similarity of two normalized words. */
export function wordSimilarity(a: string, b: string): number {
  const max = Math.max(a.length, b.length);
  if (max === 0) return 1;
  return 1 - levenshtein(a, b) / max;
}

/** Uthmani word contains a madd sign (maddah above U+0653) or a dagger alif (U+0670). */
export function hasMaddMark(uthmaniWord: string): boolean {
  return /[ٰٓ]/.test(uthmaniWord);
}

const HAS_ARABIC = /[\u0600-\u06FF]/;

/**
 * Keyword search input: Arabic is normalized exactly like ayahs.text_simple (diacritics,
 * alif and ya forms), so "الرَّحْمَٰن" and "الرحمن" find the same ayahs. Other scripts
 * (translation search) are only trimmed.
 */
export function keywordQuery(input: string): string {
  const q = input.trim();
  return HAS_ARABIC.test(q) ? normalizeArabic(q) || q : q;
}
