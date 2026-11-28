# 7. Virality: moments people *want* to share

Today the app has an invite code (both sides get bonus XP, the inviter gets a streak freeze), verse sharing from the
reader, and the `share_plus` package. Everything below marked **(to build)** is a spec for an implementation thread.

---

## 7.1 The cultural constraint that decides everything: riya'

Sharing one's own worship can feel like showing off (رياء), and many devout users will refuse to post a "my score"
card for that reason. Generic gamified sharing ("I scored 94!") will underperform here and can draw criticism.

Two motives *do* work, and both are rooted in the tradition:

1. **Inviting to good.** "Whoever guides to good has a reward like the one who does it" (Sahih Muslim). Sharing
   framed as *an invitation for someone else to recite* is a good deed, not a boast.
2. **Gratitude and encouragement.** "Alhamdulillah, I finished Surah Al-Mulk" is a normal, accepted thing to say among
   family and friends, especially in private groups (WhatsApp, Snapchat), not public feeds.

**Design rules for every share card:**

- The hero of the card is **an ayah or the surah**, never the user's number.
- Personal numbers are **off by default**; a toggle "أظهر تقدّمي / Show my progress" adds them.
- Every card carries an **invitation**, not a brag: «سمّع أنت أيضًا / Recite with me».
- Default destination: **WhatsApp and Snapchat** (private circles, the dominant channels in Saudi Arabia), then
  Instagram Stories, then X.
- Every card includes the user's invite link (QR on the image, link in the text).
- Card format: 1080 × 1920 (Stories/Status) and 1080 × 1080 (WhatsApp, X). Arabic-first layout, Amiri Quran for ayahs.

---

## 7.2 The shareable moments

| # | Moment | Trigger | Card headline (AR / EN) | Card content | Why people share | Status |
|---|---|---|---|---|---|---|
| 1 | **Surah memorized** | `hifz_milestones` (exists) | **أتممتُ حفظ سورة الملك، الحمد لله** / **I've memorized Surah Al-Mulk, Alhamdulillah** | Surah name in calligraphy, its first ayah, date (Hijri + Gregorian), invite line «ادعُ لي بالثبات، وسمّع أنت أيضًا» / "Pray I keep it, and recite with me" | Gratitude, asks for du'a (very natural to share), invites | **To build** (milestone exists; card doesn't) |
| 2 | **First Al-Fatiha check** | `recitation_completed {source: onboarding}` | **سمّعتُ الفاتحة اليوم. متى سمّعتها آخر مرة؟** / **I recited Al-Fatiha to a coach today. When did you last?** | The ayah, no score by default, QR | Curiosity transfer: the receiver asks themselves the hook question | **To build** |
| 3 | **Weekly review card** | Weekly summary (exists), Fridays | **أسبوعي مع القرآن** / **My week with the Quran** | Active days, reviews, ayahs safe (optional), a weekly ayah | Habit identity; Friday is a natural sharing day | **To build** |
| 4 | **At-risk ayah recovered** | Item moves from at-risk back to safe | **رجعت آية كنت سأنساها** / **I brought back an ayah I was about to forget** | The ayah itself | Relief, a small story; makes the forgetting model visible to non-users | **To build** |
| 5 | **Streak milestones** (7, 30, 100 days) | Streak RPC (exists) | **٣٠ يومًا مع القرآن، بفضل الله** / **30 days with the Quran, by Allah's grace** | A streak ring, an ayah about steadfastness | Mild identity signal; gratitude framing | **To build** |
| 6 | **Verse card** | Reader, Ask, search (exists as text share) | The ayah | Ayah + reference + translation, «عبر تطبيق أسمِعني» | Sharing an ayah is common and sadaqah-like | **Exists as text; upgrade to image** |
| 7 | **Ramadan khatmah / review** | Ramadan plan (to build) | **رمضاني مع أسمِعني** / **My Ramadan with Asmi3ni** | Juz reviewed, nights active | Seasonal, socially accepted to share | **To build** |
| 8 | **Yearly Quran report** | 1 Muharram (Hijri new year) and/or Eid al-Fitr | **سنتي مع القرآن ١٤٤٨** / **My Quran year 1448** | Swipeable 5-card story: days with the Quran, ayahs memorized, surahs safe, most-practised word, favourite reciter; last card: an ayah and «ادعُ صديقًا يسمّع معك» | Year-in-review is the strongest single organic moment for subscription apps; the Hijri new year makes it ours, not a copy | **To build** |

### The yearly report in detail (moment 8)

| Card | العربية | English | Data (exists?) |
|---|---|---|---|
| 1 | في هذه السنة كنتَ مع القرآن **١٨٤ يومًا** | This year you were with the Quran on **184 days** | `daily_activity` ✓ |
| 2 | حفظتَ **٢١٢ آية**، وراجعتَ **١٬٤٠٣ مرة** | You memorized **212 ayahs** and reviewed **1,403 times** | `hifz_items`, `hifz_reviews` ✓ |
| 3 | **٧ سور** في أمان الآن | **7 surahs** are safe now | SM-2 state ✓ |
| 4 | الكلمة التي أتقنتها بعد تعب: **﴿…﴾** | The word you finally mastered: **…** | weak words history ✓ |
| 5 | ﴿وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا﴾ · سمّع معي في السنة الجديدة | "…and recite the Quran with measured recitation" · Recite with me this new year | invite link ✓ |

Numbers are examples. Private by default; the user picks which cards to share. Also the natural annual **renewal
moment**: the subscription audit's "30 days before renewal" message links here.

---

## 7.3 Invites: make the reward match the product

Current: invitee and inviter get bonus XP; inviter gets a streak freeze. XP is not something people recruit friends
for.

**Proposal (to build, needs a RevenueCat promotional entitlement; see `docs/full-audit.md` G3):**

| Who | Reward | Why |
|---|---|---|
| Inviter | **One week of Premium** per friend who completes their first recitation (max 4 a year), plus the streak freeze | A reward in the product's own currency; tied to activation, not install, so it can't be farmed |
| Invitee | **One week of Premium** after their first recitation | Experiencing Premium early raises later conversion |
| Both | Shown as «هدية من [الاسم]» / "A gift from [name]" | Gifting frame fits the culture; "referral" sounds commercial |

Invite copy (shared text):
- AR: «أستخدم أسمِعني لأسمّع حفظي كل يوم، ويُريني أين أتعثّر كلمة بكلمة. جرّبه وسمّع الفاتحة، وهذا أسبوع مميز هدية مني: [link]»
- EN: "I use Asmi3ni to recite my hifz every day and it shows me where I slip, word by word. Try it with Al-Fatiha, and here's a free Premium week from me: [link]"

AI cost check: a Premium week costs at most the trial-like budget per user and is granted only after activation; it
stays within the 50% rule because promotional grants have their own fixed budget (`promo_monthly_usd`).

---

## 7.4 Family and halaqa loops (the biggest long-term multiplier)

Hifz in the Gulf happens in **families and halaqat**, not alone. Each group that adopts the app brings 5–20 people.

| Loop | How it spreads | Status |
|---|---|---|
| **«سمّع لي» — a parent asks a child to recite into the parent's phone** | The child becomes a user; the parent sees the value | Works today (any account can record); add a "child profile" later |
| **Halaqa challenge**: a teacher creates a group, students join with a code, weekly review leaderboard by *days active*, not scores | Teacher invites 10–30 students at once | **To build** (Quran Companion's best idea, done right) |
| **Family plan**: one subscription, up to 5 profiles, parent sees each child's at-risk ayahs | Parents recruit their children | **To build** (`full-audit.md` G4) |

Leaderboards rank **consistency (days active)**, never accuracy, to avoid shaming and riya'.

---

## 7.5 Targets and measurement

| Metric | Event (add where missing) | Target by month 3 |
|---|---|---|
| Share rate | `share_card_created {moment}` / weekly active users | ≥ 0.15 shares per WAU per week |
| Milestone share rate | shares / `hifz_milestone` | ≥ 25% |
| Share → install | store campaign token per card type (`ct=share_milestone` etc.) | ≥ 3% of share views |
| Invites sent per active user | `invite_shared` | ≥ 0.5 in the first 30 days |
| Invite conversion | redeemed code + first recitation / invites sent | ≥ 15% |
| **K-factor** | invites per user × invite conversion | **≥ 0.25** (matches `03-growth-monetization.md` §14.4) |
| Yearly report share rate | `annual_report_shared` / viewers | ≥ 30% |

**Build order (by expected installs per engineering day):** 1) surah-memorized card, 2) invite reward = Premium week,
3) weekly Friday card, 4) yearly Hijri report (ship for 1 Muharram 1449, around June 2027), 5) halaqa challenge.
