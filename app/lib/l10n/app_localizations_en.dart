// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Asmi3ni';

  @override
  String get tabHome => 'Home';

  @override
  String get tabQuran => 'Quran';

  @override
  String get tabLearn => 'Learn';

  @override
  String get tabAsk => 'Ask';

  @override
  String get tabMe => 'Me';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get apply => 'Apply';

  @override
  String get done => 'Done';

  @override
  String get delete => 'Delete';

  @override
  String get or => 'or';

  @override
  String get continueLabel => 'Continue';

  @override
  String get copy => 'Copy';

  @override
  String get share => 'Share';

  @override
  String xpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String achievementUnlocked(String names) {
    return 'Achievement: $names';
  }

  @override
  String get onboardingTitle =>
      'Recite. Get corrected. Never forget what you memorize.';

  @override
  String get onboardingSubtitle =>
      'An AI coach that listens to your recitation, and a hifz plan that keeps it strong.';

  @override
  String get getStarted => 'Get started';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String get pickDailyGoal => 'How much Quran a day?';

  @override
  String get goalCasual => 'Casual';

  @override
  String get goalRegular => 'Regular';

  @override
  String get goalSerious => 'Serious';

  @override
  String get goalIntense => 'Intense';

  @override
  String ayahsPerDay(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ayahs/day',
      one: '1 ayah/day',
    );
    return '$_temp0';
  }

  @override
  String get remindersTitle => 'When should we remind you?';

  @override
  String get remindersBody =>
      'One gentle reminder a day. You can change it anytime in settings.';

  @override
  String get enableReminders => 'Enable reminders';

  @override
  String get notNow => 'Not now';

  @override
  String get reminderMorningTitle => 'Morning adhkar';

  @override
  String get reminderMorningBody =>
      'Start your day with the remembrance of Allah.';

  @override
  String get reminderEveningTitle => 'Evening adhkar';

  @override
  String get reminderEveningBody => 'A few minutes of evening adhkar.';

  @override
  String get reminderStreakTitle => 'Keep your streak';

  @override
  String get reminderStreakBody =>
      'Read a few ayahs to keep your streak alive.';

  @override
  String get reminderHifzTitle => 'Hifz review';

  @override
  String get reminderHifzBody => 'Your review session is ready.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInBody => 'Sign in to restore your progress on this device.';

  @override
  String get saveProgress => 'Save your progress';

  @override
  String get saveProgressBody =>
      'Link an account so your streak, XP and hifz are safe if you change phones.';

  @override
  String get saveProgressHint => 'You\'re using a guest account';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get email => 'Email';

  @override
  String get sendCode => 'Send code';

  @override
  String get verificationCode => '6-digit code';

  @override
  String get verify => 'Verify';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get prayersToday => 'Today\'s prayers';

  @override
  String get continueJourney => 'Continue your journey';

  @override
  String get goPremium => 'Go Premium';

  @override
  String get premiumPitchShort => 'Your Hifz Coach · 7 days free';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get dayStreak => 'day streak';

  @override
  String levelN(int n) {
    return 'Level $n';
  }

  @override
  String xpToNext(int xp, int next) {
    return '$xp / $next XP';
  }

  @override
  String streakFreezes(int n) {
    return '$n streak freezes';
  }

  @override
  String get todaysGoals => 'Today\'s goals';

  @override
  String get goalQuran => 'Reading';

  @override
  String get goalMemorize => 'Hifz';

  @override
  String get goalAdhkar => 'Adhkar';

  @override
  String get goalPrayer => 'Prayer';

  @override
  String get goalListen => 'Listening';

  @override
  String get fajr => 'Fajr';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get continueReading => 'Continue reading';

  @override
  String get startWithFatihah => 'Start with Al-Fatihah';

  @override
  String get pickUpWhereLeft => 'Pick up where you left';

  @override
  String get hifzReview => 'Hifz review';

  @override
  String dueCount(int n) {
    return '$n due';
  }

  @override
  String get reciteWithAi => 'Recite with AI';

  @override
  String get aiCoachHint => 'Get instant feedback';

  @override
  String get adhkar => 'Adhkar';

  @override
  String get morningAdhkar => 'Morning adhkar';

  @override
  String get eveningAdhkar => 'Evening adhkar';

  @override
  String get sleepAdhkar => 'Sleep adhkar';

  @override
  String get askTheQuran => 'Ask the Quran';

  @override
  String get askHint => 'Guidance for life';

  @override
  String get searchQuran => 'Search the Quran';

  @override
  String get searchHint => 'Search by meaning';

  @override
  String get findSurah => 'Find a surah';

  @override
  String ayahCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ayahs',
      one: '1 ayah',
    );
    return '$_temp0';
  }

  @override
  String get makki => 'Makki';

  @override
  String get madani => 'Madani';

  @override
  String ayahN(String key) {
    return 'Ayah $key';
  }

  @override
  String get speed => 'Speed';

  @override
  String get repeatRange => 'Repeat';

  @override
  String get playFromHere => 'Play from here';

  @override
  String get repeatAyah3 => 'Repeat this ayah (memorization)';

  @override
  String quranRef(String key) {
    return 'Quran $key';
  }

  @override
  String get sharedFromApp => 'Shared from Asmi3ni';

  @override
  String get memorizationMode => 'Memorization mode';

  @override
  String get playSurah => 'Play surah';

  @override
  String get aiCoach => 'AI Quran Coach';

  @override
  String get hifzTest => 'Hifz test';

  @override
  String get aiCoachPitch => 'Recite aloud and get word-by-word feedback';

  @override
  String get micPermissionNeeded =>
      'Microphone access is needed to listen to your recitation.';

  @override
  String get analysisFailed =>
      'We couldn\'t analyse this recording. Please try again.';

  @override
  String get analysing => 'Listening to your recitation…';

  @override
  String get chooseWhatToRecite => 'What will you recite?';

  @override
  String get surah => 'Surah';

  @override
  String get fromAyah => 'From ayah';

  @override
  String get toAyah => 'To ayah';

  @override
  String get coachRangeHint => 'Tip: 1–5 ayahs give the most precise feedback.';

  @override
  String get reciteFromMemory => 'Recite from memory. The text is hidden.';

  @override
  String get tapToRecite => 'Tap to start reciting';

  @override
  String get excellent => 'Excellent! ما شاء الله';

  @override
  String get goodJob => 'Good job, keep going';

  @override
  String get keepPracticing => 'Keep practicing, you\'re improving';

  @override
  String get notCompleted => 'You stopped before the end of the selection.';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get fluency => 'Fluency';

  @override
  String get tajweed => 'Tajweed';

  @override
  String get yourRecitation => 'Your recitation';

  @override
  String get legendCorrect => 'Correct';

  @override
  String get legendCheck => 'Check';

  @override
  String get legendMistake => 'Mistake';

  @override
  String get corrections => 'Corrections';

  @override
  String get expected => 'Expected';

  @override
  String get heard => 'Heard';

  @override
  String get mistakeMispronounced => 'Pronunciation';

  @override
  String get mistakeWrongWord => 'Wrong word';

  @override
  String get mistakeSkipped => 'Skipped word';

  @override
  String get mistakeAdded => 'Extra word';

  @override
  String get mistakeRepetition => 'Repetition';

  @override
  String get mistakeUnclear => 'Unclear, please check';

  @override
  String get mistakeShortMadd => 'Possible short madd (check the elongation)';

  @override
  String get mistakeLongPause => 'Long pause';

  @override
  String get coachDisclaimer =>
      'AI feedback can be wrong. For tajweed certification, learn with a qualified teacher.';

  @override
  String get listenCorrect => 'Listen to the correct recitation';

  @override
  String get tryAgain => 'Try again';

  @override
  String get hifzCoach => 'Hifz coach';

  @override
  String get todaysSession => 'Today\'s session';

  @override
  String queueSummary(int reviews, int fresh) {
    return '$reviews reviews · $fresh new ayahs';
  }

  @override
  String get allDoneToday => 'All done for today';

  @override
  String get startSession => 'Start session';

  @override
  String get myPlans => 'My plans';

  @override
  String get newPlan => 'New plan';

  @override
  String get noPlansYet => 'Create a plan to start memorizing.';

  @override
  String get hifzPlan => 'Hifz plan';

  @override
  String newPerDay(int n) {
    return '$n new ayahs per day';
  }

  @override
  String newAyahsPerDay(int n) {
    return 'New ayahs per day: $n';
  }

  @override
  String get createPlan => 'Create plan';

  @override
  String get memorized => 'Memorized';

  @override
  String get retention => 'Retention';

  @override
  String get atRisk => 'At risk';

  @override
  String get sessionComplete => 'Session complete';

  @override
  String get newAyah => 'New';

  @override
  String get review => 'Review';

  @override
  String predictedRecall(int n) {
    return 'Predicted recall: $n%';
  }

  @override
  String get reciteThenReveal =>
      'Recite this ayah from memory, then reveal to check.';

  @override
  String get listen => 'Listen';

  @override
  String get testWithAi => 'Test with AI';

  @override
  String get reveal => 'Reveal';

  @override
  String get gradeAgain => 'Again';

  @override
  String get gradeHard => 'Hard';

  @override
  String get gradeGood => 'Good';

  @override
  String get gradeEasy => 'Easy';

  @override
  String get crisisHelp =>
      'If you are in danger or thinking of harming yourself, please contact local emergency services or a crisis line now, and reach out to someone you trust. You are not alone.';

  @override
  String get consultScholar =>
      'This needs a personal ruling. Please consult a qualified scholar.';

  @override
  String get fromQuran => 'From the Quran';

  @override
  String get fromHadith => 'From the Hadith';

  @override
  String get explanation => 'Explanation';

  @override
  String get scholarlyViews => 'Scholarly views';

  @override
  String get reportAnswer => 'Report a problem';

  @override
  String get tafsir => 'Tafsir';

  @override
  String get assistant => 'Islamic assistant';

  @override
  String get thanksForReport => 'Thank you. We\'ll review this answer.';

  @override
  String get suggestStress => 'How do I deal with stress?';

  @override
  String get suggestForgiveness => 'What does Islam say about forgiveness?';

  @override
  String get suggestAnger => 'How can I control anger?';

  @override
  String get suggestGratitude => 'Verses about gratitude';

  @override
  String get assistantIntro =>
      'Ask anything about Islam. Answers cite the Quran and Hadith.';

  @override
  String get askIntro =>
      'Ask a question and get related verses, hadith and an explanation.';

  @override
  String get searchingSources => 'Searching the sources…';

  @override
  String get askPlaceholder => 'Type your question…';

  @override
  String get topicPatience => 'Patience';

  @override
  String get topicAnxiety => 'Anxiety';

  @override
  String get topicGratitude => 'Gratitude';

  @override
  String get topicFamily => 'Family';

  @override
  String get topicSuccess => 'Success';

  @override
  String get topicKindness => 'Kindness';

  @override
  String get topicBusiness => 'Business';

  @override
  String get searchPlaceholder => 'e.g. verses about patience';

  @override
  String get byMeaning => 'By meaning';

  @override
  String get byWords => 'By words';

  @override
  String get tryTopics => 'Try a topic';

  @override
  String get noResults => 'No results';

  @override
  String get dailyGoals => 'Daily goals';

  @override
  String get goalsIntro =>
      'Choose small, steady goals. The most beloved deeds are the consistent ones, even if small.';

  @override
  String get unitAyahs => 'ayahs';

  @override
  String get unitSets => 'sets';

  @override
  String get unitPrayers => 'prayers';

  @override
  String get unitMinutes => 'minutes';

  @override
  String get guest => 'Guest';

  @override
  String get member => 'Member';

  @override
  String get statistics => 'Statistics';

  @override
  String get currentStreak => 'Current streak';

  @override
  String get bestStreak => 'Best streak';

  @override
  String get ayahs30d => 'Ayahs (30d)';

  @override
  String get goalDays30d => 'Goal days (30d)';

  @override
  String get achievements => 'Achievements';

  @override
  String get coachingHistory => 'AI coaching history';

  @override
  String get noRecitationsYet => 'No recitations yet.';

  @override
  String scoreN(int n) {
    return 'Score $n';
  }

  @override
  String get reading => 'Reading';

  @override
  String get inviteFriends => 'Invite friends';

  @override
  String get inviteBody =>
      'Share your code. You both get bonus XP, and you get a streak freeze.';

  @override
  String get shareInvite => 'Share invite';

  @override
  String get haveInviteCode => 'I have an invite code';

  @override
  String get inviteCode => 'Invite code';

  @override
  String inviteMessage(String code) {
    return 'Join me on Asmi3ni, my daily Quran companion. Use my code $code for bonus XP.';
  }

  @override
  String get inviteApplied => 'Invite code applied!';

  @override
  String get inviteInvalid => 'That code isn\'t valid.';

  @override
  String get settings => 'Settings';

  @override
  String get general => 'General';

  @override
  String get language => 'Language';

  @override
  String get reciter => 'Reciter';

  @override
  String get showTranslation => 'Show translation';

  @override
  String get reminders => 'Reminders';

  @override
  String get streakReminder => 'Streak reminder';

  @override
  String get subscription => 'Subscription';

  @override
  String get manageSubscription => 'Manage subscription';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get restored => 'Premium restored';

  @override
  String get nothingToRestore => 'No purchases to restore';

  @override
  String get account => 'Account';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get terms => 'Terms';

  @override
  String get signOut => 'Sign out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountWarning =>
      'This permanently deletes your progress and data. Cancel any subscription in your store account separately.';

  @override
  String get premiumTitle => 'Asmi3ni Premium';

  @override
  String get premiumSubtitle =>
      'Your Hifz Coach listens, grades each review and schedules the next one, so nothing slips.';

  @override
  String get storeUnavailable => 'Subscriptions aren\'t available right now.';

  @override
  String get yearly => 'Yearly';

  @override
  String get monthly => 'Monthly';

  @override
  String freeTrialDays(int n) {
    return '$n-day free trial';
  }

  @override
  String get perYear => 'year';

  @override
  String get perMonth => 'month';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get subscriptionTerms =>
      'Auto-renews until cancelled. Cancel anytime in your App Store or Google Play account settings.';

  @override
  String get welcomePremium => 'Welcome to Premium!';

  @override
  String get purchasePending => 'Your purchase is pending.';

  @override
  String get purchaseFailed => 'Purchase failed.';

  @override
  String get bestValue => 'Best value';

  @override
  String savePercent(int pct) {
    return 'Save $pct%';
  }

  @override
  String startFreeTrial(int n) {
    return 'Start $n-day free trial';
  }

  @override
  String trialThenPrice(int n, String price, String period) {
    return '$n days free, then $price / $period';
  }

  @override
  String get aiBudgetTitle => 'This month\'s AI allowance is used up';

  @override
  String aiBudgetPremium(String date) {
    return 'To keep Premium affordable for everyone, AI features pause until $date. Reading, listening, keyword search, adhkar and your hifz reviews keep working as usual.';
  }

  @override
  String aiBudgetFree(String date) {
    return 'Free AI features renew on $date. Premium includes a much larger allowance. Meanwhile, reading, listening and your hifz reviews keep working.';
  }

  @override
  String aiBudgetTrial(String date) {
    return 'You\'ve used the AI allowance included in your free trial. It renews when your subscription starts on $date.';
  }

  @override
  String aiLighterMode(String date) {
    return 'You\'re near this month\'s AI allowance, so answers use a lighter model until $date.';
  }

  @override
  String get intentTitle => 'What matters most to you right now?';

  @override
  String get intentMemorize => 'Memorize the Quran';

  @override
  String get intentRecite => 'Perfect my recitation';

  @override
  String get intentRead => 'Read every day';

  @override
  String get intentUnderstand => 'Understand the Quran';

  @override
  String get knownTitle => 'Which surahs do you already know by heart?';

  @override
  String get knownBody => 'We\'ll keep them fresh with short reviews.';

  @override
  String get knownNone => 'None yet';

  @override
  String get firstRecitationTitle => 'Recite Al-Fatiha';

  @override
  String get firstRecitationBody =>
      'Recite it aloud and see what the coach hears, word by word. This one is on us.';

  @override
  String get reciteNow => 'Recite now';

  @override
  String get skip => 'Skip';

  @override
  String firstResult(int score, int n) {
    return 'Score $score · $n words to polish';
  }

  @override
  String firstResultPerfect(int score) {
    return 'Score $score · masha\'Allah, no mistakes';
  }

  @override
  String get planTitle => 'Your plan';

  @override
  String planMemorize(String name) {
    return 'Memorize Surah $name';
  }

  @override
  String planKnown(int n) {
    return '$n surahs you know get short reviews, starting tomorrow.';
  }

  @override
  String planRead(int n) {
    return 'Read $n ayahs a day';
  }

  @override
  String get planFirstReview => 'Your first review is tomorrow.';

  @override
  String reminderAt(String time) {
    return 'Remind me at $time';
  }

  @override
  String get alsoAdhkar => 'Also remind me of morning and evening adhkar';

  @override
  String get remindMe => 'Remind me';

  @override
  String get reminderReadTitle => 'Your daily ayahs';

  @override
  String get reminderReadBody => 'A few minutes with the Quran.';

  @override
  String limitTitleRecitation(int n) {
    return 'You\'ve used this week\'s $n checks';
  }

  @override
  String limitTitleHifz(int n) {
    return 'You\'ve used this week\'s $n AI tests';
  }

  @override
  String limitTitleAsk(int n) {
    return 'You\'ve asked $n questions this week';
  }

  @override
  String limitTitleSearch(int n) {
    return 'You\'ve used this week\'s $n meaning searches';
  }

  @override
  String limitRenews(String day) {
    return 'They renew on $day.';
  }

  @override
  String limitWaitUntil(String day) {
    return 'Wait until $day';
  }

  @override
  String get limitKeepsWorking =>
      'Reading, listening, adhkar and self-graded reviews stay unlimited.';

  @override
  String get tryPremiumFree => 'Try Premium free';

  @override
  String checksLeft(int left, int limit) {
    return '$left of $limit checks left this week';
  }

  @override
  String aiTestsLeft(int left) {
    return '$left AI tests left this week';
  }

  @override
  String get clipNoteFree =>
      'Free checks cover 60 seconds. Premium checks a full page in one go.';

  @override
  String secondsLeft(int s) {
    return '${s}s left';
  }

  @override
  String get rangeTooLong => 'Up to 50 ayahs at a time.';

  @override
  String searchFellBack(String day) {
    return 'This week\'s meaning searches are used up, so these are word matches. They renew on $day.';
  }

  @override
  String hifzLimitInline(int n) {
    return 'You\'ve used this week\'s $n AI tests. Your review continues with self-grading. Want the coach to grade every review?';
  }

  @override
  String get continueReviewing => 'Continue reviewing';

  @override
  String get aiTestNotGraded =>
      'That recitation didn\'t cover this ayah. Grade it yourself.';

  @override
  String milestoneTitle(String name) {
    return 'You\'ve memorized Surah $name';
  }

  @override
  String milestoneBody(int xp) {
    return 'Alhamdulillah. +$xp XP';
  }

  @override
  String get milestoneOffer =>
      'Keep it strong for good: the coach tests it with you until it\'s mastered. 7 days free.';

  @override
  String get finishCoach => 'Continue';

  @override
  String get paywallHeadlineMemorize => 'Keep every ayah you memorize.';

  @override
  String get paywallHeadlineRecite =>
      'Recite with confidence. Every word checked.';

  @override
  String get benefitHifzTests =>
      'Test your hifz with your voice every day. Grading is automatic.';

  @override
  String get benefitFullPage => 'Check a full page in one go, up to 3 minutes.';

  @override
  String get benefitWeakWords => 'Your weak words, practised first.';

  @override
  String get benefitBestAi => 'Ask the Quran with our most capable AI.';

  @override
  String get trialToday => 'Today';

  @override
  String get trialTodayBody => 'Full access, no charge.';

  @override
  String trialDayN(int n) {
    return 'Day $n';
  }

  @override
  String get trialReminderStep => 'We remind you before any charge.';

  @override
  String trialChargeStep(String price, String period) {
    return 'Your plan starts at $price/$period. Cancel before then and pay nothing.';
  }

  @override
  String startMyFreeDays(int n) {
    return 'Start my $n free days';
  }

  @override
  String get subscribeMonthly => 'Subscribe monthly';

  @override
  String get continueFree => 'Continue free';

  @override
  String get noChargeToday =>
      'No charge today. Cancel anytime in your App Store or Google Play settings. Auto-renews until cancelled.';

  @override
  String get adFreePromise =>
      'Your subscription keeps Asmi3ni free of ads, always.';

  @override
  String get trialReminderTitle => 'Your free trial ends in 2 days';

  @override
  String get trialReminderBody =>
      'Keep it and your plan continues. Cancel in your store settings and you won\'t be charged.';

  @override
  String get todayReviewTitle => 'Today\'s review';

  @override
  String todayReviewBody(int n, int m) {
    return '$n ayahs · about $m min';
  }

  @override
  String get todayNewTitle => 'Today\'s new ayahs';

  @override
  String get todayReciteTitle => 'Recite with the coach';

  @override
  String get todayReciteBody => 'One minute, word-by-word feedback';

  @override
  String get todayDoneTitle => 'Today\'s review is done';

  @override
  String get todayDoneBody => 'Alhamdulillah. See you tomorrow.';

  @override
  String get startHifzPlan => 'Start a hifz plan';

  @override
  String get startHifzPlanBody =>
      'A few ayahs a day, reviewed before you forget them';

  @override
  String get startLabel => 'Start';

  @override
  String get weekTitle => 'Your week';

  @override
  String weekStats(int days, int reviews, int ayahs) {
    return '$days active days · $reviews reviews · $ayahs ayahs read';
  }

  @override
  String weekAtRisk(int n) {
    return '$n ayahs are at risk of being forgotten this week.';
  }

  @override
  String get weekAtRiskOffer => 'Premium tests all of them for you.';

  @override
  String get weekAllSafe => 'Every ayah you memorized is safe. Masha\'Allah.';

  @override
  String get seeMyPlan => 'See my plan';

  @override
  String get billingIssue => 'Update your payment to keep your Hifz Coach.';

  @override
  String trialEnds(String date) {
    return 'Your free trial ends on $date. Cancel anytime in your store settings.';
  }

  @override
  String get update => 'Update';

  @override
  String get weakWordsTitle => 'Your weak words';

  @override
  String get weakWordsBody =>
      'The words you get wrong most often, practised first.';

  @override
  String get weakWordsEmpty =>
      'No weak words yet. Recite with the coach and they\'ll appear here.';

  @override
  String weakWordMisses(int n) {
    return 'Missed $n times';
  }

  @override
  String weakWordsLocked(int n) {
    return '$n more words and the full drill with Premium';
  }

  @override
  String get practise => 'Practise';

  @override
  String get knownSurahsPlan => 'Already memorized';

  @override
  String get notificationsBlocked =>
      'Notifications are off for Asmi3ni. Turn them on in your phone settings.';

  @override
  String get pausePlan => 'Pause new ayahs';

  @override
  String get resumePlan => 'Resume';

  @override
  String get planPaused => 'Paused · reviews continue';

  @override
  String weakWordsCardBody(int n) {
    return '$n words to polish';
  }
}
