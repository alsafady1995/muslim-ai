import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics.dart';
import '../../core/monetization.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../groups/call_widgets.dart';
import '../groups/groups_common.dart';
import '../hifz/hifz_review_screen.dart';
import '../hifz/hifz_screen.dart' show hifzQueueProvider, hifzStatsProvider;

final weeklySummaryProvider = FutureProvider.autoDispose<WeeklySummary>((ref) {
  ref.watch(dashboardProvider);
  return ref.watch(userRepoProvider).weeklySummary();
});

/// Home answers one question first: "what should I do today?" (docs/full-audit.md, UX).
/// Then streak and goals, the week in review, and a short list of other things to do.
/// Premium is only promoted after the user has had real value on 3 different days.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static bool _tzSynced = false;

  @override
  void initState() {
    super.initState();
    _syncTimezone();
  }

  /// Older builds sent "AST"/"+03" as the timezone; travellers move. Keep the IANA name current.
  Future<void> _syncTimezone() async {
    if (_tzSynced || kIsWeb) return;
    _tzSynced = true;
    try {
      final tz = (await FlutterTimezone.getLocalTimezone()).identifier;
      final prefs = ref.read(sharedPrefsProvider);
      if (prefs.getString('tz_synced') == tz) return;
      await ref.read(userRepoProvider).updateProfile({'timezone': tz});
      await prefs.setString('tz_synced', tz);
    } catch (_) {
      _tzSynced = false; // try again next time Home opens
    }
  }

  @override
  Widget build(BuildContext context) {
    final dash = ref.watch(dashboardProvider);
    final user = ref.watch(currentUserProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => context.push('/search'))],
      ),
      body: dash.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(dashboardProvider)),
        data: (d) {
          final gate = ref.read(paywallGateProvider);
          final valueGate = gate.valueGatePassed(d.valueDays);
          if (valueGate && !gate.usedOnce('value_gate_tracked')) {
            gate.markOnce('value_gate_tracked');
            Analytics.track(Events.valueGatePassed, {'days_since_signup': d.daysSinceSignup});
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardProvider);
              ref.invalidate(pendingCallsProvider);
              ref.invalidate(hifzQueueProvider);
            },
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
              if (d.billingProblem) ...[_BillingCard(), const SizedBox(height: 12)],
              if (d.inTrial && d.periodEnd != null) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.trialEnds(DateFormat.MMMd(Localizations.localeOf(context).languageCode).format(d.periodEnd!))),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const _PendingCalls(),
              _TodayCard(d: d),
              const SizedBox(height: 12),
              _StreakCard(d: d),
              const SizedBox(height: 12),
              _GoalsCard(d: d),
              if (d.daysSinceSignup >= 6) ...[
                SectionTitle(l10n.weekTitle),
                _WeekSummaryCard(d: d, offer: valueGate && !d.premium),
              ],
              SectionTitle(l10n.prayersToday),
              _PrayerRow(d: d),
              SectionTitle(l10n.continueJourney),
              _QuickActions(d: d),
              if (user?.isAnonymous == true) ...[
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.cloud_upload_outlined),
                    title: Text(l10n.saveProgress),
                    subtitle: Text(l10n.saveProgressHint),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/sign-in?link=1'),
                  ),
                ),
              ],
              if (!d.premium && valueGate) ...[
                const SizedBox(height: 12),
                Card(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  child: ListTile(
                    leading: const Icon(Icons.workspace_premium, color: AppColors.gold),
                    title: Text(l10n.goPremium),
                    subtitle: Text(l10n.premiumPitchShort),
                    onTap: () => context.push('/paywall?source=home_banner'),
                  ),
                ),
              ],
              SectionTitle(l10n.last7Days),
              _WeekChart(history: d.history),
            ]),
          );
        },
      ),
    );
  }
}

class _BillingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final url = defaultTargetPlatform == TargetPlatform.iOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions';
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.credit_card_off_outlined),
        title: Text(l10n.billingIssue),
        trailing: TextButton(onPressed: () => launchUrl(Uri.parse(url)), child: Text(l10n.update)),
      ),
    );
  }
}

/// The one thing to do today, picked by [nextBestAction].
class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.d});
  final Dashboard d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final queue = ref.watch(hifzQueueProvider).value;
    final reviews = queue?.reviews.length ?? d.hifzDue;
    final fresh = queue?.fresh.length ?? 0;
    final action = nextBestAction(
      hifzDue: reviews,
      hasPlan: d.hifzHasPlan,
      newAvailable: fresh,
      recitationsToday: (d.today['recitations'] as num?)?.toInt() ?? 0,
      reviewsToday: (d.today['reviews_done'] as num?)?.toInt() ?? 0,
      intent: userIntent(ref),
    );
    final minutes = ((reviews * 0.5) + (fresh * 1.5)).ceil().clamp(1, 120);
    final (IconData icon, String title, String body, String? cta, String? path) = switch (action) {
      NextAction.review => (Icons.psychology, l10n.todayReviewTitle, l10n.todayReviewBody(reviews + fresh, minutes), l10n.startLabel, '/learn'),
      NextAction.learnNew => (Icons.add_task, l10n.todayNewTitle, l10n.todayReviewBody(fresh, minutes), l10n.startLabel, '/learn'),
      NextAction.startPlan => (Icons.flag_outlined, l10n.startHifzPlan, l10n.startHifzPlanBody, l10n.startLabel, '/learn'),
      NextAction.recite => (Icons.mic, l10n.todayReciteTitle, l10n.todayReciteBody, l10n.startLabel, '/coach?source=home'),
      NextAction.read => (
          Icons.menu_book,
          l10n.continueReading,
          d.lastAyahId == null ? l10n.startWithFatihah : l10n.pickUpWhereLeft,
          l10n.startLabel,
          '/quran'
        ),
      NextAction.done => (Icons.check_circle, l10n.todayDoneTitle, l10n.todayDoneBody, null, null),
    };
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(icon, size: 40, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(body),
              if (action == NextAction.review && d.hifzAtRisk > 0) ...[
                const SizedBox(height: 4),
                Text(l10n.weekAtRisk(d.hifzAtRisk), style: theme.textTheme.bodySmall),
              ],
            ]),
          ),
          if (cta != null && path != null)
            FilledButton(
              // The theme makes filled buttons full width; inside this Row that is an infinite width.
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () async {
                // Straight into the session: one tap from Home to the first card.
                if ((action == NextAction.review || action == NextAction.learnNew) && queue != null && !queue.isEmpty) {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => HifzReviewScreen(queue: queue)));
                  ref.invalidate(hifzQueueProvider);
                  ref.invalidate(hifzStatsProvider);
                  ref.invalidate(dashboardProvider);
                } else if (context.mounted) {
                  path.startsWith('/coach') ? context.push(path) : context.go(path);
                }
              },
              child: Text(cta),
            ),
        ]),
      ),
    );
  }
}

class _WeekSummaryCard extends ConsumerStatefulWidget {
  const _WeekSummaryCard({required this.d, required this.offer});
  final Dashboard d;
  final bool offer;
  @override
  ConsumerState<_WeekSummaryCard> createState() => _WeekSummaryCardState();
}

class _WeekSummaryCardState extends ConsumerState<_WeekSummaryCard> {
  bool _tracked = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final summary = ref.watch(weeklySummaryProvider);
    return summary.when(
      loading: () => const SizedBox(height: 80, child: LoadingView()),
      error: (_, _) => const SizedBox.shrink(),
      data: (w) {
        if (!_tracked) {
          _tracked = true;
          Analytics.track(Events.weeklySummaryViewed, {'active_days': w.activeDays, 'at_risk': w.atRisk});
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.weekStats(w.activeDays, w.reviewsDone, w.ayahsRead), style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (w.hifzMemorized > 0)
                Text(w.atRisk > 0 ? l10n.weekAtRisk(w.atRisk) : l10n.weekAllSafe),
              if (w.atRisk > 0 && widget.offer) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text(l10n.weekAtRiskOffer, style: theme.textTheme.bodySmall)),
                  TextButton(
                    onPressed: () => context.push('/paywall?source=weekly_summary'),
                    child: Text(l10n.tryPremiumFree),
                  ),
                ]),
              ],
            ]),
          ),
        );
      },
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.d});
  final Dashboard d;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final span = (d.nextLevelXp - d.levelStartXp).clamp(1, 1 << 30);
    final progress = (d.xp - d.levelStartXp) / span;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Column(children: [
            Icon(Icons.local_fire_department, size: 44, color: d.activeToday ? AppColors.flame : theme.disabledColor),
            Text('${d.streak}', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            Text(l10n.dayStreak, style: theme.textTheme.labelSmall),
          ]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.levelN(d.level), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: progress.clamp(0, 1).toDouble(), minHeight: 10, borderRadius: BorderRadius.circular(8)),
              const SizedBox(height: 6),
              Text(l10n.xpToNext(d.xp, d.nextLevelXp), style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.ac_unit, size: 16, color: Colors.lightBlue),
                const SizedBox(width: 4),
                Text(l10n.streakFreezes(d.streakFreezes), style: theme.textTheme.bodySmall),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.d});
  final Dashboard d;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final goals = d.goals;
    final labels = {
      'quran_read': (l10n.goalQuran, Icons.menu_book),
      'memorize': (l10n.goalMemorize, Icons.psychology),
      'adhkar': (l10n.goalAdhkar, Icons.nights_stay),
      'prayer': (l10n.goalPrayer, Icons.mosque),
      'listen': (l10n.goalListen, Icons.headphones),
    };
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/goals'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.todaysGoals, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(spacing: 16, runSpacing: 12, children: [
              for (final e in goals.entries)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  ProgressRing(
                    value: e.value.$1 / e.value.$2,
                    color: e.value.$1 >= e.value.$2 ? AppColors.success : null,
                    child: Icon(labels[e.key]?.$2 ?? Icons.flag, size: 22),
                  ),
                  const SizedBox(height: 4),
                  Text('${labels[e.key]?.$1 ?? e.key}\n${e.value.$1}/${e.value.$2}',
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
                ]),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _PrayerRow extends ConsumerWidget {
  const _PrayerRow({required this.d});
  final Dashboard d;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final names = {
      'fajr': l10n.fajr,
      'dhuhr': l10n.dhuhr,
      'asr': l10n.asr,
      'maghrib': l10n.maghrib,
      'isha': l10n.isha,
    };
    return Wrap(spacing: 8, children: [
      for (final p in names.entries)
        FilterChip(
          label: Text(p.value),
          selected: d.prayersToday.contains(p.key),
          onSelected: d.prayersToday.contains(p.key)
              ? null
              : (_) async {
                  final r = await ref.read(userRepoProvider).logPrayer(p.key);
                  Analytics.track(Events.prayerLogged, {'prayer': p.key});
                  if (context.mounted) showXpToast(context, r.xpAwarded, achievements: r.newAchievements);
                  ref.invalidate(dashboardProvider);
                },
        ),
    ]);
  }
}

/// Everything that is not today's main step. Recitation and hifz live in the Today card.
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.d});
  final Dashboard d;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hour = DateTime.now().hour;
    final adhkarId = hour < 12 ? 1 : (hour < 20 ? 2 : 3);
    final items = <(IconData, String, String, String)>[
      (Icons.menu_book, l10n.continueReading, d.lastAyahId == null ? l10n.startWithFatihah : l10n.pickUpWhereLeft, '/quran'),
      (Icons.nights_stay, l10n.adhkar, adhkarId == 1 ? l10n.morningAdhkar : (adhkarId == 2 ? l10n.eveningAdhkar : l10n.sleepAdhkar), '/adhkar/$adhkarId'),
      (Icons.mic, l10n.reciteWithAi, l10n.aiCoachHint, '/coach?source=home_grid'),
      (Icons.auto_awesome, l10n.askTheQuran, l10n.askHint, '/ask'),
      (Icons.diversity_3_outlined, l10n.groupsTitle, l10n.groupsHint, '/groups'),
      (Icons.explore_outlined, l10n.qiblaTitle, l10n.qiblaHint, '/qibla'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        for (final (icon, title, sub, path) in items)
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => path.startsWith('/quran') || path == '/ask' ? context.go(path) : context.push(path),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const Spacer(),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(sub, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ),
          ),
      ],
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.history});
  final List<Map<String, dynamic>> history;
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final byDate = {for (final h in history) '${h['date']}': h};
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final values = days.map((d) => ((byDate[d.toIso8601String().substring(0, 10)]?['xp'] as num?) ?? 0).toDouble()).toList();
    final max = values.fold<double>(10, (a, b) => b > a ? b : a);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 120,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text(values[i].toInt().toString(), style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Container(
                    height: 70 * values[i] / max + 2,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: i == 6 ? scheme.primary : scheme.primary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(MaterialLocalizations.of(context).narrowWeekdays[days[i].weekday % 7],
                      style: Theme.of(context).textTheme.labelSmall),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Calls from my groups that I haven't answered yet (newest 3). Hidden when there are none.
class _PendingCalls extends ConsumerWidget {
  const _PendingCalls();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calls = ref.watch(pendingCallsProvider).value ?? const [];
    if (calls.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(context.l10n.pendingCallsTitle, trailing: TextButton(
        onPressed: () => context.push('/groups'),
        child: Text(context.l10n.groupsTitle),
      )),
      for (final c in calls.take(3)) CallCard(call: c, showGroup: true),
      const SizedBox(height: 12),
    ]);
  }
}
