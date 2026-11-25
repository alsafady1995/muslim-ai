# 4. The subscription page (paywall)

Goal: the highest trial-to-paid and lowest refund rate we can get **without** a single trick we would be embarrassed to
explain to the user. In a Quran app, a manipulative paywall does not just lose one sale; it produces the review that
stops the next thousand installs.

This builds on what is already in the app (`app/lib/features/paywall/paywall_screen.dart`, copy in
`tools/gen_arb.py`, rules in `docs/subscription-growth-audit.md` §7–8 and §14). What is new is marked **(new)**.

---

## 4.1 When it appears (unchanged, and it matters more than the copy)

- **Never in onboarding.** The user's first session is a recitation, not a price.
- **Value gate:** no automatic offer until the user has had value on 3 different days.
- **First offer** at the first of: a weekly limit, a hifz milestone, or the day-7 summary with at-risk ayahs.
- **Never** right after a low score, during recitation, while reading or listening, after adhkar, or in a grief
  conversation.
- **Frequency cap:** at most 1 automatic paywall a day, 3 a week; after two "Not now" taps, a 7-day pause.

**Psychology:** a paywall shown at the moment the user *feels* the limit of the free product converts better and
refunds less than one shown at the moment the user is most excited. Intent beats impulse for an annual plan.

---

## 4.2 The page, top to bottom

| # | Element | العربية | English | Why (psychology) |
|---|---|---|---|---|
| 1 | **Context line (new)**, small, above the headline, depends on where the user came from | من ملخّص أسبوعك: ٦ آيات معرّضة للنسيان / أتممت حفظ سورة الملك، الحمد لله / استخدمت اختبارات هذا الأسبوع الخمسة | From your week: 6 ayahs at risk / You've memorized Surah Al-Mulk, Alhamdulillah / You've used this week's 5 AI tests | **Relevance and continuity.** The user sees why this screen is here, in their own data. Only shown when true; never invented numbers |
| 2 | **Headline**, by intent chosen in onboarding | Memorize: **احفظ… ولا تنسَ ما حفظت.** · Recite: **اقرأ بثقة. كل كلمة تُراجَع.** | Memorize: **Keep every ayah you memorize.** · Recite: **Recite with confidence. Every word checked.** | **Loss aversion** for memorizers (the strongest monthly motive), **certainty** for reciters. One outcome, not a feature list |
| 3 | **Subheadline** | مدرّب الحفظ يستمع إليك، ويقيّم كل مراجعة، ويجدول التالية تلقائيًا، فلا يتفلّت منك شيء. | Your Hifz Coach listens, grades each review and schedules the next one, so nothing slips. | Explains the **mechanism** in one line, so the promise is believable |
| 4 | **Your progress so far (new)**, three numbers from the user's data | ٢٣ تسميعًا · ٤٨ آية في خطتك · ٣ سور في أمان | 23 checks · 48 ayahs in your plan · 3 surahs safe | **Endowment effect and sunk value**: you have built something here. Data already exists (`get_hifz_stats`, `get_weekly_summary`) |
| 5 | **Benefits (4)**, each a change in the user's day, not a feature | اختبر حفظك بصوتك كل يوم، والتقييم تلقائي. · سمّع صفحة كاملة دفعة واحدة، حتى ٣ دقائق. · الكلمات التي تخطئ فيها، تتدرب عليها أولًا. · اسأل القرآن بأقوى نموذج لدينا. | Test your hifz with your voice every day. Grading is automatic. · Check a full page in one go, up to 3 minutes. · Your weak words, practised first. · Ask the Quran with our most capable AI. | Four is the most people read. Order = value to the payer: the hifz loop first, the AI chat last |
| 6 | **Free vs Premium line (new)** | المجاني يبقى لك: القراءة والاستماع والأذكار والمراجعة الذاتية بلا حدود. | Free stays yours: unlimited reading, listening, adhkar and self-graded reviews. | **Removes the threat.** Saying what stays free lowers the fear of "they'll take things away" and makes the upgrade feel like an addition, not a ransom |
| 7 | **Plans** (annual pre-selected, monthly always visible) | **سنوي** · ١٠٩٫٩٩ ريال سنويًا · (٩٫١٧ ريال شهريًا) · ٧ أيام مجانًا · شارة: «الأوفر · وفّر ٥١٪» ───── **شهري** · ١٨٫٩٩ ريال شهريًا | **Yearly** · SAR 109.99/year · (SAR 9.17/month) · 7 days free · badge "Best value · Save 51%" ───── **Monthly** · SAR 18.99/month | See §4.3. The billed amount is the largest price on the row (Apple 3.1.2); the monthly equivalent is smaller and in brackets |
| 8 | **Trial timeline** (annual only) | **اليوم:** وصول كامل بدون أي خصم. · **اليوم الخامس:** نذكّرك. · **اليوم السابع:** يبدأ اشتراكك بـ ١٠٩٫٩٩ ريال سنويًا. ألغِ قبلها ولن تدفع شيئًا. | **Today:** full access, no charge. · **Day 5:** we remind you. · **Day 7:** your plan starts at SAR 109.99/year. Cancel before then and pay nothing. | The biggest **anxiety reducer** in subscription design. Making the charge date visible lowers trial starts slightly and raises trial-to-paid and ratings more |
| 9 | **Primary button** | Annual: **ابدأ أيامي السبعة المجانية** · Monthly: **اشترك شهريًا** | Annual: **Start my 7 free days** · Monthly: **Subscribe monthly** | "My" = ownership. It names exactly what happens (a trial), not a vague "Continue" |
| 10 | **Secondary button**, full width, same height | **المتابعة مجانًا** | **Continue free** | **Autonomy.** A visible exit makes the choice feel free, which increases trust and, for this audience, conversion. A hidden ✕ is the dark pattern we refuse |
| 11 | **Small print** | لا خصم اليوم. يمكنك الإلغاء في أي وقت من إعدادات App Store أو Google Play. يتجدد تلقائيًا حتى الإلغاء. | No charge today. Cancel anytime in your App Store or Google Play settings. Auto-renews until cancelled. | Required disclosure, written in plain words |
| 12 | **Questions (new)**, collapsed, 4 rows | see §4.4 | see §4.4 | Answers the objections *before* they become a "Not now" |
| 13 | **Promise** | اشتراكك يُبقي التطبيق بلا إعلانات، دائمًا. | Your subscription keeps Asmi3ni free of ads, always. | **Meaning over price.** Paying protects the space; it isn't a toll |
| 14 | Footer | استعادة المشتريات · الشروط · الخصوصية | Restore purchases · Terms · Privacy | Required by both stores |

**Remove** (already removed in code, keep it that way): "Less than a coffee a month", "advanced analytics",
any bullet the app cannot deliver.

---

## 4.3 Annual plan positioning

1. **Hifz is a year-long project.** The annual plan is framed as matching the goal, not as a discount: the badge says
   "Best value", and the plan row is the one the trial is attached to. A memorizer does not think in months.
2. **Anchor with the monthly plan, honestly.** Monthly at SAR 18.99 is real, always visible and always purchasable. It
   makes SAR 109.99 a year read as "half price" because it is (12 × 18.99 = 227.88; 109.99 saves 51.7%). No fake
   strike-through prices, no "was SAR 299".

   Note: the app computes the badge from store prices (`_annualSavingsPercent`), so it will show the right number in
   every storefront. With USD prices it is 49–50%.
3. **Show the monthly equivalent, small.** "(SAR 9.17/month)" turns an annual price into a daily-life number without
   hiding the billed amount. **(new: the plan row today shows only the yearly price; add the equivalent line.)**
4. **Trial only on annual.** Trials on monthly attract the people most likely to cancel; on annual they let the user
   judge a year's commitment with a week of full use. This is already decided (`BLOCKERS.md` #21).
5. **The price comparison you may use outside the stores:** about a third of the leading competitor's yearly price in
   Saudi Arabia (SAR 109.99 vs SAR 349.99). **Never** name it on the paywall or in store metadata; use it on the
   landing page comparison and in PR only, with the date it was checked.

---

## 4.4 Objection handling (the "Questions" block)

| Objection (what the user thinks) | Question shown | العربية | English |
|---|---|---|---|
| "I'll forget and get charged" | هل سيُخصم مني اليوم؟ / Will I be charged today? | لا. التجربة مجانية ٧ أيام، ونذكّرك قبل نهايتها بيومين. ألغِ قبلها من إعدادات المتجر ولن تدفع شيئًا. | No. The trial is free for 7 days and we remind you 2 days before it ends. Cancel before then in your store settings and you pay nothing. |
| "What if the AI is wrong about the Quran?" | ماذا لو أخطأ المدرّب في كلمة؟ / What if the coach gets a word wrong? | قد يحدث. الكلمات التي لا يتأكد منها تظهر «غير واضحة» بدل «خاطئة». المدرّب رفيق تدريب بين دروسك مع معلّمك، لا بديل عنه. | It can happen. Words it isn't sure about show as "unclear", not "wrong". The coach is a practice partner between lessons with your teacher, not a replacement. |
| "Will I lose everything if I stop?" | ماذا يبقى إن لم أشترك؟ / What stays if I don't subscribe? | كل شيء تقريبًا: القراءة والاستماع وجميع القرّاء والأذكار وخطة الحفظ والمراجعة الذاتية، و١٠ تسميعات و٥ اختبارات أسبوعيًا. | Almost everything: reading, listening, all reciters, adhkar, your hifz plan and self-graded reviews, plus 10 checks and 5 AI tests every week. |
| "Is my voice stored somewhere?" | أين تذهب تسجيلاتي؟ / What happens to my recordings? | تُحذف مباشرة بعد التحليل. لا إعلانات ولا تتبّع إعلاني. | They are deleted right after analysis. No ads and no ad tracking. |

When the "this word was right" button ships (§4.6), change the second answer to: «…وإن رأيت خطأً فاضغط "كانت صحيحة"
لنتعلّم منه.» / "…and if you see a mistake, tap 'It was right' so we learn from it."

---

## 4.5 Ethics: what this page will never do

| Dark pattern | Why it would "work" | Why we refuse it |
|---|---|---|
| Fake countdown ("offer ends in 09:59") | Urgency | It is a lie, and users screenshot it |
| Religious guilt ("Don't let the words of Allah slip away… subscribe") | Fear | Uses faith as a sales lever. Unacceptable, and reportable |
| Hidden or delayed close button | Fewer exits | Disrespect; Apple rejects it, users remember it |
| Pre-selected trial with tiny charge text | More trials | More refunds, chargebacks, 1-star reviews |
| Fake testimonials or "10,000 users" | Social proof | Untrue; violates store rules |
| "Was SAR 299" strike-through | Anchoring | There was never such a price |
| Paywall after a bad recitation score | Emotion | Selling to someone who just struggled reads as shaming |
| Locking famous reciters (Haram imams) | Easy upsell | Feels like charging for the Quran; already removed |

**Psychology:** this audience is primed to distrust apps that monetize faith. Visible fairness is not a cost to
conversion here; it *is* the conversion strategy, and it compounds through ratings and word of mouth.

---

## 4.6 App changes this page needs (for an implementation thread)

| # | Change | Where | Size | Expected effect |
|---|---|---|---|---|
| P1 | Context line by `source` (summary / milestone / limit) with real numbers | `paywall_screen.dart` (source already passed) | S | Higher relevance; +10–15% relative paywall → trial (our estimate, to be measured) |
| P2 | "Your progress" strip (checks, ayahs in plan, surahs safe) | `paywall_screen.dart` + existing RPCs | S | Endowment; same metric |
| P3 | Monthly-equivalent line under the annual price | plan row | XS | Annual share of purchases |
| P4 | "Free stays yours" line | under benefits | XS | Fewer "Not now" from fear of loss |
| P5 | Questions accordion (4 rows above) | under the small print | S | Fewer exits; lower refund rate |
| P6 | "It was right" tap on each flagged word in the recitation result (stores a dispute, feeds the accuracy set) | `coach_result_view.dart`, `recitation_sessions` | M | Trust; turns false flags from 1-star reviews into data |

Measure each with the existing events: `paywall_viewed {source}`, `purchase_started`, `purchase_completed {trial}`,
`paywall_dismissed`, plus RevenueCat trial conversion and refunds.

### A/B tests on this page (in order)

| Test | A | B | Primary metric | Guardrail |
|---|---|---|---|---|
| 1 | No progress strip | Progress strip (P2) | Paywall view → trial | Refund rate |
| 2 | CTA «ابدأ أيامي السبعة المجانية» | «جرّب ٧ أيام مجانًا» | Paywall view → trial | Trial → paid |
| 3 | Benefits as list | Free vs Premium two-column table | Paywall view → trial | `paywall_dismissed` time-to-dismiss |

Do not test removing "Continue free" or the trial timeline. They are principles, not variables.
