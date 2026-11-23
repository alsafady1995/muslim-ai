import { admin } from "./supabase.ts";
import { HttpError } from "./http.ts";

export type AiFeature = "recitation" | "ask" | "search";

export interface QuotaResult {
  allowed: boolean;
  premium: boolean;
  limit: number;
  remaining: number;
}

/** Atomically consumes one unit of the user's daily quota, or throws 402 with paywall info. */
export async function consumeQuota(userId: string, feature: AiFeature): Promise<QuotaResult> {
  const { data, error } = await admin().rpc("consume_ai_quota", { p_user: userId, p_feature: feature });
  if (error) throw error;
  const q = data as QuotaResult;
  if (!q.allowed) {
    throw new HttpError(402, "quota_exceeded", `Daily ${feature} limit reached`, {
      feature,
      premium: q.premium,
      limit: q.limit,
    });
  }
  return q;
}

export async function refundQuota(userId: string, feature: AiFeature): Promise<void> {
  const { error } = await admin().rpc("refund_ai_quota", { p_user: userId, p_feature: feature });
  if (error) console.error("refund_ai_quota failed", error);
}
