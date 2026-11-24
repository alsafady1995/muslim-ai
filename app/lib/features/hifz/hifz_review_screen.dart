import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics.dart';
import '../../core/monetization.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../quran/audio_controller.dart';

/// Flashcard-style session: reviews first (most at-risk first), then new ayahs.
/// The user can self-grade or test with the AI coach (which grades automatically).
/// When this week's free AI tests are used up, the session continues with self-grading
/// and an inline card offers Premium; a review is never blocked.
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
  bool _grading = false; // ignore extra taps while a grade is being saved
  bool _showLimitCard = false;
  int _testLimit = 5;

  HifzCard get _card => _cards[_index];

  Future<void> _testWithAi() async {
    final c = _card;
    final quota = await ref.read(weeklyQuotaProvider.future).catchError((_) => WeeklyQuota(const {}));
    if (!mounted) return;
    if (quota.raw.isNotEmpty && !quota.premium && quota.remaining('hifz') <= 0) {
      Analytics.track(Events.quotaHit, {'feature': 'hifz', 'kind': 'inline'});
      setState(() {
        _testLimit = quota.limit('hifz');
        _showLimitCard = true;
      });
      return;
    }
    final result = await context.push<RecitationResult>('/coach?from=${c.ayahId}&to=${c.ayahId}&mode=hifz');
    if (!mounted || result == null) return; // left without a result: stay on this card
    final graded = result.hifzUpdates.any((u) => '${u['item_id']}' == '${c.itemId}');
    if (!graded) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.aiTestNotGraded)));
      setState(() => _revealed = true);
      return;
    }
    if (result.milestone != null) await _celebrate(result.milestone!);
    if (mounted) await _advanceWithoutGrade();
  }

  /// "You've memorized Surah X": celebration first; the offer is a quiet link under it, once.
  Future<void> _celebrate(HifzMilestone m) async {
    Analytics.track(Events.milestoneReached, {'surah': m.surahId, 'first': m.first});
    final gate = ref.read(paywallGateProvider);
    final premium = ref.read(premiumProvider).value ?? false;
    final valueDays = await ref.read(userRepoProvider).dashboard().then((d) => d.valueDays).catchError((_) => 0);
    final offer = !premium && !gate.usedOnce('milestone') && gate.canAutoShow(valueDays: valueDays, premium: premium);
    if (!mounted) return;
    final l10n = context.l10n;
    final name = context.isArabic ? m.nameAr : m.transliteration;
    final wantsOffer = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        icon: const Icon(Icons.emoji_events, color: AppColors.gold, size: 48),
        title: Text(l10n.milestoneTitle(name), textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l10n.milestoneBody(m.xp), textAlign: TextAlign.center),
          if (offer) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: () => Navigator.pop(d, true), child: Text(l10n.milestoneOffer, textAlign: TextAlign.center)),
          ],
        ]),
        actions: [FilledButton(onPressed: () => Navigator.pop(d, false), child: Text(l10n.done))],
      ),
    );
    if (offer) {
      await gate.markOnce('milestone');
      await gate.recordShown();
      Analytics.track(Events.offerShown, {'source': 'milestone'});
    }
    if (wantsOffer == true && mounted) await context.push('/paywall?source=milestone');
  }

  Future<void> _grade(int score) async {
    if (_grading) return;
    _grading = true;
    try {
      await _gradeCard(score);
    } finally {
      _grading = false;
    }
  }

  Future<void> _gradeCard(int score) async {
    final r = await ref.read(userRepoProvider).recordHifzReview(_card.itemId, score);
    _xp += r.xpAwarded;
    Analytics.track(Events.hifzReviewed, {'score': score, 'new': _card.isNew});
    if (!mounted) return;
    if (r.newAchievements.isNotEmpty) showXpToast(context, r.xpAwarded, achievements: r.newAchievements);
    if (r.milestone != null) await _celebrate(r.milestone!);
    if (!mounted) return;
    if (_index + 1 >= _cards.length) {
      await showDialog<void>(
        context: context,
        // Close with the dialog's own context: the dialog lives on the root navigator,
        // while this screen's context points at the tab's nested navigator.
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.sessionComplete),
          content: Text(context.l10n.xpEarned(_xp)),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(context.l10n.done))],
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
                  onPressed: _testWithAi,
                ),
              ),
            ]),
            if (_showLimitCard) ...[
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(l10n.hifzLimitInline(_testLimit)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() {
                        _showLimitCard = false;
                        _revealed = true;
                      }),
                      child: Text(l10n.continueReviewing),
                    ),
                    TextButton(
                      onPressed: () => context.push('/paywall?source=hifz_limit'),
                      child: Text(l10n.tryPremiumFree),
                    ),
                  ]),
                ),
              ),
            ],
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
