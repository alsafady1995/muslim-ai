import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';

final weakWordsProvider = FutureProvider.autoDispose<WeakWords>((ref) => ref.watch(userRepoProvider).weakWords());

/// The words the coach heard wrong most often. Tapping one re-checks that ayah.
/// Free users see the top 3 (the server cuts the list) plus how many more there are.
class WeakWordsScreen extends ConsumerStatefulWidget {
  const WeakWordsScreen({super.key});
  @override
  ConsumerState<WeakWordsScreen> createState() => _WeakWordsScreenState();
}

class _WeakWordsScreenState extends ConsumerState<WeakWordsScreen> {
  @override
  void initState() {
    super.initState();
    Analytics.track(Events.weakWordsOpened);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = ref.watch(weakWordsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.weakWordsTitle)),
      body: data.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(weakWordsProvider)),
        data: (w) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(weakWordsProvider),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Text(l10n.weakWordsBody, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            if (w.words.isEmpty)
              Card(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.weakWordsEmpty, textAlign: TextAlign.center)))
            else
              for (final word in w.words) _WordTile(word: word),
            if (w.locked > 0)
              Card(
                color: AppColors.gold.withValues(alpha: 0.15),
                child: ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(l10n.weakWordsLocked(w.locked)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/paywall?source=weak_words'),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _WordTile extends ConsumerWidget {
  const _WordTile({required this.word});
  final WeakWord word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(word.word,
            textDirection: TextDirection.rtl, style: AppTheme.quran(context, size: 24)),
        subtitle: Text('${word.surahId}:${word.ayahNumber} · ${l10n.weakWordMisses(word.misses)}'),
        trailing: FilledButton.tonal(
          onPressed: () async {
            await context.push('/coach?from=${word.ayahId}&to=${word.ayahId}&source=weak_words');
            ref.invalidate(weakWordsProvider);
          },
          child: Text(l10n.practise),
        ),
      ),
    );
  }
}
