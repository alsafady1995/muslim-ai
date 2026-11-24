# Muslim AI vs Tarteel, Quran Companion, Muslim Pro, Ayah and Quran Majeed

Where Muslim AI is superior, equal and inferior today, and the roadmap to become the best Quran app in the market.

Compared against what is actually in `main` (Flutter app in `app/`, Supabase backend, ASR service), not against the
original spec. Builds on `docs/full-audit.md` §1.2 and `docs/subscription-growth-audit.md`; decisions taken there
(value-first paywall, weekly free limits, all reciters free, the 50% AI cost rule, Ramadan plan, family plan,
share card) are referenced, not repeated. Competitor data is from their App Store listings, read on 24 November 2026.

---

## ملخص بالعربية

**الخلاصة:** نحن **الأفضل فعلًا** في شيء واحد لا يملكه أحد: مدرّب حفظ يجدول المراجعة بالتكرار المتباعد ويتنبأ
بالآيات المعرّضة للنسيان ويختبرها بالتلاوة صوتيًا. ونحن **أرخص بكثير** من تَرتيل (٩٩$ سنويًا عندهم، و٣٤٩٫٩٩ ريال
في السعودية) وأنظف من Muslim Pro وQuran Majeed (فيهما إعلانات وتتبّع).

**نتساوى** في: الأذكار، والصوت مع التكرار والسرعة، والسلاسل والإنجازات، وسجل الأخطاء (الكلمات الضعيفة).

**نتأخر** في: كشف الأخطاء **المباشر** أثناء التلاوة (تَرتيل يصحح لحظيًا ونحن نحلل بعد التسجيل)، وعرض المصحف
بالصفحات، والتحميل بدون إنترنت، وعدد الترجمات والتفاسير، ومواقيت الصلاة والقبلة، والودجت، والثقة (لا تقييمات
بعد، بينما Muslim Pro لديه ٦٠٢ ألف تقييم).

**تصحيح مهم:** تطبيق Quran Companion متوقف عن التحديث منذ ٢٠١٨، فهو ليس منافسًا حقيقيًا. المنافس الحقيقي في
الحفظ هو تَرتيل وحده. وهناك تطبيقان على App Store يحملان اسم "Muslim AI"، فيجب حسم الاسم قبل الإطلاق.

**الخطة (بالترتيب):**
1. **قبل الإطلاق:** قياس دقة التصحيح الصوتي مقابل تَرتيل، ثم **وضع الاختبار المباشر** (الآية مخفية وتظهر كلماتها
   وأنت تتلو)، وعرض المصحف بالصفحات مع تحميل مجاني بدون إنترنت، وحسم الاسم.
2. **قبل رمضان ٢٠٢٧:** مواقيت الصلاة والأذان والقبلة مجانًا على الجهاز (بدون تكلفة ذكاء اصطناعي)، وتفسير
   الميسّر بالعربية، وودجت "مراجعة اليوم"، وخطة رمضان وبطاقة المشاركة.
3. **بعد قياس الاحتفاظ:** خطة العائلة ولوحة المعلّم والحلقة (لا يملكها أي منافس)، ثم التجويد لأهم الأحكام.

**لا ننافس** في: مطاعم حلال، بث مكة المباشر، المجتمع والمنشورات، الزكاة.

---

## 1. The competitors as they really are (November 2026)

| App | Position | Ratings (US) | Paid tiers (US App Store) | Ads | Last update |
|---|---|---|---|---|---|
| **Tarteel** | AI memorization: live mistake detection while you recite | 4.7 (11K); SA 4.5 (14K), **#1 in Books in Saudi Arabia** | $12.99/mo, $99/yr; higher tier $19.99/mo, $239.99/yr. SA: SAR 44.99/mo, SAR 349.99/yr | No | This month (5.83.1) |
| **Quran Companion** | Hifz with "swipe to reveal" self-testing, group challenges, hasanah leaderboard | 4.5 (112) | 1-month and 1-year subscriptions, prices not listed | No | **June 2018.** Effectively abandoned; a 2025 review says it crashes when starting memorization |
| **Muslim Pro** | Everything app: prayer times, athan, Qibla, Quran, duas, community, AI bot (since Ramadan 2024) | 4.7 (602K) | $12.99/mo or $34.99/yr per its description; many legacy tiers | **Yes**, with third-party tracking; Premium removes ads | This month (17.11.1) |
| **Ayah** | Beautiful Madinah Mushaf reader: highlights, khatmah, tafsir, word meanings, widget | 4.7 (37K, UAE store) | "Ayah Membership" AED 9.99 and AED 59.99 | No | March 2025 (28.0) |
| **Quran Majeed** | Quran + prayer times: 45 translation languages, tajweed colors, memorization audio, Watch and CarPlay | 4.7 (241K) | $0.99 to $1.99/mo, $29.99/yr, $49.99 lifetime | **Yes**, with ad tracking | This month (12.1.1) |

Two corrections to `docs/full-audit.md` §1.2:

- **Quran Companion** was described as "gamified hifz with leagues". It has not shipped an update since 2018. Its ideas
  (group challenges, swipe-to-reveal) are worth keeping, but it is not a live competitor. Tarteel is the only serious
  hifz rival.
- **Muslim Pro** is not only prayer times: it has had an Islamic AI chatbot since Ramadan 2024, plus quests and a
  community space. Our AI is not unique against it; our *grounding* (verbatim sources only, uncited claims dropped
  server-side) is the difference, and it has to be shown, not claimed.

**Our pricing** (from `BLOCKERS.md`, as in `main`): $4.99/month or $29.99/year with a 7-day trial on annual only, about
$0.99 / $6.99 in Egypt, Pakistan and Indonesia. The project brief for this comparison quotes $2.99 / $19.99 with the
Gulf at $4.99 / $29.99. Every conclusion below holds at either price.

---

## 2. Feature matrix

**S** = Muslim AI is superior, **=** equal, **I** = inferior, **–** = neither has it.
"Muslim AI today" describes the code in `main`, not the spec.

### 2.1 Learning: recitation and memorization (our core)

| Area | Muslim AI today | Tarteel | Q. Companion | Muslim Pro | Ayah | Q. Majeed |
|---|---|---|---|---|---|---|
| Recitation mistake detection | Record, then word-by-word result (missed, extra, wrong). Free clips 60 s, Premium 3 min | **I.** Tarteel corrects *live* while you recite, including wrong tashkeel | S | S | S | S (its "Recite & Sync" follows you, does not grade) |
| Proven accuracy | Not measured on real users yet | **I.** Years of production data; but reviews report repeated misses on some ayahs | S | S | S | S |
| Memorization scheduling | SM-2 spaced repetition, forgetting prediction, at-risk ayahs, plans with daily ayahs, pause plan | **S.** Tarteel has goals and a random-position Test mode, not a forgetting model | S | S | S | S |
| Testing from memory | AI test by reciting, graded automatically, feeds the schedule | **I on the moment, S on the loop.** Their hidden-verse mode is live; ours grades after recording but schedules the next review | S (theirs is self-graded) | S | S | S |
| Mistake history | Weak-words screen (top 3 free, all Premium) | = | S | S | S | S |
| Tajweed feedback | "Possible short madd" heuristic only | = (not advertised by Tarteel either) | – | – | – | **I** (tajweed-coloured text) |
| "Already know these surahs" onboarding, plan reveal, Today card | Shipped | S | S | S | S | S |
| Progress analytics | Weekly summary, milestones, XP; no heatmap | **I** (streak heatmaps, analytics dashboard) | S | = | S | S |

### 2.2 Reading and listening (table stakes)

| Area | Muslim AI today | Tarteel | Q. Companion | Muslim Pro | Ayah | Q. Majeed |
|---|---|---|---|---|---|---|
| Mushaf view | Ayah-by-ayah list | **I** (Madani and Indo-Pak mushaf) | I (13-line Urdu script) | I | **I** (best-in-class Madinah Mushaf) | **I** (Uthmani, Indo-Pak 15-line) |
| Reciters | About 10, all free | = (free unlimited listening) | = (15) | I | I ("tens of reciters") | I |
| Repeat, range loop, speed | Yes | = | = | = | = | **I** (also repeat interval) |
| Offline | Streams and caches; full download is Phase 2 | I | – | **I** (Premium offline text and audio) | I | I |
| Translations | One English (Saheeh International) | = | **I** (10) | **I** | **I** | **I** (45 languages) |
| Tafsir | Ibn Kathir (abridged, English) | S | S | = | **I** (several tafsir books, word meanings) | = |
| Bookmarks, highlights, khatmah | Basic | = | = | = | **I** (coloured bookmarks, thematic highlights, khatmah) | I |
| Widgets, Watch, CarPlay | None | = | = | **I** (prayer widgets) | **I** (bookmark widget) | **I** (Watch, CarPlay) |

### 2.3 Understanding: search and AI

| Area | Muslim AI today | Tarteel | Q. Companion | Muslim Pro | Ayah | Q. Majeed |
|---|---|---|---|---|---|---|
| Semantic search ("verses about anxiety") | Yes, with keyword fallback | S | S | S | S | S (word search only) |
| Ask the Quran / assistant | Grounded: cites only retrieved ayahs and graded hadith; uncited claims dropped server-side; crisis handling | S | S | **= on features, S on grounding** (needs a public proof) | S | S |
| Voice search (recite to find the ayah) | No | **I** | – | – | – | – |

### 2.4 Daily practice and habit

| Area | Muslim AI today | Tarteel | Q. Companion | Muslim Pro | Ayah | Q. Majeed |
|---|---|---|---|---|---|---|
| Prayer times, athan, Qibla, Hijri | None | = | = | **I** (its core) | = | **I** |
| Adhkar | Morning, evening, sleep, travel, prayer, with progress | S | S | = (duas, tasbih) | S | = (ruqyah, manzil playlists) |
| Streaks, XP, levels, achievements | Yes, server-owned, streak freezes | = | = | = (quests) | S | = (badges) |
| Social: friends, groups, leaderboards | None | = | **I** (group challenges, leaderboard) | **I** (community) | = | = |
| Ramadan features | None yet (planned, `full-audit.md` R7, G1) | = | = | **I** (suhoor and iftar times) | = | **I** |
| Family / children / teacher | None (planned, G4, G5) | – | – | – | – | – |

### 2.5 Business, trust and brand

| Area | Muslim AI today | Tarteel | Q. Companion | Muslim Pro | Ayah | Q. Majeed |
|---|---|---|---|---|---|---|
| Price for the coaching tier | $29.99/yr | **S** (70% cheaper than $99; in Saudi Arabia SAR ≈ 110 vs SAR 349.99, also about 70% cheaper) | n/a | S ($34.99/yr) | = (AED 59.99 ≈ $16, but no coaching) | = ($29.99/yr) |
| Free tier | Weekly limits, all reciters free, no ads | = | – | **S** (theirs has ads) | = | **S** (theirs has ads) |
| Privacy | No ads, no ad tracking, voice deleted after analysis | = | = | **S** (third-party ad tracking) | = | **S** (ad tracking) |
| Arabic-first UI and Gulf focus | Yes (RTL, Arabic copy written, not translated) | S | S | S | = | = |
| Social proof | 0 ratings, not launched | **I** | = | **I** | **I** | **I** |
| Unique name in store search | "Muslim AI" is already used by at least two App Store apps ("Muslim AI: Dua Islam Assistant", "Muslim AI Quran & Prayer Times") | I | I | I | I | I |

---

## 3. Verdict

**Superior (defend and advertise):**
1. The **hifz loop**: spaced repetition + forgetting prediction + automatic grading by voice. No competitor has all
   three; Tarteel has the voice part only.
2. **Price for AI coaching**: about a third of Tarteel's, in the US and in Saudi Arabia.
3. **Trust and calm**: no ads, no tracking, grounded AI that will not invent a hadith, against the two biggest apps
   (Muslim Pro, Quran Majeed) which run ads with tracking.
4. **Value-first paywall**: Tarteel and Muslim Pro lead with trials; we let the coach prove itself for three days.

**Equal (good enough, do not over-invest):** adhkar, audio controls, streaks and XP, weak-word history, single-device
sync, free reciters.

**Inferior (ranked by how many users it costs us):**
1. **Live correction while reciting** (Tarteel). This is the reason people pay Tarteel $99/year. Without it, a
   Tarteel user will see our record-then-analyze flow as a step back, however good the scheduling is.
2. **Unmeasured accuracy.** One wrong "mistake" on Al-Fatiha in onboarding loses the user and the review.
3. **Mushaf page view and offline.** Hafiz memorize by page; people read on flights and in the haram with weak signal.
   Ayah and Majeed set the bar here.
4. **Prayer times / athan / Qibla.** The reason Muslim Pro and Majeed are opened five times a day. Its absence means we
   are opened once a day at best.
5. **Translations and tafsir**, especially an Arabic tafsir (Al-Muyassar) for the Gulf, and Urdu and Indonesian for
   Phase 2 markets.
6. **Ratings** and a **name** that is not shared with other apps.

---

## 4. Roadmap to be the best Quran app in the market

"Best" means four measurable things, not more features than Muslim Pro:

| Goal | Target | Measured by |
|---|---|---|
| Most accurate recitation feedback | False "mistake" rate ≤ Tarteel's on the same test set | Eval set (item 1) |
| Best hifz retention | 30-day retention of memorized ayahs ≥ 90% for active users | SM-2 review grades |
| Daily habit | D30 ≥ 20% (the growth audit's D7 ≥ 25% stays) | PostHog |
| Trust | 4.8 with 10K ratings in Saudi Arabia; top 3 in Books in KSA during Ramadan 2027 | App Store Connect |

We **do not** chase Muslim Pro's long tail: halal restaurant finder, live Makkah TV, journaling, community feed, zakat
calculator, quests. Each one adds cost and dilutes "the Hifz Coach that hears you".

### Now: before public launch (next 6 weeks)

| # | Item | Closes gap | Why first | Size | AI cost |
|---|---|---|---|---|---|
| 1 | **Accuracy benchmark.** 300 labelled clips (men, women, children, non-native speakers, Juz Amma and long surahs); run ours and record Tarteel's output on the same clips; ship an "I'm not sure" state for low-confidence words | Inferior #2 | Everything we sell depends on it; a wrong flag in onboarding is fatal | M | One-off |
| 2 | **Live test mode.** Ayah hidden; words appear as you recite them; a wrong or skipped word stops and shows the correct one. Streaming ASR from the existing service; the final grade still feeds SM-2 | Inferior #1 | Matches Tarteel's best feature and keeps our scheduling on top. Together they beat Tarteel outright | L | Per-minute ASR, reserved through `begin_ai_call` like every other AI call, so the 50% rule holds automatically. Free users get it inside the existing 5 weekly hifz tests |
| 3 | **Mushaf page view** (Madani 15-line) as an option in the reader and in hifz plans ("memorize page 582") | Inferior #3 | Hafiz think in pages | M | None |
| 4 | **Free offline download** of the Quran text, one translation and the chosen reciter, per surah or juz | Inferior #3 | Muslim Pro charges for offline; we give it free, which supports the value-first rule | M | None |
| 5 | **Name and store listing.** Decide a distinct name (or a distinct subtitle such as "Hifz Coach"), then ASO in Arabic and English around "تحفيظ القرآن" and "hifz" | Inferior #6 | Must be settled before reviews accumulate | S | None |

### Next: before Ramadan 2027 (around 8 February)

| # | Item | Closes gap | Size | Notes |
|---|---|---|---|---|
| 6 | **Prayer times, athan notification, Qibla**, on-device, free | Inferior #4 | M | On-device calculation, no AI cost, no paywall. Turns one daily open into five, each one a chance to show "3 ayahs due" |
| 7 | **Tafsir Al-Muyassar (Arabic)** + Urdu and Indonesian translations | Inferior #5 | S | Licence check alongside `BLOCKERS.md` item 18 |
| 8 | **Home-screen widget**: today's review count and at-risk ayahs | Widgets | S | The cheapest daily reminder there is |
| 9 | **Progress heatmap** on the profile (reviews per day) | Analytics | S | Matches Tarteel; reuses data we already store |
| 10 | **Ramadan mode and the shareable recitation card** | Ramadan | M | Already specified in `full-audit.md` (R7, G1, G2); start in January |

### Later: after D30 retention is measured

| # | Item | Why it makes us the best | Size |
|---|---|---|---|
| 11 | **Family plan and parent dashboard** (`full-audit.md` G4): parents see each child's hifz and at-risk ayahs | No competitor has it; it is how hifz actually happens in the Gulf | L |
| 12 | **Halaqa / teacher dashboard** (G5) with group challenges | Quran Companion's best idea, done on a maintained product with automatic grading | L |
| 13 | **Tajweed detection** for 4 rules first: madd, ghunnah, qalqalah, idgham | Goes beyond Tarteel, which only advertises word and tashkeel errors | XL (needs labelled data from item 1) |
| 14 | **Voice search**: recite a few words, jump to the ayah | Matches Tarteel; reuses the ASR service | S |
| 15 | **Apple Watch and CarPlay** listening | Matches Quran Majeed | M |

### What stays fixed through every phase

- No paywall before about 3 days of real value; at most one offer a day and three a week (`full-audit.md` §3).
- No user costs more in AI than half of what they paid. Live test mode (item 2) is the only new AI cost in this plan,
  and it goes through the same per-user budget, so the cap needs no new rule.
- Everything that is not AI (reading, listening, offline, prayer times, widgets, adhkar) stays free. Premium sells
  more coaching, never basic access.

---

## 5. The one-line positioning

Muslim Pro tells you when to pray, Ayah gives you a beautiful mushaf, and Tarteel tells you what you got wrong today.
**Muslim AI is the only one that knows what you will forget next week, hears you test it, and costs a third of the
price.** Items 1 and 2 make the "hears you" part true at Tarteel's level; until they ship, our paywall should lead with
the schedule and the at-risk ayahs, not with accuracy claims.

---

## Sources

App Store listings read on 24 November 2026:
[Tarteel (US)](https://apps.apple.com/us/app/tarteel-%D8%AA%D8%B1%D8%AA%D9%8A%D9%84-ai-quran/id1391009396),
[Tarteel (SA)](https://apps.apple.com/sa/app/id1391009396),
[Quran Companion (US)](https://apps.apple.com/us/app/id1111843462),
[Quran Companion (SA)](https://apps.apple.com/sa/app/id1111843462),
[Muslim Pro (US)](https://apps.apple.com/us/app/muslim-pro-quran-prayer-times/id388389451),
[Ayah (UAE)](https://apps.apple.com/ae/app/ayah-quran-app/id706037876),
[Quran Majeed (US)](https://apps.apple.com/us/app/-/id365557665).
Muslim Pro AI bot launch (Ramadan 2024):
[Industry.co.id](https://www.industry.co.id/read/130820/muslim-pro-luncurkan-ai-bot-islami-dan-fitur-al-quran-yang-diperbarui).
Apps already using the name: [Muslim AI: Dua Islam Assistant](https://apps.apple.com/us/app/id6448193852),
[Muslim AI Quran & Prayer Times](https://apps.apple.com/app/id6759032770).

Caveats: App Store in-app purchase lists show names and prices separately, so Muslim Pro's tier pairing is approximate
(its description states $12.99/month or $34.99/year). Ratings and versions change weekly. Accuracy comparisons with
Tarteel are not possible until item 1 is done; nothing in this document claims we are more accurate today.
