// Recitation accuracy benchmark.
//
// Our system (ASR service + the same alignment the app uses):
//   ASR_SERVICE_URL=... ASR_SERVICE_TOKEN=... deno task run --dataset ./bench-data [--sweep]
// Another app, from predictions typed in by hand (see dataset.ts):
//   deno task run --dataset ./bench-data --predictions tarteel.jsonl --system Tarteel
//
// ASR output is cached in <out>/asr/<clip>.json, so re-scoring (or --sweep) costs nothing.
// Pass --fresh to transcribe again (after changing the model). Writes report.md, report.json
// and clips.jsonl to --out (default <dataset>/results/<system>).

import { parseArgs } from "@std/cli/parse-args";
import { encodeBase64 } from "@std/encoding/base64";
import { analyzeRecitation, type HeardWord, THRESHOLDS } from "../../supabase/functions/_shared/alignment.ts";
import { type ManifestClip, parseManifest, parsePredictions, truthOf } from "./dataset.ts";
import { type ClipPrediction, type ClipScore, scoreClip, summarize, verdictOf, wordKey } from "./metrics.ts";
import { type ClipDetail, renderReport, type SweepRow } from "./report.ts";

interface AsrResult {
  text: string;
  duration: number;
  words: HeardWord[];
  latencyMs: number;
}

const args = parseArgs(Deno.args, {
  string: ["dataset", "out", "predictions", "system", "concurrency"],
  boolean: ["sweep", "fresh"],
});
if (!args.dataset) {
  console.error(
    "Usage: deno task run --dataset <folder> [--predictions file --system Name] [--sweep] [--fresh]",
  );
  Deno.exit(2);
}
const dataset = args.dataset.replace(/\/$/, "");
const system = args.system ?? (args.predictions ? "other" : "Asmi3ni");
const outDir = args.out ?? `${dataset}/results/${system.toLowerCase().replace(/[^a-z0-9]+/g, "-")}`;
const clips = parseManifest(await Deno.readTextFile(`${dataset}/manifest.jsonl`));
await Deno.mkdir(`${outDir}/asr`, { recursive: true });

async function transcribe(clip: ManifestClip): Promise<AsrResult> {
  const cache = `${outDir}/asr/${clip.id}.json`;
  if (!args.fresh) {
    try {
      return JSON.parse(await Deno.readTextFile(cache));
    } catch { /* not cached yet */ }
  }
  const url = Deno.env.get("ASR_SERVICE_URL");
  const token = Deno.env.get("ASR_SERVICE_TOKEN");
  if (!url || !token) throw new Error("Set ASR_SERVICE_URL and ASR_SERVICE_TOKEN (or pass --predictions)");
  const audio = await Deno.readFile(`${dataset}/${clip.audio}`);
  const started = performance.now();
  const res = await fetch(`${url.replace(/\/$/, "")}/v1/transcribe`, {
    method: "POST",
    headers: { "Authorization": `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify({ audio_base64: encodeBase64(audio), language: "ar" }),
    signal: AbortSignal.timeout(300_000),
  });
  if (!res.ok) throw new Error(`ASR ${res.status} for ${clip.id}: ${await res.text()}`);
  const body = await res.json();
  const result: AsrResult = { ...body, latencyMs: Math.round(performance.now() - started) };
  await Deno.writeTextFile(cache, JSON.stringify(result));
  return result;
}

async function mapLimit<T, R>(items: T[], limit: number, fn: (t: T, i: number) => Promise<R>): Promise<R[]> {
  const out: R[] = new Array(items.length);
  let next = 0;
  const worker = async () => {
    while (next < items.length) {
      const i = next++;
      out[i] = await fn(items[i], i);
    }
  };
  await Promise.all(Array.from({ length: Math.max(1, limit) }, worker));
  return out;
}

function ourPrediction(clip: ManifestClip, asr: AsrResult) {
  const analysis = analyzeRecitation(clip.words, asr.words);
  const verdicts = new Map(analysis.words.map((w) => [wordKey(w), verdictOf(w.status)]));
  const pred: ClipPrediction = { id: clip.id, verdicts, latencyMs: asr.latencyMs, durationSec: asr.duration };
  return { pred, analysis };
}

const scores: ClipScore[] = [];
const details: ClipDetail[] = [];
let sweep: SweepRow[] | undefined;

if (args.predictions) {
  const preds = parsePredictions(await Deno.readTextFile(args.predictions));
  for (const clip of clips) {
    const pred = preds.get(clip.id);
    if (!pred) {
      console.warn(`no prediction for ${clip.id}; skipped`);
      continue;
    }
    const s = scoreClip(truthOf(clip), pred);
    scores.push(s);
    const text = new Map(clip.words.map((w) => [wordKey(w), w.uthmani]));
    details.push({
      id: clip.id,
      falseFlags: s.falseFlagWords.map((k) => ({ key: k, expected: text.get(k) ?? "", status: "flag" })),
      missed: s.missedWords.map((k) => ({ key: k, expected: text.get(k) ?? "" })),
    });
  }
} else {
  let done = 0;
  const asr = await mapLimit(clips, Number(args.concurrency ?? 2), async (clip) => {
    const r = await transcribe(clip);
    if (++done % 10 === 0 || done === clips.length) console.log(`transcribed ${done}/${clips.length}`);
    return r;
  });
  clips.forEach((clip, i) => {
    const { pred, analysis } = ourPrediction(clip, asr[i]);
    const s = scoreClip(truthOf(clip), pred);
    scores.push(s);
    const byKey = new Map(analysis.words.map((w) => [wordKey(w), w]));
    details.push({
      id: clip.id,
      falseFlags: s.falseFlagWords.map((k) => {
        const w = byKey.get(k)!;
        return { key: k, expected: w.text, heard: w.heard, status: w.status };
      }),
      missed: s.missedWords.map((k) => ({
        key: k,
        expected: byKey.get(k)!.text,
        heard: byKey.get(k)!.heard,
      })),
    });
  });

  if (args.sweep) {
    const original = THRESHOLDS.correct;
    sweep = [];
    try {
      for (const t of [0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95]) {
        THRESHOLDS.correct = t;
        const rows = clips.map((clip, i) => scoreClip(truthOf(clip), ourPrediction(clip, asr[i]).pred));
        sweep.push({ threshold: t, summary: summarize(rows) });
      }
    } finally {
      THRESHOLDS.correct = original;
    }
  }
}

const date = new Date().toISOString().slice(0, 10);
const report = renderReport({
  system,
  dataset,
  date,
  scores,
  sweep,
  currentThreshold: THRESHOLDS.correct,
  details,
});
await Deno.writeTextFile(`${outDir}/report.md`, report + "\n");
await Deno.writeTextFile(
  `${outDir}/report.json`,
  JSON.stringify({ system, dataset, date, summary: summarize(scores), sweep }, null, 2) + "\n",
);
await Deno.writeTextFile(`${outDir}/clips.jsonl`, scores.map((s) => JSON.stringify(s)).join("\n") + "\n");
console.log(report.split("\n").slice(0, 12).join("\n"));
console.log(`\nFull report: ${outDir}/report.md`);
