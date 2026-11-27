// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'أسمِعني';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabQuran => 'القرآن';

  @override
  String get tabLearn => 'تعلّم';

  @override
  String get tabAsk => 'اسأل';

  @override
  String get tabMe => 'حسابي';

  @override
  String get errorGeneric => 'حدث خطأ. حاول مرة أخرى.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get apply => 'تطبيق';

  @override
  String get done => 'تم';

  @override
  String get delete => 'حذف';

  @override
  String get or => 'أو';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get copy => 'نسخ';

  @override
  String get share => 'مشاركة';

  @override
  String xpEarned(int xp) {
    return '+$xp نقطة';
  }

  @override
  String achievementUnlocked(String names) {
    return 'إنجاز جديد: $names';
  }

  @override
  String get onboardingTitle => 'رتّل، وصحّح تلاوتك، ولا تنسَ ما حفظت.';

  @override
  String get onboardingSubtitle =>
      'مدرّب ذكي يستمع إلى تلاوتك، وخطة حفظ تحافظ على ما حفظت.';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get haveAccount => 'لدي حساب بالفعل';

  @override
  String get pickDailyGoal => 'كم آية تقرأ يوميًا؟';

  @override
  String get goalCasual => 'خفيف';

  @override
  String get goalRegular => 'منتظم';

  @override
  String get goalSerious => 'جاد';

  @override
  String get goalIntense => 'مكثف';

  @override
  String ayahsPerDay(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n آية يوميًا',
      few: '$n آيات يوميًا',
      two: 'آيتان يوميًا',
      one: 'آية يوميًا',
    );
    return '$_temp0';
  }

  @override
  String get remindersTitle => 'متى نذكّرك؟';

  @override
  String get remindersBody =>
      'تذكير لطيف واحد يوميًا. يمكنك تغييره في أي وقت من الإعدادات.';

  @override
  String get enableReminders => 'تفعيل التذكيرات';

  @override
  String get notNow => 'ليس الآن';

  @override
  String get reminderMorningTitle => 'أذكار الصباح';

  @override
  String get reminderMorningBody => 'ابدأ يومك بذكر الله.';

  @override
  String get reminderEveningTitle => 'أذكار المساء';

  @override
  String get reminderEveningBody => 'دقائق مع أذكار المساء.';

  @override
  String get reminderStreakTitle => 'حافظ على سلسلتك';

  @override
  String get reminderStreakBody => 'اقرأ بضع آيات لتحافظ على سلسلتك.';

  @override
  String get reminderHifzTitle => 'مراجعة الحفظ';

  @override
  String get reminderHifzBody => 'جلسة المراجعة جاهزة.';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signInBody => 'سجّل الدخول لاستعادة تقدمك على هذا الجهاز.';

  @override
  String get saveProgress => 'احفظ تقدمك';

  @override
  String get saveProgressBody =>
      'اربط حسابًا حتى تبقى سلسلتك ونقاطك وحفظك محفوظة إذا غيّرت هاتفك.';

  @override
  String get saveProgressHint => 'أنت تستخدم حساب ضيف';

  @override
  String get continueWithApple => 'المتابعة باستخدام Apple';

  @override
  String get continueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get verificationCode => 'رمز من ٦ أرقام';

  @override
  String get verify => 'تحقق';

  @override
  String get invalidEmail => 'أدخل بريدًا صحيحًا';

  @override
  String get prayersToday => 'صلوات اليوم';

  @override
  String get continueJourney => 'تابع رحلتك';

  @override
  String get goPremium => 'اشترك في المميز';

  @override
  String get premiumPitchShort => 'مدرّب الحفظ · ٧ أيام مجانًا';

  @override
  String get last7Days => 'آخر ٧ أيام';

  @override
  String get dayStreak => 'يوم متتالي';

  @override
  String levelN(int n) {
    return 'المستوى $n';
  }

  @override
  String xpToNext(int xp, int next) {
    return '$xp / $next نقطة';
  }

  @override
  String streakFreezes(int n) {
    return '$n حماية للسلسلة';
  }

  @override
  String get todaysGoals => 'أهداف اليوم';

  @override
  String get goalQuran => 'القراءة';

  @override
  String get goalMemorize => 'الحفظ';

  @override
  String get goalAdhkar => 'الأذكار';

  @override
  String get goalPrayer => 'الصلاة';

  @override
  String get goalListen => 'الاستماع';

  @override
  String get fajr => 'الفجر';

  @override
  String get dhuhr => 'الظهر';

  @override
  String get asr => 'العصر';

  @override
  String get maghrib => 'المغرب';

  @override
  String get isha => 'العشاء';

  @override
  String get continueReading => 'تابع القراءة';

  @override
  String get startWithFatihah => 'ابدأ بالفاتحة';

  @override
  String get pickUpWhereLeft => 'أكمل من حيث توقفت';

  @override
  String get hifzReview => 'مراجعة الحفظ';

  @override
  String dueCount(int n) {
    return '$n مستحقة';
  }

  @override
  String get reciteWithAi => 'رتّل مع الذكاء الاصطناعي';

  @override
  String get aiCoachHint => 'احصل على تقييم فوري';

  @override
  String get adhkar => 'الأذكار';

  @override
  String get morningAdhkar => 'أذكار الصباح';

  @override
  String get eveningAdhkar => 'أذكار المساء';

  @override
  String get sleepAdhkar => 'أذكار النوم';

  @override
  String get askTheQuran => 'اسأل القرآن';

  @override
  String get askHint => 'إرشاد لحياتك';

  @override
  String get searchQuran => 'البحث في القرآن';

  @override
  String get searchHint => 'ابحث بالمعنى';

  @override
  String get findSurah => 'ابحث عن سورة';

  @override
  String ayahCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n آية',
      few: '$n آيات',
      two: 'آيتان',
      one: 'آية واحدة',
    );
    return '$_temp0';
  }

  @override
  String get makki => 'مكية';

  @override
  String get madani => 'مدنية';

  @override
  String ayahN(String key) {
    return 'آية $key';
  }

  @override
  String get speed => 'السرعة';

  @override
  String get repeatRange => 'تكرار';

  @override
  String get playFromHere => 'تشغيل من هنا';

  @override
  String get repeatAyah3 => 'كرر هذه الآية (للحفظ)';

  @override
  String quranRef(String key) {
    return 'القرآن $key';
  }

  @override
  String get sharedFromApp => 'عبر تطبيق أسمِعني';

  @override
  String get memorizationMode => 'وضع الحفظ';

  @override
  String get playSurah => 'تشغيل السورة';

  @override
  String get aiCoach => 'المدرب القرآني الذكي';

  @override
  String get hifzTest => 'اختبار الحفظ';

  @override
  String get aiCoachPitch => 'رتّل بصوتك واحصل على تقييم كلمة بكلمة';

  @override
  String get micPermissionNeeded => 'نحتاج إذن الميكروفون للاستماع إلى تلاوتك.';

  @override
  String get analysisFailed => 'تعذّر تحليل التسجيل. حاول مرة أخرى.';

  @override
  String get analysing => 'نستمع إلى تلاوتك…';

  @override
  String get chooseWhatToRecite => 'ماذا ستتلو؟';

  @override
  String get surah => 'السورة';

  @override
  String get fromAyah => 'من آية';

  @override
  String get toAyah => 'إلى آية';

  @override
  String get coachRangeHint => 'نصيحة: من ١ إلى ٥ آيات تعطي أدق تقييم.';

  @override
  String get reciteFromMemory => 'اتلُ من حفظك. النص مخفي.';

  @override
  String get tapToRecite => 'اضغط لبدء التلاوة';

  @override
  String get excellent => 'ممتاز! ما شاء الله';

  @override
  String get goodJob => 'أحسنت، واصل';

  @override
  String get keepPracticing => 'واصل التدريب، أنت تتحسن';

  @override
  String get notCompleted => 'توقفت قبل نهاية المقطع المحدد.';

  @override
  String get accuracy => 'الدقة';

  @override
  String get fluency => 'الطلاقة';

  @override
  String get tajweed => 'التجويد';

  @override
  String get yourRecitation => 'تلاوتك';

  @override
  String get legendCorrect => 'صحيح';

  @override
  String get legendCheck => 'راجع';

  @override
  String get legendMistake => 'خطأ';

  @override
  String get corrections => 'التصحيحات';

  @override
  String get expected => 'الصحيح';

  @override
  String get heard => 'سُمع';

  @override
  String get mistakeMispronounced => 'خطأ في النطق';

  @override
  String get mistakeWrongWord => 'كلمة خاطئة';

  @override
  String get mistakeSkipped => 'كلمة متروكة';

  @override
  String get mistakeAdded => 'كلمة زائدة';

  @override
  String get mistakeRepetition => 'تكرار';

  @override
  String get mistakeUnclear => 'غير واضح، راجعها';

  @override
  String get mistakeShortMadd => 'احتمال قصر في المد (راجع المد)';

  @override
  String get mistakeLongPause => 'توقف طويل';

  @override
  String get coachDisclaimer =>
      'قد يخطئ التقييم الآلي. لإتقان التجويد تعلّم على يد معلم متقن.';

  @override
  String get listenCorrect => 'استمع للتلاوة الصحيحة';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get hifzCoach => 'مدرب الحفظ';

  @override
  String get todaysSession => 'جلسة اليوم';

  @override
  String queueSummary(int reviews, int fresh) {
    return '$reviews مراجعة · $fresh آيات جديدة';
  }

  @override
  String get allDoneToday => 'أنجزت جلسة اليوم';

  @override
  String get startSession => 'ابدأ الجلسة';

  @override
  String get myPlans => 'خططي';

  @override
  String get newPlan => 'خطة جديدة';

  @override
  String get noPlansYet => 'أنشئ خطة لتبدأ الحفظ.';

  @override
  String get hifzPlan => 'خطة حفظ';

  @override
  String newPerDay(int n) {
    return '$n آيات جديدة يوميًا';
  }

  @override
  String newAyahsPerDay(int n) {
    return 'آيات جديدة يوميًا: $n';
  }

  @override
  String get createPlan => 'إنشاء الخطة';

  @override
  String get memorized => 'محفوظة';

  @override
  String get retention => 'الثبات';

  @override
  String get atRisk => 'معرضة للنسيان';

  @override
  String get sessionComplete => 'انتهت الجلسة';

  @override
  String get newAyah => 'جديدة';

  @override
  String get review => 'مراجعة';

  @override
  String predictedRecall(int n) {
    return 'احتمال التذكر: $n٪';
  }

  @override
  String get reciteThenReveal => 'اتلُ هذه الآية من حفظك ثم اكشفها للتحقق.';

  @override
  String get listen => 'استمع';

  @override
  String get testWithAi => 'اختبر بالذكاء الاصطناعي';

  @override
  String get reveal => 'اكشف';

  @override
  String get gradeAgain => 'أعد';

  @override
  String get gradeHard => 'صعب';

  @override
  String get gradeGood => 'جيد';

  @override
  String get gradeEasy => 'سهل';

  @override
  String get crisisHelp =>
      'إن كنت في خطر أو تفكر في إيذاء نفسك، فتواصل الآن مع خدمات الطوارئ أو خط المساعدة في بلدك، وتحدث مع شخص تثق به. لست وحدك.';

  @override
  String get consultScholar =>
      'هذه مسألة تحتاج فتوى شخصية. استشر عالمًا موثوقًا.';

  @override
  String get fromQuran => 'من القرآن الكريم';

  @override
  String get fromHadith => 'من الحديث الشريف';

  @override
  String get explanation => 'الشرح';

  @override
  String get scholarlyViews => 'آراء العلماء';

  @override
  String get reportAnswer => 'الإبلاغ عن مشكلة';

  @override
  String get tafsir => 'التفسير';

  @override
  String get assistant => 'المساعد الإسلامي';

  @override
  String get thanksForReport => 'شكرًا لك. سنراجع هذه الإجابة.';

  @override
  String get suggestStress => 'كيف أتعامل مع القلق والتوتر؟';

  @override
  String get suggestForgiveness => 'ماذا يقول الإسلام عن العفو؟';

  @override
  String get suggestAnger => 'كيف أتحكم في غضبي؟';

  @override
  String get suggestGratitude => 'آيات عن الشكر';

  @override
  String get assistantIntro =>
      'اسأل عن أي شيء في الإسلام. الإجابات موثقة بالقرآن والحديث.';

  @override
  String get askIntro =>
      'اطرح سؤالك واحصل على الآيات والأحاديث المتعلقة مع الشرح.';

  @override
  String get searchingSources => 'نبحث في المصادر…';

  @override
  String get askPlaceholder => 'اكتب سؤالك…';

  @override
  String get topicPatience => 'الصبر';

  @override
  String get topicAnxiety => 'القلق';

  @override
  String get topicGratitude => 'الشكر';

  @override
  String get topicFamily => 'الأسرة';

  @override
  String get topicSuccess => 'النجاح';

  @override
  String get topicKindness => 'الإحسان';

  @override
  String get topicBusiness => 'التجارة';

  @override
  String get searchPlaceholder => 'مثال: آيات عن الصبر';

  @override
  String get byMeaning => 'بالمعنى';

  @override
  String get byWords => 'بالكلمات';

  @override
  String get tryTopics => 'جرّب موضوعًا';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get dailyGoals => 'الأهداف اليومية';

  @override
  String get goalsIntro =>
      'اختر أهدافًا صغيرة ثابتة؛ فأحب الأعمال إلى الله أدومها وإن قل.';

  @override
  String get unitAyahs => 'آيات';

  @override
  String get unitSets => 'مجموعات';

  @override
  String get unitPrayers => 'صلوات';

  @override
  String get unitMinutes => 'دقائق';

  @override
  String get guest => 'ضيف';

  @override
  String get member => 'عضو';

  @override
  String get statistics => 'الإحصائيات';

  @override
  String get currentStreak => 'السلسلة الحالية';

  @override
  String get bestStreak => 'أفضل سلسلة';

  @override
  String get ayahs30d => 'آيات (٣٠ يومًا)';

  @override
  String get goalDays30d => 'أيام الأهداف (٣٠ يومًا)';

  @override
  String get achievements => 'الإنجازات';

  @override
  String get coachingHistory => 'سجل التدريب الذكي';

  @override
  String get noRecitationsYet => 'لا توجد تلاوات بعد.';

  @override
  String scoreN(int n) {
    return 'النتيجة $n';
  }

  @override
  String get reading => 'قراءة';

  @override
  String get inviteFriends => 'ادعُ أصدقاءك';

  @override
  String get inviteBody =>
      'شارك رمزك. تحصلان على نقاط إضافية وتحصل أنت على حماية للسلسلة.';

  @override
  String get shareInvite => 'مشاركة الدعوة';

  @override
  String get haveInviteCode => 'لدي رمز دعوة';

  @override
  String get inviteCode => 'رمز الدعوة';

  @override
  String inviteMessage(String code) {
    return 'انضم إليّ في تطبيق أسمِعني، رفيقي اليومي مع القرآن. استخدم رمزي $code لتحصل على نقاط إضافية.';
  }

  @override
  String get inviteApplied => 'تم تطبيق رمز الدعوة!';

  @override
  String get inviteInvalid => 'الرمز غير صالح.';

  @override
  String get settings => 'الإعدادات';

  @override
  String get general => 'عام';

  @override
  String get language => 'اللغة';

  @override
  String get reciter => 'القارئ';

  @override
  String get showTranslation => 'إظهار الترجمة';

  @override
  String get reminders => 'التذكيرات';

  @override
  String get streakReminder => 'تذكير السلسلة';

  @override
  String get subscription => 'الاشتراك';

  @override
  String get manageSubscription => 'إدارة الاشتراك';

  @override
  String get restorePurchases => 'استعادة المشتريات';

  @override
  String get restored => 'تمت استعادة بريميوم';

  @override
  String get nothingToRestore => 'لا توجد مشتريات لاستعادتها';

  @override
  String get account => 'الحساب';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get terms => 'الشروط';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountWarning =>
      'سيُحذف تقدمك وبياناتك نهائيًا. ألغِ أي اشتراك من حساب المتجر بشكل منفصل.';

  @override
  String get premiumTitle => 'أسمِعني المميز';

  @override
  String get premiumSubtitle =>
      'مدرّب الحفظ يستمع إليك، ويقيّم كل مراجعة، ويجدول التالية تلقائيًا، فلا يتفلّت منك شيء.';

  @override
  String get storeUnavailable => 'الاشتراكات غير متاحة حاليًا.';

  @override
  String get yearly => 'سنوي';

  @override
  String get monthly => 'شهري';

  @override
  String freeTrialDays(int n) {
    return 'تجربة مجانية $n أيام';
  }

  @override
  String get perYear => 'سنة';

  @override
  String get perMonth => 'شهر';

  @override
  String get subscribe => 'اشترك';

  @override
  String get subscriptionTerms =>
      'يتجدد تلقائيًا حتى الإلغاء. يمكنك الإلغاء في أي وقت من إعدادات حسابك في App Store أو Google Play.';

  @override
  String get welcomePremium => 'أهلًا بك في بريميوم!';

  @override
  String get purchasePending => 'عملية الشراء قيد المعالجة.';

  @override
  String get purchaseFailed => 'فشلت عملية الشراء.';

  @override
  String get bestValue => 'الأفضل قيمة';

  @override
  String savePercent(int pct) {
    return 'وفّر $pct٪';
  }

  @override
  String startFreeTrial(int n) {
    return 'ابدأ تجربة مجانية لمدة $n أيام';
  }

  @override
  String trialThenPrice(int n, String price, String period) {
    return '$n أيام مجانًا، ثم $price / $period';
  }

  @override
  String get aiBudgetTitle => 'انتهى رصيد الذكاء الاصطناعي لهذه الفترة';

  @override
  String aiBudgetPremium(String date) {
    return 'حتى يبقى بريميوم بسعر في متناول الجميع، تتوقف ميزات الذكاء الاصطناعي حتى $date. القراءة والاستماع والبحث بالكلمات والأذكار ومراجعة الحفظ تعمل كالمعتاد.';
  }

  @override
  String aiBudgetFree(String date) {
    return 'تتجدد ميزات الذكاء الاصطناعي المجانية في $date. يتضمن بريميوم رصيدًا أكبر بكثير. وحتى ذلك الحين تعمل القراءة والاستماع ومراجعة الحفظ كالمعتاد.';
  }

  @override
  String aiBudgetTrial(String date) {
    return 'استهلكت رصيد الذكاء الاصطناعي المضمَّن في الفترة التجريبية. يتجدد عند بدء اشتراكك في $date.';
  }

  @override
  String aiLighterMode(String date) {
    return 'اقتربت من رصيد الذكاء الاصطناعي لهذه الفترة، لذا تُستخدم إجابات أخف حتى $date.';
  }

  @override
  String get intentTitle => 'ما الأهم بالنسبة لك الآن؟';

  @override
  String get intentMemorize => 'حفظ القرآن';

  @override
  String get intentRecite => 'إتقان التلاوة';

  @override
  String get intentRead => 'القراءة كل يوم';

  @override
  String get intentUnderstand => 'فهم القرآن';

  @override
  String get knownTitle => 'ما السور التي تحفظها؟';

  @override
  String get knownBody => 'سنحافظ عليها بمراجعات قصيرة.';

  @override
  String get knownNone => 'لا شيء بعد';

  @override
  String get firstRecitationTitle => 'رتّل سورة الفاتحة';

  @override
  String get firstRecitationBody =>
      'رتّلها بصوتك وشاهد ما يسمعه المدرّب كلمة بكلمة. هذه علينا.';

  @override
  String get reciteNow => 'رتّل الآن';

  @override
  String get skip => 'تخطَّ';

  @override
  String firstResult(int score, int n) {
    return 'النتيجة $score · $n كلمات تحتاج إتقانًا';
  }

  @override
  String firstResultPerfect(int score) {
    return 'النتيجة $score · ما شاء الله، بلا أخطاء';
  }

  @override
  String get planTitle => 'خطتك';

  @override
  String planMemorize(String name) {
    return 'حفظ سورة $name';
  }

  @override
  String planKnown(int n) {
    return '$n سور تحفظها ستُراجع مراجعات قصيرة بدءًا من الغد.';
  }

  @override
  String planRead(int n) {
    return 'اقرأ $n آيات يوميًا';
  }

  @override
  String get planFirstReview => 'أول مراجعة لك غدًا.';

  @override
  String reminderAt(String time) {
    return 'ذكّرني الساعة $time';
  }

  @override
  String get alsoAdhkar => 'ذكّرني أيضًا بأذكار الصباح والمساء';

  @override
  String get remindMe => 'ذكّرني';

  @override
  String get reminderReadTitle => 'آياتك اليومية';

  @override
  String get reminderReadBody => 'دقائق مع القرآن.';

  @override
  String limitTitleRecitation(int n) {
    return 'استخدمت تسميعات هذا الأسبوع ($n)';
  }

  @override
  String limitTitleHifz(int n) {
    return 'استخدمت اختبارات الحفظ الذكية لهذا الأسبوع ($n)';
  }

  @override
  String limitTitleAsk(int n) {
    return 'طرحت $n سؤالًا هذا الأسبوع';
  }

  @override
  String limitTitleSearch(int n) {
    return 'استخدمت عمليات البحث بالمعنى لهذا الأسبوع ($n)';
  }

  @override
  String limitRenews(String day) {
    return 'تتجدد يوم $day.';
  }

  @override
  String limitWaitUntil(String day) {
    return 'أنتظر حتى $day';
  }

  @override
  String get limitKeepsWorking =>
      'القراءة والاستماع والأذكار والمراجعة الذاتية تبقى بلا حدود.';

  @override
  String get tryPremiumFree => 'جرّب المميز مجانًا';

  @override
  String checksLeft(int left, int limit) {
    return 'تبقّى $left من $limit تسميعات هذا الأسبوع';
  }

  @override
  String aiTestsLeft(int left) {
    return 'تبقّى $left اختبارات ذكية هذا الأسبوع';
  }

  @override
  String get clipNoteFree =>
      'التسميع المجاني حتى ٦٠ ثانية. المميز يسمّع صفحة كاملة دفعة واحدة.';

  @override
  String secondsLeft(int s) {
    return 'تبقّى $s ث';
  }

  @override
  String get rangeTooLong => 'حتى ٥٠ آية في المرة الواحدة.';

  @override
  String searchFellBack(String day) {
    return 'انتهت عمليات البحث بالمعنى لهذا الأسبوع، فهذه نتائج مطابقة الكلمات. تتجدد يوم $day.';
  }

  @override
  String hifzLimitInline(int n) {
    return 'استخدمت اختبارات الحفظ الذكية ($n) لهذا الأسبوع. ستكمل مراجعتك بالتقييم الذاتي. هل تريد أن يقيّم المدرّب كل مراجعة؟';
  }

  @override
  String get continueReviewing => 'أكمل المراجعة';

  @override
  String get aiTestNotGraded => 'لم يشمل التسميع هذه الآية. قيّمها بنفسك.';

  @override
  String milestoneTitle(String name) {
    return 'أتممت حفظ سورة $name';
  }

  @override
  String milestoneBody(int xp) {
    return 'الحمد لله. +$xp نقطة';
  }

  @override
  String get milestoneOffer =>
      'حافظ عليها للأبد: المدرّب يختبرها معك حتى تُتقنها. ٧ أيام مجانًا.';

  @override
  String get finishCoach => 'متابعة';

  @override
  String get paywallHeadlineMemorize => 'احفظ… ولا تنسَ ما حفظت.';

  @override
  String get paywallHeadlineRecite => 'اقرأ بثقة. كل كلمة تُراجَع.';

  @override
  String get benefitHifzTests => 'اختبر حفظك بصوتك كل يوم، والتقييم تلقائي.';

  @override
  String get benefitFullPage => 'سمّع صفحة كاملة دفعة واحدة، حتى ٣ دقائق.';

  @override
  String get benefitWeakWords => 'الكلمات التي تخطئ فيها، تتدرب عليها أولًا.';

  @override
  String get benefitBestAi => 'اسأل القرآن بأقوى نموذج لدينا.';

  @override
  String get trialToday => 'اليوم';

  @override
  String get trialTodayBody => 'وصول كامل بدون أي خصم.';

  @override
  String trialDayN(int n) {
    return 'اليوم $n';
  }

  @override
  String get trialReminderStep => 'نذكّرك قبل أي خصم.';

  @override
  String trialChargeStep(String price, String period) {
    return 'يبدأ اشتراكك بـ $price/$period. ألغِ قبلها ولن تدفع شيئًا.';
  }

  @override
  String startMyFreeDays(int n) {
    return 'ابدأ أيامي المجانية ($n)';
  }

  @override
  String get subscribeMonthly => 'اشترك شهريًا';

  @override
  String get continueFree => 'المتابعة مجانًا';

  @override
  String get noChargeToday =>
      'لا خصم اليوم. يمكنك الإلغاء في أي وقت من إعدادات App Store أو Google Play. يتجدد تلقائيًا حتى الإلغاء.';

  @override
  String get adFreePromise => 'اشتراكك يُبقي التطبيق بلا إعلانات، دائمًا.';

  @override
  String get trialReminderTitle => 'تنتهي تجربتك المجانية بعد يومين';

  @override
  String get trialReminderBody =>
      'إن أبقيتها يستمر اشتراكك، وإن ألغيتها من إعدادات المتجر فلن يُخصم منك شيء.';

  @override
  String get todayReviewTitle => 'مراجعة اليوم';

  @override
  String todayReviewBody(int n, int m) {
    return '$n آيات · حوالي $m دقائق';
  }

  @override
  String get todayNewTitle => 'آيات اليوم الجديدة';

  @override
  String get todayReciteTitle => 'رتّل مع المدرّب';

  @override
  String get todayReciteBody => 'دقيقة واحدة وتقييم كلمة بكلمة';

  @override
  String get todayDoneTitle => 'أنهيت مراجعة اليوم';

  @override
  String get todayDoneBody => 'الحمد لله. نلقاك غدًا.';

  @override
  String get startHifzPlan => 'ابدأ خطة حفظ';

  @override
  String get startHifzPlanBody => 'آيات قليلة يوميًا، تُراجَع قبل أن تنساها';

  @override
  String get startLabel => 'ابدأ';

  @override
  String get weekTitle => 'أسبوعك';

  @override
  String weekStats(int days, int reviews, int ayahs) {
    return '$days أيام نشاط · $reviews مراجعة · $ayahs آية مقروءة';
  }

  @override
  String weekAtRisk(int n) {
    return '$n آيات معرّضة للنسيان هذا الأسبوع.';
  }

  @override
  String get weekAtRiskOffer => 'المميز يختبرها كلها معك.';

  @override
  String get weekAllSafe => 'كل ما حفظته في أمان. ما شاء الله.';

  @override
  String get seeMyPlan => 'اعرض خطتي';

  @override
  String get billingIssue => 'حدّث طريقة الدفع لتحتفظ بمدرّب الحفظ.';

  @override
  String trialEnds(String date) {
    return 'تنتهي تجربتك المجانية في $date. يمكنك الإلغاء في أي وقت من إعدادات المتجر.';
  }

  @override
  String get update => 'تحديث';

  @override
  String get weakWordsTitle => 'كلماتك الضعيفة';

  @override
  String get weakWordsBody =>
      'الكلمات التي تخطئ فيها أكثر، تتدرّب عليها أولًا.';

  @override
  String get weakWordsEmpty =>
      'لا توجد كلمات ضعيفة بعد. رتّل مع المدرّب وستظهر هنا.';

  @override
  String weakWordMisses(int n) {
    return 'أخطأت فيها $n مرات';
  }

  @override
  String weakWordsLocked(int n) {
    return '$n كلمات أخرى والتدريب الكامل مع المميز';
  }

  @override
  String get practise => 'تدرّب';

  @override
  String get knownSurahsPlan => 'المحفوظ سابقًا';

  @override
  String get notificationsBlocked =>
      'الإشعارات متوقفة لتطبيق أسمِعني. فعّلها من إعدادات الهاتف.';

  @override
  String get pausePlan => 'إيقاف الآيات الجديدة مؤقتًا';

  @override
  String get resumePlan => 'استئناف';

  @override
  String get planPaused => 'متوقفة · المراجعة مستمرة';

  @override
  String weakWordsCardBody(int n) {
    return '$n كلمات تحتاج إتقانًا';
  }
}
