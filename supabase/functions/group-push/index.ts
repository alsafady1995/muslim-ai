// POST /functions/v1/group-push  { call_id }
// Called by the app right after send_group_call (or after completing a khatma, with the
// khatma_done call id). Postgres decides who may announce the call and to whom, and marks it pushed
// so a call is announced once. Without FCM_SERVICE_ACCOUNT it does nothing: members still see
// the call in the app.
import { handler, HttpError, json } from "../_shared/http.ts";
import { admin, requireUser } from "../_shared/supabase.ts";
import { callNotification, type CallPush } from "../_shared/group_push.ts";
import { fcmConfigured, sendFcm } from "../_shared/fcm.ts";

Deno.serve(handler(async (req, body) => {
  const user = await requireUser(req);
  const callId = Number(body?.call_id);
  if (!Number.isSafeInteger(callId) || callId <= 0) throw new HttpError(400, "invalid_call");
  if (!fcmConfigured()) return json({ sent: 0, configured: false });

  const db = admin();
  const { data, error } = await db.rpc("_group_call_push_targets", { p_call: callId, p_caller: user.id });
  if (error) throw error;
  if (!data) return json({ sent: 0 });

  const call = data as CallPush & {
    call_id: number;
    group_id: string;
    targets: { token: string; locale: string }[];
  };
  const messages = call.targets.map((t) => ({
    token: t.token,
    ...callNotification(call, t.locale),
    data: { type: "group_call", group_id: call.group_id, call_id: String(call.call_id), kind: call.kind },
  }));
  const { sent, invalid } = await sendFcm(messages);
  if (invalid.length) await db.rpc("_drop_push_tokens", { p_tokens: invalid });
  return json({ sent });
}));
