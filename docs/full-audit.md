# Muslim AI: Full Product Audit

Product, UX, subscription, retention, technical, QA, growth, and an executive top 10, followed by implementation
tickets. This document builds on `docs/subscription-growth-audit.md` (PR #3) and does not repeat it: where that
document already decided something (weekly limits, all reciters free, value before the paywall, the 50% cost rule),
this audit checks that the code does it and fixes what it did not.

Audited: `main` plus PRs #1 (web preview), #2 (pricing and the AI cost cap), #3 (growth audit) and #4 (deploy fixes),
as of 24 November 2026. Everything marked **Shipped** is in this PR, with tests.

---

## ملخص بالعربية

**الحكم العام:** الأساس التقني قوي (قاعدة بيانات محكمة، حدّ تكلفة الذكاء الاصطناعي على الخادم، مدرّب حفظ بنظام SM-2)،
لكن التجربة كانت تبيع قبل أن تُفيد، وكان فيها خطأ خطير في المنطقة الزمنية يجعل "اليوم" عند المستخدم السعودي يبدأ
الساعة ٧ صباحًا تقريبًا، فتنكسر السلاسل والأهداف والحدود.

**أهم ما وجدته وأصلحته في هذا الطلب:**

1. **خطأ المنطقة الزمنية (حرج):** التطبيق كان يرسل "AST" أو "+03"، وPostgres يفهمها بإزاحة خاطئة. الآن يُرسل
   الاسم الصحيح (Asia/Riyadh) ويرفض الخادم أي قيمة غير صحيحة ويصلح الحسابات القديمة.
2. **الحدود الأسبوعية مطبّقة فعلًا:** ١٠ تصحيحات تلاوة و٥ اختبارات حفظ و١٥ سؤالًا و٣٠ بحثًا أسبوعيًا للمجاني،
   تتجدد كل جمعة. ٤٠٪ من ميزانية كل مستخدم محجوزة للتلاوة والحفظ. لا أحد يكلّف أكثر من نصف ما يدفع.
3. **القيمة أولًا:** تسجيل جديد بلا أي عرض اشتراك: نية المستخدم ← السور المحفوظة ← تلاوة الفاتحة مجانًا ← خطة
   جاهزة ← تذكير واحد. لا يظهر أي عرض تلقائي قبل ٣ أيام من فائدة حقيقية، وبحد أقصى مرة يوميًا و٣ أسبوعيًا.
4. **صفحة اشتراك صادقة:** حُذفت وعود بميزات غير موجودة، وأُضيف جدول التجربة وتذكير قبل الخصم بيومين وزر
   "المتابعة مجانًا" بحجم كامل.
5. **الرئيسية تجيب عن سؤال واحد:** "ماذا أفعل اليوم؟" ثم ملخص الأسبوع، وبطاقة لمشكلة الدفع ولنهاية التجربة.
6. **إصلاحات جودة:** حذف التسجيل الصوتي دائمًا، منع التحليل المزدوج، اختبار الحفظ لا يتخطى الآية دون تقييم،
   البحث ينتقل للبحث النصي عند انتهاء الحد، إغلاق ثغرات الإحالة، ترتيب أحداث المتجر، إعدادات التذكير صادقة،
   وحذف الحساب لا يُخرج المستخدم إن فشل.

**ما يحتاجك أنت (حسابات المتاجر):** دمج الطلبات #1–#4 ثم هذا الطلب؛ التجربة المجانية على الخطة السنوية فقط؛
قرار السعر في الخليج (نوصي ٢٩٫٩٩$ سنويًا و٤٫٩٩$ شهريًا)؛ تفعيل فترة السماح للدفع وعروض الاسترجاع في المتجرين.
التفاصيل في `BLOCKERS.md` القسم ٥.

---

## Contents

1. Product audit
2. UX audit
3. Subscription audit
4. Retention audit
5. Technical audit
6. QA and testing audit
7. Growth audit
8. Executive summary: top 10 by ROI
9. Implementation tickets

Severity scale used throughout: **Critical** (breaks the core promise or loses money), **High** (measurably hurts
conversion or retention), **Medium** (friction or risk), **Low** (polish).

---

## 1. Product audit

### 1.1 What the product is

Muslim AI is a Quran companion with four layers:

| Layer | Features | Verdict |
|---|---|---|
| Daily practice | Reader with audio and 10+ reciters, adhkar, prayer log, goals, streaks, XP, achievements | Solid, but the same as twenty other apps. This layer retains; it does not differentiate. |
| **Hifz Coach** | SM-2 memorization plans, forgetting prediction, at-risk ayahs, AI tests by reciting from memory | **The product.** No mainstream competitor combines spaced repetition with automatic grading of recitation. |
| AI recitation coach | Word-by-word feedback on recitation (Whisper fine-tuned on Quran audio) | Strong demo moment; the hook for the hifz coach. |
| Ask the Quran | Grounded answers citing ayahs, hadith with grades, scholarly differences, crisis handling | Good and responsible, but expensive and easy to copy. It should support the coach, not lead the pitch. |

**Positioning recommendation:** "The Hifz Coach that hears you." Everything else is the free daily layer that keeps
people opening the app. PR #3 reached the same conclusion; the code did not reflect it (the paywall sold six
features, three of which were not built, and Home led with XP).

### 1.2 Competitor comparison

| App | What they do best | What we copy | Where we beat them |
|---|---|---|---|
| **Tarteel** | Live mistake detection while reciting; strong memorization mode | Their "memorization mistakes history" idea, as our weak-words drill (shipped) | Spaced repetition: Tarteel tells you what you got wrong today; we schedule what you will forget next week |
| **Muslim Pro** | Prayer times, Qibla, massive reach | Nothing on monetization (ad-heavy experience is the top complaint in reviews) | Ad-free promise on the paywall (shipped) |
| **Quran Companion** | Gamified hifz with leagues and social challenges | Weekly summary and milestones (shipped); leagues later | Automatic grading; their reviews are self-graded |
| **Duolingo** | Daily habit, streak freeze, one obvious next step | "Today" card with one action (shipped); streak freezes (existed) | Our sessions are spiritually meaningful, so we need fewer tricks and no guilt notifications |
| **Headspace / Calm** | Trial timeline that says when you will be charged; calm, non-pushy paywall | Trial timeline + reminder 2 days before the charge (shipped) | |
| **Noom** | Onboarding that asks about the goal, then shows a personal plan before the paywall | Intent → known surahs → plan reveal (shipped), but without a paywall at the end (our standing rule) | |
| **Spotify** | Free tier good enough to love, limits that renew on a known day | Weekly limits that renew on Friday, all reciters free (shipped) | |

### 1.3 Product findings

| # | Finding | Severity | Status |
|---|---|---|---|
| P1 | Paywall promised features that do not exist (advanced analytics, priority support, "exclusive reciters" after reciters were made free). App Store guideline 3.1.2 risk and a refund driver. | Critical | **Shipped:** four honest benefits only |
| P2 | No moment of value before sign-up: onboarding was language → goal → reminders → done, ending on an empty Home. | High | **Shipped:** free Al-Fatiha check and a ready plan inside onboarding |
| P3 | Users who already know surahs had to create plans for them as if new, so their first week was reviewing An-Nas. | High | **Shipped:** "surahs I already know" seeds review-only items, spread over 6 days |
| P4 | Weak words were stored per recitation but never shown back. That is the most personal data we have. | High | **Shipped:** weak-words screen (top 3 free, all with Premium) |
| P5 | No sense of progress beyond XP: memorizing a whole surah passed without notice. | Medium | **Shipped:** surah milestone (+100 XP, celebration, one-time gentle offer) |
| P6 | No way to pause a plan during exams or Ramadan, so users deleted the app instead. | Medium | **Shipped:** pause / resume plan (reviews continue) |
| P7 | "Ask" is the costliest feature and the least differentiated. | Medium | Kept, with 15/week free and a 60% budget ceiling (shipped) |
| P8 | Leagues / friends / family plan | Low (now) | Later: after D30 retention is measured |

---

## 2. UX audit

### 2.1 First session (before → after)

| Step | Before | After (shipped) |
|---|---|---|
| 1 | Welcome + language | Same, with one promise: "Memorize the Quran with a coach that hears you" |
| 2 | Pick a goal | **Intent:** memorize / recite better / read daily / understand |
| 3 | Reminders permission (before any value) | **Surahs I already know** (Juz Amma chips; memorizers and reciters only) |
| 4 | Empty Home | **Recite Al-Fatiha** with word-by-word feedback, free and not counted; skippable |
| 5 | | **Your plan:** next surah to memorize with daily ayahs, known surahs scheduled for review tomorrow |
| 6 | | **One reminder,** asked after the value, at a time the user picks (mobile only) |
| 7 | | Home with a "Today" card that already has something to do |

The guest account is now created right after the intent step (so the Al-Fatiha check can run), and the router keeps
the user in onboarding until it finishes, even if the app is closed mid-way.

### 2.2 Findings

| # | Finding | Severity | Status |
|---|---|---|---|
| U1 | Home had six equal tiles and no answer to "what should I do now?" | High | **Shipped:** Today card picks one action (review → new ayahs → start plan → recite → read → done) and opens the review session in one tap |
| U2 | The weekly limit was discovered **after** reciting for a minute and uploading. | High | **Shipped:** checked before recording; the screen shows checks left and seconds left |
| U3 | Limit messages were a generic error. | High | **Shipped:** limit sheet says what renews and when ("Friday"), with two equal-weight buttons: wait, or try Premium |
| U4 | "Test with AI" in a hifz session skipped the card even when the recitation failed or was cancelled. | High | **Shipped:** advances only if this card was graded; otherwise a short note |
| U5 | Coach ranges above 50 ayahs failed after recording. | Medium | **Shipped:** picker capped at 50 |
| U6 | Ask lost the typed question when a limit was hit. | Medium | **Shipped:** question restored |
| U7 | Reminder switches in Settings showed "on" by default even when nothing was scheduled; times were fixed. | Medium | **Shipped:** real state, editable times, "notifications blocked" message |
| U8 | Reciter list showed locks after the decision to make all reciters free. | Medium | **Shipped:** locks removed (server and app) |
| U9 | Delete account signed the user out even if the delete failed (guest loses everything, account still exists). | Medium | **Shipped:** error shown, user stays signed in |
| U10 | Semantic search hit a dead end at its limit. | Medium | **Shipped:** falls back to keyword search with a one-line note |
| U11 | Free recitations longer than 60 s were analysed in full (cost) with no explanation. | Medium | **Shipped:** cut on the server at 60 s + 5 s grace, with a one-line note on the result |
| U12 | RTL: several rows mixed Arabic and Latin numerals and alignment. | Low | Partly: new screens use `textDirection` for Quran text; full RTL pass later |
| U13 | Accessibility: icon-only buttons without labels in the reader. | Low | Later |

---

## 3. Subscription audit

### 3.1 Paywall

| # | Finding | Severity | Status |
|---|---|---|---|
| S1 | Unbuilt features on the paywall (see P1). | Critical | **Shipped** |
| S2 | Headline was price-led ("Unlock everything"). | High | **Shipped:** outcome-led, personalized by intent ("Never forget what you memorized" / "Recite with confidence") |
| S3 | Trial terms in small grey text. | High | **Shipped:** timeline: Today (full access, no charge) → Day 5 (we remind you) → Day 7 (plan starts at price) |
| S4 | We promised no reminder before the charge, and had none. | High | **Shipped:** local notification scheduled 2 days before the trial ends |
| S5 | "Not now" was a small link. | Medium | **Shipped:** full-width "Continue free" |
| S6 | No frequency control: the banner was on Home from minute one, every day. | High | **Shipped:** PaywallGate (below) |
| S7 | Monthly plan carries a 7-day trial. | Medium | **Decided:** trial on annual only; store steps ready in `docs/store-setup.md` |
| S8 | GCC price ($19.99/yr) is below the market. | Medium | **Decided:** $29.99/yr and $4.99/mo; docs, demo and store steps updated |
| S9 | No billing-issue handling in the app. | High | **Shipped:** "update your payment" card when the store reports a billing issue or grace period. **Owner:** enable grace periods (BLOCKERS #23) |
| S10 | No win-back. | Medium | **Owner:** store win-back offers (BLOCKERS #24) |

### 3.2 When the app may offer Premium on its own (PaywallGate)

All rules are in `app/lib/core/monetization.dart` and unit-tested.

- Never in onboarding and never right after the first Al-Fatiha recitation.
- Only after **3 different days of real value** (a recitation check, an AI hifz test or a completed review;
  `get_dashboard.value_days`).
- At most **once a day, 3 times a week, once per app session.**
- After two "not now"s in a row, **nothing automatic for 7 days.**
- Once-only moments: the first surah milestone, the first weekly summary with at-risk ayahs.
- Not gated (the user asked or already hit the wall): limit sheets, Settings, Profile, the weak-words lock.
- Never after a crisis answer in Ask.

### 3.3 Plans and limits (as built)

| | Free | Premium |
|---|---|---|
| Reader, audio, all reciters, adhkar, goals, streaks, keyword search, hifz plans, self-graded reviews | Unlimited | Unlimited |
| Recitation checks | 10 / week, 60 s each | 150 / week, 3 min each |
| AI hifz tests | 5 / week | 150 / week |
| Ask + assistant | 15 / week (Haiku) | 100 / week (Sonnet, then Haiku) |
| Semantic search | 30 / week | 300 / week |
| Weak words | Top 3 | All |
| Money cap | $0.15 / month | 50% of net payment; 40% ring-fenced for recitation and hifz; annual pooled with 3× monthly pacing |

Deliberate deviation from PR #3: limits renew on the **next** Friday after sign-up, not the second one. It is
simpler to explain ("every Friday") and the monthly money cap still bounds the cost.

---

## 4. Retention audit

| # | Finding | Severity | Status |
|---|---|---|---|
| R1 | **Time zone bug:** "today" rolled over at about 7 am for Saudi users, so evening reviews counted for the wrong day and streaks broke. Details in §5. | Critical | **Shipped** |
| R2 | The hifz reminder was never scheduled in onboarding, so the core loop had no trigger. | High | **Shipped:** one contextual reminder (hifz or reading) at the user's time, plus optional adhkar |
| R3 | No weekly reflection. | High | **Shipped:** "Your week" card from day 6: active days, reviews, ayahs read, at-risk or "all safe" |
| R4 | No celebration of real progress. | Medium | **Shipped:** surah milestones |
| R5 | The first review session after install was empty for users who know surahs. | High | **Shipped:** known surahs seeded, first reviews due tomorrow |
| R6 | Streak repair / freeze purchase | Low | Later (freezes are earned; do not sell them) |
| R7 | Ramadan mode (khatm plan, taraweeh juz tracker) | Medium | Later: highest-leverage seasonal feature; ship before Ramadan 2027 (around 8 Feb) |

### Retention funnel to track (events exist)

`onboarding_started` → `onboarding_intent` → `recitation_result_viewed{source:onboarding}` → `hifz_plan_created` →
`onboarding_completed` → D1 `hifz_review_completed` → `value_gate_passed` (day 3+) → D7 `weekly_summary_viewed` → D30.

Targets for the first cohort: onboarding completion 70%, first recitation 50%, D1 35%, D7 18%, D30 9%.

---

## 5. Technical audit

### 5.1 Architecture

Flutter 3.35 (Riverpod 3, go_router), Supabase Postgres with RLS and security-definer RPCs, Deno edge functions,
a stateless ASR service on Cloud Run, RevenueCat. The design is sound: all money and limit decisions are on the
server, inside one transaction, with worst-case reservation. The issues were in the edges.

### 5.2 Findings

| # | Finding | Severity | Status |
|---|---|---|---|
| T1 | **Time zones.** The app sent `DateTime.timeZoneName` ("AST", "+03", "GMT+03:00"). Postgres reads "AST" as Atlantic Standard Time (UTC−4) and "+03" as UTC−3 (POSIX sign), so Riyadh users were 6–7 hours off. | Critical | **Shipped:** app sends the IANA name (`flutter_timezone`); trigger rejects anything else; existing rows repaired; Home re-syncs on launch |
| T2 | Recitation audio was not deleted when the quota or budget check failed, or when analysis threw. Privacy promise broken. | Critical | **Shipped:** deleted in `finally` |
| T3 | The same recitation session could be analysed twice (double tap, retry): double cost, double XP. | High | **Shipped:** atomic claim `pending → processing`, 409 otherwise |
| T4 | Referral farming: any account of any age could redeem, two accounts could refer each other, referrer XP unbounded. | High | **Shipped:** accounts under 14 days only, no mutual referrals, rewards for the first 25 |
| T5 | Out-of-order RevenueCat webhooks could overwrite a renewal with an older expiration. | High | **Shipped:** `last_event_ms` guard |
| T6 | Keyword search treated `%` and `_` as wildcards and did not normalize Arabic like the ingest did. | Medium | **Shipped** |
| T7 | `get_hifz_queue` applied `limit 100` before ordering, so a large backlog returned arbitrary ayahs instead of the most at-risk. | Medium | **Shipped** |
| T8 | Free clip length was only enforced in the app. | Medium | **Shipped:** server cuts words heard after 60 s (+5 s grace) |
| T9 | Ask and search could use the whole budget, leaving nothing for recitation. | Medium | **Shipped:** 40% core ring-fence |
| T10 | Annual subscribers had 12 small monthly windows: a heavy week in month 1 hit the cap. | Medium | **Shipped:** pooled annual budget with 3× monthly pacing |
| T11 | `PremiumController` never flips back to false while the app is open after an expiry. | Low | Later: refresh on resume |
| T12 | Prompt injection through user questions into the grounded answer prompt. | Low | Reviewed: sources are retrieved server-side, the model can only cite IDs we pass, output is schema-validated. No change needed |
| T13 | `search_ayahs_keyword` depends on `pg_trgm`, whose functions clients cannot execute. | Low | Fine: it is called by the edge function with the service role; documented as service-role in `ARCHITECTURE.md` |
| T14 | Ask "report answer" only sends analytics; nobody reviews it. | Medium | Later: write to a `answer_reports` table and review weekly |

---

## 6. QA and testing audit

### 6.1 Bugs found, by severity

| # | Bug | Severity | Status |
|---|---|---|---|
| Q1 | Time zone misread, day rolls over at ~7 am in KSA | Critical | Fixed + DB test |
| Q2 | Audio not deleted on quota/budget/analysis failure | Critical | Fixed |
| Q3 | Paywall lists unbuilt features | Critical | Fixed |
| Q4 | Double analysis of one session | High | Fixed |
| Q5 | Hifz "Test with AI" skips ungraded cards | High | Fixed |
| Q6 | Quota discovered after recording | High | Fixed |
| Q7 | Referral farming | High | Fixed + DB test |
| Q8 | Stale webhook overwrites newer state | High | Fixed + Deno test |
| Q9 | Coach range > 50 ayahs fails after recording | Medium | Fixed |
| Q10 | Delete account signs out on failure | Medium | Fixed |
| Q11 | Reminder switches show "on" when nothing is scheduled | Medium | Fixed |
| Q12 | Hifz queue limit before order | Medium | Fixed + DB test |
| Q13 | Keyword search wildcard injection | Medium | Fixed + DB test |
| Q14 | Ask loses typed question at the limit | Low | Fixed |
| Q15 | Coach recording can be stopped twice (timer + tap) | Low | Fixed |

### 6.2 Test coverage

| Suite | Before | After |
|---|---|---|
| Flutter (`app/test`) | 6 tests, models and the answer view | **33**: PaywallGate rules, next best action, surah order, Friday weeks, quota/dashboard/milestone/weak-words parsing, limit sheet widget |
| Edge functions (Deno) | 18 | **23**: clip policy, onboarding check rules, stale events, Arabic keyword normalization |
| Database behaviour (`supabase/tests/10_behaviour.sql`, real Postgres) | RLS, XP, streaks, SM-2, daily quotas, budget | + weekly limits, ring-fence, annual pooling, time zones, seeding known surahs, milestones, weekly summary, weak words (free cut at 3), referral rules, keyword escaping, free reciters |

All three suites pass locally and run in CI on every push.

### 6.3 Still not covered

- Native builds (no Android SDK / macOS here); CI builds both on the first tag.
- End-to-end purchase flow: needs sandbox store accounts (owner).
- Real ASR accuracy on children's and non-native voices: record 50 samples before launch.

---

## 7. Growth audit

| # | Lever | Impact | Status |
|---|---|---|---|
| G1 | **Ramadan 2027** (around 8 Feb): khatm plan, "memorize Juz Amma before Eid" challenge, App Store in-app event | Very high: Quran app installs multiply in Ramadan | Later, start in January |
| G2 | Shareable recitation score card ("I recited Al-Mulk with 94% accuracy") | High: organic, on-brand | Later |
| G3 | Referral: reward both sides with a free Premium week instead of XP | Medium | Later (needs promo entitlement in RevenueCat) |
| G4 | Family plan (parents tracking children's hifz) | High in GCC | Later: biggest new revenue line |
| G5 | Masjid / halaqa teacher dashboard | Medium, B2B | Later |
| G6 | ASO: Arabic keywords "تحفيظ القرآن", "مراجعة الحفظ", "تصحيح التلاوة" | High, free | Owner, with store listings |
| G7 | App Store in-app events (Ramadan, Dhul Hijjah) | Medium, free | Owner |

**Funnel dashboard (PostHog):** install → onboarding_completed → first recitation → value_gate_passed →
paywall_viewed → purchase_started → purchase_completed (trial) → trial converted. Targets: 2.5–4% of installs start
a trial by day 14; 55% of annual trials convert.

---

## 8. Executive summary: top 10 by ROI

| Rank | Action | Effort | Impact | Status |
|---|---|---|---|---|
| 1 | Fix the time zone bug (streaks, goals and limits for every KSA user) | S | Critical | **Shipped** |
| 2 | Remove unbuilt features from the paywall; honest trial timeline + reminder | S | Critical (store review, refunds, trust) | **Shipped** |
| 3 | Value-first onboarding: free Al-Fatiha check + ready plan | M | High (activation) | **Shipped** |
| 4 | Weekly limits that renew on Friday, checked before recording | M | High (fairness, cost) | **Shipped** |
| 5 | PaywallGate: no offer before 3 value days, frequency caps, snooze | S | High (retention without losing conversion) | **Shipped** |
| 6 | Today card on Home + hifz reminder in onboarding | S | High (D1–D7) | **Shipped** |
| 7 | Trial on annual only; billing grace periods; win-back offers | S (store settings) | High (revenue) | **Owner** |
| 8 | Weak-words drill + surah milestones + weekly summary | M | Medium-high (retention and the Premium reason) | **Shipped** |
| 9 | Server hardening: audio deletion, double analysis, referral abuse, webhook order | S | High (privacy and money) | **Shipped** |
| 10 | Ramadan 2027 plan | L | Very high, seasonal | **Later** (start January) |

---

## 9. Implementation tickets

Effort: S ≤ 1 day, M 2–4 days, L 1–2 weeks.

### Shipped in this PR

| ID | Title | Priority | Effort | Business impact | Technical impact | Steps (done) |
|---|---|---|---|---|---|---|
| MA-01 | IANA time zones | P0 | S | Streaks and limits correct for every user | Trigger + repair migration; app uses `flutter_timezone` | `_valid_timezone`, `_profiles_sanitize` trigger, repair update; onboarding and Home send `getLocalTimezone()`; DB tests |
| MA-02 | Honest paywall | P0 | S | Store approval, fewer refunds | Copy + timeline widget + local notification | Remove 6 benefits, add 4 real ones; intent headline; `_TrialTimeline`; `Reminders.scheduleOnce` 2 days before trial end |
| MA-03 | Weekly limits + hifz feature | P0 | M | Generous, predictable free tier; cost bounded | `plan_limits.free_weekly/premium_weekly`, `ai_feature` += hifz, `begin_ai_call` weekly | Migration 0002/0004, `quota.ts`, `get_my_quota` with `resets_at`, DB tests |
| MA-04 | Core ring-fence + annual pooling | P1 | M | Paying users never lose recitation to chat | `_ai_budget_window` pacing, `_ai_window_used(core)` | Settings `core_share`, `annual_pace_multiple`; DB tests |
| MA-05 | Value-first onboarding | P0 | M | Activation | New 6-step screen, guest created after intent, router guard | `onboarding_screen.dart`, `seed_known_surahs`, free onboarding check in `recitation-analyze` |
| MA-06 | PaywallGate | P0 | S | Conversion without annoying | Prefs-backed gate, unit-tested | `monetization.dart`; used by Home, milestones, weekly summary |
| MA-07 | Limit sheet + pre-recording check | P1 | S | Fewer frustrated users; clear upgrade path | `showLimitSheet`, `QuotaExceeded.resetsAt` | Coach, hifz review, Ask, search |
| MA-08 | Today card + weekly summary + billing/trial cards | P1 | M | D1–D7 retention, fewer involuntary churns | `nextBestAction`, `get_weekly_summary` | `home_screen.dart` |
| MA-09 | Weak words | P1 | S | The clearest Premium reason | `get_weak_words` with free cut at 3 | `weak_words_screen.dart`, hifz screen card |
| MA-10 | Milestones + pause plans + known surahs | P1 | M | Progress and fewer uninstalls | `hifz_milestones`, `review_only` plans | `_hifz_apply_review`, hifz screen |
| MA-11 | Recitation hardening | P0 | S | Privacy and cost | Atomic claim, `finally` delete, server clip | `recitation-analyze/index.ts`, `recitation_policy.ts` + tests |
| MA-12 | Referral, webhook, search, queue fixes | P1 | S | No abuse; correct subscription state | Migration 0003, `billing.ts` | DB + Deno tests |
| MA-13 | Settings honesty | P2 | S | Trust | Reminder state/time prefs; error handling | `settings_screen.dart` |
| MA-14 | Demo mode parity | P2 | S | Web preview shows the real behaviour | Weekly limits, hifz grading, milestones, weak words in demo | `app/lib/demo/*` |

### Owner (needs your accounts; see `BLOCKERS.md` §5)

| ID | Title | Priority | Effort | Steps |
|---|---|---|---|---|
| MA-20 | Merge #1–#4 then this PR; check the backend deploy run | P0 | S | GitHub → merge in order → Actions → "Deploy backend" green |
| MA-21 | Trial on annual only | P0 | S | Remove the intro offer from the monthly product in both stores |
| MA-22 | GCC/EU/US prices $29.99 / $4.99 (decided) | P1 | S | Enter in both stores: `docs/store-setup.md` §1 |
| MA-23 | Billing grace period + account hold | P0 | S | Apple 16 days; Google 7 + 30 |
| MA-24 | Win-back offers | P2 | S | Apple win-back, Google lapsed-subscriber offer |
| MA-25 | PostHog funnel dashboards | P1 | S | Build from the event list in §4 and §7 |
| MA-26 | Arabic ASO | P1 | S | Keywords and screenshots around "تحفيظ" and "تصحيح التلاوة" |

### Later (next threads)

| ID | Title | Priority | Effort | Business impact | Steps |
|---|---|---|---|---|---|
| MA-30 | Ramadan 2027 mode | P0 (by Jan) | L | Biggest seasonal growth | Khatm plan, Juz Amma challenge, in-app event, Ramadan paywall copy |
| MA-31 | Shareable recitation card | P1 | M | Organic growth | Render result to image, share sheet, deep link |
| MA-32 | Family plan | P1 | L | New revenue line in GCC | Household table, child profiles, parent view, store family sharing |
| MA-33 | Premium state refresh on resume | P2 | S | Correctness | Listen to app lifecycle, invalidate `premiumProvider` |
| MA-34 | Answer reports table + weekly review | P2 | S | Answer quality, scholar trust | `answer_reports`, admin query |
| MA-35 | Full RTL and accessibility pass | P2 | M | Store featuring, inclusivity | Semantics labels, numerals, mirrored icons |
| MA-36 | Referral: both sides get a free Premium week | P2 | M | Viral loop | RevenueCat promotional entitlement via webhook |
