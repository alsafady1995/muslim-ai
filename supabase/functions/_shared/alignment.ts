// Recitation analysis: align what the user recited (ASR words with timestamps)
// against the expected Quran words and turn the alignment into mistakes and scores.
//
// The ASR is run WITHOUT the expected text as a prompt, so the transcript reflects
// what was actually said. Alignment is global Needleman-Wunsch over normalized words.

import { hasMaddMark, normalizeArabic, wordSimilarity } from "./arabic.ts";

export interface ExpectedWord {
  ayahId: number;
  position: number;
  uthmani: string;
  simple: string;
}

export interface HeardWord {
  word: string;
  start: number; // seconds
  end: number; // seconds
  probability?: number;
}

export type WordStatus = "correct" | "mispronounced" | "wrong" | "skipped" | "unclear" | "not_recited";

export interface WordResult {
  ayahId: number;
  position: number;
  text: string;
  status: WordStatus;
  heard?: string;
  similarity?: number;
  startMs?: number;
  endMs?: number;
}

export type MistakeType =
  | "mispronounced"
  | "wrong_word"
  | "skipped"
  | "added_word"
  | "repetition"
  | "unclear"
  | "possible_short_madd"
  | "long_pause";

export interface Mistake {
  type: MistakeType;
  ayahId?: number;
  position?: number;
  expected?: string;
  heard?: string;
  similarity?: number;
  startMs?: number;
  endMs?: number;
}

export interface AnalysisResult {
  words: WordResult[];
  mistakes: Mistake[];
  wordsTotal: number;
  wordsCorrect: number;
  accuracy: number;
  fluency: number;
  tajweed: number | null;
  overall: number;
  completed: boolean;
}

export const THRESHOLDS = {
  correct: 0.85,
  partial: 0.5,
  lowProbability: 0.4,
  longPauseSec: 2.5,
  shortMaddRatio: 0.6,
};

const GAP = -0.6;

function pairScore(sim: number): number {
  return sim >= THRESHOLDS.partial ? 2 * sim - 0.5 : -1;
}

type Op = { kind: "pair"; e: number; h: number; sim: number } | { kind: "del"; e: number } | {
  kind: "ins";
  h: number;
};

export function align(expected: string[], heard: string[]): Op[] {
  const n = expected.length;
  const m = heard.length;
  const score: Float64Array[] = Array.from({ length: n + 1 }, () => new Float64Array(m + 1));
  const sims: Float64Array[] = Array.from({ length: n + 1 }, () => new Float64Array(m + 1));
  for (let i = 1; i <= n; i++) score[i][0] = i * GAP;
  for (let j = 1; j <= m; j++) score[0][j] = j * GAP;
  for (let i = 1; i <= n; i++) {
    for (let j = 1; j <= m; j++) {
      const s = wordSimilarity(expected[i - 1], heard[j - 1]);
      sims[i][j] = s;
      score[i][j] = Math.max(
        score[i - 1][j - 1] + pairScore(s),
        score[i - 1][j] + GAP,
        score[i][j - 1] + GAP,
      );
    }
  }
  const ops: Op[] = [];
  let i = n;
  let j = m;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && score[i][j] === score[i - 1][j - 1] + pairScore(sims[i][j])) {
      ops.push({ kind: "pair", e: i - 1, h: j - 1, sim: sims[i][j] });
      i--;
      j--;
    } else if (i > 0 && score[i][j] === score[i - 1][j] + GAP) {
      ops.push({ kind: "del", e: i - 1 });
      i--;
    } else {
      ops.push({ kind: "ins", h: j - 1 });
      j--;
    }
  }
  return ops.reverse();
}

const clamp = (v: number) => Math.max(0, Math.min(100, Math.round(v * 100) / 100));

export function analyzeRecitation(expectedWords: ExpectedWord[], heardWords: HeardWord[]): AnalysisResult {
  const exp = expectedWords.map((w) => normalizeArabic(w.simple || w.uthmani));
  const heardNorm = heardWords.map((w) => normalizeArabic(w.word));
  // drop tokens that normalize to nothing (punctuation, Latin noise)
  const heardIdx = heardNorm.map((w, i) => (w ? i : -1)).filter((i) => i >= 0);
  const ops = align(exp, heardIdx.map((i) => heardNorm[i]));

  const words: WordResult[] = expectedWords.map((w) => ({
    ayahId: w.ayahId,
    position: w.position,
    text: w.uthmani,
    status: "skipped" as WordStatus,
  }));
  const mistakes: Mistake[] = [];

  // last expected index that was matched: anything after it was simply not recited yet
  let lastMatched = -1;
  for (const op of ops) if (op.kind === "pair") lastMatched = Math.max(lastMatched, op.e);

  let prevExpected = -1;
  for (let k = 0; k < ops.length; k++) {
    const op = ops[k];
    if (op.kind === "pair") {
      const h = heardWords[heardIdx[op.h]];
      const w = words[op.e];
      w.heard = h.word;
      w.similarity = Math.round(op.sim * 100) / 100;
      w.startMs = Math.round(h.start * 1000);
      w.endMs = Math.round(h.end * 1000);
      const lowProb = h.probability !== undefined && h.probability < THRESHOLDS.lowProbability;
      if (op.sim >= THRESHOLDS.correct) w.status = "correct";
      else if (lowProb) w.status = "unclear";
      else if (op.sim >= THRESHOLDS.partial) w.status = "mispronounced";
      else w.status = "wrong";
      if (w.status !== "correct") {
        mistakes.push({
          type: w.status === "wrong" ? "wrong_word" : (w.status as MistakeType),
          ayahId: w.ayahId,
          position: w.position,
          expected: w.text,
          heard: h.word,
          similarity: w.similarity,
          startMs: w.startMs,
          endMs: w.endMs,
        });
      }
      prevExpected = op.e;
    } else if (op.kind === "del") {
      const w = words[op.e];
      if (op.e > lastMatched) {
        w.status = "not_recited";
      } else {
        w.status = "skipped";
        mistakes.push({ type: "skipped", ayahId: w.ayahId, position: w.position, expected: w.text });
      }
    } else {
      const h = heardWords[heardIdx[op.h]];
      const norm = heardNorm[heardIdx[op.h]];
      // A repeated word may be aligned on either side of the extra token.
      const next = ops.slice(k + 1).find((o) => o.kind === "pair") as { e: number } | undefined;
      const isRepeat = [prevExpected, next?.e ?? -1].some((e) =>
        e >= 0 && wordSimilarity(norm, exp[e]) >= THRESHOLDS.correct
      );
      mistakes.push({
        type: isRepeat ? "repetition" : "added_word",
        heard: h.word,
        startMs: Math.round(h.start * 1000),
        endMs: Math.round(h.end * 1000),
        ...(prevExpected >= 0
          ? { ayahId: words[prevExpected].ayahId, position: words[prevExpected].position }
          : {}),
      });
    }
  }

  // Long pauses inside an ayah (pauses at ayah boundaries are natural)
  const matched = words.filter((w) => w.startMs !== undefined);
  let longPauses = 0;
  for (let k = 1; k < matched.length; k++) {
    const a = matched[k - 1];
    const b = matched[k];
    if (a.ayahId === b.ayahId && (b.startMs! - a.endMs!) / 1000 > THRESHOLDS.longPauseSec) {
      longPauses++;
      mistakes.push({
        type: "long_pause",
        ayahId: b.ayahId,
        position: b.position,
        startMs: a.endMs,
        endMs: b.startMs,
      });
    }
  }

  // Tajweed heuristic (MVP): words carrying a madd sign that were recited noticeably
  // faster per letter than the reciter's own median are flagged as a *possible* short madd.
  let tajweed: number | null = null;
  const timed = words.filter((w) =>
    w.status === "correct" && w.startMs !== undefined && w.endMs! > w.startMs!
  );
  if (timed.length >= 5) {
    const perChar = (w: WordResult) => (w.endMs! - w.startMs!) / Math.max(normalizeArabic(w.text).length, 1);
    const sorted = timed.map(perChar).sort((a, b) => a - b);
    const median = sorted[Math.floor(sorted.length / 2)];
    let flagged = 0;
    for (const w of timed) {
      if (hasMaddMark(w.text) && perChar(w) < median * THRESHOLDS.shortMaddRatio) {
        flagged++;
        mistakes.push({
          type: "possible_short_madd",
          ayahId: w.ayahId,
          position: w.position,
          expected: w.text,
          startMs: w.startMs,
          endMs: w.endMs,
        });
      }
    }
    tajweed = clamp(100 - flagged * 8);
  }

  const attempted = words.filter((w) => w.status !== "not_recited");
  const total = attempted.length;
  const correct = attempted.filter((w) => w.status === "correct").length;
  const partial = attempted.filter((w) => w.status === "mispronounced" || w.status === "unclear").length;
  const added = mistakes.filter((m) => m.type === "added_word").length;
  const repeats = mistakes.filter((m) => m.type === "repetition").length;

  const accuracy = total === 0 ? 0 : clamp(((correct + 0.5 * partial - 0.25 * added) / total) * 100);
  const fluency = total === 0 ? 0 : clamp(100 - longPauses * 6 - repeats * 3);
  const overall = tajweed === null
    ? clamp(accuracy * 0.8 + fluency * 0.2)
    : clamp(accuracy * 0.7 + fluency * 0.15 + tajweed * 0.15);

  return {
    words,
    mistakes,
    wordsTotal: total,
    wordsCorrect: correct,
    accuracy,
    fluency,
    tajweed,
    overall,
    completed: total === expectedWords.length,
  };
}

/** Maps an overall score to a 0-5 SM-2 grade for the hifz scheduler. */
export function scoreToGrade(overall: number, completed: boolean): number {
  if (!completed) return Math.min(2, Math.floor(overall / 40));
  if (overall >= 95) return 5;
  if (overall >= 85) return 4;
  if (overall >= 70) return 3;
  if (overall >= 50) return 2;
  if (overall >= 25) return 1;
  return 0;
}
