import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { env } from "./env.ts";
import { HttpError } from "./http.ts";

let _admin: SupabaseClient | null = null;

/** Service-role client. Bypasses RLS: only use after the caller is authenticated. */
export function admin(): SupabaseClient {
  _admin ??= createClient(env.supabaseUrl(), env.serviceRoleKey(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return _admin;
}

export interface AuthedUser {
  id: string;
  isAnonymous: boolean;
}

/** Resolves the Supabase user from the bearer token or throws 401. */
export async function requireUser(req: Request): Promise<AuthedUser> {
  const auth = req.headers.get("Authorization") ?? "";
  const token = auth.replace(/^Bearer\s+/i, "");
  if (!token) throw new HttpError(401, "unauthorized");
  const { data, error } = await admin().auth.getUser(token);
  if (error || !data.user) throw new HttpError(401, "unauthorized");
  return { id: data.user.id, isAnonymous: Boolean((data.user as any).is_anonymous) };
}
