import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics.dart';
import '../../core/providers.dart';
import '../../core/push.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'groups_common.dart';

/// My family / friends groups, plus create and join.
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
    final l10n = context.l10n;
    final name = await _myName(ref);
    if (!context.mounted) return;
    final r = await _twoFieldDialog(context,
        title: l10n.createGroup,
        label1: l10n.groupName,
        hint1: l10n.groupNameHint,
        label2: l10n.yourNameInGroup,
        initial2: name,
        action: l10n.createGroup);
    if (r == null || !context.mounted) return;
    try {
      final repo = ref.read(groupsRepoProvider);
      final id = await repo.create(r.$1, r.$2);
      Analytics.track('group_created');
      ref.invalidate(myGroupsProvider);
      GroupPush.enable(repo);
      if (context.mounted) context.push('/groups/$id');
    } catch (e) {
      if (context.mounted) showCommunityError(context, e);
    }
  }

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = await _myName(ref);
    if (!context.mounted) return;
    final r = await _twoFieldDialog(context,
        title: l10n.joinGroup,
        label1: l10n.inviteCode,
        code: true,
        label2: l10n.yourNameInGroup,
        initial2: name,
        action: l10n.joinGroup);
    if (r == null || !context.mounted) return;
    try {
      final repo = ref.read(groupsRepoProvider);
      final id = await repo.join(r.$1, r.$2);
      Analytics.track('group_joined');
      ref.invalidate(myGroupsProvider);
      GroupPush.enable(repo);
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
      appBar: AppBar(title: Text(l10n.groupsTitle)),
      body: groups.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myGroupsProvider)),
        data: (list) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(myGroupsProvider),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (list.isEmpty) ...[
              const SizedBox(height: 24),
              const Icon(Icons.diversity_3_outlined, size: 64, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(l10n.groupsEmptyTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(l10n.groupsEmptyBody, textAlign: TextAlign.center),
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
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (g.openCalls > 0) Badge(label: Text(l10n.openCallsN(g.openCalls))),
                    if (g.muted) const Padding(padding: EdgeInsetsDirectional.only(start: 4), child: Icon(Icons.notifications_off_outlined, size: 18)),
                    const Icon(Icons.chevron_right),
                  ]),
                  onTap: () async {
                    await context.push('/groups/${g.id}');
                    ref.invalidate(myGroupsProvider);
                    ref.invalidate(pendingCallsProvider);
                  },
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(icon: const Icon(Icons.add), label: Text(l10n.createGroup), onPressed: () => _create(context, ref)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
                icon: const Icon(Icons.group_add_outlined), label: Text(l10n.joinWithCode), onPressed: () => _join(context, ref)),
          ]),
        ),
      ),
    );
  }
}

/// Two-field dialog (group name / code + my name). Returns null when cancelled.
Future<(String, String)?> _twoFieldDialog(BuildContext context,
    {required String title,
    required String label1,
    String? hint1,
    String initial1 = '',
    required String label2,
    String initial2 = '',
    bool code = false,
    required String action}) {
  final a = TextEditingController(text: initial1);
  final b = TextEditingController(text: initial2);
  final l10n = context.l10n;
  return showDialog<(String, String)>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: a,
          autofocus: initial1.isEmpty,
          maxLength: code ? 8 : 40,
          textCapitalization: code ? TextCapitalization.characters : TextCapitalization.sentences,
          decoration: InputDecoration(labelText: label1, hintText: hint1, counterText: ''),
        ),
        const SizedBox(height: 8),
        TextField(controller: b, maxLength: 30, decoration: InputDecoration(labelText: label2, counterText: '')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () {
            if (a.text.trim().isEmpty || b.text.trim().isEmpty) return;
            Navigator.pop(c, (a.text.trim(), b.text.trim()));
          },
          child: Text(action),
        ),
      ],
    ),
  );
}
