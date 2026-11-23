// Provider-agnostic subscription state. Each payment provider maps its events to
// SubscriptionRow; adding Stripe/Moyasar later means adding another mapper + webhook.

export interface SubscriptionRow {
  provider: string;
  entitlement: string;
  status: "active" | "grace_period" | "billing_issue" | "cancelled" | "expired" | "paused";
  store: "app_store" | "play_store" | "stripe" | "promotional" | "other" | null;
  product_id: string | null;
  period_type: string | null;
  current_period_end: string | null;
  will_renew: boolean | null;
  original_transaction_id: string | null;
  environment: string | null;
  updated_at: string;
}

const STORE_MAP: Record<string, SubscriptionRow["store"]> = {
  APP_STORE: "app_store",
  MAC_APP_STORE: "app_store",
  PLAY_STORE: "play_store",
  STRIPE: "stripe",
  PROMOTIONAL: "promotional",
};

/** Returns the new subscription state for an event, or null when the event does not change it. */
export function mapRevenueCatEvent(event: any, entitlementId: string): SubscriptionRow | null {
  const entitlements: string[] = event.entitlement_ids ??
    (event.entitlement_id ? [event.entitlement_id] : []);
  if (entitlements.length && !entitlements.includes(entitlementId) && event.type !== "TRANSFER") return null;

  const expires = event.expiration_at_ms ? new Date(event.expiration_at_ms).toISOString() : null;
  const stillValid = expires ? new Date(expires).getTime() > Date.now() : false;
  let status: SubscriptionRow["status"];
  let willRenew: boolean | null = true;

  switch (event.type) {
    case "INITIAL_PURCHASE":
    case "RENEWAL":
    case "UNCANCELLATION":
    case "PRODUCT_CHANGE":
    case "NON_RENEWING_PURCHASE":
    case "SUBSCRIPTION_EXTENDED":
    case "TEMPORARY_ENTITLEMENT_GRANT":
    case "TRANSFER":
      status = "active";
      if (event.type === "NON_RENEWING_PURCHASE") willRenew = false;
      break;
    case "CANCELLATION":
      // Access continues until expiration; only auto-renew is off.
      status = stillValid ? "active" : "cancelled";
      willRenew = false;
      break;
    case "BILLING_ISSUE":
      status = event.grace_period_expiration_at_ms ? "grace_period" : "billing_issue";
      break;
    case "SUBSCRIPTION_PAUSED":
      status = "paused";
      break;
    case "EXPIRATION":
      status = "expired";
      willRenew = false;
      break;
    default:
      return null;
  }

  return {
    provider: "revenuecat",
    entitlement: entitlementId,
    status,
    store: STORE_MAP[event.store] ?? (event.store ? "other" : null),
    product_id: event.product_id ?? event.new_product_id ?? null,
    period_type: event.period_type ? String(event.period_type).toLowerCase() : null,
    current_period_end: event.type === "BILLING_ISSUE" && event.grace_period_expiration_at_ms
      ? new Date(event.grace_period_expiration_at_ms).toISOString()
      : expires,
    will_renew: willRenew,
    original_transaction_id: event.original_transaction_id ?? null,
    environment: event.environment ? String(event.environment).toLowerCase() : null,
    updated_at: new Date().toISOString(),
  };
}
