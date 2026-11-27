import { createClient } from "@supabase/supabase-js";
export { normalizeArabic } from "../../supabase/functions/_shared/arabic.ts";

export function env(name: string, fallback?: string): string {
  const v = Deno.env.get(name) ?? fallback;
  if (v === undefined) throw new Error(`Missing env ${name}`);
  return v;
}

// Every request gets a deadline so a stalled connection fails (and is retried) instead of
// hanging the run forever.
const TIMEOUT_MS = 90_000;
export const timedFetch: typeof fetch = (input, init) =>
  fetch(input, { ...init, signal: AbortSignal.timeout(TIMEOUT_MS) });

export const db = () =>
  createClient(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY"), {
    auth: { persistSession: false },
    global: { fetch: timedFetch },
  });

export async function getJson<T = any>(
  url: string,
  init?: RequestInit,
  tries = 4,
): Promise<T> {
  for (let i = 0;; i++) {
    let res: Response;
    try {
      res = await timedFetch(url, init);
    } catch (e) {
      if (i >= tries - 1) throw e;
      await new Promise((r) => setTimeout(r, 1000 * 2 ** i));
      continue;
    }
    if (res.ok) return await res.json();
    if (i >= tries - 1 || (res.status < 500 && res.status !== 429)) {
      throw new Error(`${res.status} ${url}: ${await res.text()}`);
    }
    await new Promise((r) => setTimeout(r, 1000 * 2 ** i));
  }
}

export async function upsertChunks(
  table: string,
  rows: unknown[],
  onConflict: string,
  size = 500,
) {
  const client = db();
  for (let i = 0; i < rows.length; i += size) {
    const { error } = await client.from(table).upsert(rows.slice(i, i + size), {
      onConflict,
    });
    if (error) throw new Error(`${table}: ${error.message}`);
  }
}
