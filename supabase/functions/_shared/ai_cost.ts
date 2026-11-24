// What each AI call costs us, in USD. Used to enforce the per-user AI budget
// (see supabase/migrations/20261124000001_ai_cost_cap.sql): no user may cost more
// than half of what they pay.
//
// Claude prices are Anthropic first-party list prices per million tokens (Nov 2026).
// Re-check https://www.anthropic.com/pricing when changing models.

export interface ModelPrice {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number; // 5-minute TTL write (1.25x input)
}

const PER_MTOK: Record<string, ModelPrice> = {
  "claude-haiku-5-5": { input: 0.10, output: 0.50, cacheRead: 0.01, cacheWrite: 0.125 },
  "claude-sonnet-5-5": { input: 2, output: 10, cacheRead: 0.10, cacheWrite: 2.5 },
  "claude-sonnet-5": { input: 2, output: 10, cacheRead: 0.20, cacheWrite: 2.5 },
  "claude-opus-5-5": { input: 4, output: 20, cacheRead: 0.20, cacheWrite: 5 },
  "claude-opus-5": { input: 5, output: 25, cacheRead: 0.50, cacheWrite: 6.25 },
  "claude-opus-4-8": { input: 5, output: 25, cacheRead: 0.50, cacheWrite: 6.25 },
  "claude-fable-5-2": { input: 8, output: 40, cacheRead: 0.20, cacheWrite: 10 },
  "claude-fable-5-1": { input: 10, output: 50, cacheRead: 0.25, cacheWrite: 12.5 },
};
// Unknown model (e.g. a server-side refusal fallback we have not priced): assume the most expensive.
const UNKNOWN: ModelPrice = { input: 10, output: 50, cacheRead: 1, cacheWrite: 12.5 };

export function modelPrice(model: string): ModelPrice {
  const exact = PER_MTOK[model];
  if (exact) return exact;
  // Tolerate dated or suffixed ids such as "claude-haiku-5-5-20261001".
  const key = Object.keys(PER_MTOK).sort((a, b) => b.length - a.length).find((k) => model.startsWith(k));
  return key ? PER_MTOK[key] : UNKNOWN;
}

export interface ClaudeUsage {
  input_tokens: number;
  output_tokens: number;
  cache_read_input_tokens?: number | null;
  cache_creation_input_tokens?: number | null;
}

/** Actual cost of one Claude response, from its usage block. */
export function claudeCostUsd(model: string, u: ClaudeUsage): number {
  const p = modelPrice(model);
  return (
    u.input_tokens * p.input +
    u.output_tokens * p.output +
    (u.cache_read_input_tokens ?? 0) * p.cacheRead +
    (u.cache_creation_input_tokens ?? 0) * p.cacheWrite
  ) / 1_000_000;
}

/**
 * Upper bound for one call: the caller keeps the prompt under maxInputTokens (with a margin
 * that covers the cache-write premium on the ~1k-token system prompt) and the API caps output
 * (thinking included) at maxOutputTokens.
 */
export function claudeReserveUsd(model: string, maxInputTokens: number, maxOutputTokens: number): number {
  const p = modelPrice(model);
  return (maxInputTokens * p.input + maxOutputTokens * p.output) / 1_000_000;
}

function num(name: string, fallback: number): number {
  const v = Number(Deno.env.get(name));
  return Number.isFinite(v) && v >= 0 && Deno.env.get(name) !== undefined ? v : fallback;
}

/** One query embedding (Voyage, ~50 tokens). Tiny, but counted so the ledger is complete. */
export const embeddingCostUsd = () => num("EMBEDDING_COST_PER_CALL_USD", 0.00002);

/** Speech recognition on our ASR service, per audio minute (GPU time incl. cold-start overhead). */
export const asrCostPerMinuteUsd = () => num("ASR_COST_PER_MINUTE_USD", 0.001);

/** Longest recording we accept; used to reserve the worst case before transcribing. */
export const ASR_MAX_MINUTES = 5; // matches ASR_MAX_DURATION_SEC on the ASR service (the app stops at 3)

/** Rough token count; deliberately high (Arabic with diacritics tokenises densely). */
export function estimateTokens(text: string): number {
  return Math.ceil(text.length / 1.5);
}

export function roundUsd(v: number): number {
  return Math.round(v * 1_000_000) / 1_000_000;
}
