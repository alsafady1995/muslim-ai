import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/analytics.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';

final achievementsProvider = FutureProvider.autoDispose<List<Achievement>>((ref) => ref.watch(userRepoProvider).achievements());
final _recitationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(userRepoProvider).recitationHistory());

const _achievementIcons = {
  'sparkles': Icons.auto_awesome,
  'flame': Icons.local_fire_department,
  'crown': Icons.emoji_events,
  'book': Icons.menu_book,
  'trophy': Icons.emoji_events,
  'brain': Icons.psychology,
  'moon': Icons.nights_stay,
  'mic': Icons.mic,
  'mosque': Icons.mosque,
  'star': Icons.star,
};

/// Personal dashboard: progress, streaks, achievements, statistics, coaching history, referrals.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dash = ref.watch(dashboardProvider);
    final achievements = ref.watch(achievementsProvider);
    final recitations = ref.watch(_recitationsProvider);
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabMe),
        actions: [IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/settings'))],
      ),
      body: dash.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(dashboardProvider)),
        data: (d) {
          final totalAyahs = d.history.fold<int>(0, (s, h) => s + ((h['ayahs_read'] as num?)?.toInt() ?? 0));
          final goalDays = d.history.where((h) => h['goals_met'] == true).length;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardProvider);
              ref.invalidate(achievementsProvider);
              ref.invalidate(_recitationsProvider);
            },
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [
                CircleAvatar(radius: 32, child: Text('${d.level}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${d.profile['display_name'] ?? (user?.isAnonymous == true ? l10n.guest : l10n.member)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    Text('${l10n.levelN(d.level)} · ${d.xp} XP'),
                    if (d.premium)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Row(children: [Icon(Icons.workspace_premium, color: AppColors.gold, size: 18), SizedBox(width: 4), Text('Premium')]),
                      ),
                  ]),
                ),
              ]),
              SectionTitle(l10n.statistics),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.1,
                children: [
                  _stat(context, '${d.streak}', l10n.currentStreak, Icons.local_fire_department, AppColors.flame),
                  _stat(context, '${d.longestStreak}', l10n.bestStreak, Icons.emoji_events, AppColors.gold),
                  _stat(context, '$totalAyahs', l10n.ayahs30d, Icons.menu_book, null),
                  _stat(context, '${d.hifzMemorized}', l10n.memorized, Icons.psychology, null),
                  _stat(context, '$goalDays', l10n.goalDays30d, Icons.check_circle, AppColors.success),
                  _stat(context, '${d.achievementsUnlocked}/${d.achievementsTotal}', l10n.achievements, Icons.military_tech, null),
                ],
              ),
              SectionTitle(l10n.achievements),
              achievements.when(
                loading: () => const SizedBox(height: 80, child: LoadingView()),
                error: (e, _) => ErrorView(error: e),
                data: (list) => Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final a in list)
                    Tooltip(
                      message: context.isArabic ? a.descriptionAr : a.descriptionEn,
                      child: SizedBox(
                        width: 96,
                        child: Column(children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: a.unlocked ? AppColors.gold.withValues(alpha: 0.25) : Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Icon(_achievementIcons[a.icon] ?? Icons.star,
                                color: a.unlocked ? AppColors.gold : Theme.of(context).disabledColor),
                          ),
                          const SizedBox(height: 4),
                          Text(context.isArabic ? a.nameAr : a.nameEn,
                              textAlign: TextAlign.center, maxLines: 2, style: Theme.of(context).textTheme.labelSmall),
                        ]),
                      ),
                    ),
                ]),
              ),
              SectionTitle(l10n.coachingHistory),
              recitations.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
                data: (rows) => rows.isEmpty
                    ? Text(l10n.noRecitationsYet)
                    : Column(children: [
                        for (final r in rows.take(10))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.mic_none),
                            title: Text(l10n.scoreN(((r['overall_score'] as num?) ?? 0).round())),
                            subtitle: Text(MaterialLocalizations.of(context).formatMediumDate(DateTime.parse(r['created_at'] as String))),
                            trailing: Text(r['mode'] == 'hifz' ? l10n.hifzTest : l10n.reading),
                          ),
                      ]),
              ),
              SectionTitle(l10n.inviteFriends),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(l10n.inviteBody),
                    const SizedBox(height: 8),
                    SelectableText(d.referralCode, textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: 4, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.share),
                      label: Text(l10n.shareInvite),
                      onPressed: () {
                        Analytics.track(Events.referralShared);
                        SharePlus.instance.share(ShareParams(text: l10n.inviteMessage(d.referralCode)));
                      },
                    ),
                    TextButton(onPressed: () => _enterCode(context, ref), child: Text(l10n.haveInviteCode)),
                  ]),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label, IconData icon, Color? color) => Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 22),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(label, textAlign: TextAlign.center, maxLines: 2, style: Theme.of(context).textTheme.labelSmall),
          ]),
        ),
      );

  Future<void> _enterCode(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final l10n = context.l10n;
    final code = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.haveInviteCode),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: l10n.inviteCode)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, controller.text), child: Text(l10n.apply)),
        ],
      ),
    );
    if (code == null || code.trim().isEmpty) return;
    final r = await ref.read(userRepoProvider).applyReferral(code);
    final ok = r['ok'] == true;
    if (ok) Analytics.track(Events.referralApplied);
    ref.invalidate(dashboardProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? l10n.inviteApplied : l10n.inviteInvalid)));
    }
  }
}
