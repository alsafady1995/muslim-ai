import { assertEquals } from "@std/assert";
import { attachSources } from "../_shared/grounded.ts";
import { mapRevenueCatEvent } from "../_shared/billing.ts";

const sources = {
  ayahs: [{
    verse_key: "2:153",
    ayah_id: 160,
    surah_id: 2,
    ayah_number: 153,
    surah_name_ar: "البقرة",
    surah_name_en: "The Cow",
    arabic: "يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ",
    translation: "O you who have believed, seek help through patience and prayer.",
    tafsir: null,
    tafsir_source: null,
    similarity: 0.8,
  }],
  hadiths: [{
    hadith_id: 42,
    reference: "Muslim 2999",
    collection: "Sahih Muslim",
    grade: "sahih",
    text_ar: "...",
    text_en: "...",
    similarity: 0.7,
  }],
};

Deno.test("citations not in the retrieved set are dropped", () => {
  const r = attachSources({
    answer_type: "answer",
    quran: [{ verse_key: "2:153", why_relevant: "a" }, { verse_key: "3:200", why_relevant: "hallucinated" }, {
      verse_key: "2:153",
      why_relevant: "dup",
    }],
    hadith: [{ hadith_id: 42, why_relevant: "b" }, { hadith_id: 999, why_relevant: "hallucinated" }],
    explanation: "",
    scholarly_differences: "",
    follow_up_questions: [],
  }, sources);
  assertEquals(r.quran.map((q) => q.verse_key), ["2:153"]);
  assertEquals(r.quran[0].arabic, sources.ayahs[0].arabic); // verbatim from DB
  assertEquals(r.hadith.map((h) => h.hadith_id), [42]);
  assertEquals(r.dropped, 3);
});

Deno.test("revenuecat events map to subscription state", () => {
  const future = Date.now() + 86400_000;
  const base = {
    entitlement_ids: ["premium"],
    store: "APP_STORE",
    product_id: "muslimai_premium_monthly",
    expiration_at_ms: future,
  };
  assertEquals(mapRevenueCatEvent({ ...base, type: "INITIAL_PURCHASE" }, "premium")?.status, "active");
  const cancel = mapRevenueCatEvent({ ...base, type: "CANCELLATION" }, "premium");
  assertEquals([cancel?.status, cancel?.will_renew], ["active", false]);
  assertEquals(mapRevenueCatEvent({ ...base, type: "EXPIRATION" }, "premium")?.status, "expired");
  assertEquals(
    mapRevenueCatEvent({ ...base, type: "INITIAL_PURCHASE", entitlement_ids: ["other"] }, "premium"),
    null,
  );
  assertEquals(
    mapRevenueCatEvent({ ...base, type: "BILLING_ISSUE", grace_period_expiration_at_ms: future }, "premium")
      ?.status,
    "grace_period",
  );
  assertEquals(
    mapRevenueCatEvent({ ...base, type: "INITIAL_PURCHASE", store: "PLAY_STORE" }, "premium")?.store,
    "play_store",
  );
});
