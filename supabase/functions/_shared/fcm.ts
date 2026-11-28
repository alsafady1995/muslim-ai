// Firebase Cloud Messaging (HTTP v1) with a service-account key, no SDK.
// Secret: FCM_SERVICE_ACCOUNT = the service account JSON from Firebase → Project settings →
// Service accounts → Generate new private key (BLOCKERS.md item 35).

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

let cached: { token: string; exp: number; projectId: string } | null = null;

function b64url(data: ArrayBuffer | Uint8Array | string): string {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : new Uint8Array(data);
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToDer(pem: string): ArrayBuffer {
  const body = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const raw = atob(body);
  const out = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
  return out.buffer;
}

export function fcmConfigured(): boolean {
  return Boolean(Deno.env.get("FCM_SERVICE_ACCOUNT"));
}

async function accessToken(): Promise<{ token: string; projectId: string }> {
  const now = Math.floor(Date.now() / 1000);
  if (cached && cached.exp - 60 > now) return cached;
  const sa = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT") ?? "{}") as ServiceAccount;
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${header}.${claims}`),
  );
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${header}.${claims}.${b64url(sig)}`,
    }),
  });
  if (!res.ok) throw new Error(`fcm auth ${res.status}: ${await res.text()}`);
  const j = await res.json();
  cached = { token: j.access_token, exp: now + (j.expires_in ?? 3600), projectId: sa.project_id };
  return cached;
}

export interface FcmMessage {
  token: string;
  title: string;
  body: string;
  data: Record<string, string>;
}

/** Sends each message; returns the tokens FCM says are no longer valid (to delete). */
export async function sendFcm(messages: FcmMessage[]): Promise<{ sent: number; invalid: string[] }> {
  if (!messages.length) return { sent: 0, invalid: [] };
  const { token, projectId } = await accessToken();
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const invalid: string[] = [];
  let sent = 0;
  await Promise.all(messages.map(async (m) => {
    const res = await fetch(url, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        message: {
          token: m.token,
          notification: { title: m.title, body: m.body },
          data: m.data,
          android: { priority: "high", notification: { channel_id: "groups" } },
          apns: { payload: { aps: { sound: "default" } } },
        },
      }),
    });
    if (res.ok) {
      sent++;
      return;
    }
    const text = await res.text();
    if (res.status === 404 || text.includes("UNREGISTERED")) invalid.push(m.token);
    else console.error("fcm send", res.status, text);
  }));
  return { sent, invalid };
}
