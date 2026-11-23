import { env } from "./env.ts";

/**
 * Voyage AI embeddings (multilingual, 1024 dims). Claude has no embeddings endpoint;
 * Voyage is Anthropic's recommended provider. Swap here if you change provider
 * (and re-run scripts/ingest/embed.ts so stored vectors match).
 */
export async function embed(texts: string[], inputType: "query" | "document"): Promise<number[][]> {
  const res = await fetch("https://api.voyageai.com/v1/embeddings", {
    method: "POST",
    headers: { "Authorization": `Bearer ${env.voyageKey()}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      input: texts,
      model: env.voyageModel(),
      input_type: inputType,
      output_dimension: 1024,
    }),
  });
  if (!res.ok) throw new Error(`voyage ${res.status}: ${await res.text()}`);
  const body = await res.json();
  return (body.data as { embedding: number[]; index: number }[])
    .sort((a, b) => a.index - b.index)
    .map((d) => d.embedding);
}

export function toPgVector(v: number[]): string {
  return `[${v.join(",")}]`;
}
