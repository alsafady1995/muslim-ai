import { createClient } from "@supabase/supabase-js";
export { normalizeArabic } from "../../supabase/functions/_shared/arabic.ts";

export function env(name: string, fallback?: string): string {
  const v = Deno.env.get(name) ?? fallback;
  if (v === undefined) throw new Error(`Missing env ${name}`);
  return v;
}

export const db = () =>
  createClient(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY"), {
    auth: { persistSession: false },
  });

export async function getJson<T = any>(
  url: string,
  init?: RequestInit,
  tries = 4,
): Promise<T> {
  for (let i = 0;; i++) {
    const res = await fetch(url, init);
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
