# Is Asmi3ni financially viable? A brutally honest audit

Date: 25 November 2026. Scope: the business, not the product. Model: `tools/financial_model.py` (editable
assumptions) and its output `docs/strategy/financial-model.csv`. Every number marked **(inference)** is my
judgement, not a published figure. Prices were checked on the web today; sources are at the end.

---

## ملخص بالعربية

**الحكم الصريح:** أسمِعني **مشروع قابل للاستدامة، وليس بعدُ شركة مربحة**. بالافتراضات المتحفظة (٢٪ من
المستخدمين النشطين يدفعون، وقرابة نصف الدافعين في أسواق السعر المنخفض) يغطي التطبيق تكاليف الخوادم من نحو
**٢٬٠٠٠ مستخدم نشط شهريًا**، لكنه لا يدفع راتبًا متواضعًا للمؤسس (٢٬٥٠٠$ شهريًا) قبل نحو **٨٠٠ ألف إلى مليون
مستخدم نشط**. إذا نجحت الخطة (٤٪ يدفعون، والخليج أولًا) يصبح الراتب ممكنًا عند نحو **٦٠ ألف مستخدم نشط**.

**أخطر ما وجدته:** سقف الذكاء الاصطناعي المجاني الحالي (٠٫١٥$ شهريًا لكل مستخدم مجاني) **أعلى بأربع مرات تقريبًا**
من متوسط ما يجلبه المستخدم الواحد (≈ ٠٫٠٤$ شهريًا)، والدخول كضيف (حساب مجهول) يعطي كل حساب جديد هذا السقف،
ولا يوجد سقف إنفاق إجمالي يومي. هذا هو الطريق الوحيد الواقعي للإفلاس، وإصلاحه رخيص.

**التبرعات:** لا تجمع "تبرعات خيرية" أو "صدقات" داخل التطبيق: Apple لا تسمح بها إلا لجمعيات معتمدة، وGoogle
لا تعفيها إلا إذا كانت معفاة ضريبيًا، والنظام السعودي يقيّد جمع التبرعات بالجهات المرخّصة. البديل الآمن بلا محامٍ:
**"ادعم أسمِعني"** كإكرامية عبر مشتريات المتجر، و**"أهدِ طالبًا سنة Premium"** كهدية رقمية يسمح بها Apple صراحةً.

**هل أستثمر مالي؟** نعم بمبلغ صغير ووقت محدود، **بشرط** اجتياز ثلاث بوابات: دقة التصحيح الصوتي، واحتفاظ اليوم
الثلاثين ≥ ١٥٪، وتحويل التجربة إلى اشتراك ≥ ١٥٪ في الخليج. ولا أستثمر كصندوق جريء الآن.

**النموذج النهائي:** القرآن والأذكار والبحث النصي والمراجعة وحلقات المعلمين **مجانية للأبد**؛ و**Premium** يبيع
التدريب الذكي الأعمق وخطة العائلة؛ و**الدعم** إكرامية اختيارية وهدية سنة لطالب؛ و**نحذف** السوق المدفوع والبث
المباشر والشهادات وكل ما يدفع المعلم مقابله.

---

## 1. The verdict in one paragraph

Asmi3ni can become a **self-sustaining one-person product** quickly and cheaply, because the architecture is lean
(Supabase, a scale-to-zero ASR service, a per-user AI cost cap). It is **not yet a profitable company** and, on
conservative assumptions, will not pay even a modest founder salary until roughly **850,000 monthly active
users**. The economics are decided by three numbers that do not exist yet: the share of active users who pay,
how many payers come from the Gulf versus the $0.99/$6.99 markets, and whether annual subscribers renew. If the
teacher-led, Gulf-first plan works (4% paying, 75% of payers in full-price storefronts) the founder can be paid at
about **60,000 MAU**, and 1M MAU is a real business (≈ $0.55M a year before founder pay). There is one cheap-to-fix
design flaw that could bankrupt the project during a viral spike: the **free AI budget is larger than the revenue
an average user brings in**, and nothing caps total free spend.

---

## 2. What exists and what is only planned

The brief lists 13 features as current. Checked against `main` today:

| Feature | Status | Evidence |
|---|---|---|
| AI Quran Coach (recitation check) | **Built** | `supabase/functions/recitation-analyze`, `services/asr` (Whisper on Cloud Run) |
| AI Hifz Coach (SM-2, recite-from-memory test) | **Built** | `hifz_*` tables and RPCs, `ARCHITECTURE.md` "Hifz scheduling" |
| Quran Search (keyword + semantic) | **Built** | `supabase/functions/quran-search`, Voyage + pgvector |
| Daily Adhkar | **Built** | `adhkar*` tables, `features/adhkar` |
| Progress tracking | **Built** | `get_dashboard`, `get_weekly_summary`, `daily_activity` |
| Gamification (XP, levels, streaks, freezes) | **Built** | `xp_rules`, `achievements`, streak freeze logic |
| Annual subscription ($29.99, 7-day trial) | **Built in code; not yet in the stores** | RevenueCat SDK + `revenuecat-webhook`; products still to be created (`BLOCKERS.md` #10, #12) |
| Teacher circles (halaqa mode) | **Planned** | PR #14, "build" under the no-lawyer decision |
| Asynchronous teacher feedback (tasmee') | **Planned** | PR #14 |
| Verified teacher profiles | **Planned** (verified by audition/vouching, not ID) | PR #14 |
| Family plan | **Planned** | PR #14, proposed $49.99/yr (inference) |
| Private learning circles | **Planned** | PR #14 |
| Optional donations | **Not designed** | This document, §6 |

There are **no users yet** and the app is not in the stores. Everything below is a forecast, not a measurement.

---

## 3. Unit economics: what one user earns and costs

### 3.1 Revenue per paying user (checked prices)

| Item | Value | Basis |
|---|---|---|
| Store fee on subscriptions | **15%** | Apple Small Business Program (under $1M proceeds a year); Google subscriptions are 15% from day one |
| VAT inside the store price | ≈ 13% blended in default storefronts **(inference)** | KSA 15%, UAE 5%, Jordan 16%; the store deducts it before paying you |
| Net from a $29.99 annual (Gulf) | **≈ $22.56** | 29.99 ÷ 1.13 × 0.85. Matches the investor memo's ≈ $22 |
| Net from a $4.99 month (Gulf) | ≈ $3.75 | same formula |
| Net from a $6.99 annual / $0.99 month (Egypt, Pakistan, Indonesia) | ≈ $5.21 / $0.74 | `BLOCKERS.md` regional prices |
| RevenueCat | **1% of gross revenue** above $2.5k monthly tracked revenue; free below it | RevenueCat pricing page |
| Blended net per paying subscriber per year | **≈ $20** conservative, ≈ $25 if Gulf-heavy | model; 60% annual / 40% monthly |

### 3.2 Cost per user (checked prices)

| Cost | Value | Basis |
|---|---|---|
| Premium "Ask" on Claude Sonnet 5.5 | ≈ **$0.021** per answer | $2 / $10 per million tokens; 5.5k in + 1k out (`BLOCKERS.md` §4) |
| Free "Ask" on Claude Haiku 5.5 | ≈ **$0.001** per answer | $0.10 / $0.50 per million tokens |
| Recitation ASR (Whisper-base on Cloud Run CPU) | ≈ $0.0003–0.0005 per audio minute (env uses $0.001) | Cloud Run prices, `docs/roadmap/live-correction-and-tajweed.md` (PR #13) |
| Embeddings (voyage-3.5) | $0.06 per million tokens; a search costs ≈ $0.00002 | Voyage pricing page |
| Supabase Pro | $25/month incl. 100k MAU, 250 GB egress, 100 GB storage, 2M function calls, Micro compute | Supabase pricing |
| Supabase overage | $0.00325 per MAU, $0.09 per GB egress, $2 per million function calls; compute Small $15, Medium $60, Large $110 per month | Supabase pricing |
| Audio storage | ≈ $0 | Recordings are deleted after every analysis (`recitation-analyze` line 197) |

**What this means:** the recitation coach, the core of the product, is almost free to run (fractions of a cent per
check). The expensive line is the **Sonnet-powered Ask** feature: one Premium question costs about as much as
40 recitation minutes. PR #13's on-device live tracker removes per-minute server cost for live correction, but since
ASR is already cheap it changes cost much less than it changes the product.

### 3.3 The number that matters

On conservative assumptions an average active user brings in **≈ $0.04 per month**
($0.47 a year). The current free-tier AI hard cap is **$0.15 per month**. See §4.4.

---

## 4. Financial audit

### 4.1 Revenue model
Freemium subscription, no ads. This is right for the mission and the market (free Quran apps are the norm), but it
means **98% of users pay nothing** and the 2% carry everything. RevenueCat's 2026 benchmarks put the median freemium
download-to-paid rate at ≈ 2.1% (day 35) and the median MEA trial-to-paid rate at ≈ 19.5%, consistent with the
investor memo's ≈ 20%. The model therefore uses **2% of MAU paying** as the conservative case.

### 4.2 Subscription model
- **Price is low for the category.** The education median is ≈ $44.99/year and $9.99/month (RevenueCat 2026).
  Tarteel's App Store listing shows Premium at $12.99–$19.99/month and $239.99/year (Adapty paywall library). Asmi3ni at
  $29.99/$4.99 is a deliberate value position. **Keep it for launch**; there is room to test a higher Gulf annual
  price after retention is proven, never before.
- **Renewal is the weak point.** RevenueCat reports ≈ 72% of annual subscribers cancelling in year one (2026) and
  ≈ 27–28% of yearly subscribers retained after a year. Most of an annual subscriber's value is the first payment.
- **The regional tier dilutes revenue.** A payer in Egypt nets ≈ $5 a year against ≈ $22.56 in Riyadh. If the app
  spreads in Egypt (likely, it is the largest Arabic market), MAU grows faster than revenue.

### 4.3 Donation model
Not built. Must be designed as **tips and gifts through store billing**, not charity (legal reasons in §6.1). On its
own it is small: modelled at ≈ 17% of subscription revenue, which is generous for tips.

### 4.4 Cost structure and AI costs
At 1M MAU (conservative), AI is ≈ 43% of revenue, infrastructure ≈ 17%, people ≈ 25%. The AI line is controlled by two
settings, not by usage:

1. **Payers:** capped at 50% of what they paid (`ARCHITECTURE.md`). Safe by design. Typical use is ≈ $0.35/month.
2. **Free users:** capped at **$0.15/month each**. Typical use is ≈ $0.01/month, so the model is fine *on average*.
   But the cap, not the average, is your exposure: if a spike of free users actually uses what the cap allows,
   1M free MAU costs **$150,000 a month** against ≈ $40,000 of monthly revenue. **Guest accounts make this worse:**
   `signInAnonymously()` gives every new device its own $0.15. There is **no global ceiling** on total free spend.

### 4.5 Infrastructure and scalability
Cheap until ≈ 100k MAU (≈ $30–70/month), then it scales roughly linearly: $0.00325 per MAU above 100k, egress, and
larger compute. Modelled at ≈ $6,700/month at 1M MAU. The architecture will hold; this is not a risk, provided the
Quran text and translations ship inside the app (they are content, not per-user data).

### 4.6 Customer acquisition
**Paid acquisition loses money**, as the investor memo found. With ≈ $20 net per payer in year one, ≈ 30% renewal,
and 2% of installs ever paying, an install is worth ≈ $0.50. Arabic-market CPI for education apps is usually above
that **(inference)**. Growth must come from teachers (halaqa mode), parents (family plan), word of mouth around
Ramadan, and store search. That is slower, so the time-to-scale in every scenario is years, not months.

### 4.7 Can it be profitable, and at what scale?

| Milestone | Conservative | If the plan works |
|---|---|---|
| Covers its own servers and AI | ≈ 2,000 MAU | ≈ 1,000 MAU |
| Pays the founder $30k/yr (≈ $2,500/month) | ≈ 840,000 MAU | ≈ 61,000 MAU |
| Profit at 1M MAU after founder pay | ≈ $32k/yr | ≈ $549k/yr |

"Conservative": 2% paying, 55% of payers in full-price markets. "Plan works": 4% paying, 75% full-price. Profit is not
smooth: costs step up when paid help is needed (part-time support from 10k MAU, a small team from 300k), so there
are dips between the four scale points (for example ≈ −$5k at 150k MAU conservative).

### 4.8 Biggest financial risks, ranked

1. **Founder bandwidth.** One person builds, supports, moderates teacher and parent features, and does marketing.
   Burnout ends the project before money does. Every planned feature that adds moderation (circles, teacher inboxes)
   is a time cost, not a server cost.
2. **Free AI exposure** (§4.4). The only path to a sudden, large bill.
3. **Low conversion or Egypt-heavy mix.** At 1% paying and 40% full-price payers the model loses money at every scale.
4. **Annual non-renewal.** If renewals are 20% instead of 30%, lifetime value falls ≈ 10%, and growth must come only
   from new payers.
5. **Store dependency.** One rejected update (for example a donation button that breaks guideline 3.2.2) or a
   suspended developer account stops all revenue. All billing goes through two companies.
6. **Content licences.** EveryAyah audio, translations, tafsir and the Whisper checkpoint must allow commercial use
   (`BLOCKERS.md` #18). A takedown removes core features.
7. **Supplier price changes.** Supabase says "pricing may change"; AI prices change yearly (so far downward).
8. **Your own legal status.** You live in Saudi Arabia on (presumably) a residency tied to an employer. Earning app
   income there may need a freelance or business licence; publishing as an individual Jordanian developer with
   payouts to a Jordanian bank may be cleaner. **I cannot verify this without a lawyer; it is a question to ask
   someone who knows residency rules, not a conclusion.**

### 4.9 What could cause bankruptcy
Realistically only three things, and the first two are preventable now:
- A viral spike (or a script creating guest accounts) consuming free AI at the cap, with no global ceiling.
- A spike of non-paying MAU above 100k on Supabase overage while revenue lags months behind (store payouts arrive
  ≈ 30–45 days after the month ends **(inference)**).
- The founder funding a team before revenue supports it.

There is no debt, no office, no fixed contract; the downside of failure is time, not money.

### 4.10 What is likely underestimated
- **Support time:** parents, children's data requests, teacher onboarding, refund questions in Arabic.
- **Seasonality:** Ramadan will bring a spike of installs that mostly leave in Shawwal. Measure MAU and conversion
  outside Ramadan before deciding anything.
- **Time to reach 100k MAU organically:** likely 18–36 months for a solo founder **(inference)**.
- **VAT and the regional tier**, which together cut the "$29.99" headline to ≈ $20 blended per payer.
- **Free-tier AI cost at the cap**, not at the average.
- **Refunds**, which already zero the AI budget, but still cost support time.

---

## 5. Revenue optimisation without losing trust

These raise revenue per user without pressure. Each is compatible with the existing honest-paywall rules.

| Lever | Expected effect (inference) | Why it does not harm trust |
|---|---|---|
| **Route Premium Ask to Haiku 5.5 if quality holds** (scholar-reviewed A/B on 100 questions) | AI cost per payer falls ≈ 80% (≈ $0.35 → ≈ $0.07/month); margin at 1M MAU +≈ $70k–$140k/yr | Same grounded answers, same citations filter; only if a reviewer cannot tell them apart |
| **Gulf-first launch** (Arabic ASO, KSA/UAE/Kuwait/Qatar first) | Raises full-price payer share, the second most important number in the model | Nothing changes for users |
| **Family plan** $49.99/yr, up to 5 profiles | ≈ +15–25% revenue per paying household | Parents buy for children; one honest price |
| **Halaqa mode free for teachers** | Zero-cost acquisition of 20–40 students per teacher | Teachers are never charged; students keep the free tier |
| **Renewal honesty**: remind annual subscribers 7 days before renewal, with what they achieved this year | Fewer refunds and complaints; renewals among those who stay are healthier | The opposite of a dark pattern |
| **Win-back offer** to lapsed subscribers (store promotional offer, once, e.g. first year at 50%) | Recovers a share of the 72% who cancel | Offered once, not countdown timers |
| **Weekly achievement summary** (already built: `get_weekly_summary`) as a notification users opt into | Retention, which drives renewal | Informational, no streak shaming |
| **Support Asmi3ni** (tips) and **gift a year to a student** | ≈ +10–15% of subscription revenue | Optional, explained, rare to appear (§6) |

Rejected: lifetime plans (AI cost continues forever), trials on the monthly plan, countdown timers, "your streak will
die" notifications, religious-reward language in any paywall or support prompt.

---

## 6. Donation strategy

### 6.1 The legal frame (checked)

| Rule | What it says | Consequence |
|---|---|---|
| Apple 3.2.1(vi) / 3.2.2(iv) | Only **approved non-profits** may fundraise inside an app; other apps may collect charity funds only **outside** the app (Safari, SMS) | No "donate to charity" button in the app |
| Apple 3.1.1 | Apps may use in-app purchase to let customers **"tip" the developer**; apps may enable **gifting** of IAP-eligible items to others ("such gifts may only be refunded to the original purchaser and may not be exchanged") | Tips and gifted Premium are allowed, through IAP |
| Google Play payments policy | Play billing is required for in-app digital value; it **must not** be used for "tax exempt donations" | Tips for the app go through Play billing; a real charity donation would need a tax-exempt entity |
| Saudi fundraising bylaw (May 2026, per LexisNexis summary) | Fundraising only through approved electronic channels; people managing campaigns must be Saudi nationals with names submitted to the state | A solo expat developer must **not** run anything that looks like a charitable campaign |

**Design rule:** Asmi3ni accepts **support for the app** and sells **gifts of Premium**. It never says تبرّع (donate),
صدقة, صدقة جارية, وقف or زكاة; it never promises reward; it never issues receipts that look like charity receipts.
A user may privately intend their gift as sadaqah, which is between them and Allah; the app makes no claim.
**This is my reading of public rules, not legal advice.**

### 6.2 What to build

| Product | Store type | Price points | Notes |
|---|---|---|---|
| **One-time support** ("ادعم أسمِعني") | Consumable IAP | $0.99 · $2.99 · $4.99 · $9.99 (nearest local tiers) | Default selection $2.99. Unlocks nothing; says so |
| **Monthly supporter** | Auto-renewing subscription in its own group | $1.99/month | Shows a small supporter mark on the user's own profile only. Cancel any time in the store |
| **Gift a year of Premium to a student** ("أهدِ طالبًا سنة Premium") | Consumable IAP | $29.99 (or the local annual price) | Adds one seat to a pool. Teachers with halaqa mode request seats for named students; the app grants Premium for a year via RevenueCat promotional entitlement **(verify the RevenueCat API before building)** |
| "Sponsor Quran learning" general fund | **Do not build** | — | A general fund sounds like charity. Merge into one-time support |

The gift seat is honest because the buyer gets exactly what they paid for: one specific student gets one year.
Privacy rule: sponsors see only "your gift was given to a student in a halaqa in [country] on [date]". Never a child's
name, photo or recitation. If the pool is not used within 90 days, say so and let the gift go to the next student in
the queue; unused gifts are refundable by the store, not by you.

### 6.3 Placement and timing

| Where | When | Who sees it |
|---|---|---|
| **Profile → "Support Asmi3ni"** row | Always there, never highlighted | Everyone |
| **Quiet card after a real milestone** (a surah fully memorised, 30 days of review, Fatiha mastered) | At most once every 60 days; never in the first 14 days; never during or right after a recitation with errors; never in the trial | Free users and payers alike; payers see "thank you" first |
| **Ramadan, once** | One in-app card in the first week of Ramadan explaining what the app costs to run | Users active for 30+ days |
| **Halaqa teacher screen** | When a teacher has students without Premium, show "students can receive gifted Premium" | Teachers only; the teacher requests, never pays |
| **Never** | Paywall, onboarding, push notifications, adhkar screens, prayer times, after a failed check | — |

Dismissing a card hides it for 60 days. Paying once hides the milestone card for a year.

### 6.4 Copy

**Arabic, milestone card:**
> **ما شاء الله، أتممتَ حفظ سورة الملك.**
> أسمِعني يعمل بفريق من شخص واحد، وبلا إعلانات. إن أحببت أن تساعد في بقائه، يمكنك دعمه بمبلغ بسيط، أو أن
> تُهدي طالبًا في حلقة تحفيظ سنة كاملة من Premium.
> [ادعم أسمِعني] [أهدِ طالبًا] [ليس الآن]

**English, milestone card:**
> **MashaAllah, you have memorised Surat Al-Mulk.**
> Asmi3ni is built by one person, with no ads. If you would like to help keep it going, you can leave a small tip, or
> give a student in a Quran circle a year of Premium.
> [Support Asmi3ni] [Gift a student] [Not now]

**Support screen (both languages), below the amounts:**
> Your support pays for servers and the AI that listens to recitations. It does not unlock anything, and the app
> stays the same whether you support it or not. This is support for an app, not a charitable donation.

**Transparency line** (optional, once a quarter, updated by hand): "Last month Asmi3ni cost $X to run. Supporters
covered Y%." Real numbers build more trust than any copy.

### 6.5 Expected size
Modelled: 0.4% of MAU tip once a year at ≈ $6, 0.1% become $2.99/month supporters, 0.1% gift a student seat
(**all inference**). That is ≈ $0.07 per MAU per year: useful, never a business on its own.

---

## 7. Monetization audit: every idea challenged

| Idea | Verdict | Why |
|---|---|---|
| Donations (charity) | **Remove** | Apple and Google rules and Saudi fundraising law. Replaced by tips and gifts |
| Tips / supporter subscription | **Keep** | Allowed by Apple 3.1.1 and Play billing; optional; small |
| Sponsor a student (gift a year) | **Keep** | Apple 3.1.1 gifting; real value to a named student; also an acquisition channel via teachers |
| Family plan | **Keep, top priority** | Biggest new revenue per household; parents are the buyers in this category |
| Teacher premium tools / analytics | **Remove** | Teachers are the acquisition channel; charging them shrinks the channel to save a few dollars |
| Circle management tools (paid) | **Remove** | Same reason; private circles are a retention feature, not a product |
| Verified teacher subscriptions | **Remove** | Paying to be "verified" destroys the meaning of verified, and the trust of parents |
| Quran achievement certificates (paid) | **Remove** | Without real ijazah verification a certificate misleads; selling it looks like selling religious standing. A free, clearly informal "progress card" to share is fine |
| White-label for schools/associations | **Remove for now** | Needs contracts, invoicing and support (the no-lawyer rule). Associations use halaqa mode free |
| Community sponsorship (mosques, businesses fund seats) | **Defer** | Needs invoicing and probably a legal entity. Individuals can already buy gift seats |
| Paid 1:1 marketplace, live classes | **Remove** (already dropped in PR #14) | Payout provider, video subscription, legal setup |
| Ads | **Remove** | Breaks the trust that the whole brand rests on, and pays very little in Quran apps |

---

## 8. Scenarios

"Users" means **monthly active users**, not downloads. Steady state for one year at that size. Generated by
`python3 tools/financial_model.py`.

### 8.1 Conservative (the case the brief asked for)

2% of MAU pay; 55% of payers in $29.99 storefronts, 45% in the $6.99 tier; 60% annual. Blended ≈ $20.36 net per
payer per year.

| USD per year | 1,000 MAU | 10,000 MAU | 100,000 MAU | 1,000,000 MAU |
|---|---:|---:|---:|---:|
| Paying subscribers | 20 | 200 | 2,000 | 20,000 |
| Subscription revenue (net) | 407 | 4,071 | 40,711 | 407,108 |
| Tips, supporters, gift seats (net) | 68 | 676 | 6,760 | 67,601 |
| **Total net revenue** | **475** | **4,747** | **47,471** | **474,709** |
| AI (Claude, ASR, embeddings) | 206 | 2,057 | 20,568 | 205,680 |
| Infrastructure (Supabase, ASR floor, analytics) | 360 | 420 | 5,646 | 80,202 |
| RevenueCat | 0 | 0 | 632 | 6,318 |
| Store accounts + domain | 139 | 139 | 139 | 139 |
| Paid help (not the founder) | 0 | 0 | 12,000 | 120,000 |
| **Total operating cost** | **705** | **2,616** | **38,985** | **412,339** |
| **Profit before founder pay** | **−230** | **2,131** | **8,486** | **62,370** |
| Profit after founder pay ($30k) | −30,230 | −27,869 | −21,514 | 32,370 |

### 8.2 If the plan works

4% pay; 75% of payers in full-price storefronts. Blended ≈ $25.33 net per payer per year.

| USD per year | 1,000 MAU | 10,000 MAU | 100,000 MAU | 1,000,000 MAU |
|---|---:|---:|---:|---:|
| Paying subscribers | 40 | 400 | 4,000 | 40,000 |
| **Total net revenue** | **1,081** | **10,809** | **108,087** | **1,080,873** |
| **Total operating cost** | **786** | **3,432** | **47,951** | **501,998** |
| **Profit before founder pay** | **295** | **7,377** | **60,137** | **578,875** |
| Profit after founder pay ($30k) | −29,705 | −22,623 | 30,137 | 548,875 |

### 8.3 Sensitivities (what moves the result most)
1. **Paying share.** Each +1 point of MAU paying adds ≈ $160k/yr of profit at 1M MAU (≈ $200k revenue minus their AI).
2. **Full-price payer share.** Moving from 55% to 75% adds ≈ $5 per payer per year.
3. **Premium AI model.** Haiku instead of Sonnet for Ask saves ≈ $3.40 per payer per year (if quality holds).
4. **Free AI at the cap instead of the average:** ≈ −$1.6M/yr at 1M MAU. This is the bankruptcy case.

### 8.4 Assumptions (all editable in the script)
- Prices, store fee, RevenueCat, Supabase and AI token prices: checked (sources below).
- VAT 13% blended in default storefronts, 14% in low-price ones: inference.
- Average free MAU uses $0.01 of AI a month; payers $0.35: inference from limits and token prices.
- 20 MB egress per MAU per month (Quran text bundled in the app), 60 function calls per MAU per month: inference.
- Analytics/crash reporting beyond free tiers: $200/month from 20k MAU, $1,000 from 200k: inference.
- Supabase compute: Small from 5k, Medium from 30k, an XL-class instance plus a read replica from 200k (≈ $810/month,
  XL/replica price is inference).
- Paid help: $1k/month from 10k MAU, $3k from 100k, $10k (≈ 3 people in Amman) from 300k: inference.
- Founder pay $2,500/month: inference.

---

## 9. Would I invest my own money?

**As an angel with a small cheque and a clear exit test: yes. As a venture fund today: no.**

Why yes:
- The core cost is near zero per user, the cost cap protects margins on payers, and the stack has no fixed
  contracts. Losing is cheap.
- The positioning is differentiated: Arabic-first, honest, and priced far below Tarteel ($239.99/yr) in a market
  that clearly pays for Quran memorisation help.
- The teacher channel and expert labels from tasmee' can become a real data moat for recitation correction.

Why not as a fund:
- Revenue per MAU (≈ $0.04/month) is too low for venture returns without proof of Gulf conversion.
- No users, no retention data, recitation accuracy unproven (PR #11 benchmark still open).
- Solo founder with a day job and residency questions.

**My conditions for putting money in:** (1) the recitation benchmark passes on real users; (2) D30 retention ≥ 15%
outside Ramadan; (3) trial-to-paid ≥ 15% on at least 500 Gulf trials. Until all three hold, the right investment is
the founder's time, not cash.

---

## 10. Top 10 actions, ranked by long-term profit impact

1. **Close the free-AI exposure before launch.** Lower the free monthly AI budget from $0.15 to $0.03 (still ≈ 30
   Haiku answers or 30–60 recitation minutes), require a signed-in account (not guest) for AI after the onboarding
   Fatiha check, and add a **global daily free-tier ceiling** in `ai_budget_settings` (for example $20/day) that
   degrades free AI to "back tomorrow" when hit. Also set spend alerts on Anthropic, Google Cloud and Supabase.
   *Prevents the only bankruptcy path.*
2. **Prove recitation accuracy (PR #11) and launch Gulf-first.** Nothing else matters if the coach is wrong. Lead
   with KSA/UAE storefronts and Arabic ASO; the full-price payer share is the second biggest lever in the model.
3. **Build halaqa mode and async tasmee' for teachers, free.** The only acquisition channel with near-zero cost and
   20–40 students per sale. Measure D30 of halaqa students against solo users.
4. **Ship the family plan ($49.99/yr, up to 5 profiles).** Highest revenue per household; parents are the real buyer.
5. **A/B Premium Ask on Haiku 5.5 versus Sonnet 5.5** with a scholar reviewing blind. If they cannot tell, switch;
   it cuts AI cost per payer by ≈ 80%.
6. **Protect renewals honestly.** Year-in-review before the renewal date, a 7-day reminder, a one-time win-back offer
   for lapsed users. Renewal is where lifetime value is lost.
7. **Add "Support Asmi3ni" and "Gift a student a year"** exactly as in §6, after action 3 (gift seats need teachers).
8. **No paid ads** until you can measure LTV per install above CPI for three months. Put effort into Ramadan, store
   search, referrals (already built), and teachers.
9. **Ship Quran text, translations and tafsir offline** in the app bundle. Cuts egress and Supabase load, and works
   with no network, which users value.
10. **Keep the team at one until ≈ 60k MAU with ≥ $5k/month net revenue.** Use part-time help for support first,
    not development. Resolve your own legal status for earning app income before revenue becomes material.

---

## 11. The final business model

**One sentence:** a free, ad-free Quran companion that is excellent between lessons with a teacher, paid for by a
minority who want deeper AI coaching and family features, and supported by people who want to give students access.

### Free forever
- The full Quran: reading, audio, translations, tafsir, offline.
- Daily adhkar, prayer-related reminders, bookmarks.
- Keyword Quran search (unlimited); limited semantic search.
- Hifz plan, spaced review queue, and progress tracking. **Reviews are never locked.**
- AI recitation checks and Ask within a small weekly allowance (enough to make the habit, cheap enough to be safe).
- Streaks, XP, levels, achievements (no shaming, freezes kept).
- **Everything for teachers:** halaqa mode, async tasmee' inbox, student overview, teacher profile.
- Joining a halaqa or a private circle.

### Premium ($4.99/month, $29.99/year with a 7-day trial; regional prices unchanged)
- Higher AI coaching limits: recitation checks, hifz tests, longer recordings, Ask.
- Full weak-word history and detailed recitation insights.
- Unlimited async tasmee' submissions to your teacher (free tier: a few per week).
- Live on-device mistake tracking when PR #13 ships.
- **Family plan ($49.99/year):** up to 5 profiles, parent dashboard.

### Accepts support
- "Support Asmi3ni": one-time tips and a $1.99/month supporter subscription, both through the stores.
- "Gift a student a year of Premium", distributed through teachers.
- No charity, sadaqah, waqf or zakat language anywhere, no reward promises, never on the paywall.

### Removed completely
- Charity fundraising inside the app.
- Paid features for teachers, paid verification, paid certificates.
- Paid 1:1 marketplace, live video classes, open communities, public profiles of learners.
- White-label and B2B invoicing (until there is an entity and a contract template).
- Ads, lifetime plans, monthly trials, countdown timers, guilt-based notifications.

**Why this is the strongest version:** every free feature is cheap to run, every paid feature has a hard cost cap,
teachers bring users at no cost, parents bring the highest revenue, and nothing in it would embarrass the app in
front of a sheikh or a parent. That trust is the asset; the subscription is how it pays the bills.

---

## Sources (checked 25 November 2026)

- Supabase pricing: https://supabase.com/pricing (Pro $25, 100k MAU, overage rates, compute add-ons)
- RevenueCat pricing: https://www.revenuecat.com/pricing (1% above $2.5k MTR)
- RevenueCat, App Store fees (updated Oct 2026): https://www.revenuecat.com/blog/engineering/app-store-fees
- Apple App Store Small Business Program: https://developer.apple.com/app-store/small-business-program/
- Apple App Review Guidelines 3.1.1, 3.2.1(vi), 3.2.2(iv): https://developer.apple.com/app-store/review/guidelines/
  (read via a summary of the UK edition; re-read the exact wording before submitting the support feature)
- Google Play payments policy: https://support.google.com/googleplay/android-developer/answer/9858738
- Saudi fundraising bylaw summary (May 2026): https://www.lexisnexis.com/blogs/ae-legal/b/insights/posts/ksa-fundraising-regulation-bylaw-enters-into-force
- RevenueCat State of Subscription Apps 2026: https://www.revenuecat.com/state-of-subscription-apps and
  https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026
- Tarteel paywall prices: https://adapty.io/paywall-library/tarteel/
- Voyage AI pricing: https://docs.voyageai.com/pricing
- Claude API prices (Haiku 5.5 $0.10/$0.50, Sonnet 5.5 $2/$10 per million tokens): Anthropic model pricing, Nov 2026
- Cloud Run pricing via PR #13: https://cloud.google.com/run/pricing
- Investor memo figures (≈ $22 net per annual subscriber, ≈ 20% trial-to-paid, paid ads lose money): as summarised in
  PR #14, `docs/strategy/ecosystem-and-teacher-marketplace.md` §15
