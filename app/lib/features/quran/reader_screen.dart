import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/analytics.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/user_repository.dart';
import 'audio_controller.dart';
import 'audio_player_bar.dart';

final _surahAyahsProvider = FutureProvider.family<List<Ayah>, int>(
  (ref, surahId) => ref.watch(quranRepoProvider).ayahsOfSurah(surahId),
);

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.surahId, this.initialAyah});
  final int surahId;
  final int? initialAyah;
  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _seen = <int>{};
  int? _lastSeenAyahId;
  bool _hideText = false; // memorization self-test
  late final UserRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(userRepoProvider);
    Analytics.track(Events.quranSurahOpened, {'surah': widget.surahId});
  }

  @override
  void dispose() {
    // Ayahs that were on screen count as read (server caps daily XP).
    if (_seen.isNotEmpty) {
      _repo.logActivity('ayah_read', _seen.length, ref: 'surah:${widget.surahId}').ignore();
      Analytics.track(Events.quranAyahsRead, {'count': _seen.length, 'surah': widget.surahId});
    }
    if (_lastSeenAyahId != null) _repo.saveReadingPosition(_lastSeenAyahId!).ignore();
    super.dispose();
  }

  void _actions(List<Ayah> ayahs, int index) {
    final a = ayahs[index];
    final l10n = context.l10n;
    final audio = ref.read(audioProvider.notifier);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: Text(l10n.playFromHere),
            onTap: () {
              Navigator.pop(ctx);
              audio.play(ayahs, startIndex: index, repeatEach: 1, loop: false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.repeat_one),
            title: Text(l10n.repeatAyah3),
            onTap: () {
              Navigator.pop(ctx);
              audio.play([a], startIndex: 0, repeatEach: 3, loop: true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.mic),
            title: Text(l10n.reciteWithAi),
            onTap: () {
              Navigator.pop(ctx);
              final end = ayahs[(index + 2).clamp(0, ayahs.length - 1)];
              context.push('/coach?from=${a.id}&to=${end.id}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: Text(l10n.copy),
            onTap: () {
              Clipboard.setData(ClipboardData(text: '${a.textUthmani}\n${a.translation ?? ''}\n(${a.verseKey})'));
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: Text(l10n.share),
            onTap: () {
              Navigator.pop(ctx);
              Analytics.track(Events.shareTapped, {'type': 'ayah'});
              SharePlus.instance.share(ShareParams(
                text: '${a.textUthmani}\n\n${a.translation ?? ''}\n— ${l10n.quranRef(a.verseKey)}\n\n${l10n.sharedFromApp}',
              ));
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ayahs = ref.watch(_surahAyahsProvider(widget.surahId));
    final surah = ref.watch(surahsProvider).value?.where((s) => s.id == widget.surahId).firstOrNull;
    final playingId = ref.watch(audioProvider.select((s) => s.currentAyahId));
    final showTranslation = ref.watch(prefsProvider.select((p) => p['show_translation'] as bool? ?? true));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(surah == null ? '' : (context.isArabic ? surah.nameAr : surah.transliteration)),
        actions: [
          IconButton(
            tooltip: context.l10n.memorizationMode,
            icon: Icon(_hideText ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _hideText = !_hideText),
          ),
          IconButton(
            tooltip: context.l10n.playSurah,
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () {
              final list = ayahs.value;
              if (list != null && list.isNotEmpty) ref.read(audioProvider.notifier).play(list, startIndex: 0, repeatEach: 1);
            },
          ),
        ],
      ),
      bottomNavigationBar: const AudioPlayerBar(),
      body: ayahs.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(_surahAyahsProvider(widget.surahId))),
        data: (list) => ListView.builder(
          cacheExtent: 0,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
          itemCount: list.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              return widget.surahId == 1 || widget.surahId == 9
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ', textAlign: TextAlign.center, style: AppTheme.quran(context)),
                    );
            }
            final a = list[i - 1];
            _seen.add(a.id);
            if (_lastSeenAyahId == null || a.id > _lastSeenAyahId!) _lastSeenAyahId = a.id;
            final active = a.id == playingId;
            return InkWell(
              onTap: () => _actions(list, i - 1),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: active ? scheme.primaryContainer.withValues(alpha: 0.5) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: _hideText
                        ? Container(
                            height: 48,
                            decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                            alignment: Alignment.center,
                            child: Text('﴿${a.ayahNumber}﴾', style: AppTheme.quran(context, size: 20)),
                          )
                        : Text('${a.textUthmani} ﴿${a.ayahNumber}﴾', style: AppTheme.quran(context), textAlign: TextAlign.justify),
                  ),
                  if (showTranslation && a.translation != null && !_hideText) ...[
                    const SizedBox(height: 8),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(a.translation!, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ],
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
