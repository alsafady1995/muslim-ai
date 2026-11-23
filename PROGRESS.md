# Build progress (paused 2026-11-23)

Done and tested:
- supabase/migrations: schema, RLS, RPCs (XP/streaks/goals/achievements, SM-2 hifz, quotas, dashboard, referrals), reference data. `supabase/tests/10_behaviour.sql` passes on Postgres 16 + pgvector.
- supabase/functions: ask-quran, assistant, quran-search, recitation-analyze, revenuecat-webhook, delete-account. `deno check` clean, 11 unit tests pass.
- services/asr: Whisper (Quran-tuned) word-timestamp service + Dockerfile, 3 tests pass.
- scripts/ingest: Quran/translation/tafsir, hadith, Voyage embeddings (not run: source hosts blocked from the build sandbox).

In progress (Flutter, app/):
- Written: core (config, analytics, providers, theme, router, notifications, api), data layer, payments abstraction + RevenueCat, onboarding, sign-in/linking, home dashboard, Quran reader + audio, AI coach + results, hifz screens.
- Remaining: search, ask/assistant, adhkar, goals, profile/settings, paywall screens; ARB files (ar/en); `flutter analyze` + tests.

Then: CI/CD (GitHub Actions + Fastlane), env templates, README/ARCHITECTURE, BLOCKERS.md.
