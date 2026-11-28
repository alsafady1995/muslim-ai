# 5. Landing page: asmi3ni.com

Every word, Arabic first (the page is `dir="rtl"` by default, with an English toggle that switches to `/en/`).
Replaces the current one-paragraph `site/index.html`; privacy, terms and account deletion pages stay as they are.

**The page has one job:** get the visitor to install and recite Al-Fatiha today. Every section either increases the
desire to try, or removes a reason not to. One CTA repeated, never two competing ones.

**Technical notes for whoever builds it:** static HTML in `site/` (GitHub Pages already serves it), no third-party
trackers (a page that says "no ad tracking" must not load Meta Pixel), store badges with smart links that detect iOS
or Android, Open Graph image = screenshot 1, page weight under 300 KB, Quran text as text (Amiri Quran web font), never
as an image of a mushaf.

---

## Section 1: Hero

| Element | العربية | English |
|---|---|---|
| Eyebrow | أسمِعني · مدرّب التسميع والحفظ | Asmi3ni · Recitation and hifz coach |
| **Headline (H1)** | **سمّع حفظك متى شئت.** | **Recite your hifz any time.** |
| Subheadline | تتلو بصوتك، فيُريك أسمِعني أين تعثّرت كلمة بكلمة، ثم يراجع معك ما حفظت قبل أن تنساه. | Recite out loud. Asmi3ni shows where you slipped, word by word, then reviews what you memorized before it fades. |
| Primary CTA | حمّل التطبيق وسمّع الفاتحة مجانًا | Get the app and recite Al-Fatiha free |
| Store badges | App Store · Google Play | App Store · Google Play |
| Micro-trust line under the CTA | مجاني للبدء · بلا إعلانات · تُحذف تسجيلاتك بعد التحليل | Free to start · No ads · Recordings deleted after analysis |
| Visual | Phone with the Al-Fatiha result (screenshot 1 phone), one red word with its callout. On desktop: phone on the left side of the RTL layout, text on the right | |

**Why:** the headline is the 5-second message; the subheadline adds the two pillars (be heard, keep it); the CTA names
the first action and makes it free, so the click is a 60-second experiment, not a commitment.

---

## Section 2: Hook (the question)

| العربية | English |
|---|---|
| **متى آخر مرة سمع أحدٌ تلاوتك؟** | **When did anyone last listen to you recite?** |
| حين كنت صغيرًا كان هناك دائمًا من يقول لك: «أسمِعني». يستمع، ويوقفك عند الكلمة، وتعيد. ثم كبرنا، وانشغل المعلّمون، وصار التسميع أمام الناس محرجًا، وبقي السؤال في القلب: هل ما زلت أقرؤها كما ينبغي؟ هل ما زالت معي؟ | When you were young, there was always someone who said "let me hear you." They listened, stopped you at the word, and you tried again. Then we grew up, teachers got busy, reciting in front of people became awkward, and one question stayed: am I still reciting it right? Is it still with me? |

**Why:** recognition before persuasion. The visitor sees their own story, and the brand name becomes its answer.

---

## Section 3: Value proposition

| العربية | English |
|---|---|
| **أسمِعني يعيد إليك من يسمعك.** | **Asmi3ni gives you back someone who listens.** |
| مدرّب ذكي تسمّع له في أي وقت، يُريك تلاوتك كلمة بكلمة، ويتذكّر عنك ما يحتاج إلى مراجعة. بلا موعد، وبلا حرج، وبلا إعلانات. | An AI coach you can recite to any time, that shows your recitation word by word and remembers what needs reviewing, so you don't have to. No appointment, no embarrassment, no ads. |

---

## Section 4: The problem

Heading: **لماذا يتفلّت الحفظ؟** / **Why does hifz slip away?**

| # | العربية | English |
|---|---|---|
| 1 | **لا تسمع أخطاءك.** الأذن تعتاد على ما تقرؤه، فتمرّ الكلمة الخاطئة كأنها صحيحة سنوات. | **You can't hear your own slips.** Your ear gets used to how you read, so a wrong word can pass as right for years. |
| 2 | **لا تجد من يسمعك.** المعلّم وقته محدود، والأهل مشغولون، والوقت الذي تفرغ فيه هو الحادية عشرة ليلًا. | **There's no one to recite to.** Teachers have limited time, family is busy, and your free moment is 11 pm. |
| 3 | **تراجع ما تعرفه، وتنسى ما لا تراجعه.** نعيد السور السهلة لأنها مريحة، والآيات التي بدأت تضعف تبقى بلا مراجعة حتى تضيع. | **You revise what you know and lose what you don't.** We repeat the easy surahs because they feel good, while the weak ayahs go unrevised until they are gone. |

---

## Section 5: The solution (how it works)

Heading: **ثلاث خطوات. دقائق كل يوم.** / **Three steps. A few minutes a day.**

| Step | العربية | English | Visual |
|---|---|---|---|
| 1 | **سمّع.** اختر السورة أو الآيات، واضغط زر التسجيل، واتلُ من حفظك أو من المصحف. | **Recite.** Pick the surah or ayahs, tap record, and recite from memory or from the text. | Recording screen |
| 2 | **شاهد.** خلال ثوانٍ تظهر تلاوتك كلمة بكلمة: سليمة، أو غير واضحة، أو فائتة، أو خاطئة، أو زائدة. | **See.** In seconds your recitation appears word by word: correct, unclear, missed, wrong or added. | Result screen |
| 3 | **ثبّت.** يضيف أسمِعني ما حفظت إلى خطة مراجعة ذكية، ويُريك كل يوم ما يحتاج إلى مراجعة قبل أن يضعف. | **Keep it.** Asmi3ni adds what you memorized to a smart review plan and shows you each day what needs revising before it fades. | Today's review card |

---

## Section 6: Features

Heading: **كل ما تحتاجه لتسميع وحفظ القرآن، في مكان واحد هادئ.** / **Everything for reciting and memorizing the Quran, in one calm place.**

| Feature | العربية | English |
|---|---|---|
| Recitation check | **تسميع كلمة بكلمة.** رتّل أي مقطع، حتى ٦٠ ثانية مجانًا و٣ دقائق في المميز. | **Word-by-word recitation check.** Any passage, up to 60 seconds free and 3 minutes with Premium. |
| Hifz plan | **خطة حفظ يومية.** بعدد الآيات الذي يناسبك، مع إضافة ما تحفظه من قبل. | **A daily hifz plan.** At your pace, including the surahs you already know. |
| Spaced review | **مراجعة قبل النسيان.** جدولة بالتكرار المتباعد، وتنبيه للآيات المعرّضة للنسيان. | **Review before you forget.** Spaced-repetition scheduling and a list of at-risk ayahs. |
| AI hifz test | **اختبر حفظك بصوتك.** التقييم تلقائي، ويحدد موعد المراجعة التالية. | **Test your hifz out loud.** Graded for you, and the next review is scheduled. |
| Weak words | **كلماتك الصعبة.** يجمع ما تتعثّر فيه لتتدرّب عليه أولًا. | **Your tricky words.** Collected so you practise them first. |
| Ask the Quran | **اسأل القرآن.** إجابات تذكر الآيات والأحاديث التي استندت إليها بمراجعها. | **Ask the Quran.** Answers that show the ayahs and hadith they are based on, with references. |
| Meaning search | **ابحث بالمعنى.** «آيات عن الصبر»، «آيات عن الرزق». | **Search by meaning.** "Verses about patience", "verses about provision". |
| Listen | **كبار القرّاء مجانًا.** نحو عشرة قرّاء، مع التكرار والتحكم في السرعة. | **Renowned reciters, free.** About ten reciters with repeat and speed control. |
| Adhkar | **أذكار الصباح والمساء.** مع عدّاد وتذكير لطيف. | **Morning and evening adhkar.** With a counter and gentle reminders. |
| Habit | **سلسلة وأهداف.** وحماية للسلسلة إن فاتك يوم، لأن العودة أهم من الكمال. | **Streaks and goals.** With a streak freeze if you miss a day, because coming back matters more than being perfect. |

---

## Section 7: Benefits (what changes in your life)

Heading: **ما الذي يتغيّر؟** / **What changes?**

| العربية | English |
|---|---|
| **من «أظن أني أحفظها» إلى «أعرف أني أحفظها».** | **From "I think I know it" to "I know I know it."** |
| **تصلّي بالسور التي حفظتها قديمًا، لا بالقصار نفسها كل يوم.** | **You pray with the surahs you memorized long ago, not the same short ones every day.** |
| **تسمّع لمعلّمك وأنت أكثر ثقة،** لأنك راجعت قبل الدرس. | **You recite to your teacher with more confidence,** because you practised before the lesson. |
| **خمس دقائق ثابتة كل يوم** بدل حماسة رمضان التي تنطفئ في الأسبوع الثاني. | **Five steady minutes a day** instead of Ramadan zeal that fades in week two. |

---

## Section 8: Honest comparison (optional block, test it)

Heading: **لماذا أسمِعني؟** / **Why Asmi3ni?**

| | أسمِعني / Asmi3ni | تطبيقات المصحف الشاملة / All-in-one Quran apps | مدرّبات التلاوة الأخرى / Other recitation coaches |
|---|---|---|---|
| يستمع إلى تلاوتك / Listens to your recitation | ✓ | ✗ | ✓ |
| يعرف ما ستنساه ويجدول مراجعته / Knows what you're forgetting and schedules it | ✓ | ✗ | Partly / جزئيًا |
| بلا إعلانات / No ads | ✓ | Often not / غالبًا لا | ✓ |
| مصمَّم بالعربية أولًا / Arabic first | ✓ | Varies / يختلف | Varies / يختلف |
| السعر السنوي في السعودية / Yearly price in Saudi Arabia | ١٠٩٫٩٩ ريال / SAR 109.99 | — | حتى ٣٤٩٫٩٩ ريال / up to SAR 349.99 |

Footnote: «الأسعار من متجر App Store السعودي، بتاريخ …» / "Prices from the Saudi App Store on [date]." Update the
date on every change. Categories, not names: we compare honestly without attacking anyone.

---

## Section 9: Testimonials (placeholders only)

> ⚠️ **Do not publish this section until real quotes exist.** Use only quotes from real beta testers or users, with
> written permission, first name and city only, unedited except for length. No invented names, no stock photos, no
> star ratings that are not from the stores.

Heading: **من مستخدمي أسمِعني** / **From people using Asmi3ni**

| Slot | Who we want (segment) | Placeholder |
|---|---|---|
| 1 | Returning memorizer (A) | «[اقتباس حقيقي من مستخدم]» — [الاسم الأول]، [المدينة] / "[Real user quote]" — [First name], [City] |
| 2 | Halaqa student (B) | «[اقتباس حقيقي من مستخدم]» — [الاسم الأول]، [المدينة] |
| 3 | Parent or teacher | «[اقتباس حقيقي من معلّم أو ولي أمر]» — [الاسم الأول]، [المدينة] |

**Before real quotes exist**, use this block instead (true from day one):

| العربية | English |
|---|---|
| **لماذا بنيت أسمِعني** — [رسالة قصيرة من المؤسس بصوته: لماذا بدأ، ولمن، وما الذي لن يفعله التطبيق أبدًا (إعلانات، بيع البيانات)]. | **Why I built Asmi3ni** — [a short note in the founder's own voice: why, for whom, and what the app will never do (ads, selling data)]. |

---

## Section 10: FAQ

| # | السؤال | الجواب | Question | Answer |
|---|---|---|---|---|
| 1 | هل التطبيق مجاني؟ | نعم للبدء. القراءة والاستماع وجميع القرّاء والأذكار وخطة الحفظ والمراجعة الذاتية بلا حدود، و١٠ تسميعات و٥ اختبارات حفظ ذكية كل أسبوع. الاشتراك المميز يضيف تسميعًا أكثر بكثير وصفحة كاملة في المرة. | Is it free? | Yes, to start. Reading, listening, all reciters, adhkar, your hifz plan and self-graded reviews are unlimited, plus 10 recitation checks and 5 AI hifz tests every week. Premium adds many more checks and a full page at a time. |
| 2 | هل يصحح التجويد؟ | ليس بعد. أسمِعني اليوم يُريك الكلمات الفائتة والخاطئة والزائدة وغير الواضحة. أحكام التجويد مرحلة قادمة، ولن نعلن عنها قبل أن تكون دقيقة. | Does it correct tajweed? | Not yet. Today Asmi3ni shows missed, wrong, added and unclear words. Tajweed rules are a later phase, and we won't announce them until they are accurate. |
| 3 | هل يصحح أثناء التلاوة مباشرة؟ | تسمّع حتى تنتهي، ثم تظهر النتيجة كلمة بكلمة خلال ثوانٍ. هكذا لا يقطع عليك تلاوتك. | Does it correct me while I recite? | You recite to the end, then your word-by-word result appears within seconds, so your recitation isn't interrupted. |
| 4 | هل يغني عن المعلّم؟ | لا. أسمِعني رفيق تدريب بين دروسك مع معلّمك، يساعدك على المراجعة اليومية، ولا يغني عن التلقّي من معلّم متقن. | Does it replace a teacher? | No. Asmi3ni is a practice partner between lessons with your teacher. It helps with daily review; it does not replace learning from a qualified teacher. |
| 5 | ماذا لو أخطأ المدرّب؟ | قد يحدث، خاصة مع التسجيل في مكان صاخب. الكلمات التي لا يتأكد منها تظهر «غير واضحة» بدل «خاطئة». | What if the coach is wrong? | It can happen, especially with a noisy recording. Words it isn't sure about show as "unclear" rather than "wrong". |
| 6 | أين تذهب تسجيلاتي؟ | تُحلَّل ثم تُحذف مباشرة. لا إعلانات في التطبيق ولا تتبّع إعلاني. | What happens to my recordings? | They are analysed and deleted right away. No ads and no ad tracking. |
| 7 | هل يناسب النساء والأطفال؟ | نعم، يمكن لأي أحد أن يسمّع بصوته. ونعمل على تحسين الدقة لأصوات الأطفال والنساء ضمن قياس الدقة الجاري. | Is it for women and children? | Yes, anyone can recite. We are improving accuracy for children's and women's voices as part of our ongoing accuracy measurement. |
| 8 | ما الفرق بين الشهري والسنوي؟ | السنوي ١٠٩٫٩٩ ريال (نحو ٩٫١٧ ريال شهريًا) مع تجربة مجانية ٧ أيام، والشهري ١٨٫٩٩ ريال بدون تجربة. الإلغاء في أي وقت من إعدادات المتجر. | Monthly or yearly? | Yearly is SAR 109.99 (about SAR 9.17 a month) with a 7-day free trial; monthly is SAR 18.99 with no trial. Cancel anytime in your store settings. |
| 9 | هل يعمل بدون إنترنت؟ | القراءة تحتاج اتصالًا اليوم، والتسميع يحتاج اتصالًا دائمًا لأن التحليل يتم على خوادمنا. التحميل للقراءة بدون إنترنت قادم. | Does it work offline? | Reading needs a connection today, and recitation checks always do, because analysis runs on our servers. Offline reading is coming. |
| 10 | من أين تأتي إجابات «اسأل القرآن»؟ | من نصوص القرآن والحديث والتفسير المخزّنة لدينا، وكل إجابة تذكر مصادرها. لا يصدر التطبيق فتاوى. | Where do Ask the Quran answers come from? | From the Quran, hadith and tafsir texts we hold, and every answer shows its sources. The app does not issue fatwas. |

**Why FAQ 2, 3, 4, 9 exist:** they are the questions a skeptical, informed Gulf user will ask, and answering them
honestly *before* they install is cheaper than answering them in 1-star reviews. FAQ 7 is a claim we can only make
gently until the benchmark reports per-group accuracy.

---

## Section 11: Final CTA

| العربية | English |
|---|---|
| **أسمِعني الفاتحة.** | **Let me hear your Al-Fatiha.** |
| دقيقة واحدة، مجانًا، وتعرف أين تقف. | One minute, free, and you'll know where you stand. |
| [App Store] [Google Play] | [App Store] [Google Play] |
| بلا إعلانات · تُحذف تسجيلاتك بعد التحليل · الإلغاء في أي وقت | No ads · Recordings deleted after analysis · Cancel anytime |

**Why:** the closing line turns the brand name into a direct, warm request (the app is speaking, as a teacher would),
and restates the smallest possible first step.

---

## Footer

أسمِعني · الخصوصية · الشروط · حذف الحساب · support@asmi3ni.com · © 2026
Asmi3ni · Privacy · Terms · Delete account · support@asmi3ni.com · © 2026

## SEO and sharing

| Field | العربية | English |
|---|---|---|
| `<title>` | أسمِعني: تسميع وحفظ القرآن بصوتك | Asmi3ni: Recite and memorize the Quran out loud |
| Meta description (≤ 155) | سمّع حفظك متى شئت، وشاهد تلاوتك كلمة بكلمة، وراجع ما حفظت قبل أن تنساه. مجاني للبدء، بلا إعلانات. | Recite your hifz any time, see your recitation word by word, and review what you memorized before it fades. Free to start, no ads. |
| OG image | Screenshot 1 (Arabic) at 1200 × 630 | Screenshot 1 (English) |

## Measurement (no third-party trackers)

Use store campaign links (App Store `ct=` campaign tokens and Google Play `utm_` referrer) per channel, read in App Store
Connect and Play Console. Targets: landing page → store click ≥ 25%; store click → install ≥ 40% (iOS, measured by
campaign token).
