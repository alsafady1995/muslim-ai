// POST /functions/v1/delete-account  — required by App Store guideline 5.1.1(v).
// Deletes recitation audio and the auth user; all user rows cascade via FKs.
// Store subscriptions must be cancelled by the user in the store; the app links there.
import { handler, json } from "../_shared/http.ts";
import { admin, requireUser } from "../_shared/supabase.ts";
import { track } from "../_shared/analytics.ts";

Deno.serve(handler(async (req) => {
  const user = await requireUser(req);
  const db = admin();
  const { data: files } = await db.storage.from("recitations").list(user.id, { limit: 1000 });
  if (files?.length) await db.storage.from("recitations").remove(files.map((f) => `${user.id}/${f.name}`));
  const { error } = await db.auth.admin.deleteUser(user.id);
  if (error) throw error;
  await track(user.id, "account_deleted");
  return json({ ok: true });
}));
