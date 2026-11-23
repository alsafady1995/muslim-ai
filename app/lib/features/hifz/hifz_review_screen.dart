import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../quran/audio_controller.dart';

/// Flashcard-style session: reviews first (most at-risk first), then new ayahs.
/// The user can self-grade or test with the AI coach (which grades automatically).
class HifzReviewScreen extends ConsumerStatefulWidget {
  const HifzReviewScreen({super.key, required this.queue});
  final HifzQueue queue;
  @override
  ConsumerState<HifzReviewScreen> createState() => _HifzReviewScreenState();
}

class _HifzReviewScreenState extends ConsumerState<HifzReviewScreen> {
  late final List<HifzCard> _cards = [...widget.queue.reviews, ...widget.queue.fresh];
  int _index = 0;
  bool _revealed = false;
  int _xp = 0;

  HifzCard get _card => _cards[_index];

  Future<void> _grade(int score) async {
    final r = await ref.read(userRepoProvider).recordHifzReview(_card.itemId, score);
    _xp += r.xpAwarded;
    Analytics.track(Events.hifzReviewed, {'score': score, 'new': _card.isNew});
    if (!mounted) return;
    if (r.newAchievements.isNotEmpty) showXpToast(context, r.xpAwarded, achievements: r.newAchievements);
    if (_index + 1 >= _cards.length) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(context.l10n.sessionComplete),
          content: Text(context.l10n.xpEarned(_xp)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.done))],
        ),
      );
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() {
      _index++;
      _revealed = _cards[_index].isNew;
    });
  }

  @override
  void initState() {
    super.initState();
    _revealed = _cards.first.isNew;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = _card;
    final ayah = Ayah(id: c.ayahId, surahId: c.surahId, ayahNumber: c.ayahNumber, textUthmani: c.text);
    return Scaffold(
      appBar: AppBar(title: Text('${_index + 1} / ${_cards.length}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            LinearProgressIndicator(value: (_index + 1) / _cards.length, borderRadius: BorderRadius.circular(8)),
            const SizedBox(height: 16),
            Chip(label: Text(c.isNew ? l10n.newAyah : l10n.review)),
            Text(l10n.ayahN('${c.surahId}:${c.ayahNumber}'), style: Theme.of(context).textTheme.titleMedium),
            if (c.retention != null)
              Text(l10n.predictedRecall((c.retention! * 100).round()), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _revealed
                        ? Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(c.text, style: AppTheme.quran(context, size: 28), textAlign: TextAlign.center),
                          )
                        : Text(l10n.reciteThenReveal, textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.headphones),
                  label: Text(l10n.listen),
                  onPressed: () => ref.read(audioProvider.notifier).play([ayah], startIndex: 0, repeatEach: c.isNew ? 3 : 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.mic),
                  label: Text(l10n.testWithAi),
                  onPressed: () async {
                    await context.push('/coach?from=${c.ayahId}&to=${c.ayahId}&mode=hifz');
                    // AI test already graded this item on the server; move on.
                    if (mounted) await _advanceWithoutGrade();
                  },
                ),
              ),
            ]),
            const SizedBox(height: 12),
            if (!_revealed)
              FilledButton(onPressed: () => setState(() => _revealed = true), child: Text(l10n.reveal))
            else
              Row(children: [
                for (final (score, label, color) in [
                  (1, l10n.gradeAgain, AppColors.error),
                  (3, l10n.gradeHard, AppColors.warning),
                  (4, l10n.gradeGood, AppColors.primary),
                  (5, l10n.gradeEasy, AppColors.success),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: color, padding: EdgeInsets.zero),
                        onPressed: () => _grade(score),
                        child: Text(label),
                      ),
                    ),
                  ),
              ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _advanceWithoutGrade() async {
    if (_index + 1 >= _cards.length) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _index++;
      _revealed = _cards[_index].isNew;
    });
  }
}
