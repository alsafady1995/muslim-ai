// Turns benchmark scores into report.md. Pure: no I/O.

import { checkGates, type ClipScore, summarize, summarizeBy, type Summary } from "./metrics.ts";

export interface SweepRow {
  threshold: number;
  summary: Summary;
}

export interface ClipDetail {
  id: string;
  falseFlags: { key: string; expected: string; heard?: string; status: string }[];
  missed: { key: string; expected: string; heard?: string }[];
}

const pct = (v: number) => `${(v * 100).toFixed(1)}%`;
const ms = (v: number | null) => (v === null ? "–" : `${(v / 1000).toFixed(1)} s`);

function summaryRow(label: string, s: Summary): string {
  const clean = s.cleanClips ? pct(s.cleanClipFalseFlagRate) : "–";
  const recall = s.mistakes ? pct(s.recall) : "–";
  const precision = s.caught + s.falseFlags ? pct(s.precision) : "–";
  return `| ${label} | ${s.clips} | ${clean} | ${pct(s.falseFlagRate)} | ${
    pct(s.unsureRate)
  } | ${recall} | ${precision} |`;
}

const HEADER = "| Group | Clips | Clean clips with a false flag | Correct words flagged | " +
  'Correct words "not sure" | Mistakes caught | Flags that were real |\n| --- | ---: | ---: | ---: | ---: | ---: | ---: |';

export function renderReport(opts: {
  system: string;
  dataset: string;
  date: string;
  scores: ClipScore[];
  sweep?: SweepRow[];
  currentThreshold?: number;
  details?: ClipDetail[];
  breakdownTags?: string[];
}): string {
  const all = summarize(opts.scores);
  const gates = checkGates(all);
  const passed = gates.every((g) => g.pass);
  const out: string[] = [];
  out.push(`# Recitation accuracy: ${opts.system}`);
  out.push("");
  out.push(
    `Dataset \`${opts.dataset}\`, ${all.clips} clips, ${all.words} words, ${all.mistakes} real mistakes. Run ${opts.date}.`,
  );
  out.push("");
  out.push(
    passed
      ? "**Result: passes every launch gate.**"
      : `**Result: fails ${gates.filter((g) => !g.pass).length} of ${gates.length} launch gates.**`,
  );
  out.push("");
  out.push("| Gate | Target | Measured | Result |\n| --- | ---: | ---: | --- |");
  for (const g of gates) {
    out.push(
      `| ${g.name} | ${g.op} ${pct(g.target)} | ${g.hasData ? pct(g.value) : "no data"} | ${
        g.hasData ? (g.pass ? "pass" : "FAIL") : "needs clips"
      } |`,
    );
  }
  out.push("");
  out.push("## Overall and by group");
  out.push("");
  out.push(HEADER);
  out.push(summaryRow("All clips", all));
  for (
    const tag of opts.breakdownTags ?? ["speaker", "native_arabic", "environment", "recitation", "surah"]
  ) {
    for (const [value, s] of summarizeBy(opts.scores, tag)) out.push(summaryRow(`${tag}: ${value}`, s));
  }
  out.push("");
  if (all.latencyP50Ms !== null) {
    out.push(
      `Speed: median ${ms(all.latencyP50Ms)}, 95th percentile ${ms(all.latencyP95Ms)} per clip` +
        (all.realTimeFactor === null
          ? "."
          : `; ${all.realTimeFactor.toFixed(2)} s of processing per second of audio.`),
    );
    out.push("");
  }
  if (opts.sweep?.length) {
    out.push("## Threshold sweep");
    out.push("");
    out.push(
      "How strict the word match is (`THRESHOLDS.correct` in `supabase/functions/_shared/alignment.ts`). " +
        "Lower means fewer false flags and fewer caught mistakes. Same ASR output, re-scored.",
    );
    out.push("");
    out.push(
      "| Threshold | Clean clips with a false flag | Correct words flagged | Mistakes caught |\n| ---: | ---: | ---: | ---: |",
    );
    for (const r of opts.sweep) {
      const mark = r.threshold === opts.currentThreshold ? " (current)" : "";
      out.push(
        `| ${r.threshold.toFixed(2)}${mark} | ${pct(r.summary.cleanClipFalseFlagRate)} | ${
          pct(r.summary.falseFlagRate)
        } | ${r.summary.mistakes ? pct(r.summary.recall) : "–"} |`,
      );
    }
    out.push("");
  }
  const worst = (opts.details ?? []).filter((d) => d.falseFlags.length || d.missed.length)
    .sort((a, b) => b.falseFlags.length - a.falseFlags.length || b.missed.length - a.missed.length)
    .slice(0, 15);
  if (worst.length) {
    out.push("## Clips to listen to");
    out.push("");
    out.push(
      "The clips with the most false flags first. Listen to each one: some will be labelling mistakes.",
    );
    out.push("");
    out.push("| Clip | Correct words shown as mistakes | Mistakes shown as correct |\n| --- | --- | --- |");
    for (const d of worst) {
      const ff = d.falseFlags.map((f) => `${f.key} ${f.expected} → ${f.heard ?? "(not heard)"} (${f.status})`)
        .join("<br>");
      const mi = d.missed.map((m) => `${m.key} ${m.expected}${m.heard ? ` → ${m.heard}` : ""}`).join("<br>");
      out.push(`| ${d.id} | ${ff || "–"} | ${mi || "–"} |`);
    }
    out.push("");
  }
  return out.join("\n");
}
