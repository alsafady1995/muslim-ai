import Anthropic from "@anthropic-ai/sdk";
import { env } from "./env.ts";

let _client: Anthropic | null = null;

export function claude(): Anthropic {
  _client ??= new Anthropic({ apiKey: env.anthropicKey(), maxRetries: 2, timeout: 60_000 });
  return _client;
}

/** Beta flag for server-side refusal fallbacks (see `fallbacks: "default"` on requests). */
export const FALLBACK_BETA = "server-side-fallback-2026-07-01";
