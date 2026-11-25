import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_ai/core/ai_budget.dart';
import 'package:muslim_ai/core/api.dart';
import 'package:muslim_ai/core/monetization.dart';
import 'package:muslim_ai/data/models.dart';
import 'package:muslim_ai/demo/demo_store.dart';
import 'package:muslim_ai/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PaywallGate', () {
    late SharedPreferences prefs;
    late DateTime now;
    PaywallGate gate() => PaywallGate(prefs, clock: () => now);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      now = DateTime(2026, 11, 24, 10);
      PaywallGate.resetSession();
    });

    test('no automatic offer before 3 days of real value', () {
      expect(gate().canAutoShow(valueDays: 0, premium: false), isFalse);
      expect(gate().canAutoShow(valueDays: 2, premium: false), isFalse);
      expect(gate().canAutoShow(valueDays: 3, premium: false), isTrue);
    });

    test('never for premium users', () {
      expect(gate().canAutoShow(valueDays: 10, premium: true), isFalse);
    });

    test('once per session and once per day', () async {
      await gate().recordShown();
      expect(gate().canAutoShow(valueDays: 5, premium: false), isFalse, reason: 'same session');
      PaywallGate.resetSession();
      now = now.add(const Duration(hours: 5));
      expect(gate().canAutoShow(valueDays: 5, premium: false), isFalse, reason: 'same day');
      now = now.add(const Duration(hours: 20));
      expect(gate().canAutoShow(valueDays: 5, premium: false), isTrue);
    });

    test('at most 3 a week', () async {
      for (var i = 0; i < 3; i++) {
        PaywallGate.resetSession();
        await gate().recordShown();
        now = now.add(const Duration(days: 1, hours: 1));
      }
      PaywallGate.resetSession();
      expect(gate().canAutoShow(valueDays: 5, premium: false), isFalse);
      now = now.add(const Duration(days: 5));
      expect(gate().canAutoShow(valueDays: 5, premium: false), isTrue);
    });

    test('two dismissals in a row snooze offers for 7 days', () async {
      await gate().recordDismissed();
      expect(gate().canAutoShow(valueDays: 5, premium: false), isTrue);
      await gate().recordDismissed();
      expect(gate().canAutoShow(valueDays: 5, premium: false), isFalse);
      now = now.add(const Duration(days: 6));
      expect(gate().canAutoShow(valueDays: 5, premium: false), isFalse);
      now = now.add(const Duration(days: 2));
      expect(gate().canAutoShow(valueDays: 5, premium: false), isTrue);
    });

    test('engaging resets the dismissal streak', () async {
      await gate().recordDismissed();
      await gate().recordEngaged();
      await gate().recordDismissed();
      expect(gate().canAutoShow(valueDays: 5, premium: false), isTrue);
    });

    test('once-only offers', () async {
      expect(gate().usedOnce('milestone'), isFalse);
      await gate().markOnce('milestone');
      expect(gate().usedOnce('milestone'), isTrue);
    });
  });

  group('nextBestAction', () {
    NextAction act({
      int due = 0,
      bool plan = false,
      int fresh = 0,
      int recited = 0,
      int reviewed = 0,
      String intent = 'memorize',
    }) => nextBestAction(
      hifzDue: due,
      hasPlan: plan,
      newAvailable: fresh,
      recitationsToday: recited,
      reviewsToday: reviewed,
      intent: intent,
    );

    test('due reviews come first', () => expect(act(due: 4, plan: true, fresh: 3), NextAction.review));
    test('then new ayahs', () => expect(act(plan: true, fresh: 3), NextAction.learnNew));
    test('done after today\'s review', () => expect(act(plan: true, reviewed: 5), NextAction.done));
    test('memorizers without a plan are asked to start one', () => expect(act(), NextAction.startPlan));
    test('reciters are asked to recite', () => expect(act(intent: 'recite'), NextAction.recite));
    test('readers are sent to read', () => expect(act(intent: 'read'), NextAction.read));
    test('after reciting today, read', () => expect(act(intent: 'recite', recited: 1), NextAction.read));
  });

  group('nextSurahToMemorize', () {
    test('Al-Fatiha first', () => expect(nextSurahToMemorize({}), 1));
    test('then An-Nas backwards', () {
      expect(nextSurahToMemorize({1}), 114);
      expect(nextSurahToMemorize({1, 114, 113, 112}), 111);
    });
    test('Al-Mulk after Juz Amma, then nothing', () {
      expect(nextSurahToMemorize({1, ...juzAmmaOrder}), 67);
      expect(nextSurahToMemorize({1, ...juzAmmaOrder, 67}), isNull);
    });
    test('every chip is a valid surah', () {
      expect(knownSurahChoices.every((s) => s >= 1 && s <= 114), isTrue);
      expect(knownSurahChoices.toSet().length, knownSurahChoices.length);
    });
  });

  group('weeks start on Friday (same as the server)', () {
    test(
      'Friday is its own week start',
      () => expect(DemoStore.weekStart(DateTime(2026, 11, 20, 13)), DateTime(2026, 11, 20)),
    );
    test(
      'Tuesday belongs to the previous Friday',
      () => expect(DemoStore.weekStart(DateTime(2026, 11, 24)), DateTime(2026, 11, 20)),
    );
    test(
      'Thursday is the last day',
      () => expect(DemoStore.weekStart(DateTime(2026, 11, 26, 23)), DateTime(2026, 11, 20)),
    );
  });

  group('models', () {
    test('WeeklyQuota', () {
      final q = WeeklyQuota({
        'premium': false,
        'resets_at': '2026-11-27T00:00:00+03:00',
        'clip_seconds': 60,
        'onboarding_check_available': true,
        'features': {
          'recitation': {'limit': 10, 'used': 4},
          'hifz': {'limit': 5, 'used': 7},
        },
      });
      expect(q.remaining('recitation'), 6);
      expect(q.remaining('hifz'), 0, reason: 'never negative');
      expect(q.remaining('ask'), 0);
      expect(q.clipSeconds, 60);
      expect(q.onboardingCheckAvailable, isTrue);
      expect(q.resetsAt!.toUtc(), DateTime.utc(2026, 11, 26, 21));
    });

    test('Dashboard subscription state', () {
      final d = Dashboard({
        'profile': {},
        'premium': true,
        'value_days': 4,
        'days_since_signup': 9,
        'hifz_has_plan': true,
        'subscription': {'status': 'active', 'period_type': 'trial', 'current_period_end': '2026-12-01T00:00:00Z'},
      });
      expect(d.inTrial, isTrue);
      expect(d.billingProblem, isFalse);
      expect(d.valueDays, 4);
      expect(d.hifzHasPlan, isTrue);
      expect(d.periodEnd, isNotNull);
      expect(
        Dashboard({
          'profile': {},
          'subscription': {'status': 'billing_issue'},
        }).billingProblem,
        isTrue,
      );
    });

    test('RecitationResult milestone and hifz updates', () {
      final r = RecitationResult({
        'scores': {'overall': 92},
        'hifz': [
          {'item_id': 7, 'status': 'review'},
        ],
        'milestone': {'surah_id': 114, 'name_ar': 'الناس', 'transliteration': 'An-Nas', 'xp': 100, 'first': true},
        'clipped': true,
      });
      expect(r.hifzUpdates.single['item_id'], 7);
      expect(r.milestone!.surahId, 114);
      expect(r.milestone!.first, isTrue);
      expect(r.clipped, isTrue);
    });

    test('WeakWords', () {
      final w = WeakWords({
        'premium': false,
        'total': 5,
        'locked': 2,
        'words': [
          {'ayah_id': 1, 'surah_id': 1, 'ayah_number': 1, 'word': 'بِسْمِ', 'misses': 3},
        ],
      });
      expect(w.locked, 2);
      expect(w.words.single.misses, 3);
    });
  });

  Future<void> openSheet(WidgetTester tester, bool allowUpgrade, {bool budget = false, String tier = 'free'}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => budget
                  ? showAiBudgetExhausted(
                      context,
                      AiBudgetExhausted('recitation', premium: false, tier: tier, resetsAt: DateTime(2026, 12, 1)),
                      allowUpgrade: allowUpgrade,
                    )
                  : showLimitSheet(
                      context,
                      QuotaExceeded('ask', premium: false, limit: 15, resetsAt: DateTime(2026, 11, 27)),
                      allowUpgrade: allowUpgrade,
                    ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('limit sheet: renewal day and two equal choices', (tester) async {
    await openSheet(tester, true);
    expect(find.textContaining('Friday'), findsWidgets);
    expect(find.byType(OutlinedButton), findsNWidgets(2));
  });

  testWidgets('limit sheet: no upgrade button in sensitive moments', (tester) async {
    await openSheet(tester, false);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('AI budget sheet: free users are offered Premium', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532); // phone
    addTearDown(tester.view.reset);
    await openSheet(tester, true, budget: true);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('AI budget sheet: guests are asked to create a free account, not to pay', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    addTearDown(tester.view.reset);
    await openSheet(tester, true, budget: true, tier: 'guest');
    expect(find.text('Create a free account to continue'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Create a free account'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('AI budget sheet: a busy free pool never sells Premium', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    addTearDown(tester.view.reset);
    await openSheet(tester, true, budget: true, tier: 'busy');
    expect(find.text('Free AI features are busy today'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('AI budget sheet: no Premium offer during onboarding', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    addTearDown(tester.view.reset);
    await openSheet(tester, false, budget: true);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });
}
