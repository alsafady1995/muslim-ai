# 3. Store listings: App Store and Google Play

Paste-ready copy. Arabic is the primary localization for Saudi Arabia and the Gulf; English (U.S.) is the second, and
English (U.K.) is used as an extra keyword slot on the App Store. Character counts were measured with Python
(`len()`); App Store Connect and Play Console count the same way for these strings, but re-check after pasting.

Policy guardrails applied to every line: no competitor names (App Store 2.3.7, Play metadata policy), no "best",
"#1" or ranking claims, no testimonials, no emojis or promo words in titles, no features that are not built, and full
auto-renewal disclosure in the Apple description (3.1.2).

---

## 3.1 Name, subtitle, keywords

| Field | Limit | العربية | Count | English | Count |
|---|---|---|---|---|---|
| **App name** (Apple) / **Title** (Play) | 30 | أسمِعني: تسميع وحفظ القرآن | 26 | Asmi3ni: Quran Hifz Coach | 25 |
| **Subtitle** (Apple) | 30 | مدرب يسمع تلاوتك ويراجع حفظك | 28 | Recitation checker & hifz plan | 30 |
| **Keywords** (Apple) | 100 | `تلاوة,تصحيح,مراجعة,تحفيظ,قران,مصحف,جزء عم,أذكار,سورة,حافظ,اسمعني,سمعني,تفسير,معلم,الكهف,الملك,أخطاء` | 99 | `memorize,hafiz,tahfiz,muslim,islamic,surah,juz,amma,adhkar,tutor,asmani,asmeeni,koran,mistakes` | 94 |
| **Promotional text** (Apple, editable without review) | 170 | سمّع الفاتحة الآن مجانًا، وشاهد تلاوتك كلمة بكلمة. ثم ابدأ خطة حفظ صغيرة تراجع معك ما حفظت قبل أن تنساه. بلا إعلانات. | 117 | Recite Al-Fatiha free and see your recitation word by word. Then start a small hifz plan that reviews what you memorized before it fades. No ads. | 145 |
| **Short description** (Play) | 80 | سمّع حفظك بصوتك، واعرف أين تعثّرت كلمة بكلمة، وراجع ما حفظت قبل أن تنساه | 72 | Recite from memory, see where you slipped word by word, and keep what you know | 78 |

**English (U.K.) keyword slot** (indexed in Saudi Arabia and most storefronts alongside the primary locale):
`quran memorization,recitation app,tasmee,hifdh,hifz tracker,ayah,dhikr,quran audio,reciters,juz amma`
(remove any word that ends up duplicated in the U.S. name or subtitle).

### Why these choices

- **Name = brand + the two highest-intent Arabic terms.** "تسميع" and "حفظ القرآن" are exactly what segment A and B
  type, and Apple weights the name most. "أسمِعني" alone ranks for nothing on day one.
- **Subtitle is a benefit sentence that also carries keywords** (مدرب، تلاوة، مراجعة، حفظ). It reads like a promise,
  not a list, which matters because it is shown in every search result.
- **"Hifz" in the English name** is the term the English-speaking Muslim audience searches; "memorization" is in the
  keywords.
- **Spelling variants** (`اسمعني`, `سمعني`, `asmani`, `asmeeni`) catch people who heard the name and try to type it.
- **No "tajweed" anywhere.** It is a high-volume keyword, but the app does not coach tajweed yet. Ranking for it would
  bring the users most likely to leave a 1-star review. Add it the day tajweed detection ships.
- **No "prayer times" or "qibla".** Not built; ranking for them would tank conversion and ratings.
- **Category:** Education (primary), Reference (secondary). Education has fewer Quran apps than Reference and matches
  "coach".

---

## 3.2 Apple App Store description (Arabic)

```
سمّع حفظك متى شئت… واعرف أين تعثّرت، كلمة بكلمة.

أسمِعني رفيقك في التسميع. تتلو بصوتك، فيستمع المدرّب الذكي إلى تلاوتك ويُريك النتيجة كلمة بكلمة: ما فاتك، وما أخطأت فيه، وما زدته، وما لم يكن واضحًا. ثم يبني لك خطة حفظ تراجع معك ما حفظت قبل أن يتفلّت منك.

بلا موعد، وبلا حرج، وبلا إعلانات.

■ سمّع لمن يسمعك
• رتّل أي سورة أو مقطع بصوتك، وشاهد النتيجة خلال ثوانٍ.
• كل كلمة تظهر بلونها: سليمة، أو غير واضحة، أو فائتة، أو خاطئة.
• ابدأ بالفاتحة: أول تسميع مجاني ولا يُحتسب من رصيدك.

■ احفظ… ولا تنسَ ما حفظت
• خطة حفظ يومية بعدد الآيات الذي يناسبك.
• مراجعة بالتكرار المتباعد: تراجع الآية قبل أن تنساها، لا بعد.
• يعرض لك الآيات المعرّضة للنسيان لتبدأ بها.
• اختبر حفظك بصوتك، فيُقيَّم تلقائيًا وتُحدَّد مراجعتك التالية.
• أخبرنا بالسور التي تحفظها، فنضيفها إلى مراجعتك من اليوم الأول.

■ كلماتك الصعبة أولًا
• يجمع الكلمات التي تتعثّر فيها مرة بعد مرة، لتتدرّب عليها قبل غيرها.

■ اسأل القرآن وابحث بالمعنى
• اسأل سؤالك، فتأتيك الإجابة مع الآيات والأحاديث التي استندت إليها، بمراجعها.
• ابحث بالمعنى، مثل: «آيات عن الصبر».

■ وردك اليومي
• القرآن آية بآية، مع ترجمة وتفسير باللغة الإنجليزية.
• نحو عشرة من كبار القرّاء، كلهم مجانًا، مع التكرار والتحكم في السرعة.
• أذكار الصباح والمساء والنوم، مع عدّاد وتذكير لطيف.
• أهداف يومية وسلسلة أيام ونقاط، وحماية للسلسلة إن فاتك يوم.

■ خصوصيتك
• لا إعلانات ولا تتبّع إعلاني.
• تُحذف تسجيلاتك الصوتية مباشرة بعد تحليلها.

■ مجاني للبدء
الخطة المجانية تشمل القراءة والاستماع والأذكار والمراجعة الذاتية بلا حدود، و١٠ تسميعات و٥ اختبارات حفظ ذكية كل أسبوع (حتى ٦٠ ثانية لكلٍّ منها).

■ أسمِعني المميز
• تسميع واختبارات حفظ أكثر بكثير، حتى ٣ دقائق في المرة (صفحة كاملة).
• تدريب كامل على كلماتك الصعبة.
• أقوى نموذج ذكاء اصطناعي لدينا في «اسأل القرآن».

كلمة صادقة: المدرّب الذكي رفيق تدريب بين دروسك مع معلّمك، وليس بديلًا عن التلقّي من معلّم متقن. وقد يخطئ أحيانًا، فإن لاحظت ذلك فأخبرنا من داخل التطبيق.

الاشتراك
• سنوي مع تجربة مجانية لمدة ٧ أيام للمشتركين الجدد، أو شهري بدون تجربة. يظهر السعر بعملتك داخل التطبيق قبل الشراء.
• يُخصم المبلغ من حساب Apple عند تأكيد الشراء، أو عند انتهاء التجربة المجانية.
• يتجدد الاشتراك تلقائيًا ما لم يُلغَ قبل ٢٤ ساعة على الأقل من نهاية الفترة الحالية، ويُخصم التجديد خلال الـ٢٤ ساعة السابقة لنهايتها.
• يمكنك إدارة اشتراكك وإلغاؤه من إعدادات حسابك في App Store.
• أي جزء غير مستخدم من التجربة المجانية يسقط عند الاشتراك.

سياسة الخصوصية: https://asmi3ni.com/privacy/
شروط الاستخدام: https://asmi3ni.com/terms/
```

## 3.3 Apple App Store description (English)

```
Recite from memory any time. See exactly where you slipped, word by word.

Asmi3ni (أسمِعني, "let me hear you") is your recitation partner. Recite out loud and the AI coach listens, then shows your result word by word: what you missed, what was wrong, what you added and what wasn't clear. Then it builds a hifz plan that reviews what you memorized before it slips away.

No appointment. No embarrassment. No ads.

RECITE TO SOMEONE WHO LISTENS
• Recite any surah or passage and see your result in seconds.
• Every word in its colour: correct, unclear, missed or wrong.
• Start with Al-Fatiha. Your first check is free and doesn't count toward any limit.

MEMORIZE IT. THEN KEEP IT.
• A daily hifz plan at the pace you choose.
• Spaced-repetition reviews: revise each ayah before you forget it, not after.
• See the ayahs at risk of being forgotten and review them first.
• Test your hifz out loud. Grading is automatic and schedules your next review.
• Tell us the surahs you already know and they join your reviews from day one.

YOUR TRICKY WORDS, FIRST
• The words you keep tripping on are collected so you practise them before anything else.

ASK THE QURAN AND SEARCH BY MEANING
• Ask a question and get an answer with the ayahs and hadith it is based on, with references.
• Search by meaning, like "verses about patience".

YOUR DAILY QURAN
• The Quran ayah by ayah, with English translation and tafsir.
• About ten renowned reciters, all free, with repeat and speed control.
• Morning, evening and sleep adhkar with a counter and gentle reminders.
• Daily goals, streaks and XP, with a streak freeze if you miss a day.

YOUR PRIVACY
• No ads and no ad tracking.
• Your recordings are deleted right after analysis.

FREE TO START
The free plan includes unlimited reading, listening, adhkar and self-graded reviews, plus 10 recitation checks and 5 AI hifz tests every week (up to 60 seconds each).

ASMI3NI PREMIUM
• Many more recitation checks and hifz tests, up to 3 minutes each (a full page).
• The full weak-words drill.
• Our most capable AI for Ask the Quran.

An honest note: the AI coach is a practice partner between lessons with your teacher, not a replacement for learning from a qualified teacher. It can sometimes be wrong; if you notice, tell us from inside the app.

SUBSCRIPTION
• Yearly with a 7-day free trial for new subscribers, or monthly with no trial. Prices in your currency are shown in the app before you buy.
• Payment is charged to your Apple ID at confirmation of purchase, or when the free trial ends.
• Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period; renewal is charged within the 24 hours before it ends.
• Manage or cancel anytime in your App Store account settings.
• Any unused part of a free trial is forfeited when you subscribe.

Privacy Policy: https://asmi3ni.com/privacy/
Terms of Use: https://asmi3ni.com/terms/
```

**Description strategy.** Apple does not index the description for search, so it is written purely to convert the
minority who tap "more": the hook first line (shown before "more"), then the three pillars in the order of the
screenshots (be heard → keep it → it knows you), then breadth, then risk reversal (privacy, free plan), then the honest
note, then legal. The honest note is deliberate: it pre-empts the "it's not a real teacher" review and is the kind of
humility this audience trusts.

---

## 3.4 Google Play full description (Arabic)

Play indexes the full description, so key terms (تسميع، حفظ القرآن، مراجعة الحفظ، تلاوة، تحفيظ) appear naturally 3–5
times each, never in lists of keywords (Play penalizes that).

```
سمّع حفظك متى شئت… واعرف أين تعثّرت، كلمة بكلمة.

أسمِعني تطبيق تسميع وحفظ القرآن الكريم. تتلو بصوتك، فيستمع المدرّب الذكي إلى تلاوتك ويُريك النتيجة كلمة بكلمة: ما فاتك، وما أخطأت فيه، وما زدته، وما لم يكن واضحًا. ثم يبني لك خطة لحفظ القرآن ومراجعة الحفظ، تراجع معك كل آية قبل أن تتفلّت منك.

بلا موعد، وبلا حرج، وبلا إعلانات.

سمّع لمن يسمعك
• تسميع القرآن بصوتك في أي وقت، والنتيجة خلال ثوانٍ.
• كل كلمة تظهر بلونها: سليمة، أو غير واضحة، أو فائتة، أو خاطئة.
• ابدأ بتسميع الفاتحة مجانًا، ولا يُحتسب من رصيدك.

احفظ… ولا تنسَ ما حفظت
• خطة تحفيظ يومية بعدد الآيات الذي يناسبك.
• مراجعة الحفظ بالتكرار المتباعد: تراجع الآية قبل أن تنساها.
• تعرض لك الآيات المعرّضة للنسيان لتبدأ بها.
• اختبر حفظك بتلاوتك، والتقييم تلقائي ويحدد مراجعتك التالية.
• أضف السور التي تحفظها من قبل، فتدخل مراجعتك من اليوم الأول.

كلماتك الصعبة أولًا
• يجمع الكلمات التي تتعثّر فيها في تلاوتك مرة بعد مرة، لتتدرّب عليها قبل غيرها.

اسأل القرآن وابحث بالمعنى
• اسأل سؤالك، فتأتيك الإجابة مع الآيات والأحاديث التي استندت إليها، بمراجعها.
• ابحث بالمعنى، مثل: «آيات عن الصبر».

وردك اليومي
• القرآن الكريم آية بآية، مع ترجمة وتفسير باللغة الإنجليزية.
• نحو عشرة من كبار القرّاء، كلهم مجانًا، مع التكرار والتحكم في السرعة.
• أذكار الصباح والمساء والنوم، مع عدّاد وتذكير لطيف.
• أهداف يومية وسلسلة أيام ونقاط، وحماية للسلسلة إن فاتك يوم.

خصوصيتك
• لا إعلانات ولا تتبّع إعلاني.
• تُحذف تسجيلاتك الصوتية مباشرة بعد تحليلها.

مجاني للبدء
القراءة والاستماع والأذكار والمراجعة الذاتية بلا حدود، و١٠ تسميعات و٥ اختبارات حفظ ذكية كل أسبوع (حتى ٦٠ ثانية لكلٍّ منها).

أسمِعني المميز
• تسميع واختبارات حفظ أكثر بكثير، حتى ٣ دقائق في المرة (صفحة كاملة).
• تدريب كامل على كلماتك الصعبة.
• أقوى نموذج ذكاء اصطناعي لدينا في «اسأل القرآن».
• اشتراك سنوي مع تجربة مجانية ٧ أيام للمشتركين الجدد، أو شهري. يتجدد تلقائيًا، ويمكنك الإلغاء في أي وقت من Google Play.

كلمة صادقة: المدرّب الذكي رفيق تدريب بين دروسك مع معلّمك، وليس بديلًا عن التلقّي من معلّم متقن. وقد يخطئ أحيانًا، فإن لاحظت ذلك فأخبرنا من داخل التطبيق.

سياسة الخصوصية: https://asmi3ni.com/privacy/
```

## 3.5 Google Play full description (English)

```
Recite from memory any time. See exactly where you slipped, word by word.

Asmi3ni (أسمِعني, "let me hear you") is a Quran recitation and hifz app. Recite out loud and the AI coach listens, then shows your recitation word by word: what you missed, what was wrong, what you added and what wasn't clear. Then it builds a Quran memorization plan that reviews every ayah before it slips away.

No appointment. No embarrassment. No ads.

RECITE TO SOMEONE WHO LISTENS
• Check your Quran recitation out loud any time and see the result in seconds.
• Every word in its colour: correct, unclear, missed or wrong.
• Start with Al-Fatiha. Your first check is free and doesn't count toward any limit.

MEMORIZE IT. THEN KEEP IT.
• A daily hifz plan at the pace you choose.
• Spaced-repetition hifz review: revise each ayah before you forget it.
• See the ayahs at risk of being forgotten and review them first.
• Test your memorization by reciting. Grading is automatic and schedules your next review.
• Add the surahs you already know and they join your reviews from day one.

YOUR TRICKY WORDS, FIRST
• The words you keep tripping on in your recitation are collected so you practise them first.

ASK THE QURAN AND SEARCH BY MEANING
• Ask a question and get an answer with the ayahs and hadith it is based on, with references.
• Search by meaning, like "verses about patience".

YOUR DAILY QURAN
• The Quran ayah by ayah, with English translation and tafsir.
• About ten renowned reciters, all free, with repeat and speed control.
• Morning, evening and sleep adhkar with a counter and gentle reminders.
• Daily goals, streaks and XP, with a streak freeze if you miss a day.

YOUR PRIVACY
• No ads and no ad tracking.
• Your recordings are deleted right after analysis.

FREE TO START
Unlimited reading, listening, adhkar and self-graded reviews, plus 10 recitation checks and 5 AI hifz tests every week (up to 60 seconds each).

ASMI3NI PREMIUM
• Many more recitation checks and hifz tests, up to 3 minutes each (a full page).
• The full weak-words drill.
• Our most capable AI for Ask the Quran.
• Yearly with a 7-day free trial for new subscribers, or monthly. Renews automatically; cancel anytime in Google Play.

An honest note: the AI coach is a practice partner between lessons with your teacher, not a replacement for learning from a qualified teacher. It can sometimes be wrong; if you notice, tell us from inside the app.

Privacy Policy: https://asmi3ni.com/privacy/
```

> Before publishing: "tell us from inside the app" needs a feedback path for recitation results. Ask the Quran already
> has a report button; the recitation result does not. Either ship the "this word was right" tap
> (`04-subscription-page.md` §6) or change the line to "email support@asmi3ni.com".

---

## 3.6 Other store fields

| Field | العربية | English |
|---|---|---|
| What's New (v1.0) | الإصدار الأول من أسمِعني. سمّع الفاتحة وشاهد تلاوتك كلمة بكلمة، ثم ابدأ خطة حفظك. نسعد بملاحظاتك على support@asmi3ni.com | The first release of Asmi3ni. Recite Al-Fatiha, see your recitation word by word, then start your hifz plan. We'd love your feedback at support@asmi3ni.com |
| Subscription display name (Apple) | أسمِعني المميز · سنوي / شهري | Asmi3ni Premium · Yearly / Monthly |
| Subscription description (Apple, 55 chars) | مدرّب الحفظ الكامل: تسميع واختبارات أكثر | Full Hifz Coach: more checks and AI tests |
| Age rating | 4+ (no user-generated content shared publicly) | |
| Support URL / Marketing URL | https://asmi3ni.com/ | |
| Primary / secondary category | Education / Reference | |

## 3.7 Seasonal metadata (no review needed for promotional text)

| When | Promotional text (AR) | Promotional text (EN) |
|---|---|---|
| 15 Sha'ban → Ramadan (≈ 23 Jan – 7 Feb 2027) | استعدّ لرمضان: سمّع ما تحفظ الآن، وابدأ خطة مراجعة صغيرة تثبّت حفظك قبل الشهر الكريم. | Get ready for Ramadan: recite what you know now and start a small review plan before the blessed month. |
| Ramadan (≈ 8 Feb – 9 Mar 2027) | رمضان مبارك. اجعل رمضان هذا العام أثبت تلاوة في حياتك: سمّع كل يوم، وراجع ما حفظت. | Ramadan Mubarak. Make this your most confident recitation yet: recite daily and keep what you memorized. |
| After Eid | حافظ على ما راجعته في رمضان: خمس دقائق يوميًا تكفي. | Keep what you revised in Ramadan: a few minutes a day is enough. |

Dates follow the expected Umm al-Qura calendar and must be confirmed nearer the time.

**In-app events (Apple) / Promotional content (Play)** to submit at least 2 weeks ahead: "تحدّي جزء عمّ قبل العيد /
Juz Amma before Eid" (Ramadan), "مراجعة العشر الأواخر / Last Ten Nights review" (last 10 nights). Both need the
Ramadan plan from `docs/full-audit.md` G1 **(to build)**; submit only once it ships.
