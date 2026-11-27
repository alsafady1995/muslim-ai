// Turns a refused begin_ai_call result into the HTTP error the app understands (kept separate
// from quota.ts so it is unit-tested without a database).
import { HttpError } from "./http.ts";

/**
 * 402 `quota_exceeded` when the weekly count is used up; 429 `ai_budget_exhausted` when the
 * budget is. Two free-tier cases reuse that 429 so the app's existing handling (friendly sheet,
 * keyword-search fallback) applies: guests asking for anything but the onboarding check
 * (`tier: "guest"`, create a free account) and the global daily free-AI pool being full
 * (`tier: "busy"`, back at midnight UTC). See migration 20261125000001_free_ai_guard.sql.
 */
// deno-lint-ignore no-explicit-any
export function refusalError(feature: string, r: Record<string, any>): HttpError {
  if (r.reason === "sign_in" || r.reason === "free_pool") {
    const guest = r.reason === "sign_in";
    return new HttpError(
      429,
      "ai_budget_exhausted",
      guest
        ? "Create a free account to keep using AI features"
        : "Free AI features are busy today and resume at midnight UTC",
      {
        feature,
        premium: false,
        tier: guest ? "guest" : "busy",
        reason: r.reason,
        resets_at: r.resets_at ?? null,
      },
    );
  }
  if (r.reason === "budget") {
    return new HttpError(429, "ai_budget_exhausted", "AI allowance for this period is used up", {
      feature,
      premium: r.premium,
      tier: r.tier,
      resets_at: r.resets_at,
    });
  }
  return new HttpError(402, "quota_exceeded", `Weekly ${feature} limit reached`, {
    feature,
    premium: r.premium,
    limit: r.limit,
    period: r.period ?? "week",
    resets_at: r.resets_at ?? null,
  });
}
