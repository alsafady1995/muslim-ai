// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'مسلم AI';

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
  String get onboardingTitle => 'رفيقك اليومي مع القرآن';

  @override
  String get onboardingSubtitle =>
      'رتّل مع مدرب ذكي، واحفظ بخطة ذكية، وتقدّم كل يوم.';

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
    return '$n آيات يوميًا';
  }

  @override
  String get remindersTitle => 'تذكيرات لطيفة';

  @override
  String get remindersBody =>
      'سنذكّرك بأذكار الصباح والمساء وبالمحافظة على سلسلتك.';

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
  String get goPremium => 'اشترك في بريميوم';

  @override
  String get premiumPitchShort => 'مدرّبك القرآني الذكي. جرّبه مجانًا ٧ أيام';

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
    return '$n آية';
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
  String get sharedFromApp => 'عبر تطبيق مسلم AI';

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
    return 'انضم إليّ في تطبيق مسلم AI، رفيقي اليومي مع القرآن. استخدم رمزي $code لتحصل على نقاط إضافية.';
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
  String get premiumTitle => 'مسلم AI بريميوم';

  @override
  String get premiumSubtitle => 'أقل من ثمن فنجان قهوة شهريًا، لقرآنك كل يوم.';

  @override
  String get benefitRecitation => 'تحليل تلاوتك بالذكاء الاصطناعي كل يوم';

  @override
  String get benefitHifz => 'تدريب حفظ ذكي';

  @override
  String get benefitAsk => 'أسئلة أكثر في اسأل القرآن والمساعد';

  @override
  String get benefitAnalytics => 'خطط مخصصة وتحليلات تقدم متقدمة';

  @override
  String get benefitReciters => 'جميع القرّاء المميزين';

  @override
  String get benefitSupport => 'ادعم استمرار تطوير التطبيق';

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
}
