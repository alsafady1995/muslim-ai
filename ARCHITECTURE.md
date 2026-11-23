# Architecture

```
Flutter app ──(supabase-js: Auth, PostgREST + RLS, RPC, Storage)──▶ Supabase Postgres (pgvector)
     │                                                                ▲
     ├──(Edge Functions, user JWT)──▶ ask-quran / assistant ──▶ Voyage embeddings ─┘ match_content()
     │                                     └──▶ Claude (structured output, citations filtered)
     ├──▶ quran-search (semantic via Voyage + pgvector, keyword via pg_trgm)
     ├──upload audio to Storage──▶ recitation-analyze ──▶ ASR service (Whisper, word timestamps)
     │                                     └──▶ alignment + scoring ──▶ hifz SM-2 update, XP
     ├──▶ RevenueCat SDK (Apple IAP / Google Play) ──webhook──▶ revenuecat-webhook ──▶ subscriptions
     ├──▶ PostHog (product analytics)        └──▶ Sentry (crashes)
     └──▶ local notifications (adhkar, hifz, streak reminders)
```

## Data model (35 tables)

Content (public read): `surahs`, `ayahs`, `ayah_words`, `translations`, `ayah_translations`, `tafsir_sources`,
`ayah_tafsir`, `reciters`, `hadith_collections`, `hadiths`, `adhkar_categories`, `adhkar`, `content_embeddings`.

User: `profiles`, `goals`, `daily_activity`, `xp_events`, `user_achievements`, `prayer_logs`, `adhkar_progress`,
`reading_progress`, `bookmarks`, `hifz_plans`, `hifz_items`, `hifz_reviews`, `recitation_sessions`,
`ai_conversations`, `ai_messages`, `ai_usage`, `subscriptions`, `referrals`.

Config: `xp_rules`, `achievements`, `plan_limits`. Audit: `billing_events`.

## RPCs (called by the app)

`get_dashboard`, `log_activity` (ayah_read, listen_minute), `log_prayer`, `complete_dhikr`, `create_hifz_plan`,
`get_hifz_queue`, `hifz_record_review`, `get_hifz_stats`, `get_my_quota`, `apply_referral`, `search_ayahs_keyword`.
Service-role only: `consume_ai_quota`, `refund_ai_quota`, `match_content`, `_log_activity`, `_hifz_apply_review`.

## Gamification rules

- Level = floor(sqrt(xp / 50)) + 1.
- XP per unit and daily caps per activity in `xp_rules` (tunable without a release).
- Streak counts any XP-earning day; one missed day is covered by a streak freeze; a freeze is earned every 7 streak days and per referral (max 5).
- Meeting all active daily goals gives +20 XP once per day.

## Hifz scheduling

SM-2 (ease factor ≥ 1.3, intervals 1 → 3 → interval × EF, capped at 180 days; ≥ 30 days = mastered).
Forgetting prediction: recall ≈ 0.9^(days since review / interval). Items under 0.8 are "at risk" and reviewed first.
AI recitation in hifz mode grades each ayah automatically (score → SM-2 grade 0–5).

## AI limits (per day)

| Feature | Free | Premium (fair use) |
|---|---|---|
| Recitation analysis | 3 | 100 |
| Ask the Quran + assistant (shared) | 5 | 20 |
| Semantic search | 10 | 200 |

Keyword search is free and unlimited. Quota is refunded when the AI call fails on our side.

## Scaling notes

- Content queries are cacheable and read-only; move them behind a CDN or ship an offline bundle in Phase 2.
- `content_embeddings` uses an HNSW index; ~60k vectors fit comfortably on the smallest Supabase compute.
- The ASR service is stateless and scales to zero on Cloud Run; switch to GPU instances only if latency requires it.
- Claude system prompt is byte-stable and cached (`cache_control`), so repeated calls mostly pay for the question and sources.
