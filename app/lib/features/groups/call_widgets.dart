import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/groups_repository.dart';
import 'groups_common.dart';

/// One call: who sent it, the preset text, the group counter and the "done" action.
class CallCard extends ConsumerStatefulWidget {
  const CallCard({super.key, required this.call, this.memberCount, this.showGroup = false, this.onChanged});
  final GroupCall call;
  final int? memberCount;
  final bool showGroup;
  final VoidCallback? onChanged;

  @override
  ConsumerState<CallCard> createState() => _CallCardState();
}

class _CallCardState extends ConsumerState<CallCard> {
  late int _mine = widget.call.mine;
  late int _total = widget.call.total;
  late int _responders = widget.call.responders;
  bool _busy = false;

  @override
  void didUpdateWidget(CallCard old) {
    super.didUpdateWidget(old);
    if (old.call != widget.call) {
      _mine = widget.call.mine;
      _total = widget.call.total;
      _responders = widget.call.responders;
    }
  }

  Future<void> _respond(int count, {String? thenGo}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final firstTime = _mine == 0;
      final mine = await ref.read(groupsRepoProvider).respond(widget.call.id, count: count);
      HapticFeedback.lightImpact();
      Analytics.track('group_call_answered', {'kind': widget.call.kind});
      if (!mounted) return;
      setState(() {
        _total += mine - _mine;
        if (firstTime) _responders++;
        _mine = mine;
      });
      widget.onChanged?.call();
      if (thenGo != null && mounted) {
        // Inside the group screen, switch to its Khatma tab; elsewhere (Home) open the group.
        final tabs = DefaultTabController.maybeOf(context);
        if (tabs != null) {
          tabs.animateTo(1);
        } else {
          context.push(thenGo);
        }
      }
    } catch (e) {
      if (mounted) showCommunityError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = widget.call;
    final theme = Theme.of(context);
    final counter = isCounterCall(c.kind);
    final done = c.kind == 'khatma_done';
    final progress = switch (c.kind) {
      'salawat' => l10n.callSalawatTotal(_total),
      'istighfar' => l10n.callIstighfarTotal(_total),
      'khatma' => l10n.callKhatmaProgress(c.juzDone ?? 0),
      'khatma_done' => null,
      _ => widget.memberCount == null ? null : l10n.callRespondersN(_responders, widget.memberCount!),
    };
    return Card(
      color: done ? AppColors.gold.withValues(alpha: 0.15) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: (done ? AppColors.gold : theme.colorScheme.primary).withValues(alpha: 0.15),
              child: Icon(callIcon(c.kind), size: 20, color: done ? AppColors.gold : theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (widget.showGroup && c.groupName != null)
                  Text(c.groupName!, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(callText(l10n, c), style: const TextStyle(fontWeight: FontWeight.w600)),
                if (progress != null) ...[
                  const SizedBox(height: 4),
                  Text(progress, style: theme.textTheme.bodySmall),
                ],
                if (c.kind == 'khatma' && c.juzDone != null) ...[
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: (c.juzDone! / 30).clamp(0, 1), borderRadius: BorderRadius.circular(4)),
                ],
              ]),
            ),
          ]),
          if (!done && !c.open) ...[
            const SizedBox(height: 8),
            Text(l10n.callEnded, style: theme.textTheme.labelSmall),
          ] else if (!done) ...[
            const SizedBox(height: 10),
            if (counter)
              Row(children: [
                for (final n in const [10, 33, 100]) ...[
                  FilledButton.tonal(
                    onPressed: _busy ? null : () => _respond(n),
                    style: FilledButton.styleFrom(minimumSize: const Size(56, 40), visualDensity: VisualDensity.compact),
                    child: Text('+$n'),
                  ),
                  const SizedBox(width: 6),
                ],
                const Spacer(),
                if (_mine > 0) Text(l10n.callMyCount(_mine), style: const TextStyle(fontWeight: FontWeight.w700)),
              ])
            else if (c.kind == 'khatma')
              FilledButton.icon(
                onPressed: _busy ? null : () => _respond(1, thenGo: '/groups/${c.groupId}?tab=khatma'),
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(l10n.callPickJuz),
              )
            else
              Row(children: [
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
                  onPressed: _busy || _mine > 0 ? null : () => _respond(1),
                  child: Text(_mine > 0 ? l10n.callDoneMine : l10n.callDone),
                ),
                if (callDestination(c) != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
                    onPressed: () => context.push(callDestination(c)!),
                    child: Text(c.kind == 'adhkar_morning' ? l10n.morningAdhkar : l10n.eveningAdhkar),
                  ),
                ],
              ]),
          ],
        ]),
      ),
    );
  }
}

/// Bottom sheet to send a preset call. Returns true when a call was sent.
Future<bool> showSendCallSheet(BuildContext context, WidgetRef ref, String groupId) async {
  final l10n = context.l10n;
  final kind = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(l10n.sendCall, style: Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final k in callKinds)
          ListTile(
            leading: Icon(callIcon(k), color: Theme.of(c).colorScheme.primary),
            title: Text(callButtonLabel(l10n, k)),
            onTap: () => Navigator.pop(c, k),
          ),
      ]),
    ),
  );
  if (kind == null || !context.mounted) return false;
  String? reason;
  String? name;
  if (kind == 'khatma' || kind == 'dua') {
    final r = await _pickReason(context, kind);
    if (r == null || !context.mounted) return false;
    (reason, name) = r;
  }
  try {
    await ref.read(groupsRepoProvider).sendCall(groupId, kind, reason: reason, dedication: name);
    Analytics.track('group_call_sent', {'kind': kind, if (reason != null) 'reason': reason});
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.callSent)));
    return true;
  } catch (e) {
    if (context.mounted) showCommunityError(context, e);
    return false;
  }
}

/// Reason from the preset list plus an optional short name (not for a general intention).
Future<(String, String?)?> _pickReason(BuildContext context, String kind) {
  final l10n = context.l10n;
  final nameCtl = TextEditingController();
  var reason = 'general';
  return showModalBottomSheet<(String, String?)>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + MediaQuery.viewInsetsOf(c).bottom),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l10n.callReasonTitle, style: Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final r in callReasons)
                ChoiceChip(label: Text(reasonLabel(l10n, r)), selected: reason == r, onSelected: (_) => setState(() => reason = r)),
            ]),
            if (reason != 'general') ...[
              const SizedBox(height: 12),
              TextField(
                controller: nameCtl,
                maxLength: 30,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: l10n.dedicationName, hintText: l10n.dedicationHint),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '${callButtonLabel(l10n, kind)} · ${reasonText(l10n, reason, reason == 'general' ? null : nameCtl.text)}',
              style: Theme.of(c).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(c, (reason, reason == 'general' ? null : nameCtl.text.trim())),
              child: Text(l10n.callSend),
            ),
          ]),
        ),
      ),
    ),
  );
}
