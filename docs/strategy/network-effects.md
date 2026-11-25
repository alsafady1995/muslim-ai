# The strongest network effect for Asmi3ni: 20 ideas ranked by ROI

Constraints (from the founder, 25 Nov 2026): no moderation, no live sessions, no chat rooms, no high operating cost,
and nothing that needs a lawyer or a new paid subscription. Focus: retention and organic growth, with friends and
family inviting each other naturally.

Builds on `docs/marketing/07-virality.md` (riya' rules for sharing, share cards, invite rewards) and
`ecosystem-and-teacher-marketplace.md` in this folder. Nothing already specified there is re-specified here; it is
only scored.

---

## ملخص بالعربية

**الاختيار الأول: «رفيق التسميع».** شخصان (أخوان، زوجان، صديقان، أمّ وابنتها) يرتبطان برابط دعوة. كل واحد يرى
إن كان الآخر سمّع اليوم أم لا، ويشتركان في سلسلة أيام واحدة، ويستطيع أحدهما أن يرسل للآخر تذكيرًا جاهزًا أو
«يوم حماية» حين توشك سلسلته أن تنقطع. ومعه **رابط «أسمِعني»**: ترسل تسجيلك لمن تحب على واتساب، فيفتحه في
المتصفح بلا تطبيق، ويسمعك والآية أمامه كلمة كلمة، ويضغط «بارك الله فيك»، ثم يُدعى: «والآن أسمِعني أنت».

**لماذا هو الأقوى؟** لأنه الشيء الوحيد في القائمة الذي **تزيد قيمته مع كل شخص تضيفه**، وهذا هو أثر الشبكة
الحقيقي، لا مجرد مشاركة. وهو حرفيًا معنى اسم التطبيق: التسميع يحتاج من يسمعك. ولا يحتاج إشرافًا: لا نصوص حرّة،
والتفاعل بأزرار جاهزة فقط، والروابط خاصة تنتهي بعد ٧ أيام، و**لا يمكن مشاركة تسجيل إلا إذا طابق نص الآية**،
فالتطبيق نفسه يمنع أي محتوى آخر.

**الأرخص والأسرع عائدًا (ابدأ بها):** عدّاد «من دلّ على خير» (كم آية راجعها من دعوتهم)، وطلب الدعاء عند ختم
سورة («ادعُ لي بالثبات» ← «دعوتُ لك»)، وأسبوع Premium هدية عند أول تسميع للمدعو.

**ما رفضناه:** رفع جهات الاتصال، ولوحات الترتيب العامة، والتحدّي بالدرجات، و«إهداء ثواب» القراءة (مسألة خلافية).

---

## 1. Viral loop vs network effect

Most "share" features are **viral loops**: one user brings another, then each uses the app alone. They help
acquisition once. A **network effect** means the product gets better for you with every person you connect. That is
what keeps people for years.

| | Viral loop | Network effect |
|---|---|---|
| Example | Surah-memorized card on WhatsApp | A partner who sees whether you recited today |
| Value after the install | None for the inviter | Grows with each connection |
| Main metric | K-factor (invites × conversion) | Retention of connected users vs solo users |
| Where it ranks by ROI | High (cheap) | Medium (more work), but it compounds |

The ROI ranking below favours cheap loops. The **top pick** (§3) is the strongest network effect, which a plain ROI
score underrates because retention compounds over months.

---

## 2. The 20 ideas, ranked by ROI

**Scoring.** Growth G (1–5: new users it brings), Retention R (1–5: how much it keeps existing users), Effort in
developer-days for one developer working with Claude **(estimates)**. **ROI = (G + R) / days.** Every idea is checked
against the constraints: no free text between users, no live audio or video, no moderation queue, no new paid service.

| Rank | Idea | What it is | G | R | Days | ROI | Depends on | Status |
|---|---|---|---|---|---|---|---|---|
| 1 | **"من دلّ على خير" counter** | Profile line: "3 people joined through you. Together they reviewed 1,240 ayahs." Aggregate only, no names or details. Taps through to "Invite one more" | 4 | 3 | 2 | **3.50** | `referrals` (exists) | New |
| 2 | **Du'a request on milestones** | Surah-memorized card says «ادعُ لي بالثبات». The link opens a tiny web page with one button «دعوتُ لك». The user gets "5 people made du'a for you" | 3 | 4 | 3 | **2.33** | Idea 4 | New |
| 3 | **Premium week as a gift** | Inviter and invitee each get a Premium week after the invitee's first recitation; framed «هدية من [الاسم]» | 4 | 2 | 3 | **2.00** | RevenueCat promo entitlement | Specified in `07-virality.md` §7.3 |
| 4 | **Surah memorized card** | Calligraphy card when a surah is fully memorized, ayah as hero, numbers off by default | 4 | 2 | 3 | **2.00** | `hifz_milestones` (exists) | Specified in `07-virality.md` §7.2 #1 |
| 5 | **Weekly Friday card** | "My week with the Quran", shared on Fridays | 3 | 3 | 3 | **2.00** | Weekly summary (exists) | Specified §7.2 #3 |
| 6 | **Friday Al-Kahf check-in link** | On Friday the user sends family «قرأتُ الكهف، وأنت؟». The web page has one button «قرأتها» and shows how many in that link read it | 3 | 3 | 3 | **2.00** | Reading progress (exists) | New |
| 7 | **Al-Fatiha "When did you last?" card** | After the onboarding check: «سمّعتُ الفاتحة اليوم. متى سمّعتها آخر مرة؟», no score | 3 | 1 | 2 | **2.00** | Onboarding (exists) | Specified §7.2 #2 |
| 8 | **Gift a hifz plan** | "I made you a plan to memorize Al-Kahf before Ramadan." The link installs the app with that plan already set up | 4 | 3 | 4 | **1.75** | Plans (exist), deferred deep link | New |
| 9 | **Hifz partner (رفيق التسميع)** | Two people linked by invite. Each sees the other's "recited today ✓ / not yet", a shared streak, preset nudges («لا تنسَ وردك»), and can gift a streak freeze | 4 | 5 | 6 | **1.50** | Push via FCM/APNs (free) | New, **top pick** with #15 |
| 10 | **Ramadan circle challenge** | Invite-only circle (2–10), shared goal ("Juz 'Amma before Eid"), board by days active only | 5 | 4 | 6 | **1.50** | Private circles | In `ecosystem-and-teacher-marketplace.md` |
| 11 | **Partner on the home-screen widget** | Widget shows "Ahmad recited today ✓" next to your due ayahs | 2 | 4 | 4 | **1.50** | Widget (PR #6 item 8), idea 9 | New |
| 12 | **Ayah image card with a deep link** | Upgrade text verse sharing to an image; the link opens that ayah in listen or hifz mode | 3 | 1 | 3 | **1.33** | Reader share (exists) | Specified §7.2 #6 |
| 13 | **Family goal board** | One shared goal for a household (e.g. "Al-Mulk by summer"), each member's days active, preset encouragements | 4 | 4 | 6 | **1.33** | Family plan or circles | New |
| 14 | **Small milestone cards** | Streak 7/30/100 and "I brought back an ayah I was about to forget" | 2 | 2 | 3 | **1.33** | Streaks, SM-2 (exist) | Specified §7.2 #4–5 |
| 15 | **"أسمِعني" link (let me hear you)** | Share your own recording by private link. The listener opens a web page (no install), hears you with the ayah text shown word by word and the coach's marks, taps «بارك الله فيك», then sees «والآن أسمِعني أنت» | 5 | 4 | 7 | **1.29** | Opt-in clip retention, web page on `site/` | New, **top pick** with #9 |
| 16 | **Eid family card** | One card for the household: days with the Quran in Ramadan, surahs reviewed together | 3 | 2 | 4 | **1.25** | Idea 13 | New |
| 17 | **Yearly Hijri report** | Swipeable "My Quran year 1448" story on 1 Muharram | 5 | 3 | 8 | **1.00** | Data exists | Specified §7.2 #8 |
| 18 | **"أكمل الآية" link** | A friend gets one ayah with the next words hidden and taps them in order on a web page. Text only, no AI cost. Ends with «سمّع السورة كاملة في أسمِعني» | 4 | 1 | 5 | **1.00** | Quran text (exists) | New; keep it reverent, no timers or scores |
| 19 | **Teacher join code + QR poster** | A teacher prints one QR; 10–30 students join a halaqa at once | 5 | 5 | 15 | **0.67** | Halaqa mode | In `ecosystem-and-teacher-marketplace.md` |
| 20 | **Child recites on the parent's phone** | Child profile under the parent's account; «سمّع لي» becomes a daily family ritual | 4 | 4 | 15 | **0.53** | Family plan | In `ecosystem-and-teacher-marketplace.md` |

### Rejected (they break a constraint or the culture)

| Idea | Why not |
|---|---|
| Upload contacts to find friends | Privacy (PDPL) and store review friction; WhatsApp links do the same job |
| Public leaderboards or ranking by score | Riya' and shaming (`07-virality.md`); invites cheating |
| "Challenge a friend to beat my score" | Same, and it turns recitation into a contest |
| Dedicating the reward of recitation to the deceased (إهداء الثواب) | Fiqh disagreement; we do not take a side in the product |
| Comments on shared recitations | Free text between users needs moderation |
| Paying users per invite | Attracts fraud and contradicts the "gift" framing |

---

## 3. Top pick: "رفيق التسميع" (Hifz partner + the "أسمِعني" link)

Ideas 9 and 15 together are one product: **someone who hears you, and whom you hear.** It is the literal meaning of
the app's name, and the only idea on the list where each new person makes the app more useful to everyone they are
connected to.

### How it works

1. After a recitation, the result screen offers «أرسلها لمن يسمعك» (send it to someone who listens to you).
2. The user picks WhatsApp/Snapchat. The message: «سمّعتُ سورة الملك اليوم، اسمعني 🎧 [link]».
3. The listener opens the link in the browser, **no install**: ayah text word by word, the audio, the coach's marks
   (off by default; the sender chooses), and three preset buttons: «بارك الله فيك», «ما شاء الله», «تابع».
4. The page ends with «والآن أسمِعني أنت»: install link with the sender's invite code, so the listener becomes a
   reciter and the pair becomes **partners** automatically (idea 9).
5. As partners, each sees the other's "recited today" status, shares a streak, and can send one preset nudge a day
   or gift a streak freeze.

### Why it needs no moderation

| Risk | Built-in control |
|---|---|
| Someone shares non-Quran audio | A clip can be shared **only if the ASR alignment matches the expected ayahs** above a threshold. Anything else has no share button |
| Abusive text | There is no free text anywhere: preset buttons only |
| Public exposure, especially of women's or children's voices | Links are unlisted, expire after 7 days, can be revoked; the sender sees a clear "anyone with the link can listen" note. Child profiles cannot create links |
| Spam nudges | One nudge per partner per day; either side can unlink silently |
| Store rules (Apple 1.2) | A "report this link" button on the web page goes to the support email; block = unlink. That meets the rule without a moderation team |

### Cost

- Storage: about 1 MB per minute of audio, kept 7 days, only for clips the user chose to share. Negligible on the
  existing Supabase Storage plan **(inference)**.
- Web page: a static page plus one read of the clip and text, on the existing Cloudflare Pages site (asmi3ni.pages.dev, already deployed from this repo).
- Push for partner nudges: FCM and APNs are free. The app today uses local notifications only, so this adds a
  token table and one Edge Function.
- No AI cost: the analysis already happened when the user recited.
- Privacy change: today recordings are deleted right after analysis. Shared clips need an explicit, per-clip
  opt-in and the 7-day expiry, plus a line in the privacy policy and store privacy labels.

### What to measure

| Metric | Target **(inference)** |
|---|---|
| Share rate of recitations | ≥ 10% of completed recitations |
| Listener → install | ≥ 8% of link opens |
| Pairs formed per 100 weekly active users | ≥ 20 |
| D30 retention of partnered users vs solo | ≥ 1.5× |
| K-factor (whole app, all loops) | ≥ 0.25 (the target in `07-virality.md`) |

**Kill rule:** if partnered users' D30 is not clearly above solo users' after 60 days, stop at the loops (ideas 1–8)
and put the time back into the coach.

---

## 4. Build order

ROI decides what comes first; dependencies decide what is possible.

| Sprint | Build | Why this order |
|---|---|---|
| 1 (≈ 1 week) | 1 counter, 3 gift week, 4 surah card, 7 Al-Fatiha card | Cheapest loops; 3 and 4 are already specified |
| 2 (≈ 1 week) | 2 du'a request, 5 Friday card, 6 Al-Kahf link | Reuse the card and web-page pieces from sprint 1 |
| 3 (≈ 2 weeks) | **15 "أسمِعني" link, then 9 partner** | The top pick; needs the opt-in clip storage and push |
| Before Ramadan 2027 | 10 Ramadan circle, 8 gift a plan | Ramadan is when families invite each other |
| Later | 11, 12, 13, 14, 16, 17, 18; 19 and 20 with halaqa mode and the family plan | Larger or seasonal |

All of this comes **after** the live-correction beta in PR #13, as agreed in `ecosystem-and-teacher-marketplace.md`
§15. A share link to a recitation the coach marked wrongly spreads the error to family, so accuracy gates sharing too:
until the benchmark passes, links show the recitation and ayah only, with the coach's marks off.
