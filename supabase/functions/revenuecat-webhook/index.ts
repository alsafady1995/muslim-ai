// POST /functions/v1/revenuecat-webhook  (configured in RevenueCat > Integrations > Webhooks)
// Authorization header must equal REVENUECAT_WEBHOOK_AUTH. The app calls
// Purchases.logIn(supabaseUserId), so app_user_id is our auth user id.
// Deploy with --no-verify-jwt (RevenueCat does not send a Supabase JWT).
import { handler, HttpError, json } from "../_shared/http.ts";
import { admin } from "../_shared/supabase.ts";
import { env } from "../_shared/env.ts";
import { track } from "../_shared/analytics.ts";
import { mapRevenueCatEvent } from "../_shared/billing.ts";

function timingSafeEqual(a: string, b: string): boolean {
  const ea = new TextEncoder().encode(a);
  const eb = new TextEncoder().encode(b);
  if (ea.length !== eb.length) return false;
  let diff = 0;
  for (let i = 0; i < ea.length; i++) diff |= ea[i] ^ eb[i];
  return diff === 0;
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

Deno.serve(handler(async (req, body) => {
  const auth = req.headers.get("Authorization") ?? "";
  if (
    !timingSafeEqual(auth, env.revenuecatWebhookAuth()) &&
    !timingSafeEqual(auth, `Bearer ${env.revenuecatWebhookAuth()}`)
  ) {
    throw new HttpError(401, "unauthorized");
  }
  const event = body?.event;
  if (!event?.id || !event?.type) throw new HttpError(400, "invalid_event");
  const db = admin();

  const candidateIds: string[] = [
    event.app_user_id,
    event.original_app_user_id,
    ...(event.aliases ?? []),
    ...(event.transferred_to ?? []),
  ].filter((id: unknown) => typeof id === "string" && UUID.test(id as string));
  const userId = candidateIds[0] ?? null;

  // Idempotency: RevenueCat retries; the unique (provider, event_id) makes replays no-ops.
  const { error: insErr } = await db.from("billing_events").insert({
    provider: "revenuecat",
    event_id: event.id,
    user_id: userId,
    event_type: event.type,
    payload: body,
  });
  if (insErr) {
    if ((insErr as any).code === "23505") return json({ ok: true, duplicate: true });
    throw insErr;
  }

  if (event.type === "TEST" || !userId) return json({ ok: true, ignored: !userId });

  if (event.type === "TRANSFER") {
    for (const from of (event.transferred_from ?? []).filter((id: string) => UUID.test(id))) {
      await db.from("subscriptions").update({ status: "expired", will_renew: false }).eq("user_id", from);
    }
  }

  const row = mapRevenueCatEvent(event, env.revenuecatEntitlement());
  if (row) {
    const { data: exists } = await db.from("profiles").select("id").eq("id", userId).maybeSingle();
    if (!exists) return json({ ok: true, ignored: "unknown_user" });
    const { error } = await db.from("subscriptions").upsert({ user_id: userId, ...row }, {
      onConflict: "user_id",
    });
    if (error) throw error;
    track(userId, "subscription_event", {
      type: event.type,
      status: row.status,
      store: row.store,
      product: row.product_id,
    });
  }
  return json({ ok: true });
}));
