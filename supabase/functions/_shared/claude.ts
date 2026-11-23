import Anthropic from "@anthropic-ai/sdk";
import { env } from "./env.ts";

let _client: Anthropic | null = null;

export function claude(): Anthropic {
  _client ??= new Anthropic({ apiKey: env.anthropicKey(), maxRetries: 2, timeout: 60_000 });
  return _client;
}

/** Beta flag for server-side refusal fallbacks (see `fallbacks: "default"` on requests). */
export const FALLBACK_BETA = "server-side-fallback-2026-07-01";

/** Models that accept the server-side `fallbacks` parameter (others reject it). */
const FALLBACK_MODELS = new Set([
  "claude-opus-5-5",
  "claude-opus-5",
  "claude-sonnet-5-5",
  "claude-fable-5-2",
  "claude-fable-5-1",
]);
export function supportsFallbacks(model: string): boolean {
  return FALLBACK_MODELS.has(model);
}
