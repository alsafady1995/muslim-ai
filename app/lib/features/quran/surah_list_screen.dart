import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import 'audio_player_bar.dart';

class SurahListScreen extends ConsumerStatefulWidget {
  const SurahListScreen({super.key});
  @override
  ConsumerState<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends ConsumerState<SurahListScreen> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final surahs = ref.watch(surahsProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabQuran)),
      bottomNavigationBar: const AudioPlayerBar(),
      body: surahs.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(surahsProvider)),
        data: (list) {
          final q = _filter.toLowerCase();
          final filtered = list
              .where((s) => q.isEmpty || s.nameAr.contains(_filter) || s.transliteration.toLowerCase().contains(q) ||
                  s.nameEn.toLowerCase().contains(q) || '${s.id}' == q)
              .toList();
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l10n.findSurah),
                onChanged: (v) => setState(() => _filter = v.trim()),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) {
                  final s = filtered[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${s.id}')),
                    title: Text(context.isArabic ? s.nameAr : s.transliteration),
                    subtitle: Text('${context.isArabic ? s.nameEn : s.nameEn} · ${l10n.ayahCount(s.ayahCount)} · '
                        '${s.revelationPlace == 'makkah' ? l10n.makki : l10n.madani}'),
                    trailing: Text(s.nameAr, style: const TextStyle(fontSize: 20)),
                    onTap: () => context.go('/quran/${s.id}'),
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }
}
