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
| 10 | **App Store Connect app + subscription** | Create app with bundle ID `app.muslimai.mobile`. Subscriptions → group "Premium" → `muslimai_premium_annual` **$29.99/year** with a **7-day free trial** introductory offer (new subscribers only) and `muslimai_premium_monthly` **$4.99/month** with **no trial**. Exact clicks in `docs/store-setup.md`. Then set lower prices per storefront for Egypt, Pakistan and Indonesia (see "Regional prices" below). Create an **App Store Connect API key** (Users and Access → Integrations) → gives Key ID, Issuer ID, .p8 file. |
| 11 | **Google Play Console** ($25 once) | play.google.com/console → personal account. New personal accounts must run a **closed test with 12+ testers for 14 days** before production access, so start this early. Identity verification required. |
| 12 | **Play: payments profile + subscription** | Set up a merchant/payments profile (individual is fine) → create app `app.muslimai.mobile` → Monetize → Subscriptions → `muslimai_premium_annual` $29.99 (base plan `annual`, with a 7-day free-trial offer) and `muslimai_premium_monthly` $4.99 (base plan `monthly`, no offer); set regional prices as below. Create a service account with "Release manager" access → JSON key. |
| 13 | **RevenueCat** (free under $2.5k MTR) | app.revenuecat.com → project → add iOS app (upload App Store Connect in-app purchase key) and Android app (upload Play service account JSON) → entitlement `premium` → offering `default` with `$rc_annual` first and `$rc_monthly` (the app pre-selects annual) → Integrations → Webhooks: URL `https://<project>.supabase.co/functions/v1/revenuecat-webhook`, Authorization header = a random 64-char string. | App: `REVENUECAT_APPLE_KEY`, `REVENUECAT_GOOGLE_KEY`. Secret: `REVENUECAT_WEBHOOK_AUTH` (same string). |
| 14 | **Sign in with Apple + Google** | Apple: Identifiers → enable Sign in with Apple, create a Services ID and key. Google Cloud → OAuth consent screen + iOS, Android and Web client IDs (Android needs the Play app-signing SHA-1). Paste into Supabase → Auth → Providers. | App: `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID` |
| 15 | **Signing for CI** | iOS: create a private git repo for `fastlane match`, run `bundle exec fastlane certs` once locally in `app/ios`. Android: `keytool -genkey -v -keystore upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`, keep it backed up. | GitHub secrets listed in `.github/workflows/release-mobile.yml` |

### Regional prices (decided)

| Market | Monthly | Annual | Why |
|---|---|---|---|
| Default (all other storefronts, incl. GCC, Europe, US) | $4.99 (≈ SAR 18.99), no trial | $29.99 (≈ SAR 109.99) with 7-day trial, shown as "save 49%" | Base price (decided 24 Nov 2026) |
| Egypt, Pakistan, Indonesia | ≈ $0.99 in local currency | ≈ $6.99 in local currency | Purchasing power; volume markets |

Apple: Subscription → Subscription Prices → Add pricing → pick the storefront → choose the local tier. Google: base plan → Set prices → edit the country. Other low-income markets (e.g. Bangladesh, Nigeria, India) can follow the same row later. The AI cost cap uses what each user actually paid, so a lower regional price automatically means a smaller AI budget; no code change is needed when you add or change a price.

## 3. Legal and content (before public launch)

| # | What | Why |
|---|---|---|
| 16 | **Domain** (e.g. muslimai.app) | Privacy policy and terms URLs are mandatory for both stores and for subscriptions. Set `PRIVACY_URL`, `TERMS_URL`. Drafts are in `docs/`. |
| 17 | **Scholar review** | Every adhkar text/reference in `supabase/migrations/20261123000004_reference_data.sql`, the AI system prompt in `supabase/functions/_shared/grounded.ts`, and a sample of AI answers should be reviewed by a qualified scholar. |
| 18 | **Content licences** | Confirm terms for: Saheeh International translation and Tafsir Ibn Kathir (abridged) via Quran.com API (Quran Foundation may require API client credentials, so register at quran.foundation), EveryAyah audio (reciter permissions), hadith-api dataset, `tarteel-ai/whisper-base-ar-quran` model licence. Swap any source that does not allow commercial use. |
| 19 | **Privacy for voice data** | Recordings are deleted right after analysis (code does this). Declare microphone + voice processing in App Privacy (Apple) and Data safety (Google). Saudi PDPL applies to KSA users. |

## 4. AI model routing and cost (decided)

| Tier | Model | Cost per answer* | Weekly Ask limit | Hard AI budget (all AI features) |
|---|---|---|---|---|
| Free | Claude Haiku 5.5 | ≈ $0.001 | 15 questions | $0.05 / month (guests: onboarding check only), plus a $20/day pool for all free users |
| Trial (7 days) | Claude Sonnet 5.5 | ≈ $0.02 | 100 questions (fair use) | $0.25 for the trial |
| Premium | Claude Sonnet 5.5, then Haiku near the limit | ≈ $0.02 | 100 questions (fair use) | 50% of what the user paid |

All weekly limits are in `ARCHITECTURE.md` ("AI limits"); they renew every Friday and are tunable in `plan_limits`.
\* About 5.5k input tokens (question + retrieved sources) and 1k output.

**Rule: no user costs more than half of what they pay.** The server enforces it per user (see `ARCHITECTURE.md`,
"AI cost cap"). What that means per subscriber, per month, after the store's 15% and VAT where included:

| Plan | Net per month | AI budget per month | ≈ Sonnet answers before switching to Haiku |
|---|---|---|---|
| $4.99 monthly | ≈ $3.69–$4.24 | ≈ $1.84–$2.12 | ≈ 55–60 (Ask may use 60% of the budget) |
| $29.99 annual | ≈ $1.85–$2.12 | ≈ $0.92–$1.06 (pooled over the year, up to 3× in one month) | ≈ 28–32 |
| Regional $0.99 monthly | ≈ $0.73–$0.84 | ≈ $0.37–$0.42 | ≈ 18 |
| Regional $6.99 annual | ≈ $0.43–$0.50 | ≈ $0.21–$0.25 | ≈ 10 |

After that, premium answers continue on Haiku until the budget is fully used, then AI pauses with a friendly
message until the next monthly window. Tune with SQL, no release needed:
`update ai_budget_settings set value = 0.05 where key = 'free_monthly_usd';` (keys: `cost_share`, `free_monthly_usd`, `guest_monthly_usd`, `free_daily_pool_usd`,
`trial_budget_usd`, `promo_monthly_usd`, `fallback_net_monthly_usd`, `core_share`, `annual_pace_multiple`). Watch `ai_spend` for how many users hit the cap, and `ai_free_pool` (`used_usd`, `refused`) for days the free pool filled up.

Before launch, run the answer-quality eval described in `docs/` on Haiku. If it fails, raise the free model with
`supabase secrets set CLAUDE_MODEL=claude-sonnet-5-5` and re-check this table.

## 5. From the full audit (docs/full-audit.md)

| # | What | Why |
|---|---|---|
| 20 | ~~Merge PRs #1–#4, then the audit PR~~ Done by Claude on 24 Nov 2026; backend deploy ran from `main`. | |
| 21 | **Trial on the annual plan only.** Ready to apply when the stores approve the account: `docs/store-setup.md` §1. | Monthly trials mostly attract people who cancel; the paywall leads with annual and its trial timeline. |
| 22 | **Prices $29.99/year, $4.99/month** (decided). Enter them when creating the products: `docs/store-setup.md` §1. Egypt, Pakistan, Indonesia unchanged. | The app reads prices from the store; no release needed. |
| 23 | **Billing grace period** + account hold: `docs/store-setup.md` §2. | Failed renewals are 20–40% of churn. The app shows an "update your payment" card. |
| 24 | **Win-back offers**: `docs/store-setup.md` §3 (after launch, once there are lapsed subscribers). | The cheapest subscriber to acquire is a former one. |
| 25 | **RevenueCat offering:** make sure `default` lists `$rc_annual` first and both products are attached to entitlement `premium`. | The paywall shows whatever the offering returns. |
| 26 | **PostHog dashboards** for the funnel in `docs/full-audit.md` §7 (onboarding → first recitation → day-3 value gate → paywall view → trial → paid). | All events are already sent; you only need to build the charts. |

## 5b. From the end-to-end verification (24 Nov 2026)

| # | What | Why |
|---|---|---|
| 27 | **Apple: enable "Sign in with Apple" on the App ID `app.muslimai.mobile`**, then regenerate the match profile once: `cd app/ios && bundle exec fastlane match appstore --force` (needs the match repo). | The app now ships the Sign in with Apple entitlement (it was missing, so the Apple button failed on iOS). A profile without the capability fails the release build. |
| 28 | **`GOOGLE_IOS_CLIENT_ID` must be in `APP_ENV_PROD_JSON`.** The iOS release job turns it into the URL scheme Google Sign-In needs and stops with an error if it is missing. For local iOS runs add the reversed id (`com.googleusercontent.apps.…`) to `CFBundleURLTypes` in `ios/Runner/Info.plist` yourself. | Without that URL scheme Google Sign-In aborts the app on iOS. |
| 29 | **Supabase → Auth → Apple: "Client IDs" must list both the Services ID and the bundle id `app.muslimai.mobile`** (comma-separated). Google: list the Web, iOS and Android client ids. | Native iOS Apple tokens carry the bundle id as audience; Supabase rejects them otherwise. |
| 30 | **Google: register the Play app-signing SHA-1 and the upload-key SHA-1** on the Android OAuth client. | Google Sign-In on Android fails with error 10 otherwise. |

## 6. Not verified in this build environment


- `scripts/ingest` was type-checked but not run: the build sandbox could not reach api.quran.com or jsDelivr. Run `deno task all` once keys exist; it logs counts (expect 114 surahs, 6,236 ayahs).
- No Android/iOS native build was produced here (no Android SDK / macOS). CI builds both on the first tag.
- The ASR Docker image was not built here (model download blocked); its API and auth are unit-tested.
