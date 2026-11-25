# 8. The 5-second message and the launch campaign

---

## 8.1 If we had five seconds

> ### سمّع حفظك متى شئت.
> ### كلمة بكلمة، بلا موعد وبلا حرج.
>
> **Recite your hifz any time.**
> **Checked word by word. No appointment, no embarrassment.**

Shown as: the first frame of every video ad, screenshot 1, the landing page H1, the feature graphic, and the
promotional text. Visual: the user's Al-Fatiha on screen, green words, one red word.

### Why this, after being critical of every alternative

| Candidate | Why it loses in 5 seconds |
|---|---|
| "Your AI Quran teacher" | "AI" triggers distrust on sacred text; "teacher" overclaims and invites scholar backlash. Says *what it is*, not *what I get* |
| "Discover mistakes you never knew you had" | Strong curiosity, but leans on fear, implies accuracy we haven't measured, and makes the first false flag fatal |
| "Real-time recitation correction" | Not true today. A Tarteel user would call it out in a review on launch day |
| "Never forget what you memorized" | Great for paying, weak for installing: it speaks only to people already memorizing and needs explaining ("how?") |
| "Memorize the Quran with AI" | Generic; every Quran app can say it; no reason to act now |

**Why ours wins:**
1. **Verb first, and it's a ritual verb.** "سمّع" tells an Arabic speaker the whole product in one word, with a memory
   attached.
2. **"متى شئت / any time"** removes the real barrier (no listener, no time slot).
3. **"كلمة بكلمة / word by word"** makes it concrete and believable without a number.
4. **"بلا حرج / no embarrassment"** names the hidden adult objection nobody else names.
5. **It is fully true today** and matches the first screen after install (Al-Fatiha), so ad → store → app is one
   continuous promise.
6. **It is the brand name, explained.** أسمِعني = "let me hear you". Every impression teaches the name.

### Brutal self-critique (what could still go wrong)

- **"Hifz" excludes people who don't think they memorized anything.** Mitigation: everyone memorized Al-Fatiha; the
  CTA is "recite Al-Fatiha", and the reciter-intent variant uses "سمّع تلاوتك / Recite to the coach".
- **"Any time" vs 10 free checks a week.** Truthful (you can check any time of day), but a user who reads it as
  "unlimited" may feel misled. Mitigation: the limit is stated on screenshot 8, in the description and in the FAQ.
- **Accuracy is the single point of failure.** Mitigation: launch gate below.

---

## 8.2 Launch gates (do not spend money on acquisition until these are true)

| Gate | Threshold | How it is measured |
|---|---|---|
| Accuracy on Al-Fatiha and Juz Amma | False "wrong/missed" flags on correctly recited words ≤ 3% per clip; ≤ 1 false flag on a correct Al-Fatiha in 95% of clips | `docs/accuracy-benchmark.md` on branch `claude/project-thread-yp9dso` |
| "Unclear" state works | Low-confidence words show as unclear, not wrong | Benchmark report |
| Stability | Crash-free sessions ≥ 99.5% | Sentry |
| Activation in beta | ≥ 60% of testers complete the Al-Fatiha check; D1 ≥ 35% | PostHog |
| Store assets | Screenshots, descriptions, landing page live; privacy labels done | `BLOCKERS.md` §2–3 |

If accuracy misses the gate, still launch organically (friends, halaqat, beta), but no paid ads and no influencers:
paid traffic amplifies whatever the first result is.

---

## 8.3 Campaign timeline (to Ramadan 2027)

Dates are approximate: Ramadan 1448 is expected to begin around **8 February 2027**; 15 Sha'ban ≈ 23 January; Eid
al-Fitr ≈ 9–10 March.

| Phase | Dates | Goal | Key actions |
|---|---|---|---|
| **0. Ready** | now → ~15 Dec | Pass the gates | Run the accuracy benchmark. Produce screenshots and preview video from real app captures. Rebuild `site/index.html` from `05-landing-page.md`. Start Play closed test (12+ testers, 14 days) and TestFlight with 30–50 testers from 2–3 halaqat: they are the source of the first real testimonials (with permission) and the first ratings |
| **1. Soft launch** | ~15 Dec → 9 Jan | Learn conversion before spending | Release in Saudi Arabia, Jordan, UAE, Kuwait. Founder story post. Personal outreach to 20 halaqa teachers and Quran centres (teacher message below). Apple Search Ads, small budget, exact-match Arabic keywords only, to measure tap-through and conversion per keyword. First Product Page Optimization test (screenshot 1) |
| **2. Pre-Ramadan** | 9 Jan (1 Sha'ban) → 7 Feb | Build the install base and the habit before the peak | Promotional text switches to Ramadan prep. Creator wave (8.5). "Prepare your hifz for Ramadan" content series. Submit Ramadan in-app event 2+ weeks ahead (only if the Ramadan plan ships) |
| **3. Ramadan** | 8 Feb → 9 Mar | Peak installs; convert engaged users | Ramadan in-app event and promotional text. Ads scale only on creatives that passed the CPI/activation bar. Last-ten-nights review push (in-app, not ads). Ads may run through the last ten nights, but no copy ever uses Laylat al-Qadr as urgency |
| **4. Keep it** | Eid → end of Shawwal | Retain the Ramadan cohort | "Keep what you revised in Ramadan" messaging; Shawwal 6-day plan; weekly Friday card; win-back offers for lapsed trials (`docs/store-setup.md` §3) |

### Teacher outreach message (WhatsApp, personal, from the founder)

> السلام عليكم ورحمة الله شيخ [الاسم]،
> أنا [الاسم]، طوّرت تطبيقًا اسمه «أسمِعني» يساعد الطلاب على التسميع والمراجعة بين حلقاتكم: يتلو الطالب بصوته، فيرى
> الكلمات التي أخطأ فيها، وتُجدوَل مراجعته تلقائيًا. لا يغني عن الشيخ أبدًا، بل يجعل الطالب يأتيكم وقد راجع.
> هل تسمح لي أن أعطي طلابكم وصولًا مجانيًا تجريبيًا وأسمع ملاحظاتكم؟ جزاكم الله خيرًا.

Why it works: respect for the teacher's role, a clear benefit *to the teacher* (students arrive prepared), and a free
pilot. Teachers are the most trusted recommenders in this market and cost nothing.

---

## 8.4 Paid acquisition plan (lean, measured, killable)

Budget is the owner's decision; below is a learning budget sized for a solo founder. All numbers are **assumptions to
validate in Phase 1**, not benchmarks.

| Channel | Why | Phase 1 test budget | Kill if | Scale if |
|---|---|---|---|---|
| **Apple Search Ads** (Saudi, Arabic exact match: تسميع القرآن، حفظ القرآن، مراجعة الحفظ، تحفيظ) | Highest intent; also tells us keyword conversion for ASO | $500 | Cost per first recitation > $3 after 300 taps | Cost per trial < $15 |
| **Snapchat Ads** (Saudi, 18–45) | Dominant in Saudi Arabia; vertical video fits the 8.1 creative | $500 | Cost per install > $2.5 or activation < 50% | Cost per trial < $20 |
| **TikTok / Instagram Reels** | Reach for the "متى آخر مرة" hook | $500 | Same as Snapchat | Same |
| **Google App Campaigns** | Android share in KSA, Jordan, Egypt | $300 | Activation < 50% | Cost per trial < $15 |

**The metric that matters is cost per trial and cost per first recitation, not cost per install.** A cheap install
that never recites is worth nothing. Optimize every network for the first-recitation event once it has volume.

LTV guide for bids: annual SAR 109.99 ≈ $29.99; after Saudi VAT (included in the price) and the 15% store fee the net is
≈ $22. At 55% trial-to-paid, a trial is worth ≈ $12 in first-year net. **Do not pay more than $10 per trial** until 30-day retention of payers is
known.

### Video ad scripts (vertical, 15–20 s, no music, real app capture)

**Ad A: «متى آخر مرة؟» (hook #2 → #1)**
| Sec | Picture | Text on screen | Voice (optional, male and female versions) |
|---|---|---|---|
| 0–2 | Close-up: phone on a prayer mat corner, night | متى آخر مرة سمع أحدٌ تلاوتك؟ | — |
| 2–7 | Hand taps record; waveform; a voice reciting Al-Fatiha | سمّع حفظك متى شئت | (recitation) |
| 7–11 | Result: green words, one red word, callout | كلمة بكلمة | — |
| 11–15 | At-risk ayahs → "Next review in 6 days" | احفظ… ولا تنسَ | — |
| 15–18 | Logo + CTA | أسمِعني · سمّع الفاتحة مجانًا | — |

**Ad B: «جزء عمّ» (hook #11, segment A)**
Text sequence: «حفظت جزء عمّ صغيرًا» → «هل ما زال معك؟» → recording of Surah An-Naba → result → «سمّع، وأسمِعني يتذكّر عنك ما تحتاج مراجعته» → CTA.

**Ad C: «الساعة ١١ ليلًا» (hook #7, privacy)**
Status bar 23:40 → «تريد أن تسمّع… ولا أحد مستيقظ؟» → record → result → «لا يسمعك إلا المدرّب. وتُحذف تسجيلاتك بعد التحليل.» → CTA.

**Ad D: teacher (when a real teacher agrees, with permission)**
A real halaqa teacher, in their own words, on why students who review between sessions progress faster. No scripted
claims about the app's accuracy.

Production rules: real app captures only; no actors pretending to be users; recitation by the founder or consenting
volunteers; no music; modest visuals; Arabic first, English cut for Jordan/UAE expat audiences.

---

## 8.5 Creators (organic and paid)

| Tier | Who | Ask | Rule |
|---|---|---|---|
| 1 | Quran teachers with small, engaged followings (5K–50K) on Snapchat, TikTok, Instagram | Try it for a week; share honestly; free Premium for their students | They say what they actually found, including limits. Paid posts are labelled as ads (Saudi GCAM rules) |
| 2 | Muslim lifestyle and productivity creators | The "Ramadan prep: 5 minutes a day" series | No religious claims from non-scholars |
| 3 | Well-known reciters | **Do not** ask them to endorse AI accuracy | Reputational risk to them and to us |

---

## 8.6 Conversion targets (the scoreboard)

All events already exist unless marked new. Review weekly; change one thing at a time.

### Store

| Metric | Source | Target (Saudi, Arabic) | First lever if missed |
|---|---|---|---|
| Search impression → page view or install (App Store "conversion rate") | App Store Connect | ≥ 8% from search | Screenshot 1, subtitle |
| Product page view → install | App Store Connect, Play Console | ≥ 30% iOS, ≥ 25% Play | Screenshots 1–3 (PPO) |
| Search Ads tap-through rate | Apple Search Ads | ≥ 8% on exact match | Keyword relevance |
| Landing page → store click | store campaign tokens | ≥ 25% | Hero CTA |

### In-app (from `docs/subscription-growth-audit.md` §16, unchanged)

| Stage | Event | Target |
|---|---|---|
| Install → onboarding started | `onboarding_started` | 95% |
| First recitation (Al-Fatiha) | `recitation_completed {source: onboarding}` | ≥ 65% of starters |
| Hifz plan created | `hifz_plan_created` | ≥ 60% |
| Notifications granted | `notification_permission_result` | ≥ 50% |
| D1 return | `hifz_reviewed` on day 1 | ≥ 45% |
| D7 / D30 retention | PostHog | ≥ 25% / ≥ 15% |
| Value gate passed (3 active days) | `value_gate_passed` | 30–35% of installs |
| Install → trial | `purchase_completed {trial: true}` | 8–11% |
| Trial → paid | RevenueCat | 55–60% |
| Install → paid (day 30) | RevenueCat | 4.5–6% |
| Refund rate | RevenueCat | ≤ 3% of purchases |

### Reputation and virality

| Metric | Target |
|---|---|
| Rating (Saudi App Store) | ≥ 4.7 |
| Ratings count before Ramadan | 500+ (in-app review prompt only after a positive moment: clean Al-Fatiha, 7-day streak, surah memorized; max once per 90 days) |
| Shares per WAU per week | ≥ 0.15 |
| K-factor by month 3 | ≥ 0.25 |

### Phase targets (to be revised after Phase 1 data)

| Phase | Installs | Trials | Paying subscribers (end of phase) |
|---|---|---|---|
| 1. Soft launch | 1,500–3,000 (organic + test ads) | 120–300 | 70–170 |
| 2. Pre-Ramadan | 5,000–10,000 | 400–1,000 | 300–700 cumulative |
| 3. Ramadan | 15,000–30,000 | 1,200–3,000 | 1,000–2,300 cumulative |

These follow from the funnel above; they are not forecasts of demand. The business plan (`docs/01-business.md` in the
project files) puts breakeven at roughly 150–250 paying subscribers at the old, lower price; at $29.99/year it arrives sooner.

---

## 8.7 Experiment backlog (in priority order)

| # | Hypothesis | Test | Metric | Decision rule |
|---|---|---|---|---|
| 1 | Curiosity ("be heard") opens better than loss ("keep it") | PPO screenshot 1: recitation result vs at-risk ayahs | Page view → install | 90% confidence, 7+ days |
| 2 | Naming embarrassment raises installs from adults 30+ | Ad C vs Ad A | Cost per first recitation | 20% better at equal spend |
| 3 | Showing the user's own progress on the paywall raises trials | Paywall P2 on/off | Paywall → trial, refunds | +10% relative, refunds not worse |
| 4 | A Premium week as invite reward beats XP | Invite reward A/B | Invites sent, K-factor | K +0.05 |
| 5 | The Hijri yearly report drives shares and renewals | Launch for 1 Muharram 1449 | Share rate, annual renewal rate | Share rate ≥ 30% |
| 6 | A celebratory clean-Fatiha result + "try a surah you memorized long ago" lifts D1 | Onboarding result screen variant | D1 | +3 points |

---

## 8.8 What the owner needs to do (in order)

1. Approve the hook and the 5-second message (this file §8.1).
2. Run the accuracy benchmark (gate) before any paid spend.
3. Produce the 8 screenshots from real captures using `02-screenshots.md` (a designer can do it in 1–2 days with the
   exact copy and layout here).
4. Paste the store copy from `03-store-listings.md` when the store accounts are approved (`BLOCKERS.md` §2).
5. Approve rebuilding `site/index.html` from `05-landing-page.md` (an implementation thread can do it).
6. Approve the paywall changes P1–P6 and the share cards (implementation threads).
7. Decide the Phase 1 test budget (§8.4).
