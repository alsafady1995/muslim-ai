// POST /functions/v1/ask-quran
// { question: string, locale?: "ar"|"en"|..., conversation_id?: uuid, translation_id?: number }
// -> GroundedAnswer with verified Quran / Hadith text and quota info.
import { handler, json } from "../_shared/http.ts";
import { requireUser } from "../_shared/supabase.ts";
import { runAsk } from "../_shared/ask_flow.ts";

Deno.serve(handler(async (req, body) => {
  const user = await requireUser(req);
  return json(await runAsk(user, body, "ask_quran"));
}));
