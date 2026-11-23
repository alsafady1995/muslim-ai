// POST /functions/v1/assistant
// Multi-turn Islamic assistant. Same request/response shape as ask-quran; pass the
// returned conversation_id on follow-up messages to keep context.
import { handler, json } from "../_shared/http.ts";
import { requireUser } from "../_shared/supabase.ts";
import { runAsk } from "../_shared/ask_flow.ts";

Deno.serve(handler(async (req, body) => {
  const user = await requireUser(req);
  return json(await runAsk(user, body, "assistant"));
}));
