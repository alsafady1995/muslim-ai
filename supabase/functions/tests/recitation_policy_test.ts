import { assert, assertEquals } from "@std/assert";
import {
  clipHeardWords,
  clipSeconds,
  featureFor,
  FREE_CLIP_SECONDS,
  isOnboardingCheck,
} from "../_shared/recitation_policy.ts";

Deno.test("hifz tests use their own quota", () => {
  assertEquals(featureFor("hifz"), "hifz");
  assertEquals(featureFor("read"), "recitation");
  assertEquals(featureFor(undefined), "recitation");
});

Deno.test("free clips stop at 60 seconds, premium gets a full page", () => {
  assertEquals(clipSeconds(false), FREE_CLIP_SECONDS);
  assertEquals(clipSeconds(true), 180);
  const words = [0, 30, 59, 64, 66, 120].map((start) => ({ word: "x", start, end: start + 0.5 }));
  const free = clipHeardWords(words, 60);
  assertEquals(free.words.map((w) => w.start), [0, 30, 59, 64]);
  assert(free.clipped);
  const premium = clipHeardWords(words, 180);
  assertEquals(premium.words.length, words.length);
  assert(!premium.clipped);
});

Deno.test("only the very first Al-Fatiha check in onboarding is free", () => {
  const fatiha = { start_ayah_id: 1, end_ayah_id: 7 };
  assert(isOnboardingCheck("onboarding", fatiha, 0));
  assert(!isOnboardingCheck("onboarding", fatiha, 1), "not after the first recitation");
  assert(!isOnboardingCheck("coach", fatiha, 0), "only from onboarding");
  assert(!isOnboardingCheck("onboarding", { start_ayah_id: 8, end_ayah_id: 20 }, 0), "only Al-Fatiha");
});
