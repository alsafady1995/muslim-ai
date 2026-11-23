// Builds pgvector embeddings for ayahs (Arabic + English translation), tafsir and hadith.
// Idempotent: skips rows already embedded. Usage: VOYAGE_API_KEY=... deno task embed
import { db, env, getJson } from "./lib.ts";

const MODEL = env("VOYAGE_MODEL", "voyage-3.5");
const BATCH = 96;
const client = db();

async function embedBatch(texts: string[]): Promise<number[][]> {
  const body = await getJson("https://api.voyageai.com/v1/embeddings", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env("VOYAGE_API_KEY")}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      input: texts,
      model: MODEL,
      input_type: "document",
      output_dimension: 1024,
    }),
  });
  return (body.data as any[]).sort((a, b) => a.index - b.index).map((d) =>
    d.embedding
  );
}

async function existing(type: string): Promise<Set<string>> {
  const keys = new Set<string>();
  for (let from = 0;; from += 1000) {
    const { data, error } = await client.from("content_embeddings").select(
      "source_id, source_variant, language",
    )
      .eq("source_type", type).range(from, from + 999);
    if (error) throw error;
    for (const r of data!) {
      keys.add(`${r.source_id}:${r.source_variant}:${r.language}`);
    }
    if (data!.length < 1000) return keys;
  }
}

async function fetchAll(table: string, select: string): Promise<any[]> {
  const out: any[] = [];
  for (let from = 0;; from += 1000) {
    const { data, error } = await client.from(table).select(select).range(
      from,
      from + 999,
    );
    if (error) throw error;
    out.push(...data!);
    if (data!.length < 1000) return out;
  }
}

interface Chunk {
  source_type: "ayah" | "tafsir" | "hadith";
  source_id: number;
  source_variant: number | null;
  language: string;
  chunk: string;
}

async function run(type: Chunk["source_type"], chunks: Chunk[]) {
  const done = await existing(type);
  const todo = chunks.filter((c) =>
    !done.has(`${c.source_id}:${c.source_variant}:${c.language}`)
  );
  console.log(
    `${type}: ${todo.length} to embed (${
      chunks.length - todo.length
    } already done)`,
  );
  for (let i = 0; i < todo.length; i += BATCH) {
    const batch = todo.slice(i, i + BATCH);
    const vectors = await embedBatch(batch.map((c) => c.chunk));
    const { error } = await client.from("content_embeddings").insert(
      batch.map((c, k) => ({ ...c, embedding: `[${vectors[k].join(",")}]` })),
    );
    if (error) throw error;
    if ((i / BATCH) % 10 === 0) {
      console.log(`  ${type} ${i + batch.length}/${todo.length}`);
    }
  }
}

const ayahs = await fetchAll("ayahs", "id, surah_id, ayah_number, text_simple");
const translations = new Map(
  (await fetchAll("ayah_translations", "ayah_id, text, translation_id")).map((
    t,
  ) => [t.ayah_id, t]),
);
await run(
  "ayah",
  ayahs.map((a) => ({
    source_type: "ayah",
    source_id: a.id,
    source_variant: translations.get(a.id)?.translation_id ?? null,
    language: "multi",
    chunk: `Quran ${a.surah_id}:${a.ayah_number}\n${a.text_simple}\n${
      translations.get(a.id)?.text ?? ""
    }`,
  })),
);

const tafsir = await fetchAll(
  "ayah_tafsir",
  "ayah_id, tafsir_id, text, tafsir_sources(language)",
);
await run(
  "tafsir",
  tafsir.map((t) => ({
    source_type: "tafsir",
    source_id: t.ayah_id,
    source_variant: t.tafsir_id,
    language: t.tafsir_sources?.language ?? "ar",
    chunk: t.text.slice(0, 2000),
  })),
);

const hadiths = await fetchAll("hadiths", "id, reference, text_ar, text_en");
await run(
  "hadith",
  hadiths.map((h) => ({
    source_type: "hadith",
    source_id: h.id,
    source_variant: null,
    language: "multi",
    chunk: `${h.reference}\n${(h.text_en ?? "").slice(0, 1500)}\n${
      h.text_ar.slice(0, 1000)
    }`,
  })),
);
console.log("embeddings complete");
