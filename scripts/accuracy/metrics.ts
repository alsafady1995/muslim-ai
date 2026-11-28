// Scoring for the recitation accuracy benchmark. Pure functions, no I/O, so the same
// numbers come out whether the predictions are ours (ASR + alignment) or another
// app's (typed in by hand from Tarteel's screen, for example).
//
// Ground truth comes from the person who recorded the clip: every word of the range is
// correct unless they marked it as a mistake. A prediction gives each word one verdict:
//   ok     - shown as correct
//   flag   - shown as a mistake (wrong, mispronounced, skipped, or missing at the end)
//   unsure - shown as "not sure" (our "unclear" status)

import type { WordStatus } from "../../supabase/functions/_shared/alignment.ts";

export type Verdict = "ok" | "flag" | "unsure";
export type MistakeLabel = "wrong" | "mispronounced" | "skipped";

export interface WordRef {
  ayahId: number;
  position: number;
}

export interface ClipTruth {
  id: string;
  words: WordRef[];
  mistakes: (WordRef & { type?: MistakeLabel })[];
  /** Breakdown keys, e.g. { speaker: "child", native_arabic: "no", environment: "noisy", surah: "1" } */
  tags: Record<string, string>;
}

export interface ClipPrediction {
  id: string;
  /** Verdict per word key (see wordKey). Words without an entry count as "ok". */
  verdicts: Map<string, Verdict>;
  latencyMs?: number;
  durationSec?: number;
}

export interface ClipScore {
  id: string;
  tags: Record<string, string>;
  correctWords: number;
  falseFlags: number;
  unsureOnCorrect: number;
  mistakes: number;
  caught: number;
  unsureOnMistake: number;
  latencyMs?: number;
  durationSec?: number;
  /** Word keys flagged although the reciter said they were correct (for review). */
  falseFlagWords: string[];
  /** Word keys the reciter marked as mistakes that were shown as correct. */
  missedWords: string[];
}

export interface Summary {
  clips: number;
  cleanClips: number;
  words: number;
  correctWords: number;
  mistakes: number;
  falseFlags: number;
  caught: number;
  /** Share of correctly recited words shown as a mistake. The number users feel most. */
  falseFlagRate: number;
  /** Share of correctly recited words shown as "not sure". */
  unsureRate: number;
  /** Share of clips recited with no mistake that still got at least one false flag. */
  cleanClipFalseFlagRate: number;
  /** Share of real mistakes shown as a mistake. */
  recall: number;
  /** Share of real mistakes shown as a mistake or as "not sure". */
  recallWithUnsure: number;
  /** Share of flags that were real mistakes. */
  precision: number;
  latencyP50Ms: number | null;
  latencyP95Ms: number | null;
  /** Processing seconds per second of audio (median). Below 1 = faster than real time. */
  realTimeFactor: number | null;
}

export const wordKey = (w: WordRef) => `${w.ayahId}:${w.position}`;

/** Our analysis statuses mapped to what the user sees. */
export function verdictOf(status: WordStatus): Verdict {
  switch (status) {
    case "correct":
      return "ok";
    case "unclear":
      return "unsure";
    default:
      // wrong, mispronounced, skipped, and not_recited: the reciter read the whole range,
      // so a word we did not hear at the end is a miss of ours, shown to them as unread.
      return "flag";
  }
}

export function scoreClip(truth: ClipTruth, pred: ClipPrediction): ClipScore {
  const mistakeKeys = new Set(truth.mistakes.map(wordKey));
  const s: ClipScore = {
    id: truth.id,
    tags: truth.tags,
    correctWords: 0,
    falseFlags: 0,
    unsureOnCorrect: 0,
    mistakes: 0,
    caught: 0,
    unsureOnMistake: 0,
    latencyMs: pred.latencyMs,
    durationSec: pred.durationSec,
    falseFlagWords: [],
    missedWords: [],
  };
  for (const w of truth.words) {
    const key = wordKey(w);
    const v = pred.verdicts.get(key) ?? "ok";
    if (mistakeKeys.has(key)) {
      s.mistakes++;
      if (v === "flag") s.caught++;
      else if (v === "unsure") s.unsureOnMistake++;
      else s.missedWords.push(key);
    } else {
      s.correctWords++;
      if (v === "flag") {
        s.falseFlags++;
        s.falseFlagWords.push(key);
      } else if (v === "unsure") s.unsureOnCorrect++;
    }
  }
  return s;
}

const ratio = (a: number, b: number) => (b === 0 ? 0 : a / b);

function percentile(values: number[], p: number): number | null {
  if (!values.length) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const idx = Math.min(sorted.length - 1, Math.max(0, Math.ceil((p / 100) * sorted.length) - 1));
  return sorted[idx];
}

export function summarize(scores: ClipScore[]): Summary {
  const sum = (f: (s: ClipScore) => number) => scores.reduce((a, s) => a + f(s), 0);
  const clean = scores.filter((s) => s.mistakes === 0);
  const correctWords = sum((s) => s.correctWords);
  const mistakes = sum((s) => s.mistakes);
  const falseFlags = sum((s) => s.falseFlags);
  const caught = sum((s) => s.caught);
  const latencies = scores.map((s) => s.latencyMs).filter((v): v is number => typeof v === "number");
  const rtf = scores
    .filter((s) => typeof s.latencyMs === "number" && (s.durationSec ?? 0) > 0)
    .map((s) => s.latencyMs! / 1000 / s.durationSec!);
  return {
    clips: scores.length,
    cleanClips: clean.length,
    words: correctWords + mistakes,
    correctWords,
    mistakes,
    falseFlags,
    caught,
    falseFlagRate: ratio(falseFlags, correctWords),
    unsureRate: ratio(sum((s) => s.unsureOnCorrect), correctWords),
    cleanClipFalseFlagRate: ratio(clean.filter((s) => s.falseFlags > 0).length, clean.length),
    recall: ratio(caught, mistakes),
    recallWithUnsure: ratio(caught + sum((s) => s.unsureOnMistake), mistakes),
    precision: ratio(caught, caught + falseFlags),
    latencyP50Ms: percentile(latencies, 50),
    latencyP95Ms: percentile(latencies, 95),
    realTimeFactor: percentile(rtf, 50),
  };
}

/** Summaries per value of one tag, e.g. per speaker group. Sorted by tag value. */
export function summarizeBy(scores: ClipScore[], tag: string): [string, Summary][] {
  const groups = new Map<string, ClipScore[]>();
  for (const s of scores) {
    const v = s.tags[tag] ?? "unknown";
    groups.set(v, [...(groups.get(v) ?? []), s]);
  }
  return [...groups.entries()].sort(([a], [b]) => a.localeCompare(b, "en", { numeric: true }))
    .map(([v, g]) => [v, summarize(g)]);
}

export interface Gate {
  name: string;
  metric: keyof Summary;
  op: "<=" | ">=";
  target: number;
  /** The gate has no data (and cannot pass) while this count is 0. */
  needs: "cleanClips" | "correctWords" | "mistakes";
}

/**
 * Proposed launch gates. A false "mistake" on a correct recitation is what loses users
 * (and reviews), so the first two are the strict ones.
 */
export const DEFAULT_GATES: Gate[] = [
  {
    name: "Clean recitations with any false flag",
    metric: "cleanClipFalseFlagRate",
    op: "<=",
    target: 0.05,
    needs: "cleanClips",
  },
  {
    name: "Correct words flagged as mistakes",
    metric: "falseFlagRate",
    op: "<=",
    target: 0.01,
    needs: "correctWords",
  },
  { name: "Real mistakes caught", metric: "recall", op: ">=", target: 0.8, needs: "mistakes" },
];

export function checkGates(summary: Summary, gates: Gate[] = DEFAULT_GATES) {
  return gates.map((g) => {
    const value = summary[g.metric] as number;
    const hasData = summary[g.needs] > 0;
    const pass = hasData && (g.op === "<=" ? value <= g.target : value >= g.target);
    return { ...g, value, hasData, pass };
  });
}
