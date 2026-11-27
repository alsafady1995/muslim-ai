import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Asmi3ni'**
  String get appName;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabQuran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get tabQuran;

  /// No description provided for @tabLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get tabLearn;

  /// No description provided for @tabAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get tabAsk;

  /// No description provided for @tabMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get tabMe;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @xpEarned.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String xpEarned(int xp);

  /// No description provided for @achievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement: {names}'**
  String achievementUnlocked(String names);

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Recite. Get corrected. Never forget what you memorize.'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'An AI coach that listens to your recitation, and a hifz plan that keeps it strong.'**
  String get onboardingSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get haveAccount;

  /// No description provided for @pickDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'How much Quran a day?'**
  String get pickDailyGoal;

  /// No description provided for @goalCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get goalCasual;

  /// No description provided for @goalRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get goalRegular;

  /// No description provided for @goalSerious.
  ///
  /// In en, this message translates to:
  /// **'Serious'**
  String get goalSerious;

  /// No description provided for @goalIntense.
  ///
  /// In en, this message translates to:
  /// **'Intense'**
  String get goalIntense;

  /// No description provided for @ayahsPerDay.
  ///
  /// In en, this message translates to:
  /// **'{n} ayahs/day'**
  String ayahsPerDay(int n);

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'When should we remind you?'**
  String get remindersTitle;

  /// No description provided for @remindersBody.
  ///
  /// In en, this message translates to:
  /// **'One gentle reminder a day. You can change it anytime in settings.'**
  String get remindersBody;

  /// No description provided for @enableReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable reminders'**
  String get enableReminders;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @reminderMorningTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning adhkar'**
  String get reminderMorningTitle;

  /// No description provided for @reminderMorningBody.
  ///
  /// In en, this message translates to:
  /// **'Start your day with the remembrance of Allah.'**
  String get reminderMorningBody;

  /// No description provided for @reminderEveningTitle.
  ///
  /// In en, this message translates to:
  /// **'Evening adhkar'**
  String get reminderEveningTitle;

  /// No description provided for @reminderEveningBody.
  ///
  /// In en, this message translates to:
  /// **'A few minutes of evening adhkar.'**
  String get reminderEveningBody;

  /// No description provided for @reminderStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your streak'**
  String get reminderStreakTitle;

  /// No description provided for @reminderStreakBody.
  ///
  /// In en, this message translates to:
  /// **'Read a few ayahs to keep your streak alive.'**
  String get reminderStreakBody;

  /// No description provided for @reminderHifzTitle.
  ///
  /// In en, this message translates to:
  /// **'Hifz review'**
  String get reminderHifzTitle;

  /// No description provided for @reminderHifzBody.
  ///
  /// In en, this message translates to:
  /// **'Your review session is ready.'**
  String get reminderHifzBody;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to restore your progress on this device.'**
  String get signInBody;

  /// No description provided for @saveProgress.
  ///
  /// In en, this message translates to:
  /// **'Save your progress'**
  String get saveProgress;

  /// No description provided for @saveProgressBody.
  ///
  /// In en, this message translates to:
  /// **'Link an account so your streak, XP and hifz are safe if you change phones.'**
  String get saveProgressBody;

  /// No description provided for @saveProgressHint.
  ///
  /// In en, this message translates to:
  /// **'You\'re using a guest account'**
  String get saveProgressHint;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get verificationCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @prayersToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s prayers'**
  String get prayersToday;

  /// No description provided for @continueJourney.
  ///
  /// In en, this message translates to:
  /// **'Continue your journey'**
  String get continueJourney;

  /// No description provided for @goPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get goPremium;

  /// No description provided for @premiumPitchShort.
  ///
  /// In en, this message translates to:
  /// **'Your Hifz Coach · 7 days free'**
  String get premiumPitchShort;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'day streak'**
  String get dayStreak;

  /// No description provided for @levelN.
  ///
  /// In en, this message translates to:
  /// **'Level {n}'**
  String levelN(int n);

  /// No description provided for @xpToNext.
  ///
  /// In en, this message translates to:
  /// **'{xp} / {next} XP'**
  String xpToNext(int xp, int next);

  /// No description provided for @streakFreezes.
  ///
  /// In en, this message translates to:
  /// **'{n} streak freezes'**
  String streakFreezes(int n);

  /// No description provided for @todaysGoals.
  ///
  /// In en, this message translates to:
  /// **'Today\'s goals'**
  String get todaysGoals;

  /// No description provided for @goalQuran.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get goalQuran;

  /// No description provided for @goalMemorize.
  ///
  /// In en, this message translates to:
  /// **'Hifz'**
  String get goalMemorize;

  /// No description provided for @goalAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Adhkar'**
  String get goalAdhkar;

  /// No description provided for @goalPrayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get goalPrayer;

  /// No description provided for @goalListen.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get goalListen;

  /// No description provided for @fajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get fajr;

  /// No description provided for @dhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get dhuhr;

  /// No description provided for @asr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get asr;

  /// No description provided for @maghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// No description provided for @isha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get isha;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get continueReading;

  /// No description provided for @startWithFatihah.
  ///
  /// In en, this message translates to:
  /// **'Start with Al-Fatihah'**
  String get startWithFatihah;

  /// No description provided for @pickUpWhereLeft.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left'**
  String get pickUpWhereLeft;

  /// No description provided for @hifzReview.
  ///
  /// In en, this message translates to:
  /// **'Hifz review'**
  String get hifzReview;

  /// No description provided for @dueCount.
  ///
  /// In en, this message translates to:
  /// **'{n} due'**
  String dueCount(int n);

  /// No description provided for @reciteWithAi.
  ///
  /// In en, this message translates to:
  /// **'Recite with AI'**
  String get reciteWithAi;

  /// No description provided for @aiCoachHint.
  ///
  /// In en, this message translates to:
  /// **'Get instant feedback'**
  String get aiCoachHint;

  /// No description provided for @adhkar.
  ///
  /// In en, this message translates to:
  /// **'Adhkar'**
  String get adhkar;

  /// No description provided for @morningAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Morning adhkar'**
  String get morningAdhkar;

  /// No description provided for @eveningAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Evening adhkar'**
  String get eveningAdhkar;

  /// No description provided for @sleepAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Sleep adhkar'**
  String get sleepAdhkar;

  /// No description provided for @askTheQuran.
  ///
  /// In en, this message translates to:
  /// **'Ask the Quran'**
  String get askTheQuran;

  /// No description provided for @askHint.
  ///
  /// In en, this message translates to:
  /// **'Guidance for life'**
  String get askHint;

  /// No description provided for @searchQuran.
  ///
  /// In en, this message translates to:
  /// **'Search the Quran'**
  String get searchQuran;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by meaning'**
  String get searchHint;

  /// No description provided for @findSurah.
  ///
  /// In en, this message translates to:
  /// **'Find a surah'**
  String get findSurah;

  /// No description provided for @ayahCount.
  ///
  /// In en, this message translates to:
  /// **'{n} ayahs'**
  String ayahCount(int n);

  /// No description provided for @makki.
  ///
  /// In en, this message translates to:
  /// **'Makki'**
  String get makki;

  /// No description provided for @madani.
  ///
  /// In en, this message translates to:
  /// **'Madani'**
  String get madani;

  /// No description provided for @ayahN.
  ///
  /// In en, this message translates to:
  /// **'Ayah {key}'**
  String ayahN(String key);

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @repeatRange.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatRange;

  /// No description provided for @playFromHere.
  ///
  /// In en, this message translates to:
  /// **'Play from here'**
  String get playFromHere;

  /// No description provided for @repeatAyah3.
  ///
  /// In en, this message translates to:
  /// **'Repeat this ayah (memorization)'**
  String get repeatAyah3;

  /// No description provided for @quranRef.
  ///
  /// In en, this message translates to:
  /// **'Quran {key}'**
  String quranRef(String key);

  /// No description provided for @sharedFromApp.
  ///
  /// In en, this message translates to:
  /// **'Shared from Asmi3ni'**
  String get sharedFromApp;

  /// No description provided for @memorizationMode.
  ///
  /// In en, this message translates to:
  /// **'Memorization mode'**
  String get memorizationMode;

  /// No description provided for @playSurah.
  ///
  /// In en, this message translates to:
  /// **'Play surah'**
  String get playSurah;

  /// No description provided for @aiCoach.
  ///
  /// In en, this message translates to:
  /// **'AI Quran Coach'**
  String get aiCoach;

  /// No description provided for @hifzTest.
  ///
  /// In en, this message translates to:
  /// **'Hifz test'**
  String get hifzTest;

  /// No description provided for @aiCoachPitch.
  ///
  /// In en, this message translates to:
  /// **'Recite aloud and get word-by-word feedback'**
  String get aiCoachPitch;

  /// No description provided for @micPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is needed to listen to your recitation.'**
  String get micPermissionNeeded;

  /// No description provided for @analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t analyse this recording. Please try again.'**
  String get analysisFailed;

  /// No description provided for @analysing.
  ///
  /// In en, this message translates to:
  /// **'Listening to your recitation…'**
  String get analysing;

  /// No description provided for @chooseWhatToRecite.
  ///
  /// In en, this message translates to:
  /// **'What will you recite?'**
  String get chooseWhatToRecite;

  /// No description provided for @surah.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get surah;

  /// No description provided for @fromAyah.
  ///
  /// In en, this message translates to:
  /// **'From ayah'**
  String get fromAyah;

  /// No description provided for @toAyah.
  ///
  /// In en, this message translates to:
  /// **'To ayah'**
  String get toAyah;

  /// No description provided for @coachRangeHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: 1–5 ayahs give the most precise feedback.'**
  String get coachRangeHint;

  /// No description provided for @reciteFromMemory.
  ///
  /// In en, this message translates to:
  /// **'Recite from memory. The text is hidden.'**
  String get reciteFromMemory;

  /// No description provided for @tapToRecite.
  ///
  /// In en, this message translates to:
  /// **'Tap to start reciting'**
  String get tapToRecite;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent! ما شاء الله'**
  String get excellent;

  /// No description provided for @goodJob.
  ///
  /// In en, this message translates to:
  /// **'Good job, keep going'**
  String get goodJob;

  /// No description provided for @keepPracticing.
  ///
  /// In en, this message translates to:
  /// **'Keep practicing, you\'re improving'**
  String get keepPracticing;

  /// No description provided for @notCompleted.
  ///
  /// In en, this message translates to:
  /// **'You stopped before the end of the selection.'**
  String get notCompleted;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @fluency.
  ///
  /// In en, this message translates to:
  /// **'Fluency'**
  String get fluency;

  /// No description provided for @tajweed.
  ///
  /// In en, this message translates to:
  /// **'Tajweed'**
  String get tajweed;

  /// No description provided for @yourRecitation.
  ///
  /// In en, this message translates to:
  /// **'Your recitation'**
  String get yourRecitation;

  /// No description provided for @legendCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get legendCorrect;

  /// No description provided for @legendCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get legendCheck;

  /// No description provided for @legendMistake.
  ///
  /// In en, this message translates to:
  /// **'Mistake'**
  String get legendMistake;

  /// No description provided for @corrections.
  ///
  /// In en, this message translates to:
  /// **'Corrections'**
  String get corrections;

  /// No description provided for @expected.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get expected;

  /// No description provided for @heard.
  ///
  /// In en, this message translates to:
  /// **'Heard'**
  String get heard;

  /// No description provided for @mistakeMispronounced.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation'**
  String get mistakeMispronounced;

  /// No description provided for @mistakeWrongWord.
  ///
  /// In en, this message translates to:
  /// **'Wrong word'**
  String get mistakeWrongWord;

  /// No description provided for @mistakeSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped word'**
  String get mistakeSkipped;

  /// No description provided for @mistakeAdded.
  ///
  /// In en, this message translates to:
  /// **'Extra word'**
  String get mistakeAdded;

  /// No description provided for @mistakeRepetition.
  ///
  /// In en, this message translates to:
  /// **'Repetition'**
  String get mistakeRepetition;

  /// No description provided for @mistakeUnclear.
  ///
  /// In en, this message translates to:
  /// **'Unclear, please check'**
  String get mistakeUnclear;

  /// No description provided for @mistakeShortMadd.
  ///
  /// In en, this message translates to:
  /// **'Possible short madd (check the elongation)'**
  String get mistakeShortMadd;

  /// No description provided for @mistakeLongPause.
  ///
  /// In en, this message translates to:
  /// **'Long pause'**
  String get mistakeLongPause;

  /// No description provided for @coachDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI feedback can be wrong. For tajweed certification, learn with a qualified teacher.'**
  String get coachDisclaimer;

  /// No description provided for @listenCorrect.
  ///
  /// In en, this message translates to:
  /// **'Listen to the correct recitation'**
  String get listenCorrect;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @hifzCoach.
  ///
  /// In en, this message translates to:
  /// **'Hifz coach'**
  String get hifzCoach;

  /// No description provided for @todaysSession.
  ///
  /// In en, this message translates to:
  /// **'Today\'s session'**
  String get todaysSession;

  /// No description provided for @queueSummary.
  ///
  /// In en, this message translates to:
  /// **'{reviews} reviews · {fresh} new ayahs'**
  String queueSummary(int reviews, int fresh);

  /// No description provided for @allDoneToday.
  ///
  /// In en, this message translates to:
  /// **'All done for today'**
  String get allDoneToday;

  /// No description provided for @startSession.
  ///
  /// In en, this message translates to:
  /// **'Start session'**
  String get startSession;

  /// No description provided for @myPlans.
  ///
  /// In en, this message translates to:
  /// **'My plans'**
  String get myPlans;

  /// No description provided for @newPlan.
  ///
  /// In en, this message translates to:
  /// **'New plan'**
  String get newPlan;

  /// No description provided for @noPlansYet.
  ///
  /// In en, this message translates to:
  /// **'Create a plan to start memorizing.'**
  String get noPlansYet;

  /// No description provided for @hifzPlan.
  ///
  /// In en, this message translates to:
  /// **'Hifz plan'**
  String get hifzPlan;

  /// No description provided for @newPerDay.
  ///
  /// In en, this message translates to:
  /// **'{n} new ayahs per day'**
  String newPerDay(int n);

  /// No description provided for @newAyahsPerDay.
  ///
  /// In en, this message translates to:
  /// **'New ayahs per day: {n}'**
  String newAyahsPerDay(int n);

  /// No description provided for @createPlan.
  ///
  /// In en, this message translates to:
  /// **'Create plan'**
  String get createPlan;

  /// No description provided for @memorized.
  ///
  /// In en, this message translates to:
  /// **'Memorized'**
  String get memorized;

  /// No description provided for @retention.
  ///
  /// In en, this message translates to:
  /// **'Retention'**
  String get retention;

  /// No description provided for @atRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get atRisk;

  /// No description provided for @sessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session complete'**
  String get sessionComplete;

  /// No description provided for @newAyah.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newAyah;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @predictedRecall.
  ///
  /// In en, this message translates to:
  /// **'Predicted recall: {n}%'**
  String predictedRecall(int n);

  /// No description provided for @reciteThenReveal.
  ///
  /// In en, this message translates to:
  /// **'Recite this ayah from memory, then reveal to check.'**
  String get reciteThenReveal;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @testWithAi.
  ///
  /// In en, this message translates to:
  /// **'Test with AI'**
  String get testWithAi;

  /// No description provided for @reveal.
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get reveal;

  /// No description provided for @gradeAgain.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get gradeAgain;

  /// No description provided for @gradeHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get gradeHard;

  /// No description provided for @gradeGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get gradeGood;

  /// No description provided for @gradeEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get gradeEasy;

  /// No description provided for @crisisHelp.
  ///
  /// In en, this message translates to:
  /// **'If you are in danger or thinking of harming yourself, please contact local emergency services or a crisis line now, and reach out to someone you trust. You are not alone.'**
  String get crisisHelp;

  /// No description provided for @consultScholar.
  ///
  /// In en, this message translates to:
  /// **'This needs a personal ruling. Please consult a qualified scholar.'**
  String get consultScholar;

  /// No description provided for @fromQuran.
  ///
  /// In en, this message translates to:
  /// **'From the Quran'**
  String get fromQuran;

  /// No description provided for @fromHadith.
  ///
  /// In en, this message translates to:
  /// **'From the Hadith'**
  String get fromHadith;

  /// No description provided for @explanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get explanation;

  /// No description provided for @scholarlyViews.
  ///
  /// In en, this message translates to:
  /// **'Scholarly views'**
  String get scholarlyViews;

  /// No description provided for @reportAnswer.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportAnswer;

  /// No description provided for @tafsir.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get tafsir;

  /// No description provided for @assistant.
  ///
  /// In en, this message translates to:
  /// **'Islamic assistant'**
  String get assistant;

  /// No description provided for @thanksForReport.
  ///
  /// In en, this message translates to:
  /// **'Thank you. We\'ll review this answer.'**
  String get thanksForReport;

  /// No description provided for @suggestStress.
  ///
  /// In en, this message translates to:
  /// **'How do I deal with stress?'**
  String get suggestStress;

  /// No description provided for @suggestForgiveness.
  ///
  /// In en, this message translates to:
  /// **'What does Islam say about forgiveness?'**
  String get suggestForgiveness;

  /// No description provided for @suggestAnger.
  ///
  /// In en, this message translates to:
  /// **'How can I control anger?'**
  String get suggestAnger;

  /// No description provided for @suggestGratitude.
  ///
  /// In en, this message translates to:
  /// **'Verses about gratitude'**
  String get suggestGratitude;

  /// No description provided for @assistantIntro.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about Islam. Answers cite the Quran and Hadith.'**
  String get assistantIntro;

  /// No description provided for @askIntro.
  ///
  /// In en, this message translates to:
  /// **'Ask a question and get related verses, hadith and an explanation.'**
  String get askIntro;

  /// No description provided for @searchingSources.
  ///
  /// In en, this message translates to:
  /// **'Searching the sources…'**
  String get searchingSources;

  /// No description provided for @askPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type your question…'**
  String get askPlaceholder;

  /// No description provided for @topicPatience.
  ///
  /// In en, this message translates to:
  /// **'Patience'**
  String get topicPatience;

  /// No description provided for @topicAnxiety.
  ///
  /// In en, this message translates to:
  /// **'Anxiety'**
  String get topicAnxiety;

  /// No description provided for @topicGratitude.
  ///
  /// In en, this message translates to:
  /// **'Gratitude'**
  String get topicGratitude;

  /// No description provided for @topicFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get topicFamily;

  /// No description provided for @topicSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get topicSuccess;

  /// No description provided for @topicKindness.
  ///
  /// In en, this message translates to:
  /// **'Kindness'**
  String get topicKindness;

  /// No description provided for @topicBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get topicBusiness;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. verses about patience'**
  String get searchPlaceholder;

  /// No description provided for @byMeaning.
  ///
  /// In en, this message translates to:
  /// **'By meaning'**
  String get byMeaning;

  /// No description provided for @byWords.
  ///
  /// In en, this message translates to:
  /// **'By words'**
  String get byWords;

  /// No description provided for @tryTopics.
  ///
  /// In en, this message translates to:
  /// **'Try a topic'**
  String get tryTopics;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @dailyGoals.
  ///
  /// In en, this message translates to:
  /// **'Daily goals'**
  String get dailyGoals;

  /// No description provided for @goalsIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose small, steady goals. The most beloved deeds are the consistent ones, even if small.'**
  String get goalsIntro;

  /// No description provided for @unitAyahs.
  ///
  /// In en, this message translates to:
  /// **'ayahs'**
  String get unitAyahs;

  /// No description provided for @unitSets.
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get unitSets;

  /// No description provided for @unitPrayers.
  ///
  /// In en, this message translates to:
  /// **'prayers'**
  String get unitPrayers;

  /// No description provided for @unitMinutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get unitMinutes;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreak;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get bestStreak;

  /// No description provided for @ayahs30d.
  ///
  /// In en, this message translates to:
  /// **'Ayahs (30d)'**
  String get ayahs30d;

  /// No description provided for @goalDays30d.
  ///
  /// In en, this message translates to:
  /// **'Goal days (30d)'**
  String get goalDays30d;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @coachingHistory.
  ///
  /// In en, this message translates to:
  /// **'AI coaching history'**
  String get coachingHistory;

  /// No description provided for @noRecitationsYet.
  ///
  /// In en, this message translates to:
  /// **'No recitations yet.'**
  String get noRecitationsYet;

  /// No description provided for @scoreN.
  ///
  /// In en, this message translates to:
  /// **'Score {n}'**
  String scoreN(int n);

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get inviteFriends;

  /// No description provided for @inviteBody.
  ///
  /// In en, this message translates to:
  /// **'Share your code. You both get bonus XP, and you get a streak freeze.'**
  String get inviteBody;

  /// No description provided for @shareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share invite'**
  String get shareInvite;

  /// No description provided for @haveInviteCode.
  ///
  /// In en, this message translates to:
  /// **'I have an invite code'**
  String get haveInviteCode;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// No description provided for @inviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Join me on Asmi3ni, my daily Quran companion. Use my code {code} for bonus XP.'**
  String inviteMessage(String code);

  /// No description provided for @inviteApplied.
  ///
  /// In en, this message translates to:
  /// **'Invite code applied!'**
  String get inviteApplied;

  /// No description provided for @inviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t valid.'**
  String get inviteInvalid;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @reciter.
  ///
  /// In en, this message translates to:
  /// **'Reciter'**
  String get reciter;

  /// No description provided for @showTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get showTranslation;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @streakReminder.
  ///
  /// In en, this message translates to:
  /// **'Streak reminder'**
  String get streakReminder;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get manageSubscription;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @restored.
  ///
  /// In en, this message translates to:
  /// **'Premium restored'**
  String get restored;

  /// No description provided for @nothingToRestore.
  ///
  /// In en, this message translates to:
  /// **'No purchases to restore'**
  String get nothingToRestore;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your progress and data. Cancel any subscription in your store account separately.'**
  String get deleteAccountWarning;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Asmi3ni Premium'**
  String get premiumTitle;

  /// No description provided for @premiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your Hifz Coach listens, grades each review and schedules the next one, so nothing slips.'**
  String get premiumSubtitle;

  /// No description provided for @storeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions aren\'t available right now.'**
  String get storeUnavailable;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @freeTrialDays.
  ///
  /// In en, this message translates to:
  /// **'{n}-day free trial'**
  String freeTrialDays(int n);

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get perYear;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get perMonth;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @subscriptionTerms.
  ///
  /// In en, this message translates to:
  /// **'Auto-renews until cancelled. Cancel anytime in your App Store or Google Play account settings.'**
  String get subscriptionTerms;

  /// No description provided for @welcomePremium.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Premium!'**
  String get welcomePremium;

  /// No description provided for @purchasePending.
  ///
  /// In en, this message translates to:
  /// **'Your purchase is pending.'**
  String get purchasePending;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed.'**
  String get purchaseFailed;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get bestValue;

  /// No description provided for @savePercent.
  ///
  /// In en, this message translates to:
  /// **'Save {pct}%'**
  String savePercent(int pct);

  /// No description provided for @startFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'Start {n}-day free trial'**
  String startFreeTrial(int n);

  /// No description provided for @trialThenPrice.
  ///
  /// In en, this message translates to:
  /// **'{n} days free, then {price} / {period}'**
  String trialThenPrice(int n, String price, String period);

  /// No description provided for @aiBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'This month\'s AI allowance is used up'**
  String get aiBudgetTitle;

  /// No description provided for @aiBudgetPremium.
  ///
  /// In en, this message translates to:
  /// **'To keep Premium affordable for everyone, AI features pause until {date}. Reading, listening, keyword search, adhkar and your hifz reviews keep working as usual.'**
  String aiBudgetPremium(String date);

  /// No description provided for @aiBudgetFree.
  ///
  /// In en, this message translates to:
  /// **'Free AI features renew on {date}. Premium includes a much larger allowance. Meanwhile, reading, listening and your hifz reviews keep working.'**
  String aiBudgetFree(String date);

  /// No description provided for @aiBudgetTrial.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used the AI allowance included in your free trial. It renews when your subscription starts on {date}.'**
  String aiBudgetTrial(String date);

  /// No description provided for @aiLighterMode.
  ///
  /// In en, this message translates to:
  /// **'You\'re near this month\'s AI allowance, so answers use a lighter model until {date}.'**
  String aiLighterMode(String date);

  /// No description provided for @intentTitle.
  ///
  /// In en, this message translates to:
  /// **'What matters most to you right now?'**
  String get intentTitle;

  /// No description provided for @intentMemorize.
  ///
  /// In en, this message translates to:
  /// **'Memorize the Quran'**
  String get intentMemorize;

  /// No description provided for @intentRecite.
  ///
  /// In en, this message translates to:
  /// **'Perfect my recitation'**
  String get intentRecite;

  /// No description provided for @intentRead.
  ///
  /// In en, this message translates to:
  /// **'Read every day'**
  String get intentRead;

  /// No description provided for @intentUnderstand.
  ///
  /// In en, this message translates to:
  /// **'Understand the Quran'**
  String get intentUnderstand;

  /// No description provided for @knownTitle.
  ///
  /// In en, this message translates to:
  /// **'Which surahs do you already know by heart?'**
  String get knownTitle;

  /// No description provided for @knownBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll keep them fresh with short reviews.'**
  String get knownBody;

  /// No description provided for @knownNone.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get knownNone;

  /// No description provided for @firstRecitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Recite Al-Fatiha'**
  String get firstRecitationTitle;

  /// No description provided for @firstRecitationBody.
  ///
  /// In en, this message translates to:
  /// **'Recite it aloud and see what the coach hears, word by word. This one is on us.'**
  String get firstRecitationBody;

  /// No description provided for @reciteNow.
  ///
  /// In en, this message translates to:
  /// **'Recite now'**
  String get reciteNow;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @firstResult.
  ///
  /// In en, this message translates to:
  /// **'Score {score} · {n} words to polish'**
  String firstResult(int score, int n);

  /// No description provided for @firstResultPerfect.
  ///
  /// In en, this message translates to:
  /// **'Score {score} · masha\'Allah, no mistakes'**
  String firstResultPerfect(int score);

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get planTitle;

  /// No description provided for @planMemorize.
  ///
  /// In en, this message translates to:
  /// **'Memorize Surah {name}'**
  String planMemorize(String name);

  /// No description provided for @planKnown.
  ///
  /// In en, this message translates to:
  /// **'{n} surahs you know get short reviews, starting tomorrow.'**
  String planKnown(int n);

  /// No description provided for @planRead.
  ///
  /// In en, this message translates to:
  /// **'Read {n} ayahs a day'**
  String planRead(int n);

  /// No description provided for @planFirstReview.
  ///
  /// In en, this message translates to:
  /// **'Your first review is tomorrow.'**
  String get planFirstReview;

  /// No description provided for @reminderAt.
  ///
  /// In en, this message translates to:
  /// **'Remind me at {time}'**
  String reminderAt(String time);

  /// No description provided for @alsoAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Also remind me of morning and evening adhkar'**
  String get alsoAdhkar;

  /// No description provided for @remindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get remindMe;

  /// No description provided for @reminderReadTitle.
  ///
  /// In en, this message translates to:
  /// **'Your daily ayahs'**
  String get reminderReadTitle;

  /// No description provided for @reminderReadBody.
  ///
  /// In en, this message translates to:
  /// **'A few minutes with the Quran.'**
  String get reminderReadBody;

  /// No description provided for @limitTitleRecitation.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used this week\'s {n} checks'**
  String limitTitleRecitation(int n);

  /// No description provided for @limitTitleHifz.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used this week\'s {n} AI tests'**
  String limitTitleHifz(int n);

  /// No description provided for @limitTitleAsk.
  ///
  /// In en, this message translates to:
  /// **'You\'ve asked {n} questions this week'**
  String limitTitleAsk(int n);

  /// No description provided for @limitTitleSearch.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used this week\'s {n} meaning searches'**
  String limitTitleSearch(int n);

  /// No description provided for @limitRenews.
  ///
  /// In en, this message translates to:
  /// **'They renew on {day}.'**
  String limitRenews(String day);

  /// No description provided for @limitWaitUntil.
  ///
  /// In en, this message translates to:
  /// **'Wait until {day}'**
  String limitWaitUntil(String day);

  /// No description provided for @limitKeepsWorking.
  ///
  /// In en, this message translates to:
  /// **'Reading, listening, adhkar and self-graded reviews stay unlimited.'**
  String get limitKeepsWorking;

  /// No description provided for @tryPremiumFree.
  ///
  /// In en, this message translates to:
  /// **'Try Premium free'**
  String get tryPremiumFree;

  /// No description provided for @checksLeft.
  ///
  /// In en, this message translates to:
  /// **'{left} of {limit} checks left this week'**
  String checksLeft(int left, int limit);

  /// No description provided for @aiTestsLeft.
  ///
  /// In en, this message translates to:
  /// **'{left} AI tests left this week'**
  String aiTestsLeft(int left);

  /// No description provided for @clipNoteFree.
  ///
  /// In en, this message translates to:
  /// **'Free checks cover 60 seconds. Premium checks a full page in one go.'**
  String get clipNoteFree;

  /// No description provided for @secondsLeft.
  ///
  /// In en, this message translates to:
  /// **'{s}s left'**
  String secondsLeft(int s);

  /// No description provided for @rangeTooLong.
  ///
  /// In en, this message translates to:
  /// **'Up to 50 ayahs at a time.'**
  String get rangeTooLong;

  /// No description provided for @searchFellBack.
  ///
  /// In en, this message translates to:
  /// **'This week\'s meaning searches are used up, so these are word matches. They renew on {day}.'**
  String searchFellBack(String day);

  /// No description provided for @hifzLimitInline.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used this week\'s {n} AI tests. Your review continues with self-grading. Want the coach to grade every review?'**
  String hifzLimitInline(int n);

  /// No description provided for @continueReviewing.
  ///
  /// In en, this message translates to:
  /// **'Continue reviewing'**
  String get continueReviewing;

  /// No description provided for @aiTestNotGraded.
  ///
  /// In en, this message translates to:
  /// **'That recitation didn\'t cover this ayah. Grade it yourself.'**
  String get aiTestNotGraded;

  /// No description provided for @milestoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve memorized Surah {name}'**
  String milestoneTitle(String name);

  /// No description provided for @milestoneBody.
  ///
  /// In en, this message translates to:
  /// **'Alhamdulillah. +{xp} XP'**
  String milestoneBody(int xp);

  /// No description provided for @milestoneOffer.
  ///
  /// In en, this message translates to:
  /// **'Keep it strong for good: the coach tests it with you until it\'s mastered. 7 days free.'**
  String get milestoneOffer;

  /// No description provided for @finishCoach.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get finishCoach;

  /// No description provided for @paywallHeadlineMemorize.
  ///
  /// In en, this message translates to:
  /// **'Keep every ayah you memorize.'**
  String get paywallHeadlineMemorize;

  /// No description provided for @paywallHeadlineRecite.
  ///
  /// In en, this message translates to:
  /// **'Recite with confidence. Every word checked.'**
  String get paywallHeadlineRecite;

  /// No description provided for @benefitHifzTests.
  ///
  /// In en, this message translates to:
  /// **'Test your hifz with your voice every day. Grading is automatic.'**
  String get benefitHifzTests;

  /// No description provided for @benefitFullPage.
  ///
  /// In en, this message translates to:
  /// **'Check a full page in one go, up to 3 minutes.'**
  String get benefitFullPage;

  /// No description provided for @benefitWeakWords.
  ///
  /// In en, this message translates to:
  /// **'Your weak words, practised first.'**
  String get benefitWeakWords;

  /// No description provided for @benefitBestAi.
  ///
  /// In en, this message translates to:
  /// **'Ask the Quran with our most capable AI.'**
  String get benefitBestAi;

  /// No description provided for @trialToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get trialToday;

  /// No description provided for @trialTodayBody.
  ///
  /// In en, this message translates to:
  /// **'Full access, no charge.'**
  String get trialTodayBody;

  /// No description provided for @trialDayN.
  ///
  /// In en, this message translates to:
  /// **'Day {n}'**
  String trialDayN(int n);

  /// No description provided for @trialReminderStep.
  ///
  /// In en, this message translates to:
  /// **'We remind you before any charge.'**
  String get trialReminderStep;

  /// No description provided for @trialChargeStep.
  ///
  /// In en, this message translates to:
  /// **'Your plan starts at {price}/{period}. Cancel before then and pay nothing.'**
  String trialChargeStep(String price, String period);

  /// No description provided for @startMyFreeDays.
  ///
  /// In en, this message translates to:
  /// **'Start my {n} free days'**
  String startMyFreeDays(int n);

  /// No description provided for @subscribeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Subscribe monthly'**
  String get subscribeMonthly;

  /// No description provided for @continueFree.
  ///
  /// In en, this message translates to:
  /// **'Continue free'**
  String get continueFree;

  /// No description provided for @noChargeToday.
  ///
  /// In en, this message translates to:
  /// **'No charge today. Cancel anytime in your App Store or Google Play settings. Auto-renews until cancelled.'**
  String get noChargeToday;

  /// No description provided for @adFreePromise.
  ///
  /// In en, this message translates to:
  /// **'Your subscription keeps Asmi3ni free of ads, always.'**
  String get adFreePromise;

  /// No description provided for @trialReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Your free trial ends in 2 days'**
  String get trialReminderTitle;

  /// No description provided for @trialReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Keep it and your plan continues. Cancel in your store settings and you won\'t be charged.'**
  String get trialReminderBody;

  /// No description provided for @todayReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s review'**
  String get todayReviewTitle;

  /// No description provided for @todayReviewBody.
  ///
  /// In en, this message translates to:
  /// **'{n} ayahs · about {m} min'**
  String todayReviewBody(int n, int m);

  /// No description provided for @todayNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s new ayahs'**
  String get todayNewTitle;

  /// No description provided for @todayReciteTitle.
  ///
  /// In en, this message translates to:
  /// **'Recite with the coach'**
  String get todayReciteTitle;

  /// No description provided for @todayReciteBody.
  ///
  /// In en, this message translates to:
  /// **'One minute, word-by-word feedback'**
  String get todayReciteBody;

  /// No description provided for @todayDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s review is done'**
  String get todayDoneTitle;

  /// No description provided for @todayDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Alhamdulillah. See you tomorrow.'**
  String get todayDoneBody;

  /// No description provided for @startHifzPlan.
  ///
  /// In en, this message translates to:
  /// **'Start a hifz plan'**
  String get startHifzPlan;

  /// No description provided for @startHifzPlanBody.
  ///
  /// In en, this message translates to:
  /// **'A few ayahs a day, reviewed before you forget them'**
  String get startHifzPlanBody;

  /// No description provided for @startLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startLabel;

  /// No description provided for @weekTitle.
  ///
  /// In en, this message translates to:
  /// **'Your week'**
  String get weekTitle;

  /// No description provided for @weekStats.
  ///
  /// In en, this message translates to:
  /// **'{days} active days · {reviews} reviews · {ayahs} ayahs read'**
  String weekStats(int days, int reviews, int ayahs);

  /// No description provided for @weekAtRisk.
  ///
  /// In en, this message translates to:
  /// **'{n} ayahs are at risk of being forgotten this week.'**
  String weekAtRisk(int n);

  /// No description provided for @weekAtRiskOffer.
  ///
  /// In en, this message translates to:
  /// **'Premium tests all of them for you.'**
  String get weekAtRiskOffer;

  /// No description provided for @weekAllSafe.
  ///
  /// In en, this message translates to:
  /// **'Every ayah you memorized is safe. Masha\'Allah.'**
  String get weekAllSafe;

  /// No description provided for @seeMyPlan.
  ///
  /// In en, this message translates to:
  /// **'See my plan'**
  String get seeMyPlan;

  /// No description provided for @billingIssue.
  ///
  /// In en, this message translates to:
  /// **'Update your payment to keep your Hifz Coach.'**
  String get billingIssue;

  /// No description provided for @trialEnds.
  ///
  /// In en, this message translates to:
  /// **'Your free trial ends on {date}. Cancel anytime in your store settings.'**
  String trialEnds(String date);

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @weakWordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your weak words'**
  String get weakWordsTitle;

  /// No description provided for @weakWordsBody.
  ///
  /// In en, this message translates to:
  /// **'The words you get wrong most often, practised first.'**
  String get weakWordsBody;

  /// No description provided for @weakWordsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No weak words yet. Recite with the coach and they\'ll appear here.'**
  String get weakWordsEmpty;

  /// No description provided for @weakWordMisses.
  ///
  /// In en, this message translates to:
  /// **'Missed {n} times'**
  String weakWordMisses(int n);

  /// No description provided for @weakWordsLocked.
  ///
  /// In en, this message translates to:
  /// **'{n} more words and the full drill with Premium'**
  String weakWordsLocked(int n);

  /// No description provided for @practise.
  ///
  /// In en, this message translates to:
  /// **'Practise'**
  String get practise;

  /// No description provided for @knownSurahsPlan.
  ///
  /// In en, this message translates to:
  /// **'Already memorized'**
  String get knownSurahsPlan;

  /// No description provided for @notificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for Asmi3ni. Turn them on in your phone settings.'**
  String get notificationsBlocked;

  /// No description provided for @pausePlan.
  ///
  /// In en, this message translates to:
  /// **'Pause new ayahs'**
  String get pausePlan;

  /// No description provided for @resumePlan.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumePlan;

  /// No description provided for @planPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused · reviews continue'**
  String get planPaused;

  /// No description provided for @weakWordsCardBody.
  ///
  /// In en, this message translates to:
  /// **'{n} words to polish'**
  String weakWordsCardBody(int n);

  /// No description provided for @qiblaTitle.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get qiblaTitle;

  /// No description provided for @qiblaHint.
  ///
  /// In en, this message translates to:
  /// **'Find the direction of Makkah'**
  String get qiblaHint;

  /// No description provided for @qiblaFacing.
  ///
  /// In en, this message translates to:
  /// **'You are facing the Qibla'**
  String get qiblaFacing;

  /// No description provided for @qiblaTurnRight.
  ///
  /// In en, this message translates to:
  /// **'Turn right {deg}°'**
  String qiblaTurnRight(int deg);

  /// No description provided for @qiblaTurnLeft.
  ///
  /// In en, this message translates to:
  /// **'Turn left {deg}°'**
  String qiblaTurnLeft(int deg);

  /// No description provided for @qiblaNoSensor.
  ///
  /// In en, this message translates to:
  /// **'This phone has no compass. Face {deg}° from north.'**
  String qiblaNoSensor(int deg);

  /// No description provided for @qiblaBearing.
  ///
  /// In en, this message translates to:
  /// **'Qibla: {deg}° from north'**
  String qiblaBearing(int deg);

  /// No description provided for @qiblaDistance.
  ///
  /// In en, this message translates to:
  /// **'{km} km to Makkah'**
  String qiblaDistance(int km);

  /// No description provided for @qiblaCalibrate.
  ///
  /// In en, this message translates to:
  /// **'Keep the phone flat and away from metal. If the direction looks off, move the phone in a figure 8.'**
  String get qiblaCalibrate;

  /// No description provided for @qiblaPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your location stays on your phone.'**
  String get qiblaPrivacy;

  /// No description provided for @qiblaLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to find the Qibla.'**
  String get qiblaLocationOff;

  /// No description provided for @qiblaPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow location access so we can work out the Qibla from where you are.'**
  String get qiblaPermission;

  /// No description provided for @qiblaLocationError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t get your location. Try again outdoors or near a window.'**
  String get qiblaLocationError;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @khatmaGroups.
  ///
  /// In en, this message translates to:
  /// **'Khatma groups'**
  String get khatmaGroups;

  /// No description provided for @khatmaGroupsHint.
  ///
  /// In en, this message translates to:
  /// **'Finish the Quran together'**
  String get khatmaGroupsHint;

  /// No description provided for @khatmaGroupsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish the Quran together'**
  String get khatmaGroupsEmptyTitle;

  /// No description provided for @khatmaGroupsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a private group for your family or friends, share the 30 juz\', encourage each other and see who reads the most.'**
  String get khatmaGroupsEmptyBody;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create a group'**
  String get createGroup;

  /// No description provided for @joinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinGroup;

  /// No description provided for @joinWithCode.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get joinWithCode;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @yourNameInGroup.
  ///
  /// In en, this message translates to:
  /// **'Your name in the group'**
  String get yourNameInGroup;

  /// No description provided for @groupMembersN.
  ///
  /// In en, this message translates to:
  /// **'{n} members'**
  String groupMembersN(int n);

  /// No description provided for @khatmasCompletedN.
  ///
  /// In en, this message translates to:
  /// **'{n} khatmas completed'**
  String khatmasCompletedN(int n);

  /// No description provided for @myJuzList.
  ///
  /// In en, this message translates to:
  /// **'My juz\': {list}'**
  String myJuzList(String list);

  /// No description provided for @khatmaNumber.
  ///
  /// In en, this message translates to:
  /// **'Khatma {n}'**
  String khatmaNumber(int n);

  /// No description provided for @juzTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a juz\' to take it or mark it as read.'**
  String get juzTapHint;

  /// No description provided for @juzDone.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get juzDone;

  /// No description provided for @juzMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get juzMine;

  /// No description provided for @juzTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get juzTaken;

  /// No description provided for @juzOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get juzOpen;

  /// No description provided for @juzN.
  ///
  /// In en, this message translates to:
  /// **'Juz\' {n}'**
  String juzN(int n);

  /// No description provided for @juzMarkRead.
  ///
  /// In en, this message translates to:
  /// **'I\'ve read it'**
  String get juzMarkRead;

  /// No description provided for @juzClaim.
  ///
  /// In en, this message translates to:
  /// **'I\'ll read it'**
  String get juzClaim;

  /// No description provided for @juzRelease.
  ///
  /// In en, this message translates to:
  /// **'Give it back'**
  String get juzRelease;

  /// No description provided for @juzAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign to a member'**
  String get juzAssign;

  /// No description provided for @juzUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get juzUndo;

  /// No description provided for @khatmaCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'The khatma is complete!'**
  String get khatmaCompleteTitle;

  /// No description provided for @khatmaCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'May Allah accept it from all of you. A new khatma has started for the group.'**
  String get khatmaCompleteBody;

  /// No description provided for @tabJuz.
  ///
  /// In en, this message translates to:
  /// **'Juz\''**
  String get tabJuz;

  /// No description provided for @tabMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get tabMessages;

  /// No description provided for @tabLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Competition'**
  String get tabLeaderboard;

  /// No description provided for @inviteToGroup.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get inviteToGroup;

  /// No description provided for @groupInviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Join our khatma \"{name}\" on Asmi3ni. Group code: {code}'**
  String groupInviteMessage(String name, String code);

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get groupMembers;

  /// No description provided for @groupOwner.
  ///
  /// In en, this message translates to:
  /// **'Group admin'**
  String get groupOwner;

  /// No description provided for @distributeJuz.
  ///
  /// In en, this message translates to:
  /// **'Share open juz\' among members'**
  String get distributeJuz;

  /// No description provided for @distributedN.
  ///
  /// In en, this message translates to:
  /// **'{n} juz\' shared out'**
  String distributedN(int n);

  /// No description provided for @renameGroup.
  ///
  /// In en, this message translates to:
  /// **'Rename group'**
  String get renameGroup;

  /// No description provided for @newInviteCode.
  ///
  /// In en, this message translates to:
  /// **'New invite code'**
  String get newInviteCode;

  /// No description provided for @newInviteCodeDone.
  ///
  /// In en, this message translates to:
  /// **'New code: {code}. The old one no longer works.'**
  String newInviteCodeDone(String code);

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get leaveGroup;

  /// No description provided for @leaveGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave this group? Juz\' you haven\'t finished go back to the group.'**
  String get leaveGroupConfirm;

  /// No description provided for @messagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Send a word of encouragement!'**
  String get messagesEmpty;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get messageHint;

  /// No description provided for @sendCheer.
  ///
  /// In en, this message translates to:
  /// **'Send encouragement'**
  String get sendCheer;

  /// No description provided for @formerMember.
  ///
  /// In en, this message translates to:
  /// **'Former member'**
  String get formerMember;

  /// No description provided for @sysJoined.
  ///
  /// In en, this message translates to:
  /// **'{name} joined the group'**
  String sysJoined(String name);

  /// No description provided for @sysJuzDone.
  ///
  /// In en, this message translates to:
  /// **'{name} finished juz\' {juz}'**
  String sysJuzDone(String name, int juz);

  /// No description provided for @sysKhatmaDone.
  ///
  /// In en, this message translates to:
  /// **'Khatma {n} is complete. Allahumma taqabbal!'**
  String sysKhatmaDone(int n);

  /// No description provided for @cheerBarakallah.
  ///
  /// In en, this message translates to:
  /// **'Barakallahu feek'**
  String get cheerBarakallah;

  /// No description provided for @cheerMashallah.
  ///
  /// In en, this message translates to:
  /// **'Masha\'Allah!'**
  String get cheerMashallah;

  /// No description provided for @cheerKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going, you\'re almost there'**
  String get cheerKeepGoing;

  /// No description provided for @cheerDua.
  ///
  /// In en, this message translates to:
  /// **'I made dua for you'**
  String get cheerDua;

  /// No description provided for @cheerJazakallah.
  ///
  /// In en, this message translates to:
  /// **'Jazakallahu khayran'**
  String get cheerJazakallah;

  /// No description provided for @cheerTogether.
  ///
  /// In en, this message translates to:
  /// **'Let\'s finish it together'**
  String get cheerTogether;

  /// No description provided for @leaderKhatma.
  ///
  /// In en, this message translates to:
  /// **'This khatma'**
  String get leaderKhatma;

  /// No description provided for @leaderWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get leaderWeek;

  /// No description provided for @leaderKhatmaLine.
  ///
  /// In en, this message translates to:
  /// **'{round} juz\' this khatma · {total} in total'**
  String leaderKhatmaLine(int round, int total);

  /// No description provided for @leaderWeekLine.
  ///
  /// In en, this message translates to:
  /// **'{ayahs} ayahs in 7 days · {streak}-day streak'**
  String leaderWeekLine(int ayahs, int streak);

  /// No description provided for @leaderboardNote.
  ///
  /// In en, this message translates to:
  /// **'Only members of this group see this. Compete in good deeds, and keep your intention for Allah.'**
  String get leaderboardNote;

  /// No description provided for @removeFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove from group'**
  String get removeFromGroup;

  /// No description provided for @communityRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Group rules'**
  String get communityRulesTitle;

  /// No description provided for @communityRule1.
  ///
  /// In en, this message translates to:
  /// **'Speak kindly. No insults, swearing, hate, or sexual content. There is zero tolerance for abuse.'**
  String get communityRule1;

  /// No description provided for @communityRule2.
  ///
  /// In en, this message translates to:
  /// **'No links, phone numbers or accounts from other apps, to keep everyone (especially children) safe.'**
  String get communityRule2;

  /// No description provided for @communityRule3.
  ///
  /// In en, this message translates to:
  /// **'You can report any message or member and block anyone. We review reports within 24 hours.'**
  String get communityRule3;

  /// No description provided for @communityRule4.
  ///
  /// In en, this message translates to:
  /// **'Content that breaks these rules is removed, and whoever posts it is banned from groups.'**
  String get communityRule4;

  /// No description provided for @communityAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree'**
  String get communityAgree;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @reportWhy.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this?'**
  String get reportWhy;

  /// No description provided for @reportOffensive.
  ///
  /// In en, this message translates to:
  /// **'Offensive or abusive'**
  String get reportOffensive;

  /// No description provided for @reportHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or bullying'**
  String get reportHarassment;

  /// No description provided for @reportSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportSpam;

  /// No description provided for @reportInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get reportInappropriate;

  /// No description provided for @reportOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportOther;

  /// No description provided for @reportThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks, we\'ll review it'**
  String get reportThanks;

  /// No description provided for @reportAlsoBlock.
  ///
  /// In en, this message translates to:
  /// **'Do you also want to block {name}? You won\'t see anything they write.'**
  String reportAlsoBlock(String name);

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @blockName.
  ///
  /// In en, this message translates to:
  /// **'Block {name}'**
  String blockName(String name);

  /// No description provided for @blockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String blockTitle(String name);

  /// No description provided for @blockBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see their messages in any group. They won\'t be told.'**
  String get blockBody;

  /// No description provided for @blockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked people'**
  String get blockedUsers;

  /// No description provided for @blockedUsersEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t blocked anyone.'**
  String get blockedUsersEmpty;

  /// No description provided for @communityErrOffensive.
  ///
  /// In en, this message translates to:
  /// **'This contains words that aren\'t allowed. Please rephrase it kindly.'**
  String get communityErrOffensive;

  /// No description provided for @communityErrContact.
  ///
  /// In en, this message translates to:
  /// **'Links, phone numbers and accounts aren\'t allowed in groups.'**
  String get communityErrContact;

  /// No description provided for @communityErrTooLong.
  ///
  /// In en, this message translates to:
  /// **'That\'s too long.'**
  String get communityErrTooLong;

  /// No description provided for @communityErrEmpty.
  ///
  /// In en, this message translates to:
  /// **'Write something first.'**
  String get communityErrEmpty;

  /// No description provided for @communityErrSlowDown.
  ///
  /// In en, this message translates to:
  /// **'You\'re sending messages too fast. Wait a moment.'**
  String get communityErrSlowDown;

  /// No description provided for @communityErrInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That code doesn\'t match a group.'**
  String get communityErrInvalidCode;

  /// No description provided for @communityErrGroupFull.
  ///
  /// In en, this message translates to:
  /// **'This group is full.'**
  String get communityErrGroupFull;

  /// No description provided for @communityErrTooManyGroups.
  ///
  /// In en, this message translates to:
  /// **'You\'re in the maximum number of groups.'**
  String get communityErrTooManyGroups;

  /// No description provided for @communityErrJuzTaken.
  ///
  /// In en, this message translates to:
  /// **'Someone else has this juz\'.'**
  String get communityErrJuzTaken;

  /// No description provided for @communityErrBanned.
  ///
  /// In en, this message translates to:
  /// **'Your access to groups has been suspended for breaking the rules.'**
  String get communityErrBanned;

  /// No description provided for @communityErrNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only the group admin can do that.'**
  String get communityErrNotAllowed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
