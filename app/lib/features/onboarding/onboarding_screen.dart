import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics.dart';
import '../../core/monetization.dart';
import '../../core/notifications.dart';
import '../../core/providers.dart';
import '../../core/router.dart' show onboardingInProgressKey;
import '../../core/widgets.dart';
import '../../data/models.dart';

/// Value first, no ask for money (docs/subscription-growth-audit.md §9):
///   1. promise + language   2. intent   3. surahs already known (memorize / recite)
///   4. first recitation: Al-Fatiha, word by word (free, not counted)
///   5. plan reveal (hifz plan created, known surahs seeded for review tomorrow)
///   6. one contextual reminder, asked after the value (mobile only)
/// The guest account is created after the intent step so the Al-Fatiha check can run.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Step { welcome, intent, known, recite, plan, reminders }

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _index = 0;
  bool _busy = false;
  String _intent = 'memorize';
  final Set<int> _known = {};
  int _dailyNew = 3;
  int _dailyAyahs = 5;
  TimeOfDay _remindAt = const TimeOfDay(hour: 20, minute: 0);
  bool _adhkarToo = true;
  RecitationResult? _firstResult;
  bool _planApplied = false;

  bool get _hifzIntent => _intent == 'memorize' || _intent == 'recite';

  List<_Step> get _steps => [
        _Step.welcome,
        _Step.intent,
        if (_hifzIntent) _Step.known,
        _Step.recite,
        _Step.plan,
        if (!kIsWeb) _Step.reminders, // no local notifications on web
      ];

  _Step get _step => _steps[_index.clamp(0, _steps.length - 1)];

  @override
  void initState() {
    super.initState();
    Analytics.track(Events.onboardingStarted);
    // Resume after the app was closed mid-onboarding (guest already created). Restore the
    // intent picked before the restart, otherwise a "read" user resumes on the memorize steps.
    if (ref.read(supabaseProvider).auth.currentUser != null) {
      final prefs = ref.read(sharedPrefsProvider);
      _intent = prefs.getString('intent') ?? _intent;
      _planApplied = prefs.getBool(_planAppliedKey) ?? false;
      _index = 2;
    }
  }

  /// Survives an app restart so the plan is not created twice when onboarding resumes.
  static const _planAppliedKey = 'onboarding_plan_applied';

  void _next() {
    Analytics.track(Events.onboardingStepCompleted, {'step': _step.name, 'intent': _intent});
    setState(() => _index = (_index + 1).clamp(0, _steps.length - 1));
  }

  Future<void> _guard(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.errorGeneric)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// IANA zone ("Asia/Riyadh"). DateTime.timeZoneName gives "AST"/"+03", which the server
  /// would misread; the server also rejects anything that is not an IANA name.
  Future<String> _timezone() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      return 'Asia/Riyadh';
    }
  }

  Future<void> _ensureGuest() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(onboardingInProgressKey, true); // before sign-in, so the router keeps us here
    await prefs.setString('intent', _intent);
    final db = ref.read(supabaseProvider);
    if (db.auth.currentUser != null) return;
    final locale = ref.read(localeProvider);
    await db.auth.signInAnonymously(data: {'locale': locale.languageCode, 'timezone': await _timezone()});
  }

  Future<void> _recite() async {
    final r = await context.push<RecitationResult>('/coach?from=1&to=7&source=onboarding');
    if (!mounted || r == null) return;
    setState(() => _firstResult = r);
    Analytics.track(Events.recitationResultViewed, {'overall': r.overall, 'source': 'onboarding'});
  }

  Future<void> _applyPlan() async {
    if (_planApplied) return;
    final l10n = context.l10n;
    final arabic = context.isArabic;
    final users = ref.read(userRepoProvider);
    final quran = ref.read(quranRepoProvider);
    if (_hifzIntent && _known.isNotEmpty) await users.seedKnownSurahs(_known.toList()..sort(), l10n.knownSurahsPlan);
    if (_intent == 'memorize') {
      final next = nextSurahToMemorize(_known);
      if (next != null) {
        final surah = await quran.surah(next);
        await users.createHifzPlan(await quran.ayahId(next, 1), await quran.ayahId(next, surah.ayahCount), _dailyNew,
            arabic ? surah.nameAr : surah.transliteration);
        await users.setGoal('memorize', _dailyNew, true);
        Analytics.track(Events.hifzPlanCreated, {'surah': next, 'daily_new': _dailyNew, 'source': 'onboarding'});
      }
    } else {
      await users.setGoal('quran_read', _dailyAyahs, true);
    }
    _planApplied = true;
    await ref.read(sharedPrefsProvider).setBool(_planAppliedKey, true);
  }

  Future<void> _finish({required bool reminders}) async {
    final l10n = context.l10n;
    final prefs = ref.read(sharedPrefsProvider);
    if (reminders) {
      final granted = await Reminders.requestPermission();
      Analytics.track(Events.notificationPermissionResult, {'granted': granted, 'source': 'onboarding'});
      if (granted) {
        final hm = '${_remindAt.hour.toString().padLeft(2, '0')}:${_remindAt.minute.toString().padLeft(2, '0')}';
        if (_hifzIntent) {
          await Reminders.scheduleDaily(Reminders.hifzReview, l10n.reminderHifzTitle, l10n.reminderHifzBody, _remindAt.hour, _remindAt.minute);
          await prefs.setBool('reminder_hifz', true);
          await prefs.setString('reminder_hifz_time', hm);
        } else {
          await Reminders.scheduleDaily(Reminders.streakSaver, l10n.reminderReadTitle, l10n.reminderReadBody, _remindAt.hour, _remindAt.minute);
          await prefs.setBool('reminder_streak', true);
          await prefs.setString('reminder_streak_time', hm);
        }
        if (_adhkarToo) {
          await Reminders.scheduleDaily(Reminders.morningAdhkar, l10n.reminderMorningTitle, l10n.reminderMorningBody, 6, 30);
          await Reminders.scheduleDaily(Reminders.eveningAdhkar, l10n.reminderEveningTitle, l10n.reminderEveningBody, 17, 30);
          await prefs.setBool('reminder_morning', true);
          await prefs.setBool('reminder_evening', true);
        }
      }
    }
    await ref.read(userRepoProvider).updateProfile({'onboarding_completed': true});
    await prefs.remove(onboardingInProgressKey);
    await prefs.remove(_planAppliedKey);
    Analytics.track(Events.onboardingCompleted, {
      'intent': _intent,
      'known_surahs': _known.length,
      'recited': _firstResult != null,
      'reminders': reminders,
    });
    ref.invalidate(dashboardProvider);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final page = switch (_step) {
      _Step.welcome => _welcome(context),
      _Step.intent => _intentPage(context),
      _Step.known => _knownPage(context),
      _Step.recite => _recitePage(context),
      _Step.plan => _planPage(context),
      _Step.reminders => _remindersPage(context),
    };
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            LinearProgressIndicator(value: (_index + 1) / _steps.length, borderRadius: BorderRadius.circular(8)),
            Expanded(child: _busy ? const LoadingView() : page),
          ]),
        ),
      ),
    );
  }

  Widget _title(BuildContext context, String text) => Text(text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700));

  Widget _welcome(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Spacer(),
      Icon(Icons.auto_awesome, size: 72, color: theme.colorScheme.primary),
      const SizedBox(height: 24),
      Text(l10n.onboardingTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      Text(l10n.onboardingSubtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
      const Spacer(),
      SegmentedButton<String>(
        segments: const [ButtonSegment(value: 'ar', label: Text('العربية')), ButtonSegment(value: 'en', label: Text('English'))],
        selected: {locale.languageCode},
        onSelectionChanged: (s) => ref.read(localeProvider.notifier).set(Locale(s.first)),
      ),
      const SizedBox(height: 16),
      FilledButton(onPressed: _next, child: Text(l10n.getStarted)),
      TextButton(onPressed: () => context.push('/sign-in'), child: Text(l10n.haveAccount)),
    ]);
  }

  Widget _intentPage(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      ('memorize', Icons.psychology, l10n.intentMemorize),
      ('recite', Icons.mic, l10n.intentRecite),
      ('read', Icons.menu_book, l10n.intentRead),
      ('understand', Icons.lightbulb_outline, l10n.intentUnderstand),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Spacer(),
      _title(context, l10n.intentTitle),
      const SizedBox(height: 24),
      for (final (id, icon, label) in options)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: _intent == id ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
            ),
            child: ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: _intent == id ? const Icon(Icons.check_circle) : null,
              onTap: () => setState(() => _intent = id),
            ),
          ),
        ),
      const Spacer(),
      FilledButton(
        onPressed: () => _guard(() async {
          Analytics.track(Events.onboardingIntent, {'intent': _intent});
          await _ensureGuest();
          _next();
        }),
        child: Text(l10n.continueLabel),
      ),
    ]);
  }

  Widget _knownPage(BuildContext context) {
    final l10n = context.l10n;
    final surahs = {for (final s in ref.watch(surahsProvider).value ?? <Surah>[]) s.id: s};
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 16),
      _title(context, l10n.knownTitle),
      const SizedBox(height: 8),
      Text(l10n.knownBody, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Expanded(
        child: SingleChildScrollView(
          child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            FilterChip(
              label: Text(l10n.knownNone),
              selected: _known.isEmpty,
              onSelected: (_) => setState(_known.clear),
            ),
            for (final id in knownSurahChoices)
              FilterChip(
                label: Text(surahs[id] == null ? '$id' : (context.isArabic ? surahs[id]!.nameAr : surahs[id]!.transliteration)),
                selected: _known.contains(id),
                onSelected: (on) => setState(() => on ? _known.add(id) : _known.remove(id)),
              ),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      FilledButton(onPressed: _next, child: Text(l10n.continueLabel)),
    ]);
  }

  Widget _recitePage(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final r = _firstResult;
    final toPolish = r?.mistakes.where((m) => m['ayahId'] != null).length ?? 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Spacer(),
      Icon(r == null ? Icons.mic : Icons.check_circle, size: 72, color: theme.colorScheme.primary),
      const SizedBox(height: 16),
      _title(context, l10n.firstRecitationTitle),
      const SizedBox(height: 8),
      if (r == null)
        Text(l10n.firstRecitationBody, textAlign: TextAlign.center)
      else
        Text(toPolish == 0 ? l10n.firstResultPerfect(r.overall.round()) : l10n.firstResult(r.overall.round(), toPolish),
            textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
      const Spacer(),
      if (r == null) ...[
        FilledButton.icon(onPressed: _recite, icon: const Icon(Icons.mic), label: Text(l10n.reciteNow)),
        TextButton(onPressed: _next, child: Text(l10n.skip)),
      ] else
        FilledButton(onPressed: _next, child: Text(l10n.continueLabel)),
    ]);
  }

  Widget _planPage(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final surahs = {for (final s in ref.watch(surahsProvider).value ?? <Surah>[]) s.id: s};
    final next = _intent == 'memorize' ? nextSurahToMemorize(_known) : null;
    final nextName = next == null || surahs[next] == null
        ? null
        : (context.isArabic ? surahs[next]!.nameAr : surahs[next]!.transliteration);
    final lines = <String>[
      if (nextName != null) l10n.planMemorize(nextName),
      if (_hifzIntent && _known.isNotEmpty) l10n.planKnown(_known.length),
      if (!_hifzIntent || _intent == 'recite') l10n.planRead(_dailyAyahs),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Spacer(),
      Icon(Icons.event_available, size: 64, color: theme.colorScheme.primary),
      const SizedBox(height: 16),
      _title(context, l10n.planTitle),
      const SizedBox(height: 16),
      for (final line in lines)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Icon(Icons.check, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(line, style: theme.textTheme.titleMedium)),
          ]),
        ),
      const SizedBox(height: 8),
      if (_intent == 'memorize' && next != null) ...[
        Text(l10n.newAyahsPerDay(_dailyNew)),
        Slider(value: _dailyNew.toDouble(), min: 1, max: 10, divisions: 9, label: '$_dailyNew',
            onChanged: (v) => setState(() => _dailyNew = v.round())),
      ] else
        Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
          for (final (n, label) in [(3, l10n.goalCasual), (5, l10n.goalRegular), (10, l10n.goalSerious), (20, l10n.goalIntense)])
            ChoiceChip(label: Text('$label · ${l10n.ayahsPerDay(n)}'), selected: _dailyAyahs == n,
                onSelected: (_) => setState(() => _dailyAyahs = n)),
        ]),
      if (_hifzIntent && (_known.isNotEmpty || next != null)) ...[
        const SizedBox(height: 12),
        Text(l10n.planFirstReview, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
      ],
      const Spacer(),
      FilledButton(
        onPressed: () => _guard(() async {
          await _applyPlan();
          if (kIsWeb) {
            await _finish(reminders: false);
          } else {
            _next();
          }
        }),
        child: Text(l10n.continueLabel),
      ),
    ]);
  }

  Widget _remindersPage(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Spacer(),
      Icon(Icons.notifications_active_outlined, size: 64, color: theme.colorScheme.primary),
      const SizedBox(height: 16),
      _title(context, l10n.remindersTitle),
      const SizedBox(height: 8),
      Text(l10n.remindersBody, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      OutlinedButton.icon(
        icon: const Icon(Icons.schedule),
        label: Text(l10n.reminderAt(_remindAt.format(context))),
        onPressed: () async {
          final t = await showTimePicker(context: context, initialTime: _remindAt);
          if (t != null) setState(() => _remindAt = t);
        },
      ),
      CheckboxListTile(
        value: _adhkarToo,
        onChanged: (v) => setState(() => _adhkarToo = v ?? false),
        title: Text(l10n.alsoAdhkar),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      const Spacer(),
      FilledButton(onPressed: () => _guard(() => _finish(reminders: true)), child: Text(l10n.remindMe)),
      TextButton(onPressed: () => _guard(() => _finish(reminders: false)), child: Text(l10n.notNow)),
    ]);
  }
}
