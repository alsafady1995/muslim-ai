# Asmi3ni / أسمِعني: Store and Launch Marketing Package

Everything needed to put Asmi3ni in the App Store and Google Play and launch it: psychology, hooks, screenshots,
store copy, subscription page, landing page, competitor positioning, sharing and the launch campaign.
Arabic comes first everywhere (Saudi Arabia and the Gulf are the launch market); English follows.

Written against the code in `main` on 25 November 2026 (`app/`, `tools/gen_arb.py`, `ARCHITECTURE.md`, `BLOCKERS.md`)
and the earlier audits (`docs/full-audit.md`, `docs/subscription-growth-audit.md`, the competitive analysis on branch
`claude/project-thread-ewg32p`). Every feature claim below is something the app does today, or is marked **(to build)**.

| # | File | What it gives you |
|---|---|---|
| 1 | [01-psychology-and-hooks.md](01-psychology-and-hooks.md) | Who the user is, what hurts, what they fear, 20 hooks, the winning hook and why |
| 2 | [02-screenshots.md](02-screenshots.md) | The 8-screenshot persuasion sequence: exact headlines, copy, layout, hierarchy, goal |
| 3 | [03-store-listings.md](03-store-listings.md) | App Store name, subtitle, promo text, keywords, description; Google Play title, short and full description (AR + EN) |
| 4 | [04-subscription-page.md](04-subscription-page.md) | The paywall: every line, every decision, and the changes to make in the app |
| 5 | [05-landing-page.md](05-landing-page.md) | asmi3ni.com, every word, Arabic and English |
| 6 | [06-competitor-positioning.md](06-competitor-positioning.md) | Tarteel, Quran Companion, Muslim Pro, Quran Majeed: weaknesses, blind spots, how we win |
| 7 | [07-virality.md](07-virality.md) | Share cards, milestones, the yearly Quran report, invites, with targets |
| 8 | [08-launch-campaign.md](08-launch-campaign.md) | The 5-second message, the launch plan to Ramadan 2027, budgets, experiments and conversion targets |

---

## The answer in one page

**The emotional problem.** Almost every Muslim who memorized anything lives with a quiet doubt: *"Am I still reciting
this right? Do I still hold what I memorized?"* The traditional cure is **tasmee' (التسميع)**: reciting to someone who
listens and stops you at the slip. Adults rarely have that person anymore. The teacher has other students, the family
is busy, reciting to a person is embarrassing at 35, and expats are far from their halaqa.

**The insight.** The app's name *is* the cure. "أسمِعني" is what a teacher says to a student: *let me hear you*. We are
not selling AI. We are selling the listener everyone lost.

**The winning hook** (Arabic first):

> **سمّع حفظك متى شئت… واعرف أين تعثّرت، كلمة بكلمة.**
> *Recite from memory any time. See exactly where you slipped, word by word.*

**The 5-second message** (store screenshot 1, ad first frame, landing page hero):

> **سمّع حفظك متى شئت.**
> كلمة بكلمة، بلا موعد وبلا حرج.
>
> **Recite your hifz any time.**
> Checked word by word. No appointment, no embarrassment.

**The subscription story** is a different one, and that is deliberate: people install to be *heard*, and they pay to
*keep* what they memorized. The paywall sells "احفظ… ولا تنسَ ما حفظت / Keep every ayah you memorize", backed by the
user's own at-risk ayahs.

**The position against competitors.** Muslim Pro tells you when to pray. Quran Majeed gives you a big library. Tarteel
follows you while you read. **Asmi3ni is the one you recite to, and the one that remembers what you are about to
forget**, with no ads, at about a third of Tarteel's price in Saudi Arabia (SAR 109.99 vs SAR 349.99 a year).

**Conversion targets** (all tracked with events that already exist; details in `08-launch-campaign.md`):

| Stage | Target |
|---|---|
| App Store product page view → install (Saudi, Arabic) | ≥ 30% |
| Install → first recitation (Al-Fatiha in onboarding) | ≥ 65% |
| Day 1 return | ≥ 45%; Day 7 ≥ 25% |
| Install → trial | 8 to 11% |
| Trial → paid | 55 to 60% |
| Install → paid by day 30 | 4.5 to 6% |
| Rating | ≥ 4.7 with 500+ ratings in Saudi Arabia before Ramadan 2027 |
| Shares per weekly active user | ≥ 0.15 per week; invite K-factor ≥ 0.25 by month 3 |

---

## Claims ledger (read before writing any ad)

The fastest way to lose a Quran app's reputation is to promise what the app does not do. Every asset in this package
follows this table. If the app changes, update this table first.

| ✅ We can say (true in `main` today) | ❌ We must not say (yet) | Why not |
|---|---|---|
| Recite aloud and get a word-by-word result: missed, wrong, extra and unclear words | "Real-time" or "live" correction, "corrects you while you recite" | We analyse after you stop recording (seconds later). Live test mode is roadmap item 2 |
| Test your memorization out loud; grading is automatic and schedules the next review | Any accuracy number ("99% accurate", "never misses") | Not measured yet. The accuracy benchmark (branch `claude/project-thread-yp9dso`) must report first |
| A hifz plan with spaced repetition that shows the ayahs at risk of being forgotten | "Improve your tajweed", "tajweed correction", "tajweed coach" | Tajweed today is a "possible short madd" hint only. Full tajweed is Phase 2 |
| Your weak words, collected over time and practised first | "Your personal sheikh/teacher", "replaces your teacher" | Theologically sensitive, invites store rejection and scholar backlash. Say "coach" and "between lessons with your teacher" |
| Ask the Quran: answers cite the ayah or hadith they come from | "Fatwa", "scholar-approved", "certified" | Scholar review (`BLOCKERS.md` #17) is not done |
| Meaning search ("verses about patience") | Mushaf page view, offline Quran, prayer times, athan, qibla, widgets | Not built |
| Morning and evening adhkar, streaks, goals, XP | "Unlimited" AI | Premium has fair-use limits and a cost cap |
| About 10 reciters, all free | "#1", "best", "most accurate", ranking claims | Store policy (Google Play forbids them in metadata), and untrue |
| No ads. No ad tracking. Recordings deleted right after analysis | "No tracking" or "we collect nothing" | We use PostHog (product analytics) and Sentry (crashes). Say **no ad tracking** |
| Arabic and English, written for Arabic speakers | Ratings, reviews, user counts, testimonials | None exist yet. Use clearly marked placeholders only |
| Free plan: 10 recitation checks and 5 AI memorization tests a week, up to 60 seconds each | "Free forever, everything" | Only the core reading, listening, adhkar and self-graded reviews are unlimited free |
| Premium: SAR 109.99/year (≈ $29.99) with a 7-day free trial, or SAR 18.99/month (≈ $4.99), no trial on monthly | "7-day free trial" next to the monthly plan | Trial is on annual only |

**One product fix this package depends on:** add a "this word was right" tap on the recitation result (marks the flag
as disputed, feeds the accuracy set). It turns the biggest objection ("what if the AI is wrong?") into a trust signal,
and it is promised nowhere until it ships. See `04-subscription-page.md` §6.
