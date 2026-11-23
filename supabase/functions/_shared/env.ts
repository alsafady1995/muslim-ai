// Central place for configuration. All secrets come from `supabase secrets set`.
function required(name: string): string {
  const v = Deno.env.get(name);
  if (!v) throw new Error(`Missing env var ${name}`);
  return v;
}

export const env = {
  supabaseUrl: () => required("SUPABASE_URL"),
  serviceRoleKey: () => required("SUPABASE_SERVICE_ROLE_KEY"),
  anonKey: () => required("SUPABASE_ANON_KEY"),
  anthropicKey: () => required("ANTHROPIC_API_KEY"),
  // Unit economics at $0.99/month: free users on Haiku 5.5, premium on Sonnet 5.5 (see BLOCKERS.md §4).
  claudeModel: () => Deno.env.get("CLAUDE_MODEL") ?? "claude-haiku-5-5",
  // Premium users get a stronger model; override with CLAUDE_MODEL_PREMIUM.
  claudeModelPremium: () => Deno.env.get("CLAUDE_MODEL_PREMIUM") ?? "claude-sonnet-5-5",
  claudeEffort: () => (Deno.env.get("CLAUDE_EFFORT") ?? "low") as "low" | "medium" | "high",
  voyageKey: () => required("VOYAGE_API_KEY"),
  voyageModel: () => Deno.env.get("VOYAGE_MODEL") ?? "voyage-3.5",
  asrUrl: () => required("ASR_SERVICE_URL"),
  asrToken: () => required("ASR_SERVICE_TOKEN"),
  revenuecatWebhookAuth: () => required("REVENUECAT_WEBHOOK_AUTH"),
  revenuecatEntitlement: () => Deno.env.get("REVENUECAT_ENTITLEMENT_ID") ?? "premium",
  posthogKey: () => Deno.env.get("POSTHOG_API_KEY"),
  posthogHost: () => Deno.env.get("POSTHOG_HOST") ?? "https://eu.i.posthog.com",
  defaultTranslationId: () => Number(Deno.env.get("DEFAULT_TRANSLATION_ID") ?? "20"),
  defaultTafsirArId: () => Number(Deno.env.get("DEFAULT_TAFSIR_AR_ID") ?? "1"),
  defaultTafsirEnId: () => Number(Deno.env.get("DEFAULT_TAFSIR_EN_ID") ?? "2"),
};
