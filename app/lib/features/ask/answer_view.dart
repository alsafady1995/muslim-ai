import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';

/// Renders a grounded answer with Quran, Hadith and interpretation kept visibly separate.
class AnswerView extends StatelessWidget {
  const AnswerView({super.key, required this.answer, this.onFollowUp, this.onReport});
  final GroundedAnswer answer;
  final ValueChanged<String>? onFollowUp;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (answer.answerType == 'crisis')
        Card(
          color: theme.colorScheme.errorContainer,
          child: Padding(padding: const EdgeInsets.all(16), child: Text(l10n.crisisHelp)),
        ),
      if (answer.answerType == 'needs_scholar')
        Card(
          color: AppColors.gold.withValues(alpha: 0.15),
          child: ListTile(leading: const Icon(Icons.school_outlined), title: Text(l10n.consultScholar)),
        ),
      if (answer.quran.isNotEmpty) ...[
        _Label(icon: Icons.menu_book, text: l10n.fromQuran),
        for (final a in answer.quran) _AyahCard(a: a),
      ],
      if (answer.hadith.isNotEmpty) ...[
        _Label(icon: Icons.format_quote, text: l10n.fromHadith),
        for (final h in answer.hadith) _HadithCard(h: h),
      ],
      _Label(icon: Icons.lightbulb_outline, text: l10n.explanation),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: SelectableText(answer.explanation))),
      if (answer.scholarlyDifferences != null) ...[
        _Label(icon: Icons.balance, text: l10n.scholarlyViews),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(answer.scholarlyDifferences!))),
      ],
      const SizedBox(height: 8),
      Text(answer.disclaimer, style: theme.textTheme.bodySmall),
      if (onReport != null)
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(onPressed: onReport, icon: const Icon(Icons.flag_outlined, size: 18), label: Text(l10n.reportAnswer)),
        ),
      if (answer.followUps.isNotEmpty && onFollowUp != null)
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final q in answer.followUps) ActionChip(label: Text(q), onPressed: () => onFollowUp!(q)),
        ]),
    ]);
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Row(children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({required this.a});
  final CitedAyah a;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go('/quran/${a.surahId}?ayah=${a.ayahNumber}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${context.isArabic ? a.surahNameAr : a.surahNameEn} · ${a.verseKey}',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(a.arabic, style: AppTheme.quran(context, size: 22), textAlign: TextAlign.justify),
            ),
            if (a.translation != null)
              Directionality(textDirection: TextDirection.ltr, child: Text(a.translation!, style: Theme.of(context).textTheme.bodyMedium)),
            if (a.whyRelevant != null && a.whyRelevant!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(a.whyRelevant!, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            ],
            if (a.tafsir != null && a.tafsir!.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('${l10n.tafsir}${a.tafsirSource == null ? '' : ' · ${a.tafsirSource}'}'),
                children: [Text(a.tafsir!)],
              ),
          ]),
        ),
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({required this.h});
  final CitedHadith h;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(h.reference, style: Theme.of(context).textTheme.labelLarge)),
              if (h.grade != null) Chip(label: Text(h.grade!), visualDensity: VisualDensity.compact),
            ]),
            Directionality(textDirection: TextDirection.rtl, child: Text(h.textAr, maxLines: 8, overflow: TextOverflow.ellipsis)),
            if (h.textEn != null) ...[
              const SizedBox(height: 6),
              Directionality(textDirection: TextDirection.ltr, child: Text(h.textEn!, maxLines: 8, overflow: TextOverflow.ellipsis)),
            ],
            if (h.whyRelevant != null && h.whyRelevant!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(h.whyRelevant!, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            ],
          ]),
        ),
      );
}
