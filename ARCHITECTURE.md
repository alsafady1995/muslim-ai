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
     ├──▶ local notifications (adhkar, hifz, streak reminders)
     └──(group-push edge function)──▶ FCM ──▶ family-group calls on members' phones
```

## Data model (42 tables)

Content (public read): `surahs`, `ayahs`, `ayah_words`, `translations`, `ayah_translations`, `tafsir_sources`,
`ayah_tafsir`, `reciters`, `hadith_collections`, `hadiths`, `adhkar_categories`, `adhkar`, `content_embeddings`.

User: `profiles`, `goals`, `daily_activity`, `xp_events`, `user_achievements`, `prayer_logs`, `adhkar_progress`,
`reading_progress`, `bookmarks`, `hifz_plans`, `hifz_items`, `hifz_reviews`, `recitation_sessions`,
`ai_conversations`, `ai_messages`, `ai_usage`, `subscriptions`, `referrals`.

Groups: `khatma_groups`, `khatma_members`, `khatma_bans`, `khatma_parts`, `group_calls`, `group_call_responses`,
`push_tokens`, `banned_terms` (name filter).

Config: `xp_rules`, `achievements`, `plan_limits`. Audit: `billing_events`.

## RPCs (called by the app)

`get_dashboard`, `log_activity` (ayah_read, listen_minute), `log_prayer`, `complete_dhikr`, `create_hifz_plan`,
`seed_known_surahs`, `get_hifz_queue`, `hifz_record_review`, `get_hifz_stats`, `get_my_quota`, `get_my_ai_budget`,
`get_weekly_summary`, `get_weak_words`, `apply_referral`.
Service-role only: `begin_ai_call`, `finish_ai_call`, `cancel_ai_call`, `match_content`, `search_ayahs_keyword`,
`_log_activity`, `_hifz_apply_review`.

Profiles only accept IANA time zones (`Asia/Riyadh`); anything else (`AST`, `+03`) is replaced by a trigger, because
Postgres reads those abbreviations with the wrong offset and every "today" would roll over hours early.

## Family groups

Private, invite-only groups (8-character code, up to 20 members, 10 groups per user). No chat: members talk through
**preset calls** (`send_group_call`): a khatma with a reason from a fixed list (for the soul of, for the recovery of,
exams, travel, a newborn, hardship, provision, or a general intention) plus an optional ≤ 30-character name,
salawat, istighfar, morning / evening adhkar and dua. The same kind can be sent once per 30 minutes per group, and
10 calls a day per sender. Salawat and istighfar add up a group counter; the others are a single "done". Calls last
24 hours; a khatma call lasts 30 days and gives the current khatma its intention (only before anyone has read a juz').

Khatma: 30 `khatma_parts` per round; members claim a juz', the admin can assign or share them out, and when all 30
are read the next round starts and the server posts a `khatma_done` call. Reading a group juz' gives no XP (it
can't be verified).

Weekly board (`get_group_board`): each member's XP, ayahs, adhkar and hifz (new + reviews) since Friday 00:00 in their
own time zone, plus streak, juz' this khatma and calls answered; ranked by XP, with last week's top member.

Push: the app registers its FCM token (`register_push_token`) after the user creates or joins a group, sends a call,
then calls the `group-push` edge function with the call id. `_group_call_push_targets()` (service role) checks that
the caller sent it, marks it pushed (once) and returns the other unmuted members' tokens; the function renders the
text in each member's language (`_shared/group_push.ts`) and sends through FCM HTTP v1. Without `FCM_SERVICE_ACCOUNT`
it does nothing and calls only show in the app (Home card + group screen).

The only typed text is the group name, a member's name and the dedication name, all through
`_community_text_check()` (offensive terms with Arabic normalisation, links, phone numbers, handles). The admin can
rename the group and remove (and ban) a member.

## Qibla

Computed on the device (great-circle bearing from `geolocator` + `flutter_compass`); the location never leaves the phone.

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
| Free (signed-in account) | $0.05 | Calendar month (UTC) |
| Guest (anonymous account) | $0.01, onboarding Al-Fatiha check only; any other AI call asks them to create a free account | Calendar month (UTC) |

**Free-tier daily pool:** all free and guest AI together may spend at most `free_daily_pool_usd` ($20) per UTC day
(`ai_free_pool`). When it is full, free AI pauses until midnight UTC with a "busy today" sheet (no Premium offer);
paying users never touch the pool. Raise the setting as the user base grows: about $0.0005 per free monthly active user per day (≈ 1.5× the expected average use), so $20 covers ≈ 40k free MAU.
Why: an average active user earns ≈ $0.04 a month, so the free budget must stay near that and total free spend must
have a ceiling (`docs/strategy/financial-viability.md` §4.4).

```
edge function ──begin_ai_call(user, feature, worst-case cost [, cheaper-model cost])──▶ Postgres
                 · locks ai_spend row, checks budget and ring-fence, then weekly count, reserves cost
             ◀── allowed / degraded / 429 ai_budget_exhausted (tier, resets_at; tier guest = sign in, busy = pool full)
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
- The ASR service is stateless and scales to zero on Modal (`services/asr/modal_app.py`, per-second billing); the same Dockerfile runs on Cloud Run or any container host. Switch to GPU only if latency requires it.
- Claude system prompt is byte-stable and cached (`cache_control`), so repeated calls mostly pay for the question and sources.
