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

## Data model (43 tables)

Content (public read): `surahs`, `ayahs`, `ayah_words`, `translations`, `ayah_translations`, `tafsir_sources`,
`ayah_tafsir`, `reciters`, `hadith_collections`, `hadiths`, `adhkar_categories`, `adhkar`, `content_embeddings`.

User: `profiles`, `goals`, `daily_activity`, `xp_events`, `user_achievements`, `prayer_logs`, `adhkar_progress`,
`reading_progress`, `bookmarks`, `hifz_plans`, `hifz_items`, `hifz_reviews`, `recitation_sessions`,
`ai_conversations`, `ai_messages`, `ai_usage`, `subscriptions`, `referrals`.

Community: `khatma_groups`, `khatma_members`, `khatma_parts`, `khatma_messages`, `khatma_bans`, `user_blocks`,
`content_reports` (moderation queue), `banned_terms` (word filter).

Config: `xp_rules`, `achievements`, `plan_limits`. Audit: `billing_events`.

## RPCs (called by the app)

`get_dashboard`, `log_activity` (ayah_read, listen_minute), `log_prayer`, `complete_dhikr`, `create_hifz_plan`,
`seed_known_surahs`, `get_hifz_queue`, `hifz_record_review`, `get_hifz_stats`, `get_my_quota`, `get_my_ai_budget`,
`get_weekly_summary`, `get_weak_words`, `apply_referral`.
Service-role only: `begin_ai_call`, `finish_ai_call`, `cancel_ai_call`, `match_content`, `search_ayahs_keyword`,
`_log_activity`, `_hifz_apply_review`.

Profiles only accept IANA time zones (`Asia/Riyadh`); anything else (`AST`, `+03`) is replaced by a trigger, because
Postgres reads those abbreviations with the wrong offset and every "today" would roll over hours early.

## Khatma groups (user-generated content)

Private, invite-only groups (8-character code, max 50 members, 20 groups per user). Each round has 30 `khatma_parts`;
members claim a juz', the admin can assign or share them out, and when all 30 are read the group starts the next
khatma. Messages are free text (≤ 500 chars) or preset cheers. The leaderboard (juz' read, ayahs in 7 days, streak)
is visible to members of that group only. Finishing a group juz' gives no XP, because it can't be verified.

Moderation, enforced in Postgres (App Store guideline 1.2): rules accepted once (`profiles.community_terms_at`);
`_community_text_check()` refuses offensive terms (Arabic normalised: diacritics, tatweel, alef/ya/ta marbuta forms,
repeated letters) and links, phone numbers and @handles; 6 messages a minute / 200 a day; report (the reporter stops
seeing the message, 2 reports hide it for everyone); block (hides the user's messages in every group); the admin
deletes messages and removes + bans members; `moderate_report()` (service role) removes content or bans a user from
all groups (`profiles.community_banned_at`). Every write is an RPC; clients only read through RLS.

The chat polls every 10 s while open (no realtime connection). Qibla is computed on the device (great-circle bearing
from `geolocator` + `flutter_compass`); the location never leaves the phone.

## Gamification rules

- Level = floor(sqrt(xp / 50)) + 1.
- XP per unit and daily caps per activity in `xp_rules` (tunable without a release).
- Streak counts any XP-earning day; one missed day is covered by a streak freeze; a freeze is earned every 7 streak days and per referral (max 5).
- Meeting all active daily goals gives +20 XP once per day.

## Hifz scheduling

SM-2 (ease factor ≥ 1.3, intervals 1 → 3 → interval × EF, capped at 180 days; ≥ 30 days = mastered).
Forgetting prediction: recall ≈ 0.9^(days since review / interval). Items under 0.8 are "at risk" and reviewed first.
AI recitation in hifz mode grades each ayah automatically (score → SM-2 grade 0–5).
Surahs the user already knows (onboarding) are seeded as review-only items due over the next 6 days.
When every ayah of a surah reaches "review" the user gets a one-time milestone (+100 XP, `hifz_milestones`).
Paused plans add no new ayahs; their reviews continue.

## AI limits (per week)

Weeks start **Friday 00:00 in the user's time zone.** `ai_usage.usage_date` holds the week start.

| Feature | Free | Premium (fair use) |
|---|---|---|
| Recitation check (up to 60 s free, 180 s Premium; longer audio is cut on the server) | 10 | 150 |
| AI hifz test (recite from memory, auto-graded) | 5 | 150 |
| Ask the Quran + assistant (shared) | 15 | 100 |
| Semantic search | 30 | 300 |

The first Al-Fatiha check in onboarding is free and not counted. Keyword search is free and unlimited, and the app
falls back to it when the semantic limit is hit. A count is refunded when the AI call fails on our side.

## AI cost cap (per user, server-enforced)

Rule: no user may cost more in AI than half of what they pay. Weekly counts above are fair-use limits; this is the money limit.

| Tier | AI budget | Window |
|---|---|---|
| Premium | 50% of the user's net payment (after store commission and tax) | Monthly from the purchase date. Annual plans pool the whole year, but any one month may spend at most 3× the monthly share |
| Free trial (7 days) | $0.25 for the whole trial | Trial period |
| Promotional grant | $0.15 | Calendar month |
| Free | $0.15 | Calendar month (UTC) |

```
edge function ──begin_ai_call(user, feature, worst-case cost [, cheaper-model cost])──▶ Postgres
                 · locks ai_spend row, checks budget and ring-fence, then weekly count, reserves cost
             ◀── allowed / degraded / 429 ai_budget_exhausted (resets_at)
   …AI work (Claude / ASR / embeddings)…
edge function ──finish_ai_call(call, measured cost) or cancel_ai_call(call)──▶ Postgres
```

- Net payment comes from the RevenueCat webhook (`price`, `tax_percentage`, `commission_percentage`), so regional price tiers are reflected automatically. If the store sent no price, the lowest regional tier is assumed.
- Claude cost is computed from the response's token usage (incl. cache reads/writes) and the model that actually answered. ASR and embeddings use per-unit rates from env.
- Reserving the worst case first means concurrent requests can never push spend over the budget. Reservations left open by a crashed function count as spent after 15 minutes.
- Premium drops to the cheaper model when the full one no longer fits, then AI pauses. The app shows a friendly sheet with the reset date; reading, audio, keyword search, adhkar and hifz reviews keep working.
- **Core ring-fence:** 40% of every budget is kept for recitation and hifz. Ask and search can use at most 60%, so a
  chatty user never loses the feature they pay for.
- A refund sets net payment to 0, which stops AI for that user immediately.
- Store webhooks can arrive out of order; `subscriptions.last_event_ms` makes an older event unable to overwrite a newer state.
- Tune budgets with SQL in `ai_budget_settings` (no deploy). Ledger: `ai_calls`; per-window totals: `ai_spend`.

## Scaling notes

- Content queries are cacheable and read-only; move them behind a CDN or ship an offline bundle in Phase 2.
- `content_embeddings` uses an HNSW index; ~60k vectors fit comfortably on the smallest Supabase compute.
- The ASR service is stateless and scales to zero on Cloud Run; switch to GPU instances only if latency requires it.
- Claude system prompt is byte-stable and cached (`cache_control`), so repeated calls mostly pay for the question and sources.
