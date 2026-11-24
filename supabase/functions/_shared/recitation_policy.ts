// Pure rules for recitation checks (kept separate so they are unit-tested).
import type { HeardWord } from "./alignment.ts";
import type { AiFeature } from "./quota.ts";

/** Free checks cover 60 seconds; Premium and trial users get a full page (3 minutes). */
export const FREE_CLIP_SECONDS = 60;
export const PREMIUM_CLIP_SECONDS = 180;
/** Small tolerance for the app's timer and encoder padding. */
export const CLIP_GRACE_SECONDS = 5;

/** AI hifz tests (recite from memory) have their own weekly quota. */
export function featureFor(mode: string | null | undefined): AiFeature {
  return mode === "hifz" ? "hifz" : "recitation";
}

export function clipSeconds(premium: boolean): number {
  return premium ? PREMIUM_CLIP_SECONDS : FREE_CLIP_SECONDS;
}

/** Drops words heard after the tier's clip length; returns whether anything was cut. */
export function clipHeardWords(
  words: HeardWord[],
  maxSeconds: number,
): { words: HeardWord[]; clipped: boolean } {
  const limit = maxSeconds + CLIP_GRACE_SECONDS;
  const kept = words.filter((w) => (w.start ?? 0) <= limit);
  return { words: kept, clipped: kept.length < words.length };
}

/** Al-Fatiha (ayahs 1..7) is the onboarding aha moment. */
export const FATIHA_LAST_AYAH_ID = 7;

/**
 * The onboarding Al-Fatiha check is free and not counted against the weekly limit, but
 * only for a user's very first recitation, and only for Al-Fatiha.
 */
export function isOnboardingCheck(
  source: unknown,
  session: { start_ayah_id: number; end_ayah_id: number },
  earlierRecitations: number,
): boolean {
  return source === "onboarding" && earlierRecitations === 0 && session.start_ayah_id >= 1 &&
    session.end_ayah_id <= FATIHA_LAST_AYAH_ID;
}
