import { assert, assertAlmostEquals, assertEquals } from "@std/assert";
import { claudeCostUsd, claudeReserveUsd, modelPrice } from "../_shared/ai_cost.ts";
import { mapRevenueCatEvent, netRevenueUsd, periodMonths } from "../_shared/billing.ts";
import { fitSources } from "../_shared/ask_flow.ts";

Deno.test("claude cost uses per-model prices including cache tokens", () => {
  // Sonnet 5.5: 5k input, 1k output, 1k cache read
  const c = claudeCostUsd("claude-sonnet-5-5", {
    input_tokens: 5000,
    output_tokens: 1000,
    cache_read_input_tokens: 1000,
    cache_creation_input_tokens: 0,
  });
  assertAlmostEquals(c, (5000 * 2 + 1000 * 10 + 1000 * 0.1) / 1e6, 1e-9);
  assertAlmostEquals(
    claudeCostUsd("claude-haiku-5-5", { input_tokens: 6000, output_tokens: 1000 }),
    0.0011,
    1e-9,
  );
});

Deno.test("unknown models are priced at the most expensive rate", () => {
  assert(modelPrice("some-future-model").output >= modelPrice("claude-fable-5-2").output);
  assertEquals(modelPrice("claude-haiku-5-5-20261001"), modelPrice("claude-haiku-5-5"));
});

Deno.test("reservation covers a realistic answer", () => {
  const reserve = claudeReserveUsd("claude-sonnet-5-5", 16_000, 4096);
  const typical = claudeCostUsd("claude-sonnet-5-5", { input_tokens: 6000, output_tokens: 1200 });
  assert(reserve > typical * 3);
});

Deno.test("net revenue subtracts store commission and tax", () => {
  assertEquals(netRevenueUsd({ price: 2.99, tax_percentage: 0.13, commission_percentage: 0.15 }), 2.1528);
  assertEquals(netRevenueUsd({ price: 19.99, takehome_percentage: 0.85 }), 16.9915);
  assertEquals(netRevenueUsd({ price: 0.99 }), 0.693); // fallback 70%
  assertEquals(netRevenueUsd({ price: 0 }), 0); // free trial start
  assertEquals(netRevenueUsd({}), null);
});

Deno.test("period length from dates or product id", () => {
  const day = 86_400_000;
  assertEquals(periodMonths({ purchased_at_ms: 0 + day, expiration_at_ms: 31 * day }), 1);
  assertEquals(periodMonths({ purchased_at_ms: day, expiration_at_ms: 366 * day }), 12);
  assertEquals(periodMonths({ product_id: "muslimai_premium_annual:annual" }), 12);
  assertEquals(periodMonths({ product_id: "muslimai_premium_monthly" }), 1);
});

Deno.test("charge events carry revenue; refunds zero it; other events leave it alone", () => {
  const now = Date.now();
  const base = {
    entitlement_ids: ["premium"],
    store: "PLAY_STORE",
    product_id: "muslimai_premium_annual",
    purchased_at_ms: now,
    expiration_at_ms: now + 365 * 86_400_000,
    price: 6.99,
    takehome_percentage: 0.85,
    country_code: "EG",
    currency: "EGP",
  };
  const renewal = mapRevenueCatEvent({ ...base, type: "RENEWAL" }, "premium")!;
  assertEquals(renewal.net_revenue_usd, 5.9415);
  assertEquals(renewal.period_months, 12);
  assertEquals(renewal.country_code, "EG");

  const billingIssue = mapRevenueCatEvent({ ...base, type: "BILLING_ISSUE" }, "premium")!;
  assertEquals("net_revenue_usd" in billingIssue, false);

  const refund = mapRevenueCatEvent(
    { ...base, type: "CANCELLATION", cancel_reason: "CUSTOMER_SUPPORT", price: -6.99 },
    "premium",
  )!;
  assertEquals(refund.net_revenue_usd, 0);

  const unknownPrice = mapRevenueCatEvent(
    { ...base, type: "INITIAL_PURCHASE", price: undefined },
    "premium",
  )!;
  assertEquals(unknownPrice.net_revenue_usd, null);
});

Deno.test("sources are trimmed to fit the reserved input", () => {
  const ayah = (i: number) => ({
    verse_key: `2:${i}`,
    ayah_id: i,
    surah_id: 2,
    ayah_number: i,
    surah_name_ar: "البقرة",
    surah_name_en: "The Cow",
    arabic: "ا".repeat(3000),
    translation: null,
    tafsir: null,
    tafsir_source: null,
    similarity: 0.9,
  });
  const sources = { ayahs: [1, 2, 3, 4, 5, 6, 7, 8].map(ayah), hadiths: [] };
  const fitted = fitSources(sources, 3000, 10_000);
  assert(fitted.ayahs.length < 8 && fitted.ayahs.length > 0);
  assertEquals(fitSources(sources, 0, 1_000_000).ayahs.length, 8);
});
