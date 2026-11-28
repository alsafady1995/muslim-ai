import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/groups_repository.dart';
import 'call_widgets.dart';
import 'groups_common.dart';

/// One group: preset calls, the shared khatma and this week's achievements.
class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key, required this.groupId, this.initialTab});
  final String groupId;
  final String? initialTab;

  void _refreshAll(WidgetRef ref) {
    ref.invalidate(groupDetailProvider(groupId));
    ref.invalidate(groupCallsProvider(groupId));
    ref.invalidate(groupBoardProvider(groupId));
    ref.invalidate(pendingCallsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(groupDetailProvider(groupId));
    return detail.when(
      loading: () => Scaffold(appBar: AppBar(), body: const LoadingView()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: e, onRetry: () => ref.invalidate(groupDetailProvider(groupId))),
      ),
      data: (g) {
        final me = g.member(ref.read(groupsRepoProvider).uid);
        final isOwner = me?.isOwner ?? false;
        return DefaultTabController(
          length: 3,
          initialIndex: switch (initialTab) { 'khatma' => 1, 'board' => 2, _ => 0 },
          child: Scaffold(
            appBar: AppBar(
              title: Text(g.name),
              actions: [
                IconButton(
                  tooltip: l10n.inviteToGroup,
                  icon: const Icon(Icons.person_add_alt),
                  onPressed: () => SharePlus.instance.share(ShareParams(text: l10n.groupInviteMessage(g.name, g.inviteCode))),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) => _menu(context, ref, g, me, v),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'members', child: Text(l10n.groupMembers)),
                    PopupMenuItem(value: 'mute', child: Text(me?.muted == true ? l10n.unmuteGroup : l10n.muteGroup)),
                    PopupMenuItem(value: 'myname', child: Text(l10n.changeMyName)),
                    if (isOwner) PopupMenuItem(value: 'distribute', child: Text(l10n.distributeJuz)),
                    if (isOwner) PopupMenuItem(value: 'rename', child: Text(l10n.renameGroup)),
                    if (isOwner) PopupMenuItem(value: 'code', child: Text(l10n.newInviteCode)),
                    PopupMenuItem(value: 'leave', child: Text(l10n.leaveGroup)),
                  ],
                ),
              ],
              bottom: TabBar(tabs: [Tab(text: l10n.tabCalls), Tab(text: l10n.tabKhatma), Tab(text: l10n.tabBoard)]),
            ),
            body: TabBarView(children: [
              _CallsTab(group: g, onChanged: () => _refreshAll(ref)),
              _JuzTab(group: g, isOwner: isOwner),
              _BoardTab(groupId: g.id),
            ]),
          ),
        );
      },
    );
  }

  Future<String?> _textDialog(BuildContext context, String title, String initial, int max) {
    final c = TextEditingController(text: initial);
    final l10n = context.l10n;
    return showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, maxLength: max, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: Text(l10n.done)),
        ],
      ),
    );
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, GroupDetail g, GroupMember? me, String v) async {
    final repo = ref.read(groupsRepoProvider);
    final l10n = context.l10n;
    try {
      switch (v) {
        case 'members':
          await showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (_) => _MembersSheet(groupId: g.id),
          );
        case 'mute':
          await repo.setMuted(g.id, !(me?.muted ?? false));
        case 'myname':
          final name = await _textDialog(context, l10n.changeMyName, me?.displayName ?? '', 30);
          if (name == null || name.isEmpty) return;
          await repo.setDisplayName(g.id, name);
        case 'distribute':
          final n = await repo.distribute(g.id);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.distributedN(n))));
        case 'rename':
          final name = await _textDialog(context, l10n.renameGroup, g.name, 40);
          if (name == null || name.isEmpty) return;
          await repo.rename(g.id, name);
        case 'code':
          final code = await repo.newInviteCode(g.id);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.newInviteCodeDone(code))));
        case 'leave':
          final ok = await showDialog<bool>(
            context: context,
            builder: (d) => AlertDialog(
              title: Text(l10n.leaveGroupConfirm),
              actions: [
                TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l10n.cancel)),
                FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(l10n.leaveGroup)),
              ],
            ),
          );
          if (ok != true) return;
          await repo.leave(g.id);
          ref.invalidate(myGroupsProvider);
          ref.invalidate(pendingCallsProvider);
          if (context.mounted) context.pop();
          return;
      }
      _refreshAll(ref);
    } catch (e) {
      if (context.mounted) showCommunityError(context, e);
    }
  }
}

// ---------------------------------------------------------------------------
// Calls
// ---------------------------------------------------------------------------
class _CallsTab extends ConsumerWidget {
  const _CallsTab({required this.group, required this.onChanged});
  final GroupDetail group;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final calls = ref.watch(groupCallsProvider(group.id));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.campaign_outlined),
        label: Text(l10n.sendCall),
        onPressed: () async {
          if (await showSendCallSheet(context, ref, group.id)) onChanged();
        },
      ),
      body: calls.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(groupCallsProvider(group.id))),
        data: (list) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(groupCallsProvider(group.id)),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.callsEmpty, textAlign: TextAlign.center),
              ),
            for (final c in list) CallCard(call: c, memberCount: group.members.length, onChanged: onChanged),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Khatma (30 juz')
// ---------------------------------------------------------------------------
class _JuzTab extends ConsumerWidget {
  const _JuzTab({required this.group, required this.isOwner});
  final GroupDetail group;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final uid = ref.read(groupsRepoProvider).uid;
    final done = group.parts.where((p) => p.done).length;
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(groupDetailProvider(group.id)),
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          ProgressRing(value: done / 30, size: 64, child: Text('$done/30', style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.khatmaNumber(group.round), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (group.roundReason != null) Text(l10n.khatmaFor(reasonText(l10n, group.roundReason, group.roundDedication))),
              Text(group.khatmasCompleted > 0 ? l10n.khatmasCompletedN(group.khatmasCompleted) : l10n.juzTapHint,
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 4, children: [
          _legend(context, AppColors.success, l10n.juzDone),
          _legend(context, scheme.primary, l10n.juzMine),
          _legend(context, scheme.secondaryContainer, l10n.juzTaken),
          _legend(context, scheme.surfaceContainerHighest, l10n.juzOpen),
        ]),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
          children: [
            for (final p in group.parts)
              _JuzTile(
                part: p,
                mine: p.assignee == uid,
                who: group.member(p.done ? p.doneBy : p.assignee)?.displayName,
                onTap: () => _actions(context, ref, p, uid),
              ),
          ],
        ),
      ]),
    );
  }

  Widget _legend(BuildContext context, Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]);

  Future<void> _actions(BuildContext context, WidgetRef ref, KhatmaPart p, String? uid) async {
    final l10n = context.l10n;
    final repo = ref.read(groupsRepoProvider);
    final mine = p.assignee == uid;
    final open = p.assignee == null && !p.done;
    final options = <(String, IconData, String)>[
      if (!p.done && (open || mine)) ('complete', Icons.check_circle, l10n.juzMarkRead),
      if (open) ('claim', Icons.bookmark_add_outlined, l10n.juzClaim),
      if (!p.done && mine) ('release', Icons.bookmark_remove_outlined, l10n.juzRelease),
      if (!p.done && isOwner) ('assign', Icons.person_pin_outlined, l10n.juzAssign),
      if (!p.done && !mine && !open && isOwner) ('release', Icons.bookmark_remove_outlined, l10n.juzRelease),
      if (p.done && (p.doneBy == uid || isOwner)) ('undo', Icons.undo, l10n.juzUndo),
    ];
    if (options.isEmpty) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l10n.juzN(p.juz), style: Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final (key, icon, label) in options)
            ListTile(leading: Icon(icon), title: Text(label), onTap: () => Navigator.pop(c, key)),
        ]),
      ),
    );
    if (choice == null || !context.mounted) return;
    try {
      switch (choice) {
        case 'complete':
          final completed = await repo.complete(group.id, p.juz);
          HapticFeedback.mediumImpact();
          if (completed && context.mounted) {
            await showDialog<void>(
              context: context,
              builder: (c) => AlertDialog(
                icon: const Icon(Icons.auto_awesome, color: AppColors.gold, size: 40),
                title: Text(l10n.khatmaCompleteTitle),
                content: Text(l10n.khatmaCompleteBody, textAlign: TextAlign.center),
                actions: [FilledButton(onPressed: () => Navigator.pop(c), child: Text(l10n.done))],
              ),
            );
          }
        case 'claim':
          await repo.claim(group.id, p.juz);
        case 'release':
          await repo.release(group.id, p.juz);
        case 'undo':
          await repo.uncomplete(group.id, p.juz);
        case 'assign':
          if (!context.mounted) return;
          final to = await showModalBottomSheet<String>(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (c) => SafeArea(
              child: ListView(shrinkWrap: true, children: [
                for (final m in group.members)
                  ListTile(
                    leading: CircleAvatar(child: Text(m.displayName.characters.first)),
                    title: Text(m.displayName),
                    trailing: p.assignee == m.userId ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(c, m.userId),
                  ),
              ]),
            ),
          );
          if (to == null) return;
          await repo.assign(group.id, p.juz, to);
      }
    } catch (e) {
      if (context.mounted) showCommunityError(context, e);
    }
    ref.invalidate(groupDetailProvider(group.id));
    ref.invalidate(groupBoardProvider(group.id));
    ref.invalidate(groupCallsProvider(group.id));
  }
}

class _JuzTile extends StatelessWidget {
  const _JuzTile({required this.part, required this.mine, required this.who, required this.onTap});
  final KhatmaPart part;
  final bool mine;
  final String? who;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = part.done
        ? (AppColors.success, Colors.white)
        : mine
            ? (scheme.primary, scheme.onPrimary)
            : part.assignee != null
                ? (scheme.secondaryContainer, scheme.onSecondaryContainer)
                : (scheme.surfaceContainerHighest, scheme.onSurface);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (part.done) Icon(Icons.check, size: 14, color: fg),
            Text('${part.juz}', style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 18)),
            if (who != null) Text(who!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: 10)),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// This week's achievements
// ---------------------------------------------------------------------------
class _BoardTab extends ConsumerWidget {
  const _BoardTab({required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final board = ref.watch(groupBoardProvider(groupId));
    final uid = ref.read(groupsRepoProvider).uid;
    final theme = Theme.of(context);
    return board.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(groupBoardProvider(groupId))),
      data: (b) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(groupBoardProvider(groupId)),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (b.championName != null)
            Card(
              color: AppColors.gold.withValues(alpha: 0.15),
              child: ListTile(
                leading: const Icon(Icons.emoji_events, color: AppColors.gold),
                title: Text(l10n.boardChampion(b.championName!), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(l10n.boardRanked, style: theme.textTheme.bodySmall),
          ),
          const SizedBox(height: 8),
          for (final (i, r) in b.rows.indexed)
            Card(
              color: r.userId == uid ? theme.colorScheme.primaryContainer : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: i < 3 && r.xpWeek > 0 ? AppColors.gold.withValues(alpha: 0.25 + (2 - i) * 0.15) : null,
                  child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                title: Text(r.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${l10n.boardLine(r.ayahsWeek, r.adhkarWeek, r.hifzWeek)}\n'
                    '${l10n.boardLine2(r.streak, r.juzRound, r.callsWeek)}'),
                isThreeLine: true,
                trailing: Text(l10n.pointsN(r.xpWeek), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ),
          const SizedBox(height: 8),
          Text(l10n.boardNote, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Members (the admin can remove someone)
// ---------------------------------------------------------------------------
class _MembersSheet extends ConsumerWidget {
  const _MembersSheet({required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(groupDetailProvider(groupId));
    final uid = ref.read(groupsRepoProvider).uid;
    return SafeArea(
      child: detail.when(
        loading: () => const SizedBox(height: 200, child: LoadingView()),
        error: (e, _) => ErrorView(error: e),
        data: (g) {
          final isOwner = g.member(uid)?.isOwner ?? false;
          return ListView(shrinkWrap: true, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(l10n.groupMembersN(g.members.length),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            for (final m in g.members)
              ListTile(
                leading: CircleAvatar(child: Text(m.displayName.characters.first)),
                title: Text(m.displayName),
                subtitle: m.isOwner ? Text(l10n.groupOwner) : null,
                trailing: !isOwner || m.userId == uid
                    ? null
                    : IconButton(
                        tooltip: l10n.removeFromGroup,
                        icon: const Icon(Icons.person_remove_outlined),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (d) => AlertDialog(
                              title: Text(l10n.removeConfirm(m.displayName)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l10n.cancel)),
                                FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(l10n.removeFromGroup)),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          try {
                            await ref.read(groupsRepoProvider).removeMember(g.id, m.userId);
                            ref.invalidate(groupDetailProvider(g.id));
                            ref.invalidate(groupBoardProvider(g.id));
                          } catch (e) {
                            if (context.mounted) showCommunityError(context, e);
                          }
                        },
                      ),
              ),
          ]);
        },
      ),
    );
  }
}
