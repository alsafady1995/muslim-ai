import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import 'hifz_review_screen.dart';

final hifzQueueProvider = FutureProvider.autoDispose<HifzQueue>((ref) => ref.watch(userRepoProvider).hifzQueue());
final hifzStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.watch(userRepoProvider).hifzStats());
final hifzPlansProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(userRepoProvider).hifzPlans());

/// "Learn" tab: AI recitation coach entry + Hifz coach (plans, daily queue, retention).
class HifzScreen extends ConsumerWidget {
  const HifzScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final queue = ref.watch(hifzQueueProvider);
    final stats = ref.watch(hifzStatsProvider);
    final plans = ref.watch(hifzPlansProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabLearn)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(hifzQueueProvider);
          ref.invalidate(hifzStatsProvider);
          ref.invalidate(hifzPlansProvider);
        },
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const Icon(Icons.mic, size: 36),
              title: Text(l10n.aiCoach, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(l10n.aiCoachPitch),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/coach'),
            ),
          ),
          SectionTitle(l10n.hifzCoach),
          stats.when(
            loading: () => const SizedBox(height: 80, child: LoadingView()),
            error: (e, _) => ErrorView(error: e),
            data: (s) => _StatsRow(stats: s),
          ),
          const SizedBox(height: 12),
          queue.when(
            loading: () => const SizedBox(height: 80, child: LoadingView()),
            error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(hifzQueueProvider)),
            data: (q) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(l10n.todaysSession, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(l10n.queueSummary(q.reviews.length, q.fresh.length)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: q.isEmpty
                        ? null
                        : () async {
                            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => HifzReviewScreen(queue: q)));
                            ref.invalidate(hifzQueueProvider);
                            ref.invalidate(hifzStatsProvider);
                            ref.invalidate(dashboardProvider);
                          },
                    child: Text(q.isEmpty ? l10n.allDoneToday : l10n.startSession),
                  ),
                ]),
              ),
            ),
          ),
          SectionTitle(l10n.myPlans,
              trailing: TextButton.icon(
                onPressed: () => _createPlan(context, ref),
                icon: const Icon(Icons.add),
                label: Text(l10n.newPlan),
              )),
          plans.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => ErrorView(error: e),
            data: (list) => list.isEmpty
                ? Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(l10n.noPlansYet)))
                : Column(children: [
                    for (final p in list)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.flag_outlined),
                          title: Text('${p['title'] ?? l10n.hifzPlan}'),
                          subtitle: Text(l10n.newPerDay(p['daily_new_ayahs'] as int)),
                        ),
                      ),
                  ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _createPlan(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreatePlanSheet(),
    );
    if (created == true) {
      ref.invalidate(hifzPlansProvider);
      ref.invalidate(hifzQueueProvider);
      ref.invalidate(hifzStatsProvider);
    }
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final Map<String, dynamic> stats;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final retention = (stats['avg_retention'] as num?)?.toDouble();
    Widget tile(String value, String label, IconData icon, [Color? color]) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(children: [
                Icon(icon, color: color),
                Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                Text(label, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
              ]),
            ),
          ),
        );
    return Row(children: [
      tile('${(stats['review'] ?? 0) + (stats['mastered'] ?? 0)}', l10n.memorized, Icons.check_circle, AppColors.success),
      const SizedBox(width: 8),
      tile(retention == null ? '—' : '${(retention * 100).round()}%', l10n.retention, Icons.insights),
      const SizedBox(width: 8),
      tile('${stats['at_risk'] ?? 0}', l10n.atRisk, Icons.warning_amber, AppColors.warning),
    ]);
  }
}

class _CreatePlanSheet extends ConsumerStatefulWidget {
  const _CreatePlanSheet();
  @override
  ConsumerState<_CreatePlanSheet> createState() => _CreatePlanSheetState();
}

class _CreatePlanSheetState extends ConsumerState<_CreatePlanSheet> {
  int _surah = 78; // Juz Amma is the most common starting point
  int _daily = 3;
  bool _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(quranRepoProvider);
      final surah = await repo.surah(_surah);
      final from = await repo.ayahId(_surah, 1);
      final to = await repo.ayahId(_surah, surah.ayahCount);
      await ref.read(userRepoProvider).createHifzPlan(from, to, _daily, context.isArabic ? surah.nameAr : surah.transliteration);
      Analytics.track(Events.hifzPlanCreated, {'surah': _surah, 'daily_new': _daily});
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.errorGeneric)));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final surahs = ref.watch(surahsProvider).value ?? [];
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l10n.newPlan, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: _surah,
          decoration: InputDecoration(labelText: l10n.surah),
          items: [for (final s in surahs) DropdownMenuItem(value: s.id, child: Text('${s.id}. ${context.isArabic ? s.nameAr : s.transliteration}'))],
          onChanged: (v) => setState(() => _surah = v ?? 78),
        ),
        const SizedBox(height: 16),
        Text(l10n.newAyahsPerDay(_daily)),
        Slider(value: _daily.toDouble(), min: 1, max: 15, divisions: 14, label: '$_daily', onChanged: (v) => setState(() => _daily = v.round())),
        const SizedBox(height: 8),
        FilledButton(onPressed: _busy ? null : _save, child: Text(l10n.createPlan)),
      ]),
    );
  }
}
