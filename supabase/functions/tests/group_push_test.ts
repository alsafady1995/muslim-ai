import { assertEquals, assertStringIncludes } from "@std/assert";
import { callNotification, langFor, reasonText } from "../_shared/group_push.ts";

const base = { reason: null, dedication: null, sender_name: "أم أحمد", group_name: "العيلة" };

Deno.test("khatma call names the reason and the person", () => {
  const n = callNotification({ ...base, kind: "khatma", reason: "deceased", dedication: "جدي" }, "ar");
  assertEquals(n.title, "العيلة");
  assertStringIncludes(n.body, "أم أحمد");
  assertStringIncludes(n.body, "لروح جدي");
});

Deno.test("a reason without a name reads naturally", () => {
  assertEquals(reasonText("ar", "sick", null), "لشفاء مرضانا");
  assertEquals(reasonText("en", "sick", "  "), "for the sick");
  assertEquals(reasonText("ar", null, null), "بنية عامة");
  assertEquals(reasonText("ar", "unknown", null), "بنية عامة");
});

Deno.test("salawat is in the member's language", () => {
  assertStringIncludes(callNotification({ ...base, kind: "salawat" }, "ar").body, "صلّوا على النبي ﷺ");
  assertStringIncludes(callNotification({ ...base, kind: "salawat" }, "en").body, "salawat");
});

Deno.test("khatma_done has no sender", () => {
  const n = callNotification({
    ...base,
    sender_name: null,
    kind: "khatma_done",
    reason: "sick",
    dedication: "خالتي",
  }, "ar");
  assertStringIncludes(n.body, "تمّت الختمة لشفاء خالتي");
});

Deno.test("language falls back to Arabic only when unknown", () => {
  assertEquals(langFor(undefined), "ar");
  assertEquals(langFor("ar"), "ar");
  assertEquals(langFor("tr"), "en");
});
