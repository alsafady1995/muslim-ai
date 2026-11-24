# Muslim AI: Subscription and Growth Audit

An independent audit of the subscription model **as it is built** (main + PR #2: Premium $2.99/month or $19.99/year,
annual pre-selected, 7-day free trial on both plans, lower regional prices for Egypt, Pakistan and Indonesia, server-enforced
AI cost cap of 50% of each user's net payment, trial $0.25, free $0.15/month, Haiku fallback near the cap).
Launch market: Saudi Arabia and the GCC, before Ramadan 1448 (about 8 February 2027, roughly 10 weeks away).

Every limit in this document respects the owner's rule: **no user may cost more in AI than half of what they pay.**
Section 15 shows the arithmetic.

---

## ملخص بالعربية

**الخلاصة الصريحة:** المنتج قوي، لكن الاشتراك المبني حاليًا لا يبيع شيئًا واضحًا. الخطة المجانية تعطي كل شيء تقريبًا،
والمميزة (Premium) هي "حصة أكبر من نفس الشيء"، وشاشة الاشتراك تَعِد بتحليلات متقدمة غير موجودة في الكود.

**أهم الأخطاء:**
1. لا توجد ميزة مدفوعة حصرية؛ المميزة = حدود يومية أعلى فقط. وبند "تحليلات متقدمة" في شاشة الدفع غير مبني (خطر رفض من Apple وخطر على الثقة).
2. قفل أصوات أئمة الحرم (السديس، الشريم، المعيقلي) خلف الاشتراك في تطبيق يطلق في السعودية: يبدو بخلًا ويضر بالتقييمات.
3. الحدود يومية (٣ تسميعات يوميًا = ~٩٠ شهريًا) فلا يشعر بها معظم المستخدمين أبدًا.
4. ميزانية الذكاء الاصطناعي مشتركة: مستخدم يكثر من الأسئلة يُوقِف مصحح التلاوة (الميزة التي دفع من أجلها).
5. المشترك السنوي (الخيار الافتراضي) يحصل على ميزانية شهرية أقل من الشهري، فهو أول من يرى "توقف الذكاء الاصطناعي".
6. التسجيل الأولي لا يحتوي على لحظة "واو" (لا تسميع للفاتحة)، ويطلب إذن الإشعارات قبل أي قيمة.
7. التجربة المجانية على الخطة الشهرية تسحب المستخدمين من السنوية، ومستخدمو رمضان الشهريون يلغون بعد العيد.

**أقوى محفّز للاشتراك:** اختبار الحفظ بالذكاء الاصطناعي (تسمّع من حفظك، فيقيّمك التطبيق ويجدول مراجعتك تلقائيًا).
تصحيح التلاوة هو لحظة الإعجاب، لكن **مدرّب الحفظ هو ما يدفع الناس من أجله شهرًا بعد شهر.**

**الاستراتيجية الواحدة التي أختارها:**
"القيمة أولًا، ثم الطلب: تجربة سنوية صادقة، ومدرّب الحفظ هو المنتج المدفوع":
- تسميع الفاتحة داخل التسجيل الأولي **بدون أي عرض اشتراك**. لا يرى المستخدم أي عرض للاشتراك قبل أن يحصل على قيمة حقيقية في ٣ أيام مختلفة على الأقل.
- أول عرض لتجربة ٧ أيام **على الخطة السنوية فقط** يظهر عند أول لحظة قيمة حقيقية: الوصول إلى حد أسبوعي، أو إنجاز في الحفظ (مثل إتمام حفظ أول سورة)، أو ملخص الأسبوع الأول. مع زر "المتابعة مجانًا" واضح، وتذكير قبل نهاية التجربة بيومين.
- حدود أسبوعية للخطة المجانية تتجدد كل جمعة: ١٠ تسميعات (حتى دقيقة)، ٥ اختبارات حفظ ذكية، ١٥ سؤالًا.
- المميزة = مدرّب حفظ كامل: اختبارات حفظ بلا حدود عملية، تسميع صفحة كاملة (حتى ٣ دقائق)، تدريب على الكلمات التي تخطئ فيها.
- حجز ٤٠٪ من ميزانية الذكاء الاصطناعي للتلاوة والحفظ، وتجميع ميزانية المشترك السنوي على مدار السنة (وكل ذلك ضمن قاعدة الـ٥٠٪).
- فتح جميع القراء مجانًا. سعر الخليج: ٢٩٫٩٩$ سنويًا (≈ ١٠٩٫٩٩ ريال) و٤٫٩٩$ شهريًا بدون تجربة. الأسعار الإقليمية كما هي.

**النتيجة المتوقعة:** تقريبًا ضعف نسبة التحويل من التثبيت إلى الدفع (من ~٢٫٥٪ إلى ~٤٫٥–٥٫٥٪، تقديرات قبل الإطلاق وليست قياسًا)، مع ثقة أعلى
لأن المستخدم يعيش القيمة عدة أيام قبل أي طلب دفع، ولا يُفاجأ بخصم.

**مسار التحويل المعدّل باختصار:**
١. اليوم ٠: لغة ← هدف ← السور المحفوظة ← تسميع الفاتحة ← خطة الحفظ ← تذكير بمراجعة الغد. لا عرض اشتراك.
٢. الأيام ١–٦: مراجعات يومية، اختبارات حفظ ذكية، سلسلة أيام. لا عرض اشتراك ولا شريط ترويجي.
٣. أول عرض (بعد ٣ أيام نشاط على الأقل): عند الحد الأسبوعي، أو إنجاز حفظ، أو ملخص اليوم السابع (أيها أسبق).
٤. تجربة ٧ أيام على السنوي، تذكير في اليوم الخامس، ثم الاشتراك.

---

## 0. What is actually built (the baseline I am auditing)

I audited the code, not the plan. Where the two disagree, the code wins.

| Area | What the code does today | Where |
|---|---|---|
| Onboarding | 3 steps: language, daily ayah goal, reminders. Signs in as guest, asks notification permission at the end, goes to Home. **No recitation, no intent question, no hifz plan, no trial offer.** | `app/lib/features/onboarding/onboarding_screen.dart` |
| Paywall entry points | Recitation / Ask / Search daily quota hit, free AI-budget sheet, Home banner (every free user from day 0), Settings, locked reciter. **No 7-day-streak or weekly-summary paywall** (the plan has them; the code does not). | `coach_screen.dart:139`, `ask_screen.dart:66`, `search_screen.dart:63`, `ai_budget.dart:38`, `home_screen.dart:57`, `settings_screen.dart:104,155` |
| Paywall content | 6 generic bullets, "Less than a coffee a month", annual pre-selected, "Start 7-day free trial", trial-then-price line, restore, terms. | `paywall_screen.dart`, `app_en.arb:360-403` |
| Free limits | Per **day**: 3 recitation checks (hifz AI tests share this quota), 5 Ask/assistant, 10 semantic searches. Hard $0.15/month. | `20261123000004_reference_data.sql:18`, `ai_budget_settings` |
| Premium limits | Per day: 100 recitation, 20 Ask, 200 search. Budget 50% of net payment per monthly window, **one shared budget across all AI features.** | `20261124000001_ai_cost_cap.sql` |
| Premium-only things | Higher quotas, Sonnet instead of Haiku, and 5 locked reciters: **Abdul Basit, Minshawi, Maher Al-Muaiqly, Sudais, Shuraim.** Nothing else in the app checks `premium`. | `reference_data.sql:45-53`, `settings_screen.dart:100` |
| Hifz | Full plan, SM-2 scheduling, at-risk detection, self-graded reviews, optional AI test (counts as a recitation check). All free. | `hifz_screen.dart`, `hifz_review_screen.dart`, `recitation-analyze/index.ts:101` |
| Recitation cost | ASR at ≈ $0.001 per audio minute; no Claude call. A 1-minute check costs us about **one tenth of a cent.** | `ai_cost.ts:73`, `recitation-analyze/index.ts:47` |
| Recording length | App stops at 3 minutes for everyone. | `coach_screen.dart:36` |
| Word-level mistakes | Stored per session in `recitation_sessions.mistakes` (jsonb), but not aggregated or shown over time. | `core_schema.sql:356` |

Two facts shape everything below:

1. **Recitation is almost free to run.** The cost cap was designed around Claude, but the core feature barely touches it.
   That means recitation limits are purely a conversion and fairness decision, not a cost decision.
2. **Premium has no capability of its own.** It is "more of the same", and the paywall promises one thing ("advanced
   progress analytics") that does not exist.

---

## 1. If the app launched tomorrow, where would users subscribe?

Honestly: **almost nowhere, and mostly by accident.**

- **Recitation quota wall (3/day).** This is the only wall a motivated user will hit, and only on a heavy day. A typical
  user does 1 to 2 checks a day and never sees it. Those who do see it are told, in effect, "come back tomorrow", which is
  an acceptable free answer, so most close the sheet.
- **Home banner.** Shown to every free user from minute one. It will collect the "I already wanted to pay" users (a
  small, fixed number) and train everyone else to ignore gold boxes.
- **Locked reciter.** Some Saudi users will tap Sudais or Shuraim, hit a paywall, and a share will convert. A larger
  share will leave a review saying the Haram imams are paywalled. Net negative.
- **Ask quota (5/day).** Rarely hit; and when hit, the user has ChatGPT one tap away.

Expected install-to-paid at launch with the build as it is: **about 2 to 3%**, front-loaded into the first week and
then flat, because nothing pushes a satisfied free user toward a decision.

With the funnel in this document, the ranking becomes:

1. **Weekly hifz-test limit** during a review session (the highest-intent moment).
2. **First hifz milestone** (first surah fully memorized, or first at-risk ayah recovered).
3. **Day 7 weekly summary** ("6 ayahs at risk").
4. **Weekly recitation limit / 60-second clip limit.**
5. **Ramadan campaign** (pre-Ramadan and first 10 days).

There is deliberately no offer in onboarding (owner's principle: show value first, ask for money second).

---

## 2. The strongest subscription trigger

**The AI hifz test: recite from memory, get graded word by word, and have the next review scheduled automatically.**

Why this and not the recitation coach:

- The recitation coach creates the "wow, it caught my mistake" moment. It is the **acquisition and aha** feature, and it is
  the thing people film for TikTok. But checking recitation is episodic: people use it hard for a week, then occasionally.
- Memorization is **ongoing, compounding and loss-averse.** Every ayah memorized adds review load forever, and the app
  already shows "at risk" ayahs that will be forgotten without review. A user with 2 juz in the plan has a reason to pay
  every single month. That is the definition of a subscription.
- Self-grading works but is lonely and unreliable ("did I really get that right?"). The AI test removes doubt, which is
  exactly what a serious memorizer will pay for.

**The exact trigger moment:** a free user opens a review session, the queue has more due ayahs than AI tests left this
week, and the at-risk count is above zero. The prompt appears *inside* the session after the free tests are used, and
the review continues either way (section 7).

---

## 3. Free features that are accidentally too generous

| Feature | Why it hurts conversion | Change |
|---|---|---|
| **3 recitation checks per day** (≈ 90/month) | Daily resets mean almost no one feels the limit, and the few who do just wait a day. | **Weekly** limit: 10 checks per week, up to 60 seconds each. |
| **Hifz AI tests share the recitation quota** | A memorizer and a casual reciter hit the same wall; the wall does not say "this is the hifz coach". | Split into its own quota: 5 AI hifz tests per week. Self-graded reviews stay unlimited and free. |
| **3-minute recordings for free users** | A free user can check a full page in one go, which is the main thing a premium user would want more of. | Free clips stop at 60 seconds (≈ Al-Fatiha plus a short surah, or 3 to 5 ayahs of a long surah). Premium keeps 3 minutes. |
| **5 Ask questions per day on Haiku** (≈ 150/month) | Not a conversion lever either way (Ask is a commodity), but it consumes almost the whole $0.15 free budget, leaving none for recitation in a worst case. | 15 per week. |
| **Home Premium banner from day 0** | Not generous, but it is noise that burns the paywall's credibility before any value. | Show only after the value gate: real value on 3 different days (section 7). |

What is **not** too generous and must stay free: Quran reader, audio, all reciters, downloads, adhkar, goals, streaks,
keyword search, the full hifz plan and SM-2 schedule, self-graded reviews, the at-risk view. A Quran app that paywalls
worship content loses the trust that drives every organic channel in the GCC.

---

## 4. Premium features that are too weak to make people pay

| Premium "benefit" on the paywall today | Problem |
|---|---|
| "AI recitation analysis every day" | Free users already get it every day. |
| "AI memorization coaching" | Free users already get the whole hifz coach. Premium adds nothing to it. |
| "More questions to Ask the Quran" | Quantity of a commodity. Nobody pays $20 a year for more chatbot questions in a Quran app. |
| "Personalized plans and advanced progress analytics" | **Not built.** Nothing in the app is gated on `premium` except reciters. This is a store-review risk (Apple 3.1.2 / 2.3.1) and a trust risk. Remove it before launch or build it. |
| "All premium reciters" | Locking the Haram imams in a Saudi launch is a net negative (section 10). |
| "Support continued development" | Fine as a closing line, not as a reason. |

What Premium is missing is **one capability a free user can see but not have**, tied to the hifz outcome. The pieces
already exist in the code; they need to be gated and surfaced, not invented:

1. **Unlimited AI hifz tests** (fair use) — split quota, already built as `mode = 'hifz'`.
2. **Full-page recitation checks up to 3 minutes** — already built; free gets 60 seconds.
3. **Weak-words drill** — the words you get wrong most often, practised first. The mistakes are already stored per
   session in `recitation_sessions.mistakes`; this is one aggregate query plus a list screen that opens the existing
   coach on those ayahs. It is also the honest version of "advanced analytics" (spec 7.10 already lists "most-missed
   words" as premium).
4. Ask with the more capable model (already built), presented last.

---

## 5. Ideal free limit for AI recitation analysis

**10 checks per week, each up to 60 seconds, resetting every Friday.** The onboarding Al-Fatiha check does not count.

- 10 per week lets a casual daily reciter (1 to 1.5 checks a day) stay free comfortably, which protects retention and
  word of mouth.
- A user practising seriously (3+ checks a day) meets the limit on day 3 or 4 of the week, mid-habit, with value
  already proven 9 times. That is the right moment to ask.
- Weekly limits create a visible "renews Friday" date, which is a real choice (wait or upgrade) rather than "tomorrow"
  (always wait).
- Friday reset is memorable, culturally natural, and gives users a fresh week on Jumu'ah, when Quran reading peaks.
- Cost: about $0.04 per user per month at the limit. Well inside the $0.15 free budget.

---

## 6. Ideal free limit for AI memorization coaching

**5 AI hifz tests per week (up to 60 seconds each). Unlimited self-graded reviews. Full plan and schedule free.**

- A new memorizer's first week has reviews on roughly days 2, 3, 5, 6 and 7. Five AI tests cover the first week's
  experience of "the coach graded me", so the user knows exactly what they would be paying for.
- From week 2 the review queue grows faster than 5 per week. The user feels the gap naturally, and self-grading keeps
  them going without a wall.
- Never block a review. When the AI tests are used up, the session continues with self-grading. Blocking worship-like
  practice behind a paywall would be the fastest way to lose this audience's trust.

---

## 7. Exactly when the paywall should appear

**Value gate (owner's principle: show value first, ask for money second).** No automatic Premium surface of any kind,
including the Home banner, until the user has had real value on **at least 3 different days** (a recitation check, an AI
hifz test or a completed review on each). The only exception is a real limit sheet: a user who used up a weekly limit has
already had the value, and the sheet must explain the limit anyway. Settings keeps its "Go Premium" row, since the user
opens it.

The **first** trial offer is shown at whichever of these comes first after the value gate: a weekly limit, a hifz
milestone, or the day-7 summary. After that, automatic paywalls follow a frequency cap: **at most 1 per day, at most 3 per
week, never twice in one session**, and after two "Not now" taps, no automatic full-screen paywall for 7 days (limit
sheets still show, since they explain a real limit).

| # | Moment | Form | Who |
|---|---|---|---|
| 1 | **Hifz AI tests used up**, inside a review session | Inline card under the current ayah; primary button continues the review | Free |
| 2 | **Hifz milestone**: first surah fully memorized (all its ayahs reviewed at least twice with grade ≥ 4), or first at-risk ayah brought back to safe | Celebration first; the offer is a card below it, framed as "keep it for good" | Free, after value gate, once per milestone type |
| 3 | **First weekly summary (day 7)** when at-risk ayahs > 0 | Card in the summary, opens paywall on tap | Free, after value gate |
| 4 | **Weekly recitation checks used up** | Bottom sheet with renewal date; two equal buttons | Free |
| 5 | **60-second clip limit** reached | Recording stops and analyses normally; one line under the result links to Premium | Free, after value gate |
| 6 | **7-day streak** | Celebration first; small "Unlock your full coach" link below it | Free, once |
| 7 | **Ramadan**: 15 Sha'ban and 1 Ramadan | Ramadan plan offer (same annual trial) | Free, after value gate, once each |
| 8 | Settings (always), Home banner (after value gate), Profile | User-initiated | Free |

---

## 8. Where the paywall must never appear

- Anywhere in onboarding, and anywhere before the value gate (3 active days), except a real limit sheet.
- During a recitation, while recording, or while the result is loading.
- Right after a low score. Never sell to someone who just struggled; it reads as shaming.
- During or after adhkar, while reading or listening to the Quran, or from a prayer-time or adhkar notification.
- In the middle of a hifz review card (only between cards, and only as an inline card).
- In any push notification other than the trial-ending reminder (which is a service message, not a sale).
- To a Premium user who hit the AI cost cap. They already pay; show the existing friendly "renews on" sheet only.
- To a user whose subscription was refunded in the last 30 days, or who cancelled in the last 7 days (they get the
  win-back flow instead, section 14).
- On reciter selection. Unlock all reciters.
- In Ask conversations about grief, illness, death, or personal crisis. When a quota ends in such a conversation, show
  the plain limit message without the upgrade button.

---

## 9. Onboarding that maximizes conversion without hurting retention

Six screens, about 2 minutes, **no ask for money.** Onboarding's job is to create the habit that later makes the
subscription obvious.

| Step | Screen | Purpose | Built today? |
|---|---|---|---|
| 1 | Language (auto from device) + promise: "Recite. Get corrected. Never forget what you memorize." | Expectation | Partly |
| 2 | **Intent:** "What matters most to you right now?" Memorize / Perfect my recitation / Read daily / Understand | Personalize home, plan and paywall copy | No |
| 3 | **Level** (memorize and recitation only): tap the surahs you know (Juz Amma chips) | Seed hifz review items | No (exists in hifz screen) |
| 4 | **First recitation: Al-Fatiha.** Record, see word-by-word result. Not counted against limits. | The aha | No |
| 5 | **Plan reveal:** "5 ayahs a day. Your first review is tomorrow at 9:00 pm. 3 of your surahs are due this week." | Commitment, day-2 reason to return | No |
| 6 | **Reminders:** "Remind me for tomorrow's review" (permission asked here, after value), then straight to Home | Opt-in rate | Yes, but asked before any value |

**Why there is no trial offer at the end of onboarding.** In many subscription apps the post-onboarding offer is the
largest single source of trial starts, so this is a real trade-off, and an earlier draft of this audit recommended it.
The owner rejected it, and I agree it is the right call for this product:

- One Al-Fatiha result proves the technology works; it does not prove the app will change the user's relationship with
  the Quran. Asking for money at that point sells a promise, not an experience.
- Trials started on day 0 convert worse and refund more, because many users start them on impulse and forget.
  Trials started after a limit or a milestone are fewer but convert at a higher rate and churn less.
- In a Quran app, "asked me to pay before I'd even used it" is the review that hurts ratings and organic growth most.

The cost is fewer trial starts in week 1. The gain is a higher trial-to-paid rate, fewer refunds, better ratings, and a
paywall that arrives when the user can judge it (section 16).

---

## 10. The biggest monetization mistakes in the current strategy

1. **Premium has no product.** It is quotas plus a model upgrade. Users do not pay for quotas; they pay for an outcome.
2. **The paywall promises something not built** ("advanced progress analytics"). Fix before submission.
3. **Haram imams behind the paywall in Saudi Arabia.** Every free Quran app in the store offers them. This will cost
   reviews and gains little revenue. Licensing for EveryAyah audio is also unconfirmed (`BLOCKERS.md` 18), and charging
   for it makes that worse.
4. **Daily limits.** Too generous to bite and too frequent to feel like a decision.
5. **One shared AI budget.** A Premium user who asks 30 Sonnet questions can pause their own recitation coach, the
   feature they paid for, until next month. Ring-fence the core.
6. **Annual subscribers get the smallest monthly budget.** The plan we pre-select ($19.99/yr ≈ $0.62/month of AI) is the
   one most likely to see "AI paused" in month 1, after paying for a full year up front. That is a refund and 1-star
   recipe. The money is already received, so the budget can be pooled across the year without breaking the 50% rule.
7. **7-day trial on the monthly plan.** It pulls trial users toward monthly, and monthly subscribers acquired in
   Ramadan cancel at Eid. Trial on annual only; monthly is the no-trial fallback.
8. **The trial can run out of AI during the trial.** $0.25 is about 10 Sonnet answers; a curious trial user can hit "used
   up" on day 2 and judge the product by that. Ring-fencing keeps recitation and hifz untouched, and Ask simply moves
   to Haiku.
9. **No trial-ending reminder.** An annual charge that surprises the user produces refunds, chargebacks and angry
   reviews. A reminder 2 days before the end lowers trial-to-paid slightly but raises net revenue and trust.
10. **Onboarding has no aha and asks for notifications before any value.**
11. **Price-led copy** ("less than a coffee"). In the GCC this signals cheapness, not quality, and it is not why anyone
    memorizes Quran.
12. **Underpriced for the launch market.** $19.99 a year is about SAR 75. Because the AI budget is 50% of what the user
    pays, a low price also means a thin Premium experience. Raising the GCC price raises both revenue and the quality of
    what Premium can deliver.

---

## 11. How to roughly double conversion without hurting satisfaction

These are estimates from typical subscription-app benchmarks, not measurements; the app has no users yet.

| Lever | Expected effect on install-to-paid | Satisfaction effect |
|---|---|---|
| Al-Fatiha aha in onboarding + first offer at a limit, milestone or day-7 summary after 3 active days | Largest single lift: more users reach a real decision moment, and they reach it convinced | Positive (value first, no ask in onboarding) |
| Premium = hifz coach (unlimited AI tests, full-page checks, weak-words drill) | Raises paywall conversion because the offer is concrete | Positive |
| Weekly limits instead of daily | More users reach a real decision moment | Neutral (casual users unaffected) |
| Trial on annual only + day-5 reminder | Higher annual mix, fewer refunds | Positive |
| Personalized paywall by intent | Typical lift 10 to 30% on paywall conversion | Neutral |
| Unlock all reciters | Small revenue loss, better ratings and ASO | Positive |
| Ring-fenced core budget + pooled annual budget | Fewer "AI paused" moments for payers, lower churn and refunds | Positive |

Rough funnel today versus proposed:

| Step | Built today | Proposed |
|---|---|---|
| Install → trial start | ~4 to 5% (only quota walls and banner) | **8 to 11%** (all after the value gate) |
| Trial → paid | ~45% (mix of monthly and annual) | **55 to 60%** (annual only, high-intent moments, honest reminder) |
| Install → paid | **~2 to 2.5%** | **~4.5 to 6%** |

---

## 12. The strategy most likely to maximize revenue over 24 months

**Annual-first, hifz-led, with a single honest trial.** Over 24 months the dominant term is how many people you lock into
an annual plan before Ramadan, during Ramadan, and at each Ramadan after.

- Ramadan installs are the biggest spike of the year, and those users drop off after Eid. Monthly subscribers from
  Ramadan mostly cancel in Shawwal; annual subscribers stay through next Ramadan, where they are reactivated by the
  season itself. That renewal lands exactly when engagement peaks again.
- Hifz creates the ongoing reason to stay subscribed between Ramadans.

Illustrative net revenue per paying subscriber over 24 months (KSA, 15% VAT included in price, 15% store commission;
assumes 35% of annual subscribers renew once and monthly subscribers stay 4 to 5 months on average):

| Plan | Net per charge | 24-month net per subscriber |
|---|---|---|
| $19.99/yr (today) | $14.78 | ≈ $20 |
| **$29.99/yr (proposed)** | **$22.17** | **≈ $30** |
| $2.99/mo (today) | $2.21 | ≈ $10 to $11 |
| $4.99/mo (proposed, no trial) | $3.69 | ≈ $15 to $17 |

---

## 13. The exact plans and weekly limits

Weekly limits reset **every Friday at 00:00 local time.** A new user's first week runs until the second Friday after
install, so nobody gets a 1-day first week. The monthly AI budgets from PR #2 stay as the hard ceiling underneath.

### Free

| What | Limit |
|---|---|
| Quran reader, audio, **all reciters**, downloads, adhkar, goals, streaks, keyword search | Unlimited |
| Hifz plan, SM-2 schedule, at-risk view, self-graded reviews | Unlimited |
| AI recitation checks | **10 per week**, up to **60 seconds** each |
| AI hifz tests (recite from memory, auto-graded) | **5 per week**, up to 60 seconds each |
| Ask the Quran + assistant (shared, Haiku) | **15 per week** |
| Semantic search | **30 per week** |
| Al-Fatiha check in onboarding | Free, not counted |
| Hard AI budget | $0.15 per calendar month (unchanged) |

### Free trial (7 days, annual plan only)

Everything in Premium, with these fair-use limits inside the $0.25 trial budget:

| What | Limit |
|---|---|
| AI recitation checks and hifz tests | Fair use, up to 3 minutes each. **$0.12 of the $0.25 is reserved for these** (≈ 40 three-minute or ≈ 80 typical checks) |
| Ask + assistant | Sonnet until the remaining $0.13 is used, then Haiku; never "used up" for recitation or hifz |
| Weak-words drill | Included |

### Premium

**Default storefront (GCC, Europe, US): $29.99/year with 7-day free trial (≈ SAR 109.99); $4.99/month, no trial (≈ SAR 18.99).**
**Egypt, Pakistan, Indonesia: unchanged regional prices; trial on annual only.**

| What | Weekly fair use |
|---|---|
| AI recitation checks | 150 per week, up to **3 minutes** each |
| AI hifz tests | 150 per week (separate from recitation) |
| Weak-words drill | Unlimited (no AI cost: it reuses stored results; each drill recitation counts as a check) |
| Ask + assistant | 100 per week; Sonnet within the Ask share of the budget, then Haiku |
| Semantic search | 300 per week |
| Budget | 50% of net payment (unchanged rule), with **40% of it reserved for recitation and hifz.** Annual plans pool the whole year's budget, spendable at up to 3× the monthly share in any one month. |

In practice no Premium user will meet a weekly recitation or hifz limit; those numbers exist only as abuse protection.

---

## 14. Exact copy

All copy is personalized by the intent chosen in onboarding. Default copy below is the "Memorize" variant; the
"Perfect my recitation" variant swaps the headline only.

### 14.1 Paywall (onboarding and contextual)

| Element | English | العربية |
|---|---|---|
| Headline (Memorize) | Keep every ayah you memorize. | احفظ… ولا تنسَ ما حفظت. |
| Headline (Recitation) | Recite with confidence. Every word checked. | اقرأ بثقة. كل كلمة تُراجَع. |
| Subhead | Your Hifz Coach listens, grades each review and schedules the next one, so nothing slips. | مدرّب الحفظ يستمع إليك، ويقيّم كل مراجعة، ويجدول التالية تلقائيًا، فلا يتفلّت منك شيء. |
| Bullet 1 | Test your hifz with your voice every day. Grading is automatic. | اختبر حفظك بصوتك كل يوم، والتقييم تلقائي. |
| Bullet 2 | Check a full page in one go, up to 3 minutes. | سمّع صفحة كاملة دفعة واحدة، حتى ٣ دقائق. |
| Bullet 3 | Your weak words, practised first. | الكلمات التي تخطئ فيها، تتدرب عليها أولًا. |
| Bullet 4 | Ask the Quran with our most capable AI. | اسأل القرآن بأقوى نموذج لدينا. |
| Trial timeline | **Today:** full access, no charge. **Day 5:** we remind you. **Day 7:** your plan starts at {price}/year. Cancel before then and pay nothing. | **اليوم:** وصول كامل بدون أي خصم. **اليوم الخامس:** نذكّرك. **اليوم السابع:** يبدأ اشتراكك بـ {price} سنويًا. ألغِ قبلها ولن تدفع شيئًا. |
| Plan rows | Yearly · {price}/year · {monthly-equivalent}/month · 7 days free / Monthly · {price}/month | سنوي · {price} سنويًا · {monthly-equivalent} شهريًا · ٧ أيام مجانًا / شهري · {price} شهريًا |
| CTA (annual) | Start my 7 free days | ابدأ أيامي السبعة المجانية |
| CTA (monthly) | Subscribe monthly | اشترك شهريًا |
| Secondary | Continue free | المتابعة مجانًا |
| Small print | No charge today. Cancel anytime in your App Store or Google Play settings. Auto-renews until cancelled. | لا خصم اليوم. يمكنك الإلغاء في أي وقت من إعدادات App Store أو Google Play. يتجدد تلقائيًا حتى الإلغاء. |
| Closing line | Your subscription keeps Muslim AI free of ads, always. | اشتراكك يُبقي التطبيق بلا إعلانات، دائمًا. |

Remove "Less than a coffee a month" and the "advanced analytics" bullet.

### 14.2 Upgrade prompts

| Trigger | English | العربية | Buttons |
|---|---|---|---|
| Hifz AI tests used up (inline, mid-session) | You've used this week's 5 AI tests. Your review continues with self-grading. Want the coach to grade every review? | استخدمت اختبارات الحفظ الخمسة لهذا الأسبوع. ستكمل مراجعتك بالتقييم الذاتي. هل تريد أن يقيّم المدرّب كل مراجعة؟ | **Continue reviewing** (primary) · Try Premium free |
| Weekly recitation checks used up | You've used this week's 10 checks. They renew on Friday. | استخدمت تسميعات هذا الأسبوع العشرة. تتجدد يوم الجمعة. | Wait until Friday · Try Premium free (equal weight) |
| 60-second clip limit | Free checks cover 60 seconds. Premium checks a full page in one go. | التسميع المجاني حتى ٦٠ ثانية. المميز يسمّع صفحة كاملة دفعة واحدة. | Text link only |
| Weekly summary, at-risk > 0 | 6 ayahs are at risk of being forgotten this week. Premium tests all of them for you. | ٦ آيات معرّضة للنسيان هذا الأسبوع. المميز يختبرها كلها معك. | See my plan |
| First surah memorized (milestone) | You've memorized Surah {name}. Alhamdulillah. Keep it strong for good: the coach tests it with you until it's mastered. | أتممت حفظ سورة {name}، الحمد لله. حافظ عليها للأبد: المدرّب يختبرها معك حتى تُتقنها. | Celebration first · Keep it with Premium, 7 days free (link) |
| 7-day streak | Seven days in a row. Masha'Allah. Unlock your full coach for the next seven. | سبعة أيام متتالية، ما شاء الله. افتح المدرّب الكامل للأيام السبعة القادمة. | Small link under celebration |
| Ask limit | You've asked 15 questions this week. They renew on Friday. | طرحت ١٥ سؤالًا هذا الأسبوع. تتجدد يوم الجمعة. | Wait · Try Premium free |
| Home banner (after value gate) | Your Hifz Coach · 7 days free | مدرّب الحفظ · ٧ أيام مجانًا | Tap to open |
| Ramadan (15 Sha'ban) | Make this Ramadan your strongest. A plan for your Quran, with a coach that listens. | اجعل رمضان هذا العام الأقوى. خطة لقرآنك، ومدرّب يستمع إليك. | Start 7 days free |

### 14.3 Trial and billing messages

| When | English | العربية |
|---|---|---|
| Trial day 5 (local notification + in-app card) | Your free trial ends in 2 days. Keep it and your plan continues; cancel in settings and you won't be charged. | تنتهي تجربتك المجانية بعد يومين. إن أبقيتها يستمر اشتراكك، وإن ألغيتها من الإعدادات فلن يُخصم منك شيء. |
| First charge | Welcome to Premium. Your Hifz Coach is fully yours. | مرحبًا بك في المميز. مدرّب الحفظ أصبح لك بالكامل. |
| 30 days before annual renewal | Your year with Muslim AI: {ayahs} ayahs memorized, {reviews} reviews. Your plan renews on {date}. | سنتك مع التطبيق: {ayahs} آية محفوظة و{reviews} مراجعة. يتجدد اشتراكك في {date}. |

---

## 15. Cost check against the 50% rule

| Tier | Worst case at the limits above | Budget | Within rule? |
|---|---|---|---|
| Free | Recitation + hifz: 15 × 4.33 weeks × 1 min × $0.001 ≈ $0.065; Ask 15 × 4.33 × ~$0.001 ≈ $0.065; search 30 × 4.33 × ~$0.0001 ≈ $0.013. **≈ $0.143/month** | $0.15 | Yes (free budget is the owner's fixed allowance) |
| Trial | Capped by the $0.25 trial budget; split $0.12 core / $0.13 Ask | $0.25 | Yes |
| Premium monthly $4.99 (KSA) | Capped at 50% of net | Net $3.69 → **$1.84/month** | Yes |
| Premium annual $29.99 (KSA) | Pooled: at most 50% of the year's net, max 3× monthly share in any month | Net $22.17 → **$11.08/year** (≈ $0.92/month) | Yes: spend never exceeds 50% of money already received |
| Regional annual ≈ $6.99 | Same mechanism | ≈ $2.6–3.0/year | Yes |

Ring-fencing and pooling change *how* the budget is spent, not *how much*. A refund still sets net to 0 and stops AI.
Pooling the annual budget is consistent with the rule as written ("no user may cost more in AI than half of what they
pay"), since the full annual payment is received on day 1. **This needs the owner's explicit OK**, because PR #2 enforces
the rule per monthly window.

---

## 16. Onboarding-to-subscription funnel (with targets)

| Stage | Event (PostHog) | Target |
|---|---|---|
| Install → onboarding started | `onboarding_started` | 95% |
| Intent chosen | `onboarding_step_completed {step: intent}` | 90% |
| First recitation completed (Al-Fatiha) | `recitation_completed {source: onboarding}` | 65% of starters |
| Plan revealed | `hifz_plan_created` | 60% |
| Notifications granted | `notification_permission_result` | 50% |
| Day 1 return (first review) | `hifz_reviewed` on day 1 | 45% |
| **Value gate passed** (value on 3 different days) | `value_gate_passed` | 30 to 35% of installs |
| First offer viewed (limit, milestone or day-7 summary) | `paywall_viewed {source: limit / milestone / summary}` | 25 to 30% of installs |
| **Trial started** (all sources, incl. Ramadan) | `purchase_completed` | **8 to 11% of installs** (≈ 30 to 35% of first-offer viewers) |
| Trial reminder shown (day 5) | `trial_reminder_shown` | 100% of trials |
| **Trial → paid** | RevenueCat `INITIAL_PURCHASE` after trial | **55 to 60%** |
| **Install → paid** | | **4.5 to 6%** |

---

## 17. Retention funnel

| When | What happens | Goal |
|---|---|---|
| Day 0 | Al-Fatiha aha, plan, reminder for tomorrow's review. No offer. | Reason to return |
| Day 1 | "Your first review is ready. 3 minutes." (user-set time) | D1 ≥ 45% |
| Day 2 to 6 | Daily review + streak; first AI hifz test grades automatically; streak freeze explained when first used. No offer until value on 3 different days. | Habit |
| First value moment after the gate | First trial offer: weekly limit, hifz milestone or day-7 summary, whichever comes first | Trial start at peak conviction |
| Day 5 (trial) | Honest trial-ending reminder | Trust, fewer refunds |
| Day 7 | First weekly summary: ayahs strengthened, ayahs at risk, best score | D7 ≥ 25% |
| Weekly (Friday) | Limits renew; Al-Kahf reminder; summary | Weekly rhythm |
| Week 2 to 4 | Weak-words drill introduced after 5 sessions; Ask and Search via contextual tips on a verse | Depth |
| Day 30 | 30-day streak, monthly report | D30 ≥ 12% |
| Subscriber, monthly | Monthly report: ayahs memorized, recitation accuracy trend | Visible value before each charge |
| Subscriber, cancels (RevenueCat `CANCELLATION`, still active) | In-app, once: "What made you cancel?" (4 options). If "too expensive": offer switch to annual. If "not using it": offer a lighter plan (fewer ayahs/day) instead of a discount | Save rate ≥ 10% |
| Billing failure | Enable **billing grace period** on both stores (Apple and Google); in-app banner "Update payment to keep your coach" | Recover ≥ 40% of involuntary churn |
| Expired, day 7 | One win-back offer: first year at 50% off (Apple win-back offer / Google Play offer for lapsed users), once per user | Win-back |
| Lapsed free user | Existing plan: one push at day 3 and day 7, then silence; "Welcome back" lightens the plan | No spam |
| Annual, 30 days before renewal | "Your year with Muslim AI" summary (section 14.3) | Renewal ≥ 35% |
| Every Ramadan | Seasonal plan; lapsed users get the Ramadan offer | Annual reactivation |

KPIs to watch weekly: trial start rate by source, trial-to-paid, refund rate (alert above 5%), annual mix (target ≥ 70%),
share of payers who hit "AI paused" (target under 2%), D1/D7/D30, 1-star reviews mentioning "paid" or "subscription".

---

## 18. What it takes to implement (for a follow-up thread)

No code is changed in this audit. Ordered by importance; "Must" means before store submission.

| # | Change | Where | Size |
|---|---|---|---|
| 1 | **Must:** remove the "advanced analytics" bullet (or ship #9 first) and the "coffee" line | `tools/gen_arb.py`, `paywall_screen.dart` | XS |
| 2 | **Must:** unlock all reciters (`is_premium = false`) | new migration | XS |
| 3 | **Must:** trial on annual only; GCC price $29.99 / $4.99; enable billing grace period | App Store Connect, Play Console, `BLOCKERS.md` | Store config |
| 4 | Weekly limits with Friday reset; split `hifz_test` from `recitation` | `plan_limits` (add `period`), `consume_ai_quota` / `begin_ai_call`, `recitation-analyze` | M |
| 5 | Free clip limit 60 s (app stops; server rejects > 65 s for free and reserves 1 minute instead of 5) | `coach_screen.dart:36`, `recitation-analyze` | S |
| 6 | Ring-fence 40% of budget for recitation + hifz (`core_share` in `ai_budget_settings`) | `20261124000001_ai_cost_cap.sql` | M |
| 7 | Pool annual budget across the year with 3× monthly pacing (needs owner OK) | same | M |
| 8 | New onboarding: intent, known surahs, Al-Fatiha check (not counted), plan reveal, contextual reminders (no offer) | `onboarding_screen.dart`, router | L |
| 8b | Value gate: count distinct days with a check, AI test or completed review; expose `value_days` in `get_dashboard`; hide automatic Premium surfaces below 3; hifz milestone events | `get_dashboard`, `home_screen.dart`, hifz RPCs | S |
| 9 | Weak-words drill from `recitation_sessions.mistakes` | new RPC + screen | M |
| 10 | Personalized paywall copy, trial timeline, inline hifz-test prompt, milestone offer, paywall frequency caps, banner after value gate | `paywall_screen.dart`, `hifz_review_screen.dart`, `home_screen.dart` | M |
| 11 | Trial day-5 reminder (local notification scheduled at purchase), cancellation survey, renewal summary | `notifications.dart`, `revenuecat-webhook` | S |

---

## 19. The one strategy I would bet my own money on

**"Value first, then one honest annual trial, and sell the Hifz Coach."**

Concretely: every new user recites Al-Fatiha in onboarding and sees their mistakes word by word. They get a hifz plan
with a review tomorrow, and **no offer at all.** For their first days the app only gives: reviews, AI tests, streaks.
Only after they have had real value on at least 3 different days, at the first moment that proves it (a weekly limit, a
hifz milestone such as their first surah memorized, or their day-7 summary), they see a 7-day free trial of the
**annual** plan, sold as the Hifz Coach (unlimited AI hifz tests, full-page checks, weak-words drill), with a timeline that
promises a reminder on day 5 and a full-width "Continue free" button. Free stays genuinely useful, with weekly limits that renew every Friday. All reciters
and all worship content stay free. Premium's AI budget protects recitation and hifz first, and annual subscribers can
use their whole year's budget. GCC annual at $29.99; monthly at $4.99 with no trial; regional prices unchanged.

Why this and nothing else:

- **It sells an outcome that compounds.** People don't renew for "more AI". They renew because 2 juz of memorization
  will fade without the coach, and the app shows them which ayahs are fading. That is retention and revenue from the
  same mechanism.
- **It converts at peak conviction without betraying trust.** The ask comes only after days of real use, at a moment
  when the user has just felt what the coach does for them (a limit they ran into, a surah they finished), and it says
  exactly when they will be charged and that they'll be reminded first. In a
  Quran app, the reviews that say "honest, reminded me before charging" are worth more than any trial-to-paid
  optimisation.
- **It wins Ramadan twice.** Annual-only trials capture the Ramadan spike for a full year, and the renewal lands on the
  next Ramadan, when engagement is highest again.
- **It fits the cost rule.** Recitation and hifz cost about a tenth of a cent per check, so the paid product is cheap to
  serve, and the 50% rule never forces a payer to lose the feature they bought.

The assumption I am most explicitly overturning from my own plan: **the AI chat is not the product, and the recitation
coach is not what people pay for. The recitation coach gets them in; the Hifz Coach keeps them paying.**
