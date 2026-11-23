import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

final _goalsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(userRepoProvider).goals());

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  static const _defaults = {'quran_read': 5, 'memorize': 3, 'adhkar': 2, 'prayer': 5, 'listen': 10};
  static const _max = {'quran_read': 100, 'memorize': 30, 'adhkar': 5, 'prayer': 5, 'listen': 120};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final goals = ref.watch(_goalsProvider);
    final labels = {
      'quran_read': (l10n.goalQuran, l10n.unitAyahs),
      'memorize': (l10n.goalMemorize, l10n.unitAyahs),
      'adhkar': (l10n.goalAdhkar, l10n.unitSets),
      'prayer': (l10n.goalPrayer, l10n.unitPrayers),
      'listen': (l10n.goalListen, l10n.unitMinutes),
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dailyGoals)),
      body: goals.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(_goalsProvider)),
        data: (rows) {
          final byType = {for (final r in rows) r['goal_type'] as String: r};
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(l10n.goalsIntro),
            const SizedBox(height: 12),
            for (final type in _defaults.keys)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(labels[type]!.$1),
                      subtitle: Text('${byType[type]?['daily_target'] ?? _defaults[type]} ${labels[type]!.$2}'),
                      value: byType[type]?['active'] == true,
                      onChanged: (v) async {
                        await ref.read(userRepoProvider).setGoal(type, (byType[type]?['daily_target'] as int?) ?? _defaults[type]!, v);
                        Analytics.track(Events.goalUpdated, {'type': type, 'active': v});
                        ref.invalidate(_goalsProvider);
                        ref.invalidate(dashboardProvider);
                      },
                    ),
                    if (byType[type]?['active'] == true)
                      _GoalSlider(
                        initial: (byType[type]!['daily_target'] as int).clamp(1, _max[type]!),
                        max: _max[type]!,
                        onChanged: (v) async {
                          await ref.read(userRepoProvider).setGoal(type, v, true);
                          Analytics.track(Events.goalUpdated, {'type': type, 'target': v});
                          ref.invalidate(_goalsProvider);
                          ref.invalidate(dashboardProvider);
                        },
                      ),
                  ]),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

class _GoalSlider extends StatefulWidget {
  const _GoalSlider({required this.initial, required this.max, required this.onChanged});
  final int initial;
  final int max;
  final ValueChanged<int> onChanged;
  @override
  State<_GoalSlider> createState() => _GoalSliderState();
}

class _GoalSliderState extends State<_GoalSlider> {
  late double _v = widget.initial.toDouble();
  @override
  Widget build(BuildContext context) => Slider(
        value: _v,
        min: 1,
        max: widget.max.toDouble(),
        divisions: widget.max - 1,
        label: '${_v.round()}',
        onChanged: (v) => setState(() => _v = v),
        onChangeEnd: (v) => widget.onChanged(v.round()),
      );
}
