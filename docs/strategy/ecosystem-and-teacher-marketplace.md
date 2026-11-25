# From AI coach to Quran learning ecosystem: what to build, what to refuse

An executive review of ten proposed expansions (teacher-led classes, sheikh scheduling, class reservations, waitlists,
community rooms, study circles, memorization groups, student communities, teacher profiles, live sessions), written
from the seats of CEO, CPO, growth, community, monetization and retention.

Grounded in what is in `main` today (README, ARCHITECTURE, BLOCKERS), `docs/full-audit.md`,
`docs/subscription-growth-audit.md`, `docs/marketing/`, the competitor analysis (PR #6) and the founding business
docs. Market and policy facts were checked on 25 November 2026 and are linked in **Sources**. Anything not sourced is
marked **(inference)**.

---

## ملخص تنفيذي بالعربية

**الحكم:** من بين الأفكار العشر، **ثلاث فقط تستحق البناء قريبًا، وبشكل مختلف عمّا طُرحت به**:
حلقات الحفظ (بقيادة معلّم حقيقي يعرف طلابه)، ودوائر المتابعة الصغيرة المغلقة (أهل وأصدقاء)، وملف المعلّم الموثّق.
**نرفض نهائيًا** غرف المجتمع المفتوحة ومجتمعات الطلاب العامة: لا تضيف للحفظ شيئًا، وتجلب عبء إشراف لا يحتمله
فريق من شخص واحد، وتفتح بابًا لأخطر ما يمكن أن يهدم ثقة الأهالي (تواصل غرباء مع أطفال). **ونؤجّل** سوق
المشايخ (الملفات العامة، الحجز، الجلسات المباشرة، الحصص الجماعية، قوائم الانتظار) إلى ما بعد إثبات الاحتفاظ،
لأن السوق ذا الطرفين يحتاج طلبًا قائمًا قبل العرض، ونحن بلا مستخدمين بعد.

**لماذا؟** الحفظ ليس منتجًا شبكيًا عالميًا. أثر الشبكة الحقيقي **محلي**: المعلّم الذي يُدخل ٢٠ طالبًا،
والأمّ التي تتابع ٣ أبناء. والخندق الحقيقي ليس "مجتمعًا"، بل **بيانات**: كل تصحيح يضعه معلّم على تلاوة طالب
هو بيانات تدريب موثّقة لنموذج التصحيح، وهذا ما لا يملكه منافس.

**الخمسة التي تُبنى مباشرة بعد الإطلاق (بالترتيب):**
1. **وضع الحلقة للمعلّم** (مجاني للمعلّم): ينشئ حلقة، يدخل الطلاب برمز، يرى المستحق والمعرّض للنسيان لكل طالب.
2. **التسميع غير المتزامن على المعلّم**: يرسل الطالب تسجيله لمعلّمه، فيعلّم الكلمات، وتدخل في جدول المراجعة.
3. **خطة العائلة ولوحة وليّ الأمر** (حتى ٥ ملفات): أكبر مصدر إيراد جديد في الخليج.
4. **دوائر المتابعة الخاصة** (٢–١٠ أشخاص بدعوة فقط): ترتيب بالمواظبة لا بالدرجة، بلا محادثة مفتوحة.
5. **ملف المعلّم الموثّق** (برابط خاص، ليس سوقًا): بداية بناء جانب العرض والتحقق من الإجازات.

**التسعير لا يتغيّر:** ٤٫٩٩$ شهريًا و٢٩٫٩٩$ سنويًا مع تجربة ٧ أيام. يُضاف: خطة عائلة سنوية، وباقة للمؤسسات
(حلقات وجمعيات) تُفوتر مباشرة، ولاحقًا عمولة ١٥٪ على الجلسات الفردية المدفوعة.

**تنبيه صريح:** كل هذا مشروط بشيء واحد لم يتحقق بعد: أن يكون التصحيح الصوتي دقيقًا وأن يعود المستخدمون.
بدون ذلك، أي مجتمع أو سوق هو طلاء على منتج لم يثبت. وإن وصل تمويل، يتغيّر **التوقيت** لا **الترتيب**.

---

## 1. The honest starting point

| Fact | Source | Consequence for this plan |
|---|---|---|
| No users; not yet in either store | Project status | No demand to route to teachers; no retention data to justify community |
| Recitation accuracy unmeasured | PR #11 (benchmark tooling, open), `competitive-analysis.md` | Any teacher who sees a wrong AI flag in front of a student will drop us publicly |
| Solo founder, very limited capital | Brief | Every feature that needs humans on call (moderation, support, payouts, disputes) costs founder hours, not money |
| Brief frames $10M committed | Brief | §13 shows what changes if it arrives: timing and staffing, not the order |
| Pricing fixed: $4.99/mo, $29.99/yr, 7-day trial on annual | `BLOCKERS.md` | Nothing here changes it |
| Positioning: "a practice partner between lessons with your teacher, not a replacement" | `docs/marketing/01`, `03`, `05` | The brand already promises to sit beside teachers. Building *for* teachers is on-brand; competing *with* them is not |
| D7 18% / D30 9% first-cohort targets | `full-audit.md` §6 | The gates in §12 use these |

**The competitive field is not empty.** Three facts change the calculus for every idea on the list:

1. **Tarteel already has Groups and Leaderboards** (group engagement by hours, khatmah completions, resetting every
   Islamic month). Social for its own sake is not a differentiator.
2. **Free, institution-backed live teaching exists at scale in Saudi Arabia.** The Electronic Charitable Association
   for Memorizing the Quran (licence 3298, chaired by Sheikh Saleh Al ash-Sheikh) reports **226,416 students** in its
   e-maqra'a, 145,008 of them women, 79,984 in Saudi Arabia. In March 2025 Sheikh Al-Sudais launched an AI-supported
   **Global Electronic Maqra'a at Masjid al-Haram** in ten languages, with live circles, reports, certificates and
   ijazahs. We cannot out-sheikh the Haram.
3. **The paid 1:1 tutor market is already liquid and cheap.** Preply lists Arabic and Quran tutors from $3 to $40+,
   with typical profiles at $11 to $32 per 50-minute lesson, and takes 18% to 33% (100% of the trial lesson).
   italki takes 15% to 21% on 1:1 and 30% on group classes.

So "teachers + live classes" is a commodity in which we would start last. What none of them has is an **AI that
listens between sessions and tells the teacher what each student is forgetting.** That is the only angle worth
pursuing.

---

## 2. Verdict on each idea

| # | Proposed | Verdict | What we build instead / why |
|---|---|---|---|
| 1 | Teacher-led classes | **Reframe, then add** | Not classes we sell, but **halaqa mode**: tools for teachers who already have students. Teachers become distribution (B2B2C), not inventory |
| 2 | Sheikh scheduling | **Defer** (Phase 3) | Only meaningful once there is a marketplace. Teachers in halaqat already have schedules (mosque, school) |
| 3 | Class reservations | **Defer** (Phase 3) | Same. Build minimal 1:1 booking when demand exists; buy the calendar logic |
| 4 | Waitlists | **Reject as a feature** | A waitlist is a symptom of supply shortage, which we will not have for a long time. It becomes a line of code inside booking ("notify me when a slot opens") the day it is needed |
| 5 | Community rooms | **Reject** | Open rooms are the highest moderation cost per unit of value on this list, invite the Apple 1.2 "random or anonymous chat" problem, and pull users away from reciting. Muslim Pro has community; it is not why people stay |
| 6 | Study circles | **Add, closed form** | **Private circles** of 2–10 invited people (family, friends, colleagues) with shared goals and a consistency board. No open chat, no discovery |
| 7 | Memorization groups | **Merge into 1 and 6** | A memorization group *is* a halaqa (with a teacher) or a circle (without one). Two names for one product create two half-products |
| 8 | Student communities | **Reject** (public); merge (private) | Public student-to-student spaces mix adults and minors and genders with no teacher in the room. The private version is a halaqa |
| 9 | Teacher profiles | **Add, private first** | A verified profile reachable by link and by the teacher's own students. Public directory only when the marketplace opens. This is where verification starts |
| 10 | Live sessions | **Defer 1:1; reject group for now** | 1:1 paid sessions are exempt from Apple and Google billing (see §11), so they can carry a commission. Group live classes must use IAP on iOS, are expensive to staff and moderate, and compete with the free Haram maqra'a |

---

## 3. Ranking

Scores 1 (low) to 5 (high). **Difficulty** is development + operating effort for a solo founder (5 = hardest).
**Moderation burden** and **damage risk** are 1 (low) to 5 (high). The last column is the weighted priority:
(value + retention + revenue) − difficulty − ½ (moderation + damage).

### 3.1 The ten proposed features, as proposed

| Rank | Feature | User value | Retention | Revenue | Difficulty | Moderation burden | Damage risk | Priority |
|---|---|---|---|---|---|---|---|---|
| 1 | Memorization groups | 4 | 5 | 3 | 3 | 2 | 2 | 7.0 |
| 2 | Teacher profiles | 3 | 2 | 3 | 2 | 2 | 3 | 3.5 |
| 3 | Study circles | 3 | 4 | 2 | 3 | 3 | 2 | 3.5 |
| 4 | Teacher-led classes | 4 | 4 | 4 | 5 | 4 | 4 | 3.0 |
| 5 | Sheikh scheduling | 3 | 2 | 3 | 4 | 2 | 2 | 2.0 |
| 6 | Class reservations | 3 | 2 | 3 | 4 | 2 | 2 | 2.0 |
| 7 | Live sessions | 4 | 3 | 4 | 5 | 4 | 5 | 1.5 |
| 8 | Waitlists | 1 | 1 | 2 | 2 | 1 | 1 | 1.0 |
| 9 | Student communities | 2 | 3 | 1 | 4 | 5 | 5 | −3.0 |
| 10 | Community rooms | 2 | 2 | 1 | 4 | 5 | 5 | −4.0 |

### 3.2 The reframed features we recommend

| Rank | Feature | User value | Retention | Revenue | Difficulty | Moderation | Damage | Priority | Covers ideas |
|---|---|---|---|---|---|---|---|---|---|
| 1= | **Halaqa mode** (teacher dashboard, join code, assignments) | 5 | 5 | 4 | 3 | 1 | 1 | 10.0 | 1, 7, 8 |
| 1= | **Family plan + parent dashboard** | 5 | 4 | 5 | 3 | 1 | 1 | 10.0 | (G4, not on the list) |
| 3 | **Async teacher tasmee'** (student sends a recording to *their* teacher) | 5 | 4 | 4 | 2 | 2 | 2 | 9.0 | 1, 10 |
| 4 | **Private circles** (2–10, invite only, consistency board) | 3 | 5 | 2 | 2 | 1 | 1 | 7.0 | 6, 7 |
| 5 | **Verified teacher profile** (by link) | 3 | 2 | 3 | 2 | 1 | 2 | 4.5 | 9 |
| 6 | 1:1 booking + live session with AI co-listener (Phase 3) | 4 | 3 | 4 | 5 | 3 | 4 | 2.5 | 2, 3, 10 |

Scores are judgement **(inference)**, made explicit so they can be argued with and re-scored when data arrives.

### 3.3 Direct answers

| Question | Answer | Why |
|---|---|---|
| Strongest retention | **Halaqa mode** and **private circles** | Someone who expects you is the strongest retention force in habit products: the teacher checks on Thursday, your sister sees you skipped. The SM-2 queue gives the daily reason to open; the group gives the reason not to skip |
| Network effects | **Halaqa mode** (local), **async tasmee'** (data) | Each teacher brings 10–30 students (`07-virality.md` §7.4). Each teacher correction is a human-labelled clip that improves the model for every user. A public community has weak network effects in learning: more strangers does not make *your* hifz better |
| Community | **Halaqa + circles** | Real community in Quran learning is the halaqa. We digitise the one that exists rather than invent one between strangers |
| Subscription conversion | **Family plan**, then **halaqa** | Parents pay for children before themselves (inference, consistent with how tutoring is bought). Halaqa students hit free weekly limits faster because the teacher assigns daily practice |
| Unnecessary moderation burden | **Community rooms, student communities, open chat in any feature** | Arabic + English, mixed genders and ages, religious disputes (aqeedah, madhhab), spam from "online Quran academies" selling off-platform |
| Could damage the product | **Live 1:1 with minors without safeguards**, **open communities**, **unverified "sheikh" profiles**, **AI flags shown live to a teacher before accuracy is proven** | One grooming case, one fake ijazah, or one viral clip of the AI "correcting" a famous qari wrongly ends the brand in a community that runs on trust. Abuse by religious tutors is documented, e.g. a Maryland Islamic tutor charged in August 2024 with abusing a 16-year-old during lessons |

---

## 4. Network effects and retention

**What kind of product this is.** Duolingo-style habit product with a learning loop, not a social network. Value to a
user comes from (a) the coach being right, (b) the schedule being right, (c) someone noticing when they stop. Only
(c) is social, and it is satisfied by **5–30 people you already know**, not by a million strangers.

| Effect | Type | Strength | How we capture it |
|---|---|---|---|
| Teacher brings students | Local, one-sided acquisition | Strong | Halaqa mode free for teachers; join code; teacher gets Premium free |
| Parent brings children | Local | Strong | Family plan |
| Circle members keep each other going | Local, retention | Medium-strong | Private circles; Friday summary card shared to the circle |
| Teacher corrections improve the AI | **Data network effect** | Strong and compounding | Every async tasmee' review stores (clip, ayah, teacher-marked words) with consent; feeds the benchmark from PR #11 and later fine-tuning |
| More teachers → more students → more teachers | Cross-side marketplace | Strong *only after liquidity*; negative before (empty directory) | Do not open until halaqa mode has seeded supply (§6) |
| Public community | Same-side | Weak for learning; negative at small scale (empty rooms) | Do not build |

**Retention mechanics we already have** (`ARCHITECTURE.md`): SM-2 daily queue, at-risk ayahs, streaks with freezes,
weekly summary, milestones. Social layers must **plug into these**, not add a parallel feed:

- The teacher sees each student's due and at-risk ayahs (no new data needed; it is `get_hifz_queue` per member).
- Circles rank **days active**, never accuracy (already a rule in `07-virality.md`, to avoid riya' and shaming).
- A missed day triggers a nudge from the system, never a public shame list.

**Kill rule.** If halaqa members do not show a D30 retention at least 1.5× solo users within 60 days of launch of the
feature, stop investing in social and put the effort back into the coach.

---

## 5. Community strategy

**Principle: small, closed, with a known adult in charge, and always in service of reciting.**

| Rule | Detail |
|---|---|
| No open spaces | No public rooms, feeds, comments, or discovery of other learners. No DMs between people who are not in the same halaqa/circle/family |
| Every group has an owner | Teacher (halaqa), parent (family), or creator (circle). The owner can remove members and is accountable |
| Size limits | Circles 2–10; halaqa up to 40 students per teacher; family up to 5 profiles |
| Communication is structured | Reactions, preset encouragements ("بارك الله فيك", "تابع"), assignments, and teacher voice/text feedback on a recording. Free-text chat only teacher ↔ student inside a halaqa, logged and reportable |
| Gender and age | Mixed-gender circles only for families. Halaqa for minors requires a verified teacher and parent consent (§8). Default teacher-to-student matching for minors is same gender **(inference: aligns with prevailing Gulf norms; confirm with the scholar reviewer, BLOCKERS item 17)** |
| What we rank | Days active, ayahs reviewed, khatmah progress. Never scores, never voice quality |
| Seasonal moments | Ramadan circle challenge, Dhul Hijjah first-ten challenge, 1 Muharram yearly report (from `07-virality.md`) |

**Community team.** Before marketplace: the founder plus 2–3 volunteer teacher-ambassadors from the TestFlight
halaqat (`08-launch-campaign.md`, phase 0). After funding: a Head of Community who is a teacher, not a marketer.

---

## 6. Teacher marketplace strategy

**Thesis: earn the teachers before selling them.** Supply first as *users of our tools*, demand second, marketplace
third.

### 6.1 Three stages

| Stage | What teachers get | What we get | Money |
|---|---|---|---|
| **A. Tool** (Phase 2) | Free halaqa mode, async tasmee' inbox, free Premium | Students, retention, labelled data, a verified teacher roster | Students convert to Premium/family plans |
| **B. Profile** (Phase 2–3) | Verified profile page, shareable link, reviews from their own students | Verification pipeline running; supply quality signal | None yet |
| **C. Marketplace** (Phase 3+, gated) | Paid 1:1 bookings from new students, payouts | Take rate | 15% commission |

**Gate to open C:** ≥ 300 verified teachers active in stage A, ≥ 30% of them with ≥ 10 students, and a waitlist of
learners who tapped "find me a teacher" ≥ 3× supply hours **(targets are inference, to be revisited)**.

### 6.2 Supply acquisition (in order of cost)

1. Teachers of the TestFlight halaqat (phase 0 of the launch plan).
2. Teachers whose students already use the app: "Your student uses Asmi3ni. See their review queue" card in the
   student's share sheet.
3. Tahfiz associations and Quran schools: institution plan (§10.3).
4. Women teachers who teach from home: underserved, highest demand from women and girls (the e-maqra'a's own split is
   145,008 women to 67,344 men) **(inference that demand transfers to us)**.
5. Last and only for stage C: teachers already selling on Preply/italki, who know the model.

### 6.3 Pricing and commission (stage C)

- Teachers set their own price within a band (e.g. $8–$40 per 30 minutes) **(inference)**.
- **15% commission**, no trial-lesson grab. That undercuts Preply (18–33%, 100% of trial) and matches italki's best
  package rate, which is the message to teachers.
- Learners pay the teacher's price plus nothing; the platform fee comes out of the teacher's side, stated plainly.
- Premium subscribers get one free 15-minute "placement" session per year subsidised by us (acquisition for teachers,
  conversion for us) **(inference; test it)**.

**Unit economics of one 30-minute session at $15 (inference):** commission $2.25; payment processing ≈ 3% ($0.45,
inference); video ≈ 60 participant-minutes ≈ $0.03 on LiveKit Ship overage or $0.24 on Daily; AI co-listener ASR
reserved via `begin_ai_call` as today. Net ≈ $1.75. About 15 sessions ≈ one annual subscriber's net revenue. The
marketplace is a **retention and positioning** product first, a revenue line second.

### 6.4 Payments and payouts

- 1:1 real-time sessions can be paid outside IAP on both stores (§11). Use a licensed payment provider that supports
  marketplace payouts in the teachers' countries. Moyasar and HyperPay cover Saudi card and mada payments;
  cross-border payouts to Egypt, Pakistan, Jordan etc. need a provider with payout rails **(inference; provider
  selection is a Phase 3 task)**.
- **Do not hold other people's money yourself.** Collecting funds on behalf of teachers in Saudi Arabia may require a
  payments licence; use the provider's marketplace/escrow product **(inference: confirm with a Saudi lawyer)**.
- Escrow: pay out 24h after the session if no dispute is opened.
- The existing `PaymentProvider` interface (README "Payments behind an interface") already anticipates Moyasar/HyperPay.

---

## 7. Moderator system

| Tier | Who | Scope | When |
|---|---|---|---|
| 0. Automatic | Code | Text filter (profanity, phone numbers, URLs, WhatsApp/Telegram handles to stop off-platform poaching) on every free-text field; rate limits; new-account limits | From Phase 2 |
| 1. Group owners | Teachers, parents, circle creators | Remove members, delete messages in their group, close the group | From Phase 2 |
| 2. Trust & Safety queue | Founder, then 1 part-time Arabic moderator (paid), then a team (one man, one woman minimum, for same-gender review of reports) | Reports, verification reviews, appeals | Phase 2 founder; Phase 3 paid |
| 3. Scholar panel | 2–3 qualified reviewers (paid per review) | Ijazah verification, recitation auditions, content disputes | From stage B |

**Moderator rules:** two-person rule for bans of verified teachers; every action logged with reason; moderators never
see recordings except attached to a report; women's recordings reviewed by women moderators where requested.

---

## 8. Abuse prevention

| Threat | Prevention |
|---|---|
| **Grooming / abuse of minors** | Minors (under 18, matching the Saudi Child Protection Law definition) cannot be found, messaged or booked by anyone. A minor joins a halaqa only via a parent-approved invite. Paid 1:1 for minors is booked by the guardian's account, shows the guardian a live "join" link, and is same-gender by default. No teacher ↔ minor messaging outside the halaqa thread, which the parent can read. Teachers serving minors must pass ID + reference checks (stage B) |
| **Contact outside the app** | Filter phone numbers, emails, social handles in profiles and chat. Off-platform solicitation is a ban reason. (It also protects revenue) |
| **Impersonation of famous sheikhs or qurra'** | Reserved-names list (well-known reciters and scholars); display names containing "الشيخ", "القارئ", "د." only after verification; verified badge only from our pipeline |
| **Fake ijazah** | §9 pipeline; ijazah claims shown only as "verified by Asmi3ni on <date>" or not at all |
| **Doctrinal disputes / takfir / sectarian content** | No open forums removes most of it. Teacher feedback is on recitation, not fatwa; the AI already refuses fiqh rulings (`01-business.md`) |
| **Harassment between adults of opposite gender** | Circles mixed only within verified family links; reports routed to a same-gender moderator |
| **Spam from tutoring academies** | Teacher accounts are individuals with ID; academies apply for an institution account |
| **Payment fraud / chargebacks** | Provider's fraud tools; payouts delayed 24h; new teachers capped at N sessions/week until 10 completed |
| **AI wrong in front of a teacher** | Teacher views show AI flags only above a confidence threshold, labelled "AI suggestion"; the teacher's mark always overrides and is stored as a correction |

**Session recordings (safety vs. policy).** Recording 1:1 sessions protects children but Google's 1:1 billing exemption
requires the session "is not available for replay" in a Play-distributed app. Option: record audio only, encrypted,
server-side, **never playable in the app**, retained 30 days, opened only by T&S on a report, with consent shown before
booking **(inference: that this satisfies the Google wording; confirm with Play policy support before launch of
stage C)**.

---

## 9. Sheikh / teacher verification

There is no central registry of Quranic ijazahs. The Muslim World League held a forum in August 2025 specifically on
"challenges associated with the authentication of Qur'anic ijazahs" and on "the uncontrolled granting of ijazahs to
those who lack proper mastery". We therefore verify **ability**, not just paper.

| Level | Badge | Checks | Unlocks |
|---|---|---|---|
| 0 | None | Account | Halaqa mode for adults only |
| 1 | **ID verified** | Government ID + selfie via a KYC provider; name matches | Profile by link; adult students |
| 2 | **Recitation verified** | 10-minute recorded audition (assigned passages incl. tajweed-heavy ones) scored by 2 panel reviewers + AI word accuracy | Teaching minors (plus reference check), paid 1:1 |
| 3 | **Ijazah verified** | Ijazah document + sanad chain + confirmation from the issuing sheikh or institution (call or letter); riwayah recorded (e.g. Hafs 'an 'Asim) | "مُجاز" badge with riwayah and date |
| — | Institution | Licence number (e.g. associations licensed by the Ministry of Human Resources and Social Development) | Bulk teacher onboarding |

Re-verify level 1 yearly; any upheld safety report removes all badges pending review.

---

## 10. Monetization and Premium

### 10.1 What stays fixed

- $4.99/month, $29.99/year, 7-day trial on annual only, regional prices (`BLOCKERS.md`).
- No user costs more in AI than half of what they pay (`ARCHITECTURE.md`). Halaqa and family features add AI use;
  they go through `begin_ai_call` like everything else.
- No ads. Reading, listening, adhkar, prayer times stay free.

### 10.2 What Premium sells, by phase

| Phase | Premium adds | Why it converts |
|---|---|---|
| Launch | More coaching (existing weekly limits) | Already in `main` |
| Phase 2 | Unlimited async tasmee' submissions to your teacher (free: 3/week) **(inference)**; create more than one circle; full weak-word history | The teacher is the reason to practise more |
| Phase 2 | **Family plan**: one annual subscription, up to 5 profiles, parent dashboard. Proposed $49.99/year **(inference; test $44.99–$59.99)**, IAP family sharing where available | Parents buy for children |
| Phase 3 | Discount on 1:1 sessions or one free placement session per year | Ties the marketplace back to the subscription |

### 10.3 Institution plan (B2B)

Tahfiz associations, schools and mosques pay per active student per year, invoiced directly. Apple allows apps sold
directly to organizations for their students to unlock access outside IAP; consumer and family sales must use IAP
(guideline 3.1.3(c), Enterprise Services; **wording recalled, verify before relying on it**). Teachers stay free.
Price: SAR 30–60 per active student per year **(inference)**. This is the fastest route to thousands of
users per sale, and in Saudi Arabia it may become the largest revenue line.

### 10.4 Marketplace

15% of 1:1 session price (§6.3). Group classes, if ever, must use IAP on iOS (one-to-few/one-to-many is excluded from
3.1.3(d)) and on Google the 1:1 exemption does not cover groups, so they carry the store fee on top of ours.

---

## 11. Legal, compliance and store policy

| Area | Rule | Source | What we do |
|---|---|---|---|
| Apple: 1:1 live services | "Real-time person-to-person services between two individuals (for example tutoring students...)" may use other payment methods. "One-to-few and one-to-many real-time services must use in-app purchase." | App Review Guideline 3.1.3(d) | Paid 1:1 outside IAP; no group classes outside IAP |
| Apple: subscriptions and features | Unlocking features or content must use IAP | 3.1.1 | Premium and family plan stay on RevenueCat |
| Apple: UGC | Must filter objectionable material, offer reporting with timely responses, blocking, and published contact info. Apps used for "random or anonymous chat" "do not belong on the App Store" | 1.2 | Required from the first group feature (Phase 2): report + block + filter + contact page |
| Apple: kids | Apps that collect personal info or the ability to chat from minors must have a privacy policy and comply with children's privacy statutes; Kids Category apps get no third-party analytics | 5.1.4, 1.3 | Do **not** enter the Kids Category (we use PostHog/Sentry). Child profiles live under a parent account |
| Google: 1:1 services | Billing not required if "the paid service is between two individuals" and is "not available for replay"; examples include "education or hobby classes" | Play "Understanding the Payments policy" | Same as Apple; see §8 on recordings |
| Google: digital content | Education subscriptions and app functionality must use Play Billing | Play Payments policy §2 | No change |
| Saudi PDPL | Minors' data needs the legal guardian's consent and verification of guardianship (Executive Regulations art. 13); the Child Protection Law defines a child as under 18 | Bird & Bird summary of PDPL | Child profiles created only by a guardian account; consent screen; voice recordings already deleted after analysis, except clips a user explicitly shares with a teacher |
| Teacher clips used for training | Separate, opt-in consent for using recordings to improve the model | PDPL purpose limitation **(inference)** | Opt-in toggle; children's clips excluded unless guardian opts in |
| Running a marketplace in KSA | Commercial registration, possibly a payments licence or a licensed facilitator, VAT on commission, teacher tax status | **(inference; needs a Saudi lawyer)** | Gate for stage C; the individual-developer setup in `BLOCKERS.md` will not be enough |
| Remote Quran teaching oversight | Existing e-maqra'at operate as licensed charitable associations | Saudipedia | Ask whether a for-profit app offering paid Quran tutoring needs any Ministry approval **(open question)** |

---

## 12. The roadmap, redesigned

The order is set by **what must be true before the next thing is worth building.**

| Phase | When (honest pace) | Build | Exit gate |
|---|---|---|---|
| **0. Prove the core** | Now → launch (Dec 2026–Jan 2027) | Accuracy benchmark (PR #11), live test mode (separate thread), store launch. **No social features** | False-flag rate measured and acceptable; app live in both stores |
| **1. Ramadan** | Jan → Ramadan 2027 (≈ 8 Feb–9 Mar) | Prayer times, widget, Ramadan plan and share card (from PR #6); **private circles lite** (invite-only Ramadan challenge, consistency board) | D7 ≥ 18%, D30 ≥ 9% on the first cohort (`full-audit.md` targets); ≥ 15% of active users in a circle |
| **2. Teachers as tools** | Mar → Jul 2027 | **Halaqa mode, async tasmee', family plan, verified profile (levels 1–2), report/block/filter**, institution pilot with 2–3 associations | ≥ 100 active teachers; halaqa members' D30 ≥ 1.5× solo; family plan ≥ 15% of new paid |
| **3. Marketplace pilot** | Aug 2027 → early 2028, KSA only, adults first | Directory, 1:1 booking (buy calendar logic), LiveKit sessions with the AI co-listener, payouts via a licensed provider, ijazah verification (level 3), paid T&S | §6.1 gate; legal setup done; < 1 upheld safety report per 1,000 sessions |
| **4. Scale** | 2028 → | Minors in 1:1 (guardian-booked), more countries, group classes via IAP only if 1:1 is healthy, B2B at scale | Marketplace GMV and retention lift proven |
| **Never** | — | Open community rooms, public student communities, stranger DMs, random matching, leaderboards by score | — |

### 12.1 Reservation system (Phase 3)

- **Buy** the hard parts: availability and booking logic from an embeddable scheduler (Cal.com has an open-source,
  self-hostable core **(inference; evaluate)**). Build only what is ours: teacher profile, price, payment, guardian rules.
- Time zones: store everything as UTC + IANA zone (already enforced on `profiles`; reuse that trigger logic).
  Show the teacher's and learner's local times, Hijri date for Ramadan scheduling.
- Prayer-time aware: block Maghrib and Isha windows in the teacher's city by default (we will have prayer times
  from Phase 1).
- **No-shows:** learner no-show → teacher paid in full after 10 minutes; teacher no-show → full refund + strike;
  3 strikes → profile hidden. Free reschedule up to 12h before.
- **Waitlists** appear here as a single behaviour: "notify me if this teacher opens a slot". No standalone feature.

### 12.2 Live class system (Phase 3)

| Option | Cost for 1:1 30 min (2 people = 60 participant-min) | Pros | Cons |
|---|---|---|---|
| **LiveKit Cloud** | Ship plan $50/mo incl. 150,000 WebRTC participant-min, then $0.0005/min ≈ **$0.03** | Open source (self-host later); same stack can stream audio to our ASR for the **AI co-listener** and for live test mode | We build the UI |
| Daily | 10,000 free/mo, then $0.004/min ≈ **$0.24** | Prebuilt UI, simple | 8× the cost; less control of the audio pipeline |
| Zoom SDK | Not priced here | Familiar to teachers | Heavier SDK, brand mixing, harder to tap audio |

**Choice: LiveKit**, audio-first (video optional and off by default for minors), because the same infrastructure
serves the live-correction roadmap. The differentiator in a session: the AI listens alongside the teacher, highlights
likely slips on the teacher's screen only, and after the call writes the teacher-confirmed mistakes into the
student's SM-2 queue. No other tutoring platform can do that.

---

## 13. If the $10 million arrives

Funding changes **how fast**, not **what first**. The gates stay.

| Item | Bootstrapped | Funded |
|---|---|---|
| Phase 2 start | After Ramadan 2027 | Immediately after launch, in parallel with Ramadan work |
| Team | Founder + AI-assisted dev | ~12 people in year 1 **(inference)**: 2 mobile, 2 backend, 2 ML/ASR (the moat), 1 PM, 1 designer, Head of Community (a teacher), T&S lead + 2 moderators (one woman), part-time scholar panel, Saudi legal counsel |
| Marketplace | Pilot late 2027 | Pilot mid-2027 after the halaqa gate, in KSA + Jordan + Egypt (supply) |
| Biggest single investment | — | Labelled recitation data (paid teacher reviews of clips) and the ASR team: accuracy is the product |
| Not spent on | — | Paid acquisition before D30 is known; community managers for open communities; building our own video stack |

Rough year-1 allocation **(inference)**: 45% people (ASR/ML weighted), 15% data labelling and scholar review,
15% growth after gates, 10% T&S and legal, 10% infrastructure and AI, 5% reserve beyond the 18-month runway.

---

## 14. The five features to build right after launch

1. **Halaqa mode.** Teachers create a halaqa, students join by code, the teacher sees each student's due and at-risk
   ayahs and assigns portions. Free for teachers. *Why first:* biggest acquisition multiplier (10–30 students per
   teacher), strongest retention force (someone expects you), on-brand ("between lessons with your teacher"),
   near-zero moderation, and reuses SM-2 data we already compute.
2. **Async teacher tasmee'.** A student sends a recording to their own teacher; the teacher taps the words they
   got wrong and adds a voice note; the marks feed the student's schedule. *Why:* the "teacher-led" idea without
   scheduling, video or payments; works across time zones; every review is a human-labelled clip that improves the
   AI (the data moat).
3. **Family plan + parent dashboard.** Up to 5 profiles, guardian-created child profiles, parent sees each child's
   progress. *Why:* biggest new revenue line (`full-audit.md` G4), PDPL-compliant path for children, and how hifz
   actually happens in Gulf homes.
4. **Private circles.** 2–10 invited people, shared goal (e.g. Juz 'Amma before Eid), board ranked by days active,
   preset encouragements, no open chat. *Why:* matches Tarteel's groups at a fraction of the moderation cost and gives
   adults without a teacher the accountability of one. Ship a lite version for Ramadan 2027.
5. **Verified teacher profile (by link).** ID check, recitation audition, ijazah when available; visible to the
   teacher's own students and shareable. *Why:* builds the verified supply and the verification pipeline the
   marketplace will need, without opening a marketplace.

**Common prerequisite for all five:** report, block, text filter and a published contact page (Apple 1.2), and
guardian consent flow (PDPL). Build these once, in the first sprint of Phase 2.

**Explicitly not in the five:** live sessions, scheduling, reservations, waitlists, community rooms, public student
communities. Each one either needs demand we do not have yet or adds risk we cannot staff.

---

## Sources

Checked on 25 November 2026.

- Apple App Review Guidelines (3.1.1, 3.1.3(d), 1.2, 1.3, 5.1.4): https://developer.apple.com/appstore/resources/approval/guidelines.html
- Apple developer forum on one-to-many live classes and 3.1.3(d) (Sept 2026, unanswered): https://developer.apple.com/forums/thread/845972
- Google Play Payments policy: https://support.google.com/googleplay/android-developer/answer/9858738?hl=en
- Google Play, Understanding the Payments policy (1:1 services, replay condition): https://support.google.com/googleplay/android-developer/answer/10281818?hl=en
- Preply commission model: https://intercom.help/preply/en/articles/4171383-preply-commission-model
- italki commission: https://support.italki.com/hc/en-us/articles/206352068
- Preply Quran tutors listing (prices): https://preply.com/en/online/tutors-quran?page=6
- Tarteel Groups and Leaderboards: https://support.tarteel.ai/en/articles/12414382-groups-and-leaderboards
- Tarteel Challenges (2021): https://tarteel.ai/blog/challenges-announcement/
- Global Electronic Maqra'a at Masjid al-Haram (Sabq, 4 March 2025): https://sabq.org/article/NLCil7k
- Electronic Charitable Association for Memorizing the Quran (Saudipedia): https://saudipedia.com/ar/الجمعية-الخيرية-الإلكترونية-لتحفيظ-القرآن-الكريم
- Muslim World League forum on authenticating Quranic ijazahs (31 Aug 2025): https://themwl.org/en/scholarly-forum-dedicated-examining-challenges-associated-authentication-quranic-ijazahs-and.md
- Saudi Arabia children's data rules (Bird & Bird): https://childreninthedigitalworld.twobirds.com/home/saudi-arabia
- Maryland Islamic tutor case (FOX 5 DC, 27 Aug 2024): https://fox5dc.com/news/maryland-islamic-tutor-accused-sexually-abusing-teen-while-she-read-quran
- LiveKit Cloud pricing: https://livekit.com/pricing.md
- Daily video SDK pricing: https://www.daily.co/pricing/video-sdk/

Caveats: Preply's full commission tier table could not be read (the 18% floor and 33% start are from its text).
Saudipedia does not state whether the e-maqra'a is free. The Apple 3.1.3(c) wording is recalled, not re-read.
Scores in §3 and all prices marked (inference) are judgement, to be replaced with data.

