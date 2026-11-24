// Benchmark dataset format: one folder with manifest.jsonl and the audio files.
//
// manifest.jsonl, one clip per line:
// {
//   "id": "c0001",
//   "audio": "clips/c0001.m4a",                    // relative to the folder
//   "surah": 1, "start_ayah_id": 1, "end_ayah_id": 7,
//   "speaker": "man" | "woman" | "child",
//   "native_arabic": true,
//   "environment": "quiet" | "noisy",
//   "words": [{ "ayahId": 1, "position": 1, "uthmani": "...", "simple": "..." }, ...],
//   "mistakes": [{ "ayahId": 2, "position": 3, "type": "wrong" }]   // [] = recited perfectly
// }
//
// export.ts writes this from the clips recorded in the app. Clips from elsewhere work too,
// as long as "words" match ayah_words (ayah id + position) and the reciter read the whole range.
//
// Predictions from another app (scored with run.ts --predictions), one clip per line:
// { "id": "c0001", "flags": [{ "ayahId": 2, "position": 3 }], "unsure": [] }

import type { ExpectedWord } from "../../supabase/functions/_shared/alignment.ts";
import type { ClipPrediction, ClipTruth, MistakeLabel, Verdict, WordRef } from "./metrics.ts";
import { wordKey } from "./metrics.ts";

export interface ManifestClip {
  id: string;
  audio: string;
  surah?: number;
  start_ayah_id: number;
  end_ayah_id: number;
  speaker?: string;
  native_arabic?: boolean;
  environment?: string;
  words: ExpectedWord[];
  mistakes: (WordRef & { type?: MistakeLabel })[];
}

const LABELS = new Set(["wrong", "mispronounced", "skipped"]);

function isRef(v: unknown): v is WordRef {
  const r = v as WordRef;
  return !!r && Number.isInteger(r.ayahId) && Number.isInteger(r.position);
}

/** Parses manifest.jsonl. Throws with the line number on the first invalid clip. */
export function parseManifest(text: string): ManifestClip[] {
  const clips: ManifestClip[] = [];
  const ids = new Set<string>();
  text.split("\n").forEach((line, i) => {
    if (!line.trim()) return;
    const where = `manifest line ${i + 1}`;
    let c: ManifestClip;
    try {
      c = JSON.parse(line);
    } catch {
      throw new Error(`${where}: not valid JSON`);
    }
    if (typeof c.id !== "string" || !c.id) throw new Error(`${where}: missing id`);
    if (ids.has(c.id)) throw new Error(`${where}: duplicate id ${c.id}`);
    ids.add(c.id);
    if (typeof c.audio !== "string" || !c.audio) throw new Error(`${where}: missing audio`);
    if (!Array.isArray(c.words) || !c.words.length || !c.words.every(isRef)) {
      throw new Error(`${where}: words must be a non-empty list of {ayahId, position, ...}`);
    }
    if (!Array.isArray(c.mistakes) || !c.mistakes.every(isRef)) {
      throw new Error(`${where}: mistakes must be a list of {ayahId, position, type}`);
    }
    const keys = new Set(c.words.map(wordKey));
    for (const m of c.mistakes) {
      if (!keys.has(wordKey(m))) throw new Error(`${where}: mistake ${wordKey(m)} is not in words`);
      if (m.type !== undefined && !LABELS.has(m.type)) {
        throw new Error(`${where}: unknown mistake type ${m.type}`);
      }
    }
    clips.push(c);
  });
  return clips;
}

export function truthOf(c: ManifestClip): ClipTruth {
  const tags: Record<string, string> = {
    speaker: c.speaker ?? "unknown",
    native_arabic: c.native_arabic === undefined ? "unknown" : c.native_arabic ? "yes" : "no",
    environment: c.environment ?? "unknown",
    surah: String(c.surah ?? "unknown"),
    recitation: c.mistakes.length ? "with mistakes" : "clean",
  };
  return { id: c.id, words: c.words, mistakes: c.mistakes, tags };
}

/** Parses another app's predictions (see the header). */
export function parsePredictions(text: string): Map<string, ClipPrediction> {
  const out = new Map<string, ClipPrediction>();
  text.split("\n").forEach((line, i) => {
    if (!line.trim()) return;
    const p = JSON.parse(line);
    if (typeof p.id !== "string") throw new Error(`predictions line ${i + 1}: missing id`);
    const verdicts = new Map<string, Verdict>();
    for (const r of (p.unsure ?? []) as WordRef[]) verdicts.set(wordKey(r), "unsure");
    for (const r of (p.flags ?? []) as WordRef[]) verdicts.set(wordKey(r), "flag");
    out.set(p.id, { id: p.id, verdicts, latencyMs: p.latency_ms, durationSec: p.duration_sec });
  });
  return out;
}
