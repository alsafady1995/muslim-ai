import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';

class CoachResultView extends StatelessWidget {
  const CoachResultView({super.key, required this.result, required this.ayahs, required this.onRetry, required this.onListen});
  final RecitationResult result;
  final List<Ayah> ayahs;
  final VoidCallback onRetry;
  final VoidCallback onListen;

  static Color statusColor(String status) => switch (status) {
        'correct' => AppColors.success,
        'mispronounced' || 'unclear' => AppColors.warning,
        'wrong' || 'skipped' => AppColors.error,
        _ => Colors.grey,
      };

  String _mistakeLabel(BuildContext context, String type) {
    final l10n = context.l10n;
    return switch (type) {
      'mispronounced' => l10n.mistakeMispronounced,
      'wrong_word' => l10n.mistakeWrongWord,
      'skipped' => l10n.mistakeSkipped,
      'added_word' => l10n.mistakeAdded,
      'repetition' => l10n.mistakeRepetition,
      'unclear' => l10n.mistakeUnclear,
      'possible_short_madd' => l10n.mistakeShortMadd,
      'long_pause' => l10n.mistakeLongPause,
      _ => type,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final words = result.words;
    final verseKeyOf = {for (final a in ayahs) a.id: a.verseKey};
    final overall = result.overall;
    final headline = overall >= 90 ? l10n.excellent : (overall >= 70 ? l10n.goodJob : l10n.keepPracticing);
    return ListView(padding: const EdgeInsets.all(20), children: [
      Center(
        child: ProgressRing(
          value: overall / 100,
          size: 120,
          color: CoachResultView.statusColor(overall >= 85 ? 'correct' : (overall >= 60 ? 'unclear' : 'wrong')),
          child: Text('${overall.round()}', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
        ),
      ),
      const SizedBox(height: 8),
      Text(headline, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
      if (!result.completed) Text(l10n.notCompleted, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _score(context, l10n.accuracy, result.accuracy),
        _score(context, l10n.fluency, result.fluency),
        _score(context, l10n.tajweed, result.tajweed),
      ]),
      SectionTitle(l10n.yourRecitation),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(spacing: 6, runSpacing: 4, children: [
              for (final w in words)
                Text(
                  w.text,
                  style: AppTheme.quran(context, size: 24, color: w.status == 'correct' ? null : CoachResultView.statusColor(w.status))
                      .copyWith(decoration: w.status == 'skipped' ? TextDecoration.lineThrough : null),
                ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 12, children: [
        _legend(context, AppColors.success, l10n.legendCorrect),
        _legend(context, AppColors.warning, l10n.legendCheck),
        _legend(context, AppColors.error, l10n.legendMistake),
      ]),
      if (result.mistakes.isNotEmpty) ...[
        SectionTitle(l10n.corrections),
        for (final m in result.mistakes.take(30))
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.error_outline, color: CoachResultView.statusColor(m['type'] == 'possible_short_madd' ? 'unclear' : 'wrong')),
              title: Text(_mistakeLabel(context, '${m['type']}')),
              subtitle: Text([
                if (m['ayahId'] != null) l10n.ayahN(verseKeyOf[m['ayahId']] ?? ''),
                if (m['expected'] != null) '${l10n.expected}: ${m['expected']}',
                if (m['heard'] != null) '${l10n.heard}: ${m['heard']}',
              ].join('\n')),
            ),
          ),
      ],
      const SizedBox(height: 8),
      Text(l10n.coachDisclaimer, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      OutlinedButton.icon(onPressed: onListen, icon: const Icon(Icons.headphones), label: Text(l10n.listenCorrect)),
      const SizedBox(height: 8),
      FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.replay), label: Text(l10n.tryAgain)),
    ]);
  }

  Widget _score(BuildContext context, String label, double? v) => Column(children: [
        Text(v == null ? '—' : '${v.round()}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ]);

  Widget _legend(BuildContext context, Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ]);
}
