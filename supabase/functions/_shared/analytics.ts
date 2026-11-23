import { env } from "./env.ts";

/** Fire-and-forget server-side PostHog event. Never throws. */
export async function track(distinctId: string, event: string, properties: Record<string, unknown> = {}) {
  const key = env.posthogKey();
  if (!key) return;
  try {
    await fetch(`${env.posthogHost()}/capture/`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        api_key: key,
        event,
        distinct_id: distinctId,
        properties: { ...properties, $lib: "edge" },
      }),
    });
  } catch (e) {
    console.warn("posthog capture failed", e);
  }
}
