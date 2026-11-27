# Asmi3ni

AI-powered Quran companion: AI recitation coach, hifz (memorization) coach with spaced repetition,
semantic Quran search, Ask the Quran, Islamic assistant, daily adhkar, goals, streaks and XP.
Arabic (RTL) and English at launch. Premium at $4.99/month or $29.99/year (7-day free trial on annual, lower regional prices in markets such as Egypt,
Pakistan and Indonesia) through Apple IAP and Google Play Billing (RevenueCat).

Product and launch documentation lives in [`docs/`](docs/). This README covers the code.

## Repository layout

| Path | What it is |
|---|---|
| `app/` | Flutter app (Riverpod, go_router, Supabase, RevenueCat, PostHog, Sentry) |
| `supabase/migrations/` | Postgres schema, RLS, business-logic RPCs, reference data |
| `supabase/functions/` | Deno Edge Functions: `ask-quran`, `assistant`, `quran-search`, `recitation-analyze`, `revenuecat-webhook`, `delete-account` |
| `supabase/tests/` | Database behaviour tests (run against plain Postgres + pgvector in CI) |
| `services/asr/` | Quran-tuned Whisper service returning words with timestamps (Docker, deployed on Modal) |
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

## Web preview (no accounts needed)

A demo build of the app runs in any browser, including iPhone Safari, with no backend or API keys:
**https://alsafady1995.github.io/muslim-ai/** (built by `.github/workflows/web-preview.yml` on every push).

`--dart-define=DEMO_MODE=true` swaps the Supabase repositories, edge functions and RevenueCat for local fakes in
`app/lib/demo/`. Real: Quran text and translation, reciter audio, adhkar, every screen, XP/levels/streaks/goals and
SM-2 hifz scheduling (computed in the browser). Simulated: guest account and sign-in, AI answers (real verses,
placeholder explanation), semantic search (keyword match), recitation analysis (random result), subscription
(no payment). A banner on every screen says so. Progress is stored in the browser's local storage.

```bash
python3 tools/fetch_demo_quran.py app/web/demo-data/quran.json   # Quran text for the demo (not committed)
cd app && flutter run -d chrome --dart-define=DEMO_MODE=true
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
- **Model routing.** Free users on Claude Haiku 5.5, premium on Claude Sonnet 5.5 (`CLAUDE_MODEL` / `CLAUDE_MODEL_PREMIUM`).
- **AI cost cap.** No user may cost more in AI than half of what they pay. Every paid AI call reserves its worst-case cost against a per-user budget in the database before it runs (`begin_ai_call`), then settles with the measured cost. Subscribers get 50% of their actual net payment per month (from the RevenueCat webhook, so regional prices are handled); free users, trials and promotional grants get small fixed budgets. Premium drops to the cheaper model near the limit, then AI pauses with a friendly message until the period resets. See `supabase/migrations/20261124000001_ai_cost_cap.sql`.
- **Payments behind an interface.** `PaymentProvider` (app) and `mapRevenueCatEvent` (server) isolate RevenueCat, so Stripe/Moyasar/HyperPay can be added later without touching features.
