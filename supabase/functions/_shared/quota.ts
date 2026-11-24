import { admin } from "./supabase.ts";
import { HttpError } from "./http.ts";

export type AiFeature = "recitation" | "hifz" | "ask" | "search";

export interface AiCall {
  id: number;
  premium: boolean;
  tier: "free" | "trial" | "premium" | "promo";
  /** True when only the cheaper model fits the remaining budget; use it. */
  degraded: boolean;
  limit: number;
  remaining: number;
  /** When this period's AI budget renews (or, for annual plans, this month's pace). */
  resetsAt: string;
  /** When the weekly fair-use count renews (Friday 00:00 local time). */
  usageResetsAt: string | null;
}

export interface BeginOptions {
  /** False for the free onboarding check: reserved against the budget, not counted in the weekly limit. */
  countUsage?: boolean;
}

/**
 * Starts a paid AI call: checks the weekly fair-use count and reserves the worst-case cost
 * against the user's AI budget (server-side, atomic). Throws 402 `quota_exceeded` when the
 * weekly count is used up and 429 `ai_budget_exhausted` when the budget is.
 *
 * `fallbackReserveUsd` is the worst case with a cheaper model; when the normal model no
 * longer fits but the cheaper one does, the call is allowed with `degraded: true`.
 */
export async function beginAiCall(
  userId: string,
  feature: AiFeature,
  reserveUsd: number,
  fallbackReserveUsd?: number,
  opts: BeginOptions = {},
): Promise<AiCall> {
  const { data, error } = await admin().rpc("begin_ai_call", {
    p_user: userId,
    p_feature: feature,
    p_reserve_usd: reserveUsd,
    p_fallback_reserve_usd: fallbackReserveUsd ?? null,
    p_count_usage: opts.countUsage ?? true,
  });
  if (error) throw error;
  const r = data as Record<string, any>;
  if (!r.allowed) {
    if (r.reason === "budget") {
      throw new HttpError(429, "ai_budget_exhausted", "AI allowance for this period is used up", {
        feature,
        premium: r.premium,
        tier: r.tier,
        resets_at: r.resets_at,
      });
    }
    throw new HttpError(402, "quota_exceeded", `Weekly ${feature} limit reached`, {
      feature,
      premium: r.premium,
      limit: r.limit,
      period: r.period ?? "week",
      resets_at: r.resets_at ?? null,
    });
  }
  return {
    id: Number(r.call_id),
    premium: !!r.premium,
    tier: r.tier,
    degraded: !!r.degraded,
    limit: r.limit,
    remaining: r.remaining,
    resetsAt: r.resets_at,
    usageResetsAt: r.usage_resets_at ?? null,
  };
}

/** Records the measured cost and releases the reservation. Never throws (the user already has the answer). */
export async function finishAiCall(
  call: AiCall,
  costUsd: number,
  model?: string,
  details?: Record<string, unknown>,
): Promise<void> {
  const { error } = await admin().rpc("finish_ai_call", {
    p_call: call.id,
    p_cost_usd: costUsd,
    p_model: model ?? null,
    p_details: details ?? null,
  });
  if (error) console.error("finish_ai_call failed", error);
}

/** The call failed on our side: release the reservation and refund the weekly count. */
export async function cancelAiCall(call: AiCall, alreadySpentUsd = 0): Promise<void> {
  const { error } = await admin().rpc("cancel_ai_call", { p_call: call.id, p_cost_usd: alreadySpentUsd });
  if (error) console.error("cancel_ai_call failed", error);
}

/** Shape returned to the app next to each AI result. */
export function quotaInfo(call: AiCall) {
  return {
    remaining: call.remaining,
    limit: call.limit,
    premium: call.premium,
    degraded: call.degraded,
    resets_at: call.resetsAt,
    period: "week",
    usage_resets_at: call.usageResetsAt,
  };
}
