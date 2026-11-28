# 2. App Store and Google Play screenshots: the persuasion sequence

Eight screenshots, designed as one argument that builds from **curiosity → recognition → desire → trust → install**.
Arabic set first (Saudi Arabia, UAE, Kuwait, Qatar, Bahrain, Oman, Jordan, Egypt storefronts); the English set is the
same sequence with translated copy, not a different story.

---

## 2.1 Rules that shape the sequence

1. **Screenshots 1–3 must sell alone.** In App Store search results, portrait screenshots show only the first three.
   Most installs from search happen without opening the product page. Screenshot 1 carries the hook, 2 the emotion,
   3 the reason to stay and pay.
2. **One idea per frame.** Arabic headline ≤ 5 words, readable at thumbnail size (about 1/6 of a phone screen).
3. **Real UI, real data, real verses.** Every phone frame shows a real screen of the app with demo data, never a mock
   of a feature we do not have. The Quran text is rendered by the app (Amiri Quran), never retyped.
4. **Right-to-left flow.** In Arabic storefronts the gallery reads right to left, so the visual continuity (the
   connecting ribbon between frames, see §2.4) flows from right to left. Verify in App Store Connect's preview.
5. **Show the user, not the AI.** No robots, no brains, no circuit patterns. The hero is the user's words on screen.
6. **No prices on screenshots 1–7.** Price talk before desire lowers conversion. Screenshot 8 mentions "free to start".
7. **No reviews, no "#1", no awards** until they are real. When real, they replace the strip at the top of
   screenshot 8 (never screenshot 1, which belongs to the hook).

### Visual system

| Element | Spec |
|---|---|
| Canvas | iPhone 6.9" 1320 × 2868 (required set; Apple scales down). Google Play phone 1080 × 1920 (9:16). iPad not needed at launch (app is phone-first) |
| Background | Deep emerald `#0B5E4E` → `#0E7C66` vertical gradient on 1, 3, 5, 7; warm paper `#F7F3EA` on 2, 4, 6, 8 (alternation keeps the gallery from feeling like one long wall) |
| Accent | Gold `#C9A227` for one word per headline maximum, and the ribbon |
| Status colours in the app UI | Correct `#2E7D32`, unclear `#F9A825`, wrong or missed `#C62828` (as in `coach_result_view.dart`) |
| Arabic headline | Noto Kufi Arabic, ExtraBold, 112–128 px at 1320 wide; supporting line Regular 56–60 px |
| English headline | Inter, ExtraBold, 104–120 px; supporting Regular 52–56 px |
| Quran text inside the phone | As rendered by the app (Amiri Quran). Never overlay Quran text with headlines, never crop an ayah mid-word, never place the Quran near the bottom edge or under a hand |
| Phone frame | Flat, frameless rounded rectangle with a soft shadow; 78–82% of canvas width; top of phone at 30–34% from the top |
| Layout | Headline top (8–26% of height), supporting line under it, phone below, optional callout bubble pointing at the one detail that matters |

**Respect rules:** no music notes, no hands touching the mushaf in photos, no people's faces in the first three frames
(keeps the focus on the user's own words and avoids imagery debates), modest imagery if people are ever shown.

---

## 2.2 The sequence at a glance

| # | Job in the argument | Arabic headline | English headline | What the phone shows |
|---|---|---|---|---|
| 1 | **Hook**: the promise | سمّع حفظك متى شئت | Recite your hifz any time | Recitation result, Al-Fatiha, words coloured |
| 2 | **Emotion**: the listener you lost | لا يسمعك إلا المدرّب | Only the coach is listening | Recording screen at night |
| 3 | **Desire**: keep what you memorized | احفظ… ولا تنسَ | Memorize it. Keep it. | Hifz plan with at-risk ayahs |
| 4 | **Mechanism**: how it keeps it | اختبر حفظك بصوتك | Test your hifz out loud | AI hifz test graded, next review scheduled |
| 5 | **Ease**: it fits your day | دقائق كل يوم تكفي | A few minutes a day | Home "Today's review" card |
| 6 | **Personal**: it learns you | كلماتك الصعبة أولًا | Your tricky words, first | Weak words screen |
| 7 | **Depth and trust**: grounded answers | اسأل… والجواب بآيته | Ask. See the ayah. | Ask the Quran answer with verse cards |
| 8 | **Risk reversal**: safe to try | ابدأ مجانًا، بلا إعلانات | Start free. No ads. | Collage: adhkar, reciters, streak, plus promises |

---

## 2.3 Each screenshot in full

### Screenshot 1: the hook

| | |
|---|---|
| **Objective** | Stop the scroll in search results and make the user *imagine reciting*. If only this frame is seen, it must still sell |
| **Headline (AR)** | **سمّع حفظك متى شئت** (gold on "متى شئت") |
| **Supporting (AR)** | ونُريك أين تعثّرت، كلمة بكلمة. |
| **Headline (EN)** | **Recite your hifz any time** (gold on "any time") |
| **Supporting (EN)** | See exactly where you slipped, word by word. |
| **Layout direction** | Emerald background. Headline top, supporting line under it. Phone centred, showing the recitation result for Al-Fatiha: score circle at top, ayahs below with most words green, **one word amber** (unclear) and **one word red** (missed). A thin gold callout line from the red word to a bubble outside the phone: AR «كلمة فاتتك» / EN "Missed word" |
| **Visual hierarchy** | 1. Headline → 2. the red word and its bubble → 3. the supporting line → 4. the score |
| **Primary focus** | The single red word. One mistake reads as "this is precise", ten mistakes read as "this is harsh" |
| **Emotional trigger** | Curiosity plus recognition ("سمّع" = my childhood teacher) |
| **Psychological goal** | Create the *personal* curiosity gap: "what would it find in mine?" while the familiar verb makes it feel safe |
| **Notes** | Use a realistic demo score in the high 80s, not 100 (a perfect score says "nothing to find") and not 60 (says "this app will make me feel bad") |

### Screenshot 2: the emotion

| | |
|---|---|
| **Objective** | Name the real barrier (no listener, embarrassment) and dissolve it |
| **Headline (AR)** | **لا يسمعك إلا المدرّب** |
| **Supporting (AR)** | سمّع في الحادية عشرة ليلًا أو بعد الفجر، بلا موعد وبلا حرج. وتُحذف تسجيلاتك بعد التحليل. |
| **Headline (EN)** | **Only the coach is listening** |
| **Supporting (EN)** | 11 pm or after Fajr. No appointment, no embarrassment. Recordings are deleted after analysis. |
| **Layout direction** | Paper background. Phone showing the recording screen (mic button active, waveform, timer). Status bar time set to **23:40**. Soft dark vignette around the phone to suggest night. Small lock icon next to the last sentence |
| **Visual hierarchy** | Headline → waveform → "23:40" → privacy line |
| **Primary focus** | The waveform: *your* voice, alone |
| **Emotional trigger** | Relief. Privacy. Intimacy |
| **Psychological goal** | Convert segment C (the quiet perfectionist) and overcome the #1 adult objection to tasmee': being heard making mistakes |

### Screenshot 3: the desire (the subscription story starts here)

| | |
|---|---|
| **Objective** | Shift from "check my recitation" (one-off) to "keep my hifz" (ongoing). This is the frame that makes a subscription make sense later |
| **Headline (AR)** | **احفظ… ولا تنسَ** |
| **Supporting (AR)** | يعرف الآيات التي بدأت تتفلّت منك، ويراجعها معك قبل أن تنساها. |
| **Headline (EN)** | **Memorize it. Keep it.** |
| **Supporting (EN)** | It knows which ayahs are slipping and reviews them with you before they fade. |
| **Layout direction** | Emerald background. Phone showing the hifz screen: surah list with progress bars, three ayahs tagged "at risk" in amber at the top. Callout bubble: AR «٣ آيات معرّضة للنسيان» / EN "3 ayahs at risk" |
| **Visual hierarchy** | Headline → the amber "at risk" tags → the bubble → the surah list |
| **Primary focus** | The at-risk tags. Loss aversion is strongest when it is specific and countable |
| **Emotional trigger** | Gentle loss aversion ("I had Al-Mulk…") and hope ("…and I can keep it") |
| **Psychological goal** | Plant the reason to pay. Segment A sees their lost surahs; segment B sees their review problem solved |

### Screenshot 4: the mechanism

| | |
|---|---|
| **Objective** | Make the hifz promise believable by showing *how* it works |
| **Headline (AR)** | **اختبر حفظك بصوتك** |
| **Supporting (AR)** | تتلو من حفظك، فتُقيَّم كل آية تلقائيًا، وتُجدوَل مراجعتها التالية. |
| **Headline (EN)** | **Test your hifz out loud** |
| **Supporting (EN)** | Recite from memory. Each ayah is graded for you, and its next review is scheduled. |
| **Layout direction** | Paper background. Phone showing the hifz review card: the ayah hidden behind «رتّل ثم اكشف» / "Recite, then reveal", the "Test with AI" button, and the predicted-recall line. A second, slightly offset phone shows the graded result with a line «المراجعة التالية: بعد ٦ أيام» / "Next review: in 6 days". **(Small app change: the review screen shows predicted recall today but not the next date; add that line after grading, it is one field from `hifz_items`.)** Three small step chips above the phones, reading right-to-left in Arabic: «تلاوة ← تقييم ← موعد المراجعة» / EN "Recite → Graded → Scheduled" |
| **Visual hierarchy** | Headline → the three chips → "Next review" line |
| **Primary focus** | "Next review: in 6 days". The system remembers so you don't have to |
| **Emotional trigger** | Competence, control |
| **Psychological goal** | Answer the skeptic ("how does an app know what I'll forget?") with a visible loop, not a claim |

### Screenshot 5: the ease

| | |
|---|---|
| **Objective** | Defuse "I don't have time" and "I've failed before" |
| **Headline (AR)** | **دقائق كل يوم تكفي** |
| **Supporting (AR)** | خطة يومية صغيرة: مراجعة اليوم، وآيات جديدة، وتذكير لطيف واحد. |
| **Headline (EN)** | **A few minutes a day** |
| **Supporting (EN)** | A small daily plan: today's review, new ayahs, one gentle reminder. |
| **Layout direction** | Emerald background. Phone showing Home with the "Today's review" card on top: «مراجعة اليوم · ٦ آيات · حوالي ٥ دقائق» / "Today's review · 6 ayahs · about 5 min", the streak flame small in the corner |
| **Visual hierarchy** | Headline → "about 5 min" → card → streak |
| **Primary focus** | "about 5 min" (the number makes the promise concrete) |
| **Emotional trigger** | Relief, achievability |
| **Psychological goal** | Lower the perceived cost of commitment. People don't fear the Quran; they fear another failed plan |

### Screenshot 6: the personal

| | |
|---|---|
| **Objective** | Show that the app gets to know *you* over time (the value that grows with use, which defends retention and the annual plan) |
| **Headline (AR)** | **كلماتك الصعبة أولًا** |
| **Supporting (AR)** | يجمع الكلمات التي تتعثّر فيها مرة بعد مرة، لتتدرّب عليها قبل غيرها. |
| **Headline (EN)** | **Your tricky words, first** |
| **Supporting (EN)** | It collects the words you keep tripping on, so you practise them before anything else. |
| **Layout direction** | Paper background. Phone showing the weak words screen: 3–4 words in large Quran script with "Missed 3 times" style labels and a "Practise" button |
| **Visual hierarchy** | Headline → the words themselves → "Missed 3 times" → Practise |
| **Primary focus** | The words in Quran script; they make it feel serious, not gamified |
| **Emotional trigger** | Being understood |
| **Psychological goal** | Personalization raises perceived value and switching cost: "it knows *my* mistakes" |

### Screenshot 7: depth and trust

| | |
|---|---|
| **Objective** | Show breadth beyond recitation, while building trust in the AI on sacred text |
| **Headline (AR)** | **اسأل… والجواب بآيته** |
| **Supporting (AR)** | اسأل القرآن وابحث بالمعنى، وكل إجابة تذكر الآية أو الحديث الذي جاءت منه. |
| **Headline (EN)** | **Ask. See the ayah.** |
| **Supporting (EN)** | Ask the Quran and search by meaning. Every answer shows the ayah or hadith it comes from. |
| **Layout direction** | Emerald background. Phone showing an Ask answer to a gentle, universal question (AR «ماذا يقول القرآن عن الصبر؟» / EN "What does the Quran say about patience?") with two verse cards with references visible |
| **Visual hierarchy** | Headline → verse card with reference → the question |
| **Primary focus** | The reference label (e.g. «البقرة ١٥٣»). The proof is the citation |
| **Emotional trigger** | Trust, safety |
| **Psychological goal** | Neutralize "AI + Quran = risky" and give a second reason to install for users who are not memorizing |
| **Notes** | Choose a question with no fiqh disagreement. Never show a ruling |

### Screenshot 8: risk reversal

| | |
|---|---|
| **Objective** | Remove the last objections (cost, ads, clutter) and close |
| **Headline (AR)** | **ابدأ مجانًا، بلا إعلانات** |
| **Supporting (AR)** | كل القرّاء مجانًا، وأذكار الصباح والمساء، وسلسلتك اليومية. لا إعلانات ولا تتبّع إعلاني. |
| **Headline (EN)** | **Start free. No ads.** |
| **Supporting (EN)** | All reciters free, morning and evening adhkar, your daily streak. No ads, no ad tracking. |
| **Layout direction** | Paper background. Three small overlapping phones (adhkar counter, reciter list, streak and goals) instead of one big phone. Under them, three icon promises in a row: «بلا إعلانات» «تسجيلاتك تُحذف» «عربي أولًا» / "No ads", "Recordings deleted", "Arabic first". **(Later)** When real: a rating strip at the top, e.g. «٤٫٨ ★ في السعودية» |
| **Visual hierarchy** | Headline → three promises → phones |
| **Primary focus** | "Free" and "No ads" |
| **Emotional trigger** | Safety, calm |
| **Psychological goal** | Risk reversal at the decision point. The user who scrolled to 8 is interested and looking for a reason not to install; remove it |

---

## 2.4 The connecting device

A thin gold line (the "ribbon") starts under the headline of screenshot 1, runs through the edge of each frame and
ends under the headline of screenshot 8, forming a gentle continuous curve across the gallery. In the Arabic set it
flows right to left. It signals "there is more" (raising swipe-through) and visually ties recitation, memory and daily
practice into one journey. It never crosses Quran text.

---

## 2.5 App preview video (optional, 20–25 s)

Apple autoplays the preview muted in search results, so it must work without sound; with sound, the only audio is the
user's recitation (no music).

| Time | Picture | On-screen text (AR / EN) |
|---|---|---|
| 0–2 s | Night, phone on a desk, mic button pulses | متى آخر مرة سمع أحدٌ تلاوتك؟ / When did anyone last hear you recite? |
| 2–8 s | Real recording of Al-Fatiha, waveform moving | سمّع حفظك متى شئت / Recite your hifz any time |
| 8–12 s | Result appears: green words, one red word, callout | كلمة بكلمة / Word by word |
| 12–17 s | Hifz screen, 3 ayahs at risk, then "Next review: in 6 days" | احفظ… ولا تنسَ / Memorize it. Keep it. |
| 17–22 s | Today's review card, streak +1 | دقائق كل يوم / A few minutes a day |
| 22–25 s | Logo, name | أسمِعني · Asmi3ni |

Use only real app captures; Apple rejects previews that show features or footage not from the app.

---

## 2.6 Google Play specifics

- **Feature graphic (1024 × 500)**: emerald background, left (in AR, right) the headline «سمّع حفظك متى شئت», the other
  side a cropped phone with the coloured Al-Fatiha result. No text in the outer 15% (Play crops it on some surfaces).
- **Icon**: no badges, no "free", no "AI" text on the icon (Play policy forbids promotional text on icons).
- Use the same 8 frames. Play shows them larger, so the supporting line can stay.

## 2.7 What to test first (Product Page Optimization / Store listing experiments)

| Test | Control | Variant | Metric | Why |
|---|---|---|---|---|
| 1 | Screenshot 1 = recitation result (hook #1) | Screenshot 1 = hifz at-risk (hook #4 first) | Page view → install | Is curiosity (be heard) or loss (keep it) the better opener? We bet on curiosity |
| 2 | Screenshot 2 = privacy ("only the coach is listening") | Screenshot 2 = "متى آخر مرة سمع أحدٌ تلاوتك؟" | Page view → install, D1 | Emotion: relief vs realization |
| 3 | Emerald backgrounds | All paper backgrounds | Page view → install | Contrast in a Quran category full of green |

Run one test at a time, for at least 7 days, and only call a winner at 90% confidence (the level App Store Connect
reports). Treat relative differences under 5% as noise at launch traffic levels.
