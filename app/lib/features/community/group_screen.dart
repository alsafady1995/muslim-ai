import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/community_repository.dart';
import 'community_common.dart';

final groupDetailProvider =
    FutureProvider.autoDispose.family<KhatmaGroupDetail, String>((ref, id) => ref.watch(communityRepoProvider).group(id));
final leaderboardProvider =
    FutureProvider.autoDispose.family<List<LeaderboardRow>, String>((ref, id) => ref.watch(communityRepoProvider).leaderboard(id));

/// One khatma group: the 30 juz', messages and the in-group leaderboard.
class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key, required this.groupId});
  final String groupId;

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
        final me = g.member(ref.read(communityRepoProvider).uid);
        final isOwner = me?.isOwner ?? false;
        return DefaultTabController(
          length: 3,
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
                  onSelected: (v) => _menu(context, ref, g, v),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'members', child: Text(l10n.groupMembers)),
                    if (isOwner) PopupMenuItem(value: 'distribute', child: Text(l10n.distributeJuz)),
                    if (isOwner) PopupMenuItem(value: 'rename', child: Text(l10n.renameGroup)),
                    if (isOwner) PopupMenuItem(value: 'code', child: Text(l10n.newInviteCode)),
                    PopupMenuItem(value: 'leave', child: Text(l10n.leaveGroup)),
                  ],
                ),
              ],
              bottom: TabBar(tabs: [Tab(text: l10n.tabJuz), Tab(text: l10n.tabMessages), Tab(text: l10n.tabLeaderboard)]),
            ),
            body: TabBarView(children: [
              _JuzTab(group: g, isOwner: isOwner),
              _MessagesTab(group: g, isOwner: isOwner),
              _LeaderboardTab(groupId: g.id),
            ]),
          ),
        );
      },
    );
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, KhatmaGroupDetail g, String v) async {
    final repo = ref.read(communityRepoProvider);
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
        case 'distribute':
          final n = await repo.distribute(g.id);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.distributedN(n))));
        case 'rename':
          final c = TextEditingController(text: g.name);
          final name = await showDialog<String>(
            context: context,
            builder: (d) => AlertDialog(
              title: Text(l10n.renameGroup),
              content: TextField(controller: c, maxLength: 40, autofocus: true),
              actions: [
                TextButton(onPressed: () => Navigator.pop(d), child: Text(l10n.cancel)),
                FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: Text(l10n.done)),
              ],
            ),
          );
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
          if (context.mounted) context.pop();
          return;
      }
      ref.invalidate(groupDetailProvider(g.id));
    } catch (e) {
      if (context.mounted) showCommunityError(context, e);
    }
  }
}

// ---------------------------------------------------------------------------
// Juz'
// ---------------------------------------------------------------------------
class _JuzTab extends ConsumerWidget {
  const _JuzTab({required this.group, required this.isOwner});
  final KhatmaGroupDetail group;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final uid = ref.read(communityRepoProvider).uid;
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
              Text(group.khatmasCompleted > 0 ? l10n.khatmasCompletedN(group.khatmasCompleted) : l10n.juzTapHint),
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
    final repo = ref.read(communityRepoProvider);
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
      ref.invalidate(groupDetailProvider(group.id));
      ref.invalidate(leaderboardProvider(group.id));
    } catch (e) {
      if (context.mounted) showCommunityError(context, e);
      ref.invalidate(groupDetailProvider(group.id));
    }
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
            if (who != null)
              Text(who!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: 10)),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Messages
// ---------------------------------------------------------------------------
class _MessagesTab extends ConsumerStatefulWidget {
  const _MessagesTab({required this.group, required this.isOwner});
  final KhatmaGroupDetail group;
  final bool isOwner;
  @override
  ConsumerState<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends ConsumerState<_MessagesTab> with AutomaticKeepAliveClientMixin {
  final _input = TextEditingController();
  final _messages = <KhatmaMessage>[];
  Timer? _poll;
  bool _loading = true;
  bool _sending = false;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _reload();
    // Light polling while the chat is open; no realtime connection needed.
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _fetchNew());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final list = await ref.read(communityRepoProvider).messages(widget.group.id);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(list);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    }
  }

  Future<void> _fetchNew() async {
    if (_loading || _messages.isEmpty) return _reload();
    try {
      final list = await ref.read(communityRepoProvider).messages(widget.group.id, afterId: _messages.last.id);
      if (mounted && list.isNotEmpty) setState(() => _messages.addAll(list));
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(communityRepoProvider).post(widget.group.id, text);
      _input.clear();
      await _fetchNew();
    } catch (e) {
      if (mounted) showCommunityError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _cheer() async {
    final l10n = context.l10n;
    final key = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final k in cheerKeys) ActionChip(label: Text(cheerText(l10n, k)), onPressed: () => Navigator.pop(c, k)),
          ]),
        ),
      ),
    );
    if (key == null) return;
    try {
      await ref.read(communityRepoProvider).cheer(widget.group.id, key);
      await _fetchNew();
    } catch (e) {
      if (mounted) showCommunityError(context, e);
    }
  }

  Future<void> _messageActions(KhatmaMessage m) async {
    final l10n = context.l10n;
    final uid = ref.read(communityRepoProvider).uid;
    final mine = m.userId == uid;
    final name = widget.group.member(m.userId)?.displayName ?? l10n.formerMember;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (m.kind == 'text') ListTile(leading: const Icon(Icons.copy), title: Text(l10n.copy), onTap: () => Navigator.pop(c, 'copy')),
          if (mine || widget.isOwner)
            ListTile(leading: const Icon(Icons.delete_outline), title: Text(l10n.delete), onTap: () => Navigator.pop(c, 'delete')),
          if (!mine && m.userId != null) ...[
            ListTile(leading: const Icon(Icons.flag_outlined), title: Text(l10n.report), onTap: () => Navigator.pop(c, 'report')),
            ListTile(leading: const Icon(Icons.block), title: Text(l10n.blockName(name)), onTap: () => Navigator.pop(c, 'block')),
          ],
        ]),
      ),
    );
    if (choice == null || !mounted) return;
    void removeLocal() => setState(() => _messages.removeWhere((x) => x.id == m.id || (choice == 'block' && x.userId == m.userId)));
    switch (choice) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: m.body));
      case 'delete':
        try {
          await ref.read(communityRepoProvider).deleteMessage(m.id);
          removeLocal();
        } catch (e) {
          if (mounted) showCommunityError(context, e);
        }
      case 'report':
        // The reported message disappears for the reporter at once.
        await reportFlow(context, ref, messageId: m.id, userId: m.userId!, name: name, onDone: _reload);
        if (mounted) setState(() => _messages.removeWhere((x) => x.id == m.id));
      case 'block':
        await blockFlow(context, ref, userId: m.userId!, name: name, onDone: removeLocal);
    }
  }

  String _systemText(KhatmaMessage m) {
    final l10n = context.l10n;
    final name = widget.group.member(m.userId)?.displayName ?? l10n.formerMember;
    return switch (m.body) {
      'joined' => l10n.sysJoined(name),
      'juz_done' => l10n.sysJuzDone(name, (m.meta['juz'] as num?)?.toInt() ?? 0),
      'khatma_done' => l10n.sysKhatmaDone((m.meta['number'] as num?)?.toInt() ?? 1),
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final uid = ref.read(communityRepoProvider).uid;
    final scheme = Theme.of(context).colorScheme;
    return Column(children: [
      Expanded(
        child: _loading
            ? const LoadingView()
            : _error != null
                ? ErrorView(error: _error!, onRetry: _reload)
                : _messages.isEmpty
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.messagesEmpty, textAlign: TextAlign.center)))
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) {
                            final m = _messages[_messages.length - 1 - i];
                            if (m.kind == 'system') {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Center(
                                  child: Text(_systemText(m),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                                ),
                              );
                            }
                            final mine = m.userId == uid;
                            final name = widget.group.member(m.userId)?.displayName ?? l10n.formerMember;
                            final to = m.meta['to'] is String ? widget.group.member(m.meta['to'] as String)?.displayName : null;
                            final text = m.kind == 'cheer' ? (to == null ? cheerText(l10n, m.body) : '${cheerText(l10n, m.body)} · $to') : m.body;
                            return Align(
                              alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                              child: GestureDetector(
                                onLongPress: () => _messageActions(m),
                                child: Container(
                                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                                  margin: const EdgeInsets.symmetric(vertical: 3),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: m.kind == 'cheer'
                                        ? AppColors.gold.withValues(alpha: 0.18)
                                        : mine
                                            ? scheme.primaryContainer
                                            : scheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    if (!mine)
                                      Text(name, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                                    Row(mainAxisSize: MainAxisSize.min, children: [
                                      if (m.kind == 'cheer') const Padding(
                                        padding: EdgeInsetsDirectional.only(end: 6),
                                        child: Icon(Icons.favorite, size: 16, color: AppColors.gold),
                                      ),
                                      Flexible(child: Text(text)),
                                    ]),
                                    Text(TimeOfDay.fromDateTime(m.createdAt).format(context), style: Theme.of(context).textTheme.labelSmall),
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Row(children: [
            IconButton(tooltip: l10n.sendCheer, icon: const Icon(Icons.favorite_border, color: AppColors.gold), onPressed: _cheer),
            Expanded(
              child: TextField(
                controller: _input,
                maxLength: 500,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(hintText: l10n.messageHint, counterText: '', border: const OutlineInputBorder()),
              ),
            ),
            IconButton(
              icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
              onPressed: _send,
            ),
          ]),
        ),
      ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Leaderboard
// ---------------------------------------------------------------------------
class _LeaderboardTab extends ConsumerStatefulWidget {
  const _LeaderboardTab({required this.groupId});
  final String groupId;
  @override
  ConsumerState<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends ConsumerState<_LeaderboardTab> {
  bool _byWeek = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = ref.watch(leaderboardProvider(widget.groupId));
    final uid = ref.read(communityRepoProvider).uid;
    return rows.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(leaderboardProvider(widget.groupId))),
      data: (list) {
        final sorted = [...list]
          ..sort((a, b) => _byWeek
              ? b.ayahs7d.compareTo(a.ayahs7d)
              : (b.juzThisRound != a.juzThisRound ? b.juzThisRound.compareTo(a.juzThisRound) : b.juzTotal.compareTo(a.juzTotal)));
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(leaderboardProvider(widget.groupId)),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.leaderKhatma)),
                ButtonSegment(value: true, label: Text(l10n.leaderWeek)),
              ],
              selected: {_byWeek},
              onSelectionChanged: (s) => setState(() => _byWeek = s.first),
            ),
            const SizedBox(height: 8),
            Text(l10n.leaderboardNote, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            for (final (i, r) in sorted.indexed)
              Card(
                color: r.userId == uid ? Theme.of(context).colorScheme.primaryContainer : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: i < 3 ? AppColors.gold.withValues(alpha: 0.25 + (2 - i) * 0.15) : null,
                    child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  title: Text(r.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(_byWeek
                      ? l10n.leaderWeekLine(r.ayahs7d, r.streak)
                      : l10n.leaderKhatmaLine(r.juzThisRound, r.juzTotal)),
                  trailing: Text(_byWeek ? '${r.ayahs7d}' : '${r.juzThisRound}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ),
          ]),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Members (report / block / remove)
// ---------------------------------------------------------------------------
class _MembersSheet extends ConsumerWidget {
  const _MembersSheet({required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(groupDetailProvider(groupId));
    final uid = ref.read(communityRepoProvider).uid;
    return SafeArea(
      child: detail.when(
        loading: () => const SizedBox(height: 200, child: LoadingView()),
        error: (e, _) => ErrorView(error: e),
        data: (g) {
          final isOwner = g.member(uid)?.isOwner ?? false;
          return ListView(shrinkWrap: true, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(l10n.groupMembersN(g.members.length), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            for (final m in g.members)
              ListTile(
                leading: CircleAvatar(child: Text(m.displayName.characters.first)),
                title: Text(m.displayName),
                subtitle: m.isOwner ? Text(l10n.groupOwner) : null,
                trailing: m.userId == uid
                    ? null
                    : PopupMenuButton<String>(
                        onSelected: (v) async {
                          switch (v) {
                            case 'report':
                              await reportFlow(context, ref, groupId: g.id, userId: m.userId, name: m.displayName);
                            case 'block':
                              await blockFlow(context, ref, userId: m.userId, name: m.displayName);
                            case 'remove':
                              try {
                                await ref.read(communityRepoProvider).removeMember(g.id, m.userId);
                                ref.invalidate(groupDetailProvider(g.id));
                              } catch (e) {
                                if (context.mounted) showCommunityError(context, e);
                              }
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'report', child: Text(l10n.report)),
                          PopupMenuItem(value: 'block', child: Text(l10n.blockName(m.displayName))),
                          if (isOwner) PopupMenuItem(value: 'remove', child: Text(l10n.removeFromGroup)),
                        ],
                      ),
              ),
          ]);
        },
      ),
    );
  }
}
