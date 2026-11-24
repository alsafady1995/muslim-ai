import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics.dart';
import '../../core/notifications.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

/// 3 steps: language -> daily goal -> reminders. The user starts as a guest
/// (anonymous Supabase user) so they reach value in under a minute; they can
/// save progress by linking Apple / Google / email later.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  int _dailyAyahs = 5;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Analytics.track(Events.onboardingStarted);
  }

  void _next() {
    Analytics.track(Events.onboardingStepCompleted, {'step': _step});
    setState(() => _step++);
  }

  Future<void> _finish({required bool reminders}) async {
    setState(() => _busy = true);
    final l10n = context.l10n;
    try {
      final locale = ref.read(localeProvider);
      final db = ref.read(supabaseProvider);
      await db.auth.signInAnonymously(data: {'locale': locale.languageCode, 'timezone': DateTime.now().timeZoneName});
      await ref.read(userRepoProvider).setGoal('quran_read', _dailyAyahs, true);
      await ref.read(userRepoProvider).updateProfile({'onboarding_completed': true});
      if (reminders) {
        final granted = await Reminders.requestPermission();
        Analytics.track(Events.notificationPermissionResult, {'granted': granted});
        if (granted) {
          await Reminders.scheduleDaily(Reminders.morningAdhkar, l10n.reminderMorningTitle, l10n.reminderMorningBody, 6, 30);
          await Reminders.scheduleDaily(Reminders.eveningAdhkar, l10n.reminderEveningTitle, l10n.reminderEveningBody, 17, 30);
          await Reminders.scheduleDaily(Reminders.streakSaver, l10n.reminderStreakTitle, l10n.reminderStreakBody, 21, 0);
        }
      }
      Analytics.track(Events.onboardingCompleted, {'daily_ayahs': _dailyAyahs, 'reminders': reminders});
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.errorGeneric)));
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final pages = [
      // 1. Welcome + language
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
      ]),
      // 2. Daily goal
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Spacer(),
        Text(l10n.pickDailyGoal, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        for (final (n, label) in [(3, l10n.goalCasual), (5, l10n.goalRegular), (10, l10n.goalSerious), (20, l10n.goalIntense)])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ChoiceChip(
              label: SizedBox(width: double.infinity, child: Text('$label · ${l10n.ayahsPerDay(n)}')),
              selected: _dailyAyahs == n,
              onSelected: (_) => setState(() => _dailyAyahs = n),
            ),
          ),
        const Spacer(),
        // Web has no local notifications, so the reminders step is skipped there.
        FilledButton(
          onPressed: _busy ? null : (kIsWeb ? () => _finish(reminders: false) : _next),
          child: Text(l10n.continueLabel),
        ),
      ]),
      // 3. Reminders
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Spacer(),
        Icon(Icons.notifications_active_outlined, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(l10n.remindersTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(l10n.remindersBody, textAlign: TextAlign.center),
        const Spacer(),
        FilledButton(onPressed: _busy ? null : () => _finish(reminders: true), child: Text(l10n.enableReminders)),
        TextButton(onPressed: _busy ? null : () => _finish(reminders: false), child: Text(l10n.notNow)),
      ]),
    ];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            LinearProgressIndicator(value: (_step + 1) / pages.length, borderRadius: BorderRadius.circular(8)),
            Expanded(child: _busy ? const LoadingView() : pages[_step]),
          ]),
        ),
      ),
    );
  }
}
