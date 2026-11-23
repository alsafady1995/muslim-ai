import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/analytics.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';

final _categoriesProvider = FutureProvider<List<DhikrCategory>>((ref) => ref.watch(quranRepoProvider).adhkarCategories());

class AdhkarScreen extends ConsumerWidget {
  const AdhkarScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(_categoriesProvider);
    const icons = {
      'morning': Icons.wb_sunny_outlined,
      'evening': Icons.nights_stay_outlined,
      'sleep': Icons.bedtime_outlined,
      'after_prayer': Icons.mosque_outlined,
      'travel': Icons.flight_takeoff,
    };
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.adhkar)),
      body: cats.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(_categoriesProvider)),
        data: (list) => ListView(padding: const EdgeInsets.all(16), children: [
          for (final c in list)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Icon(icons[c.slug] ?? Icons.auto_awesome, size: 32),
                title: Text(context.isArabic ? c.nameAr : c.nameEn, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/adhkar/${c.id}'),
              ),
            ),
        ]),
      ),
    );
  }
}

class AdhkarDetailScreen extends ConsumerStatefulWidget {
  const AdhkarDetailScreen({super.key, required this.categoryId});
  final int categoryId;
  @override
  ConsumerState<AdhkarDetailScreen> createState() => _AdhkarDetailScreenState();
}

class _AdhkarDetailScreenState extends ConsumerState<AdhkarDetailScreen> {
  List<Dhikr>? _items;
  final _remaining = <int, int>{};
  Set<int> _done = {};
  final _player = AudioPlayer();
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await ref.read(quranRepoProvider).adhkar(widget.categoryId);
      final done = await ref.read(userRepoProvider).completedDhikrToday(widget.categoryId);
      setState(() {
        _items = items;
        _done = done;
        for (final d in items) {
          _remaining[d.id] = done.contains(d.id) ? 0 : d.repeatCount;
        }
      });
    } catch (e) {
      setState(() => _error = e);
    }
  }

  Future<void> _tap(Dhikr d) async {
    final left = _remaining[d.id] ?? 0;
    if (left <= 0) return;
    HapticFeedback.lightImpact();
    setState(() => _remaining[d.id] = left - 1);
    if (left - 1 > 0) return;
    HapticFeedback.mediumImpact();
    _done.add(d.id);
    Analytics.track(Events.dhikrCompleted, {'dhikr': d.id});
    final r = await ref.read(userRepoProvider).completeDhikr(widget.categoryId, d.id);
    if (r['category_completed'] == true && (r['xp_awarded'] as num? ?? 0) > 0) {
      Analytics.track(Events.adhkarSetCompleted, {'category': widget.categoryId});
      ref.invalidate(dashboardProvider);
      if (mounted) {
        showXpToast(context, (r['xp_awarded'] as num).toInt(),
            achievements: ((r['new_achievements'] as List?) ?? const []).cast<Map<String, dynamic>>());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adhkar)),
      body: _error != null
          ? ErrorView(error: _error!, onRetry: _load)
          : items == null
              ? const LoadingView()
              : Column(children: [
                  LinearProgressIndicator(value: items.isEmpty ? 0 : _done.length / items.length),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final d = items[i];
                        final left = _remaining[d.id] ?? 0;
                        final finished = left == 0;
                        return Opacity(
                          opacity: finished ? 0.55 : 1,
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _tap(d),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(d.textAr, style: AppTheme.quran(context, size: 21), textAlign: TextAlign.justify),
                                  ),
                                  if (!context.isArabic) ...[
                                    const SizedBox(height: 8),
                                    Text(d.translationEn, style: Theme.of(context).textTheme.bodyMedium),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Expanded(child: Text(d.reference, style: Theme.of(context).textTheme.labelSmall)),
                                    if (d.audioUrl != null)
                                      IconButton(
                                        icon: const Icon(Icons.volume_up_outlined),
                                        onPressed: () async {
                                          await _player.setUrl(d.audioUrl!);
                                          await _player.play();
                                        },
                                      ),
                                    CircleAvatar(
                                      backgroundColor: finished ? AppColors.success : Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      child: finished ? const Icon(Icons.check) : Text('$left'),
                                    ),
                                  ]),
                                ]),
                              ),
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
