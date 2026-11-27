import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/community_repository.dart';
import 'community_common.dart';

final myGroupsProvider =
    FutureProvider.autoDispose<List<KhatmaGroupSummary>>((ref) => ref.watch(communityRepoProvider).myGroups());

/// Khatma groups I belong to, plus create / join.
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  Future<String> _myName(WidgetRef ref) async {
    try {
      return ((await ref.read(userRepoProvider).profile())['display_name'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    if (!await ensureCommunityTerms(context, ref) || !context.mounted) return;
    final l10n = context.l10n;
    final name = await _myName(ref);
    if (!context.mounted) return;
    final r = await twoFieldDialog(context,
        title: l10n.createGroup, label1: l10n.groupName, label2: l10n.yourNameInGroup, initial2: name);
    if (r == null || !context.mounted) return;
    try {
      final id = await ref.read(communityRepoProvider).create(r.$1, r.$2);
      Analytics.track('khatma_group_created');
      ref.invalidate(myGroupsProvider);
      if (context.mounted) context.push('/groups/$id');
    } catch (e) {
      if (context.mounted) showCommunityError(context, e);
    }
  }

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    if (!await ensureCommunityTerms(context, ref) || !context.mounted) return;
    final l10n = context.l10n;
    final name = await _myName(ref);
    if (!context.mounted) return;
    final controller = TextEditingController();
    final nameController = TextEditingController(text: name);
    final r = await showDialog<(String, String)>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.joinGroup),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: controller,
            autofocus: true,
            maxLength: 8,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l10n.inviteCode, counterText: ''),
          ),
          const SizedBox(height: 8),
          TextField(controller: nameController, maxLength: 30, decoration: InputDecoration(labelText: l10n.yourNameInGroup, counterText: '')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty || nameController.text.trim().isEmpty) return;
              Navigator.pop(c, (controller.text.trim(), nameController.text.trim()));
            },
            child: Text(l10n.joinGroup),
          ),
        ],
      ),
    );
    if (r == null || !context.mounted) return;
    try {
      final id = await ref.read(communityRepoProvider).join(r.$1, r.$2);
      Analytics.track('khatma_group_joined');
      ref.invalidate(myGroupsProvider);
      if (context.mounted) context.push('/groups/$id');
    } catch (e) {
      if (context.mounted) showCommunityError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final groups = ref.watch(myGroupsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.khatmaGroups)),
      body: groups.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myGroupsProvider)),
        data: (list) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(myGroupsProvider),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (list.isEmpty) ...[
              const SizedBox(height: 24),
              const Icon(Icons.groups_2_outlined, size: 64, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(l10n.khatmaGroupsEmptyTitle,
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(l10n.khatmaGroupsEmptyBody, textAlign: TextAlign.center),
              const SizedBox(height: 24),
            ],
            for (final g in list)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: ProgressRing(
                    value: g.doneCount / 30,
                    size: 48,
                    child: Text('${g.doneCount}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text([
                    l10n.groupMembersN(g.memberCount),
                    if (g.khatmasCompleted > 0) l10n.khatmasCompletedN(g.khatmasCompleted),
                    if (g.myJuz.isNotEmpty) l10n.myJuzList(g.myJuz.join('، ')),
                  ].join(' · ')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await context.push('/groups/${g.id}');
                    ref.invalidate(myGroupsProvider);
                  },
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(icon: const Icon(Icons.add), label: Text(l10n.createGroup), onPressed: () => _create(context, ref)),
            const SizedBox(height: 8),
            OutlinedButton.icon(icon: const Icon(Icons.group_add_outlined), label: Text(l10n.joinWithCode), onPressed: () => _join(context, ref)),
          ]),
        ),
      ),
    );
  }
}
