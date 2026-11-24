import { assert, assertEquals, assertStringIncludes, assertThrows } from "@std/assert";
import { analyzeRecitation, type ExpectedWord } from "../../supabase/functions/_shared/alignment.ts";
import { parseManifest, parsePredictions, truthOf } from "./dataset.ts";
import {
  checkGates,
  type ClipPrediction,
  type ClipTruth,
  scoreClip,
  summarize,
  summarizeBy,
  verdictOf,
  wordKey,
} from "./metrics.ts";
import { renderReport } from "./report.ts";

const FATIHA_2: ExpectedWord[] = ["الحمد", "لله", "رب", "العالمين"].map((w, i) => ({
  ayahId: 2,
  position: i + 1,
  uthmani: w,
  simple: w,
}));

const truth = (id: string, mistakes: number[], tags: Record<string, string> = {}): ClipTruth => ({
  id,
  words: FATIHA_2,
  mistakes: mistakes.map((p) => ({ ayahId: 2, position: p, type: "wrong" as const })),
  tags,
});

const pred = (id: string, flags: number[], unsure: number[] = []): ClipPrediction => ({
  id,
  verdicts: new Map([
    ...unsure.map((p) => [`2:${p}`, "unsure"] as const),
    ...flags.map((p) => [`2:${p}`, "flag"] as const),
  ]),
});

Deno.test("verdicts follow what the user sees", () => {
  assertEquals(verdictOf("correct"), "ok");
  assertEquals(verdictOf("unclear"), "unsure");
  for (const s of ["wrong", "mispronounced", "skipped", "not_recited"] as const) {
    assertEquals(verdictOf(s), "flag");
  }
});

Deno.test("scoreClip separates false flags from caught mistakes", () => {
  const s = scoreClip(truth("a", [3]), pred("a", [1, 3], [4]));
  assertEquals(s.correctWords, 3);
  assertEquals(s.falseFlags, 1);
  assertEquals(s.falseFlagWords, ["2:1"]);
  assertEquals(s.unsureOnCorrect, 1);
  assertEquals(s.mistakes, 1);
  assertEquals(s.caught, 1);
  assertEquals(s.missedWords, []);
});

Deno.test("summary rates, including clean clips with a false flag", () => {
  const scores = [
    scoreClip(truth("clean-ok", []), pred("clean-ok", [])),
    scoreClip(truth("clean-bad", []), pred("clean-bad", [2])),
    scoreClip(truth("mistake-caught", [1]), pred("mistake-caught", [1])),
    scoreClip(truth("mistake-missed", [4]), pred("mistake-missed", [], [4])),
  ];
  const s = summarize(scores);
  assertEquals(s.clips, 4);
  assertEquals(s.cleanClips, 2);
  assertEquals(s.cleanClipFalseFlagRate, 0.5);
  assertEquals(s.falseFlagRate, 1 / 14);
  assertEquals(s.recall, 0.5);
  assertEquals(s.recallWithUnsure, 1);
  assertEquals(s.precision, 0.5);
});

Deno.test("gates need data before they can pass", () => {
  const onlyClean = summarize([scoreClip(truth("a", []), pred("a", []))]);
  const gates = checkGates(onlyClean);
  assert(gates.find((g) => g.metric === "falseFlagRate")!.pass);
  const recall = gates.find((g) => g.metric === "recall")!;
  assertEquals(recall.hasData, false);
  assertEquals(recall.pass, false);
});

Deno.test("breakdown by tag", () => {
  const scores = [
    scoreClip(truth("a", [], { speaker: "child" }), pred("a", [1])),
    scoreClip(truth("b", [], { speaker: "man" }), pred("b", [])),
  ];
  const by = Object.fromEntries(summarizeBy(scores, "speaker"));
  assertEquals(by.child.falseFlagRate, 0.25);
  assertEquals(by.man.falseFlagRate, 0);
});

Deno.test("end to end with the app's alignment: a clean recitation and a wrong word", () => {
  const heard = (words: string[]) =>
    words.map((w, i) => ({ word: w, start: i, end: i + 0.8, probability: 0.9 }));
  const run = (id: string, words: string[], mistakes: number[]) => {
    const a = analyzeRecitation(FATIHA_2, heard(words));
    const verdicts = new Map(a.words.map((w) => [wordKey(w), verdictOf(w.status)]));
    return scoreClip(truth(id, mistakes), { id, verdicts });
  };
  const clean = run("clean", ["الحمد", "لله", "رب", "العالمين"], []);
  assertEquals(clean.falseFlags, 0);
  const wrong = run("wrong", ["الحمد", "لله", "رب", "الناس"], [4]);
  assertEquals(wrong.caught, 1);
  assertEquals(wrong.falseFlags, 0);
});

Deno.test("manifest validation names the line", () => {
  const ok = JSON.stringify({ id: "c1", audio: "clips/c1.m4a", words: FATIHA_2, mistakes: [] });
  assertEquals(parseManifest(ok + "\n\n").length, 1);
  assertThrows(() => parseManifest(ok + "\n" + ok), Error, "line 2: duplicate id");
  const stray = JSON.stringify({
    id: "c2",
    audio: "x",
    words: FATIHA_2,
    mistakes: [{ ayahId: 9, position: 1 }],
  });
  assertThrows(() => parseManifest(stray), Error, "9:1 is not in words");
  const badType = JSON.stringify({
    id: "c3",
    audio: "x",
    words: FATIHA_2,
    mistakes: [{ ayahId: 2, position: 1, type: "tajweed" }],
  });
  assertThrows(() => parseManifest(badType), Error, "unknown mistake type");
});

Deno.test("truth tags and other-app predictions", () => {
  const [clip] = parseManifest(JSON.stringify({
    id: "c1",
    audio: "a",
    surah: 1,
    speaker: "child",
    native_arabic: false,
    words: FATIHA_2,
    mistakes: [{ ayahId: 2, position: 2, type: "skipped" }],
  }));
  const t = truthOf(clip);
  assertEquals(t.tags, {
    speaker: "child",
    native_arabic: "no",
    environment: "unknown",
    surah: "1",
    recitation: "with mistakes",
  });
  const preds = parsePredictions(
    '{"id":"c1","flags":[{"ayahId":2,"position":2}],"unsure":[{"ayahId":2,"position":2}]}',
  );
  // A word in both lists counts as a flag.
  assertEquals(preds.get("c1")!.verdicts.get("2:2"), "flag");
});

Deno.test("report shows gates and the clips to review", () => {
  const scores = [scoreClip(truth("c1", []), pred("c1", [2]))];
  const md = renderReport({
    system: "Asmi3ni",
    dataset: "bench",
    date: "2026-11-24",
    scores,
    details: [{
      id: "c1",
      falseFlags: [{ key: "2:2", expected: "لله", heard: "له", status: "wrong" }],
      missed: [],
    }],
  });
  assertStringIncludes(md, "fails");
  assertStringIncludes(md, "| Clean recitations with any false flag | <= 5.0% | 100.0% | FAIL |");
  assertStringIncludes(md, "2:2 لله → له (wrong)");
});
