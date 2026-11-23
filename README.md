# Muslim AI

AI-powered Quran companion: AI recitation coach, hifz (memorization) coach with spaced repetition,
semantic Quran search, Ask the Quran, Islamic assistant, daily adhkar, goals, streaks and XP.
Arabic (RTL) and English at launch. Premium at $0.99/month through Apple IAP and Google Play Billing (RevenueCat).

Product and launch documentation lives in [`docs/`](docs/). This README covers the code.

## Repository layout

| Path | What it is |
|---|---|
| `app/` | Flutter app (Riverpod, go_router, Supabase, RevenueCat, PostHog, Sentry) |
| `supabase/migrations/` | Postgres schema, RLS, business-logic RPCs, reference data |
| `supabase/functions/` | Deno Edge Functions: `ask-quran`, `assistant`, `quran-search`, `recitation-analyze`, `revenuecat-webhook`, `delete-account` |
| `supabase/tests/` | Database behaviour tests (run against plain Postgres + pgvector in CI) |
| `services/asr/` | Quran-tuned Whisper service returning words with timestamps (Docker, Cloud Run) |
| `scripts/ingest/` | Loads Quran text, words, translation, tafsir, hadith and builds embeddings |
| `tools/gen_arb.py` | Single source for app strings; generates `app_en.arb` / `app_ar.arb` |
| `.github/workflows/` | CI, backend deploy, mobile release (Fastlane) |
| `BLOCKERS.md` | Everything that needs the owner: accounts, keys, approvals |

See [ARCHITECTURE.md](ARCHITECTURE.md) for how the pieces fit.

## Run locally

Prerequisites: Flutter 3.35+, Deno 2, Supabase CLI, Docker.

```bash
# 1. Backend
supabase start                                   # local Postgres/Auth/Storage/Functions
supabase db reset                                # applies migrations + reference data
cp supabase/.env.example supabase/.env.local     # fill in keys
supabase functions serve --env-file supabase/.env.local

# 2. Content (Quran, tafsir, hadith, embeddings) into the local DB
cd scripts/ingest
export SUPABASE_URL=http://127.0.0.1:54321 SUPABASE_SERVICE_ROLE_KEY=<from supabase status> VOYAGE_API_KEY=...
deno task all

# 3. ASR service (optional locally; needed for the recitation coach)
docker build -t muslim-ai-asr services/asr && docker run -p 8080:8080 -e ASR_SERVICE_TOKEN=dev muslim-ai-asr

# 4. App
cd app
cp env/example.json env/dev.json                 # fill in values
flutter run --dart-define-from-file=env/dev.json
```

## Tests

```bash
cd app && flutter analyze && flutter test                       # 6 tests
cd supabase/functions && deno lint && deno test tests/          # 11 tests (alignment, citations, billing)
# DB: see .github/workflows/ci.yml job "database"               # RLS, XP caps, streaks, SM-2, quotas, referrals
cd services/asr && python -m pytest -q tests                    # 3 tests
```

## Key decisions

- **Guest first.** Users start as anonymous Supabase users (value in under a minute) and link Apple, Google or email later without losing progress.
- **Server-owned gamification.** XP, streaks, levels, achievements and subscription state are written only by SECURITY DEFINER functions or the service role. Daily XP caps per activity are in `xp_rules`.
- **Grounded AI.** Claude may cite only retrieved verse keys / hadith ids; anything else is dropped server-side, and Quran/Hadith text shown to users always comes verbatim from the database.
- **Honest recitation analysis.** Whisper runs without the expected text as a prompt (so mistakes are not hidden), then Needleman-Wunsch alignment classifies each word. Tajweed in MVP is a "possible short madd" heuristic only; full tajweed rules are Phase 2.
- **Model routing.** Free users on Claude Haiku 5.5, premium on Claude Opus 5.5 (`CLAUDE_MODEL` / `CLAUDE_MODEL_PREMIUM`).
- **Payments behind an interface.** `PaymentProvider` (app) and `mapRevenueCatEvent` (server) isolate RevenueCat, so Stripe/Moyasar/HyperPay can be added later without touching features.
