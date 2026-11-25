import { assertEquals } from "@std/assert";
import { refusalError } from "../_shared/ai_refusal.ts";

Deno.test("weekly limit is a 402 the app turns into the limit sheet", () => {
  const e = refusalError("ask", { reason: "weekly_limit", premium: false, limit: 15, resets_at: "x" });
  assertEquals(e.status, 402);
  assertEquals(e.code, "quota_exceeded");
  assertEquals(e.extra?.limit, 15);
});

Deno.test("budget is a 429 with the user's tier", () => {
  const e = refusalError("recitation", { reason: "budget", premium: true, tier: "premium", resets_at: "x" });
  assertEquals(e.status, 429);
  assertEquals(e.code, "ai_budget_exhausted");
  assertEquals(e.extra?.tier, "premium");
});

Deno.test("guests are asked to create an account, never shown Premium", () => {
  const e = refusalError("ask", { reason: "sign_in", premium: false, tier: "guest" });
  assertEquals(e.status, 429);
  assertEquals(e.code, "ai_budget_exhausted");
  assertEquals(e.extra?.tier, "guest");
  assertEquals(e.extra?.premium, false);
});

Deno.test("a full daily free pool pauses free AI until midnight UTC", () => {
  const e = refusalError("search", {
    reason: "free_pool",
    tier: "free",
    resets_at: "2026-11-26T00:00:00+00:00",
  });
  assertEquals(e.status, 429);
  assertEquals(e.extra?.tier, "busy");
  assertEquals(e.extra?.resets_at, "2026-11-26T00:00:00+00:00");
});
