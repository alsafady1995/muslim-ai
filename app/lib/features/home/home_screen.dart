import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        data: (d) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
            _StreakCard(d: d),
            const SizedBox(height: 12),
            _GoalsCard(d: d),
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
            if (!d.premium) ...[
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
        ),
      ),
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
      (Icons.psychology, l10n.hifzReview, l10n.dueCount(d.hifzDue), '/learn'),
      (Icons.mic, l10n.reciteWithAi, l10n.aiCoachHint, '/coach'),
      (Icons.nights_stay, l10n.adhkar, adhkarId == 1 ? l10n.morningAdhkar : (adhkarId == 2 ? l10n.eveningAdhkar : l10n.sleepAdhkar), '/adhkar/$adhkarId'),
      (Icons.auto_awesome, l10n.askTheQuran, l10n.askHint, '/ask'),
      (Icons.manage_search, l10n.searchQuran, l10n.searchHint, '/search'),
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
              onTap: () => path.startsWith('/quran') || path == '/learn' || path == '/ask' ? context.go(path) : context.push(path),
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
