# Owner action list

Everything below needs you personally (accounts, identity, payment, legal). The code is ready for each item;
the "Where it goes" column says where to paste the result. Order = fastest path to a TestFlight / Play internal build.

## 1. Accounts and keys (week 1)

| # | What | Steps | Where it goes |
|---|---|---|---|
| 1 | **GitHub repo** | Create an empty private repo (e.g. `muslim-ai`) on github.com and tell Claude its name. Claude pushes the code. | — |
| 2 | **Supabase project** | supabase.com → New project → region **Middle East (Bahrain) or EU (Frankfurt)**, Pro plan ($25/mo) recommended at launch. Settings → API: copy Project URL, anon/publishable key, service role key. Settings → Access tokens: create a token. | App: `env/prod.json` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`). GitHub secrets: `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF`, `SUPABASE_DB_PASSWORD`. |
| 3 | **Anthropic API key** | console.anthropic.com → API keys → Create. Add billing (prepaid credit). | `supabase secrets set ANTHROPIC_API_KEY=...` |
| 4 | **Voyage AI key** (embeddings) | dash.voyageai.com → API keys. One-time ingest costs about $1–3. | `supabase secrets set VOYAGE_API_KEY=...` and local env for `scripts/ingest` |
| 5 | **Google Cloud** (ASR service) | console.cloud.google.com → new project → enable Cloud Run + billing → run the `gcloud run deploy` command in `services/asr/README.md`. | `supabase secrets set ASR_SERVICE_URL=... ASR_SERVICE_TOKEN=...` |
| 6 | **PostHog** | posthog.com → EU cloud → project API key. | App `POSTHOG_KEY`; secret `POSTHOG_API_KEY` |
| 7 | **Sentry** | sentry.io → new Flutter project → DSN. | App `SENTRY_DSN` |

## 2. Store accounts (start day 1: identity checks take days)

| # | What | Steps |
|---|---|---|
| 8 | **Apple Developer Program** ($99/yr) | developer.apple.com/programs/enroll → enroll **as an individual** (no company needed). Needs Apple ID with 2FA and government ID. Approval 1–2 days. |
| 9 | **Apple: Paid Apps agreement + banking + tax** | App Store Connect → Business → accept Paid Apps Agreement, add bank account and W-8BEN tax form. Without this, in-app purchases do not work even in TestFlight. Also enrol in the **App Store Small Business Program** (15% commission instead of 30%). |
| 10 | **App Store Connect app + subscription** | Create app with bundle ID `app.muslimai.mobile`. Subscriptions → group "Premium" → product `muslimai_premium_monthly` at $0.99 (tier 1), optional `muslimai_premium_annual` $7.99 with 7-day free trial. Create an **App Store Connect API key** (Users and Access → Integrations) → gives Key ID, Issuer ID, .p8 file. |
| 11 | **Google Play Console** ($25 once) | play.google.com/console → personal account. New personal accounts must run a **closed test with 12+ testers for 14 days** before production access, so start this early. Identity verification required. |
| 12 | **Play: payments profile + subscription** | Set up a merchant/payments profile (individual is fine) → create app `app.muslimai.mobile` → Monetize → Subscriptions → `muslimai_premium_monthly` $0.99 (+ annual). Create a service account with "Release manager" access → JSON key. |
| 13 | **RevenueCat** (free under $2.5k MTR) | app.revenuecat.com → project → add iOS app (upload App Store Connect in-app purchase key) and Android app (upload Play service account JSON) → entitlement `premium` → offering `default` with monthly (and annual) packages → Integrations → Webhooks: URL `https://<project>.supabase.co/functions/v1/revenuecat-webhook`, Authorization header = a random 64-char string. | App: `REVENUECAT_APPLE_KEY`, `REVENUECAT_GOOGLE_KEY`. Secret: `REVENUECAT_WEBHOOK_AUTH` (same string). |
| 14 | **Sign in with Apple + Google** | Apple: Identifiers → enable Sign in with Apple, create a Services ID and key. Google Cloud → OAuth consent screen + iOS, Android and Web client IDs (Android needs the Play app-signing SHA-1). Paste into Supabase → Auth → Providers. | App: `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID` |
| 15 | **Signing for CI** | iOS: create a private git repo for `fastlane match`, run `bundle exec fastlane certs` once locally in `app/ios`. Android: `keytool -genkey -v -keystore upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`, keep it backed up. | GitHub secrets listed in `.github/workflows/release-mobile.yml` |

## 3. Legal and content (before public launch)

| # | What | Why |
|---|---|---|
| 16 | **Domain** (e.g. muslimai.app) | Privacy policy and terms URLs are mandatory for both stores and for subscriptions. Set `PRIVACY_URL`, `TERMS_URL`. Drafts are in `docs/`. |
| 17 | **Scholar review** | Every adhkar text/reference in `supabase/migrations/20261123000004_reference_data.sql`, the AI system prompt in `supabase/functions/_shared/grounded.ts`, and a sample of AI answers should be reviewed by a qualified scholar. |
| 18 | **Content licences** | Confirm terms for: Saheeh International translation and Tafsir Ibn Kathir (abridged) via Quran.com API (Quran Foundation may require API client credentials, so register at quran.foundation), EveryAyah audio (reciter permissions), hadith-api dataset, `tarteel-ai/whisper-base-ar-quran` model licence. Swap any source that does not allow commercial use. |
| 19 | **Privacy for voice data** | Recordings are deleted right after analysis (code does this). Declare microphone + voice processing in App Privacy (Apple) and Data safety (Google). Saudi PDPL applies to KSA users. |

## 4. One owner decision: AI model cost

The code defaults to **Claude Opus 5.5** (`CLAUDE_MODEL`). Rough cost per Ask-the-Quran answer
(~5.5k input tokens with sources, ~1k output): **Opus 5.5 ≈ $0.04**, **Haiku 5.5 ≈ $0.001**.
A free user using all 5 daily questions costs ~$6/month on Opus vs ~$0.15 on Haiku; a premium user pays $0.99
(≈ $0.84 after Apple/Google 15%). Changing it is one command, no app release:
`supabase secrets set CLAUDE_MODEL=claude-haiku-5-5` (optionally `CLAUDE_MODEL_PREMIUM=claude-opus-5-5`).
Run a quality check on ~50 real questions before switching.

## 5. Not verified in this build environment

- `scripts/ingest` was type-checked but not run: the build sandbox could not reach api.quran.com or jsDelivr. Run `deno task all` once keys exist; it logs counts (expect 114 surahs, 6,236 ayahs).
- No Android/iOS native build was produced here (no Android SDK / macOS). CI builds both on the first tag.
- The ASR Docker image was not built here (model download blocked); its API and auth are unit-tested.
