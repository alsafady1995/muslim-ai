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
  // What the user paid for the current period. Only present on events that charge (or refund)
  // the user, so other events never overwrite it. Drives the AI cost cap.
  price_usd?: number | null;
  net_revenue_usd?: number | null;
  period_start?: string | null;
  period_months?: number;
  country_code?: string | null;
  currency?: string | null;
}

/** Used when the store reports a price but not its fees: 15% commission + ~15% VAT. */
export const FALLBACK_TAKEHOME = 0.70;

const CHARGE_EVENTS = new Set(["INITIAL_PURCHASE", "RENEWAL", "NON_RENEWING_PURCHASE"]);

function fraction(v: unknown): number | null {
  const n = typeof v === "number" ? v : typeof v === "string" && v.trim() ? Number(v) : NaN;
  return Number.isFinite(n) && n >= 0 && n <= 1 ? n : null;
}

/**
 * Net revenue (USD) of a RevenueCat transaction after store commission and tax.
 * `price` is the USD price the user paid (local price converted by RevenueCat), so
 * regional price tiers are reflected automatically. Returns null when unknown.
 */
export function netRevenueUsd(event: any): number | null {
  const price = typeof event.price === "number" ? event.price : null;
  if (price === null) return null;
  if (price <= 0) return 0;
  const tax = fraction(event.tax_percentage);
  const commission = fraction(event.commission_percentage);
  let net: number;
  if (tax !== null && commission !== null) net = price * (1 - tax - commission);
  else if (fraction(event.takehome_percentage) !== null) net = price * fraction(event.takehome_percentage)!;
  else net = price * FALLBACK_TAKEHOME;
  return Math.max(0, Math.round(net * 10_000) / 10_000);
}

/** Billing period length in months (1 monthly, 12 annual), from the transaction dates or product id. */
export function periodMonths(event: any): number {
  const start = Number(event.purchased_at_ms);
  const end = Number(event.expiration_at_ms);
  if (start > 0 && end > start) {
    const days = (end - start) / 86_400_000;
    if (days >= 20) return Math.max(1, Math.round(days / 30.44));
  }
  return /annual|year/i.test(String(event.product_id ?? event.new_product_id ?? "")) ? 12 : 1;
}

/** Revenue fields for events that charge or refund the user; empty for all other events. */
export function revenueFields(event: any): Partial<SubscriptionRow> {
  const refunded = event.type === "CANCELLATION" &&
    (event.cancel_reason === "CUSTOMER_SUPPORT" || (typeof event.price === "number" && event.price < 0));
  if (refunded) return { net_revenue_usd: 0 };
  if (!CHARGE_EVENTS.has(event.type)) return {};
  const net = netRevenueUsd(event);
  const fields: Partial<SubscriptionRow> = {
    price_usd: typeof event.price === "number" ? event.price : null,
    period_start: event.purchased_at_ms ? new Date(event.purchased_at_ms).toISOString() : null,
    period_months: periodMonths(event),
    country_code: event.country_code ?? null,
    currency: event.currency ?? null,
  };
  // Unknown price: null makes the server use the conservative fallback (lowest regional tier).
  fields.net_revenue_usd = net;
  return fields;
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
    ...revenueFields(event),
  };
}

/**
 * RevenueCat can deliver events out of order (retries). An event older than the one that
 * last changed the subscription must not overwrite it, e.g. a late EXPIRATION after a RENEWAL.
 */
export function isStaleEvent(event: any, lastEventMs: number | null | undefined): boolean {
  const ts = Number(event?.event_timestamp_ms);
  if (!Number.isFinite(ts) || ts <= 0 || lastEventMs == null) return false;
  return ts < Number(lastEventMs);
}
