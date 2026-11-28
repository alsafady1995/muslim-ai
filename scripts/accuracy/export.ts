// Downloads the clips volunteers recorded in the app (Settings → Accuracy recordings,
// builds with BENCHMARK_RECORDER=true) into a benchmark folder for run.ts.
//
//   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... deno task export --out ./bench-data
//
// Re-running only downloads new clips. Audio stays private: it is in the
// "benchmark-clips" bucket, readable only with the service role.

import { parseArgs } from "@std/cli/parse-args";
import { createClient } from "@supabase/supabase-js";
import type { ManifestClip } from "./dataset.ts";

const args = parseArgs(Deno.args, { string: ["out"] });
const out = (args.out ?? "./bench-data").replace(/\/$/, "");
const url = Deno.env.get("SUPABASE_URL");
const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
if (!url || !key) {
  console.error("Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY");
  Deno.exit(2);
}
const db = createClient(url, key, { auth: { persistSession: false } });
await Deno.mkdir(`${out}/clips`, { recursive: true });

const { data: rows, error } = await db.from("benchmark_clips").select("*").order("created_at");
if (error) throw error;

const exists = async (p: string) => {
  try {
    await Deno.stat(p);
    return true;
  } catch {
    return false;
  }
};

const manifest: ManifestClip[] = [];
let downloaded = 0;
for (const r of rows as any[]) {
  const ext = String(r.audio_path).split(".").pop() ?? "m4a";
  const file = `clips/${r.id}.${ext}`;
  if (!(await exists(`${out}/${file}`))) {
    const { data, error: dlErr } = await db.storage.from("benchmark-clips").download(r.audio_path);
    if (dlErr || !data) {
      console.warn(`skipped ${r.id}: ${dlErr?.message ?? "no audio"}`);
      continue;
    }
    await Deno.writeFile(`${out}/${file}`, new Uint8Array(await data.arrayBuffer()));
    downloaded++;
  }
  const [{ data: words, error: wErr }, { data: ayah }] = await Promise.all([
    db.from("ayah_words").select("ayah_id, position, text_uthmani, text_simple")
      .gte("ayah_id", r.start_ayah_id).lte("ayah_id", r.end_ayah_id)
      .order("ayah_id").order("position").limit(5000),
    db.from("ayahs").select("surah_id").eq("id", r.start_ayah_id).maybeSingle(),
  ]);
  if (wErr) throw wErr;
  manifest.push({
    id: r.id,
    audio: file,
    surah: ayah?.surah_id,
    start_ayah_id: r.start_ayah_id,
    end_ayah_id: r.end_ayah_id,
    speaker: r.speaker_group,
    native_arabic: r.native_arabic,
    environment: r.environment,
    words: (words as any[]).map((w) => ({
      ayahId: w.ayah_id,
      position: w.position,
      uthmani: w.text_uthmani,
      simple: w.text_simple,
    })),
    mistakes: ((r.mistakes ?? []) as any[]).map((m) => ({
      ayahId: m.ayah_id,
      position: m.position,
      type: m.type,
    })),
  });
}

await Deno.writeTextFile(`${out}/manifest.jsonl`, manifest.map((c) => JSON.stringify(c)).join("\n") + "\n");
const by = (f: (c: ManifestClip) => string) =>
  Object.entries(
    manifest.reduce<Record<string, number>>((a, c) => ({ ...a, [f(c)]: (a[f(c)] ?? 0) + 1 }), {}),
  )
    .map(([k, v]) => `${k} ${v}`).join(", ");
console.log(`${manifest.length} clips (${downloaded} new) in ${out}`);
console.log(`speaker: ${by((c) => c.speaker ?? "?")}`);
console.log(`native Arabic: ${by((c) => String(c.native_arabic))}`);
console.log(`with mistakes: ${manifest.filter((c) => c.mistakes.length).length}`);
