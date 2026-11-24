import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ai_budget.dart';
import '../../core/analytics.dart';
import '../../core/api.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';

/// AI semantic Quran search ("verses about patience") with a free keyword mode.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});
  final String? initialQuery;
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _input = TextEditingController(text: widget.initialQuery);
  bool _semantic = true;
  bool _busy = false;
  List<CitedAyah>? _results;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery?.isNotEmpty == true) WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  Future<void> _search([String? q]) async {
    if (q != null) _input.text = q;
    final query = _input.text.trim();
    if (query.length < 2) return;
    setState(() {
      _busy = true;
      _error = false;
    });
    Analytics.track(Events.searchPerformed, {'mode': _semantic ? 'semantic' : 'keyword'});
    try {
      final res = await ref.read(edgeApiProvider).call('quran-search', {
        'query': query,
        'locale': ref.read(localeProvider).languageCode,
        'mode': _semantic ? 'semantic' : 'keyword',
      });
      final rows = ((res['results'] as List?) ?? const []).map((e) {
        final m = (e as Map).cast<String, dynamic>();
        // keyword results use a different shape
        return CitedAyah({
          'verse_key': m['verse_key'] ?? '${m['surah_id']}:${m['ayah_number']}',
          'arabic': m['arabic'] ?? m['text_uthmani'],
          ...m,
        });
      }).toList();
      setState(() => _results = rows);
    } on AiBudgetExhausted catch (e) {
      if (mounted) showAiBudgetExhausted(context, e);
    } on QuotaExceeded {
      Analytics.track(Events.quotaHit, {'feature': 'search'});
      if (mounted) context.push('/paywall?source=search_quota');
    } catch (_) {
      setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final topics = [l10n.topicPatience, l10n.topicAnxiety, l10n.topicGratitude, l10n.topicFamily, l10n.topicSuccess,
      l10n.topicKindness, l10n.topicBusiness];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchQuran)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _input,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.searchPlaceholder,
              suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _search),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, icon: const Icon(Icons.auto_awesome), label: Text(l10n.byMeaning)),
              ButtonSegment(value: false, icon: const Icon(Icons.text_fields), label: Text(l10n.byWords)),
            ],
            selected: {_semantic},
            onSelectionChanged: (s) => setState(() => _semantic = s.first),
          ),
        ),
        Expanded(
          child: _busy
              ? const LoadingView()
              : _error
                  ? ErrorView(error: 'search', onRetry: _search)
                  : _results == null
                      ? ListView(padding: const EdgeInsets.all(16), children: [
                          Text(l10n.tryTopics, style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final t in topics) ActionChip(label: Text(t), onPressed: () => _search(t)),
                          ]),
                        ])
                      : _results!.isEmpty
                          ? Center(child: Text(l10n.noResults))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _results!.length,
                              itemBuilder: (_, i) {
                                final a = _results![i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => context.go('/quran/${a.surahId}?ayah=${a.ayahNumber}'),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                        Text('${context.isArabic ? a.surahNameAr : a.surahNameEn} ${a.verseKey}',
                                            style: Theme.of(context).textTheme.labelLarge),
                                        const SizedBox(height: 6),
                                        Directionality(
                                          textDirection: TextDirection.rtl,
                                          child: Text(a.arabic, style: AppTheme.quran(context, size: 22)),
                                        ),
                                        if (a.translation != null)
                                          Directionality(textDirection: TextDirection.ltr, child: Text(a.translation!)),
                                        if (a.tafsir != null && a.tafsir!.isNotEmpty)
                                          ExpansionTile(
                                            tilePadding: EdgeInsets.zero,
                                            title: Text(l10n.explanation),
                                            children: [Text(a.tafsir!)],
                                          ),
                                      ]),
                                    ),
                                  ),
                                );
                              },
                            ),
        ),
      ]),
    );
  }
}
