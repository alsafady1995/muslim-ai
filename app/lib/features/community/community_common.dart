import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../data/community_repository.dart';
import '../../l10n/app_localizations.dart';

final communityRepoProvider = Provider<CommunityRepository>((ref) => CommunityRepository(ref.watch(supabaseProvider)));

String communityErrorText(AppLocalizations l10n, Object e) {
  if (e is! CommunityException) return l10n.errorGeneric;
  return switch (e.reason) {
    'offensive' => l10n.communityErrOffensive,
    'contact' => l10n.communityErrContact,
    'too_long' => l10n.communityErrTooLong,
    'empty' => l10n.communityErrEmpty,
    'slow_down' => l10n.communityErrSlowDown,
    'invalid_code' => l10n.communityErrInvalidCode,
    'group_full' => l10n.communityErrGroupFull,
    'too_many_groups' => l10n.communityErrTooManyGroups,
    'juz_taken' => l10n.communityErrJuzTaken,
    'banned' => l10n.communityErrBanned,
    'not_member' || 'not_owner' => l10n.communityErrNotAllowed,
    _ => l10n.errorGeneric,
  };
}

void showCommunityError(BuildContext context, Object e) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(communityErrorText(context.l10n, e))));
}

String cheerText(AppLocalizations l10n, String key) => switch (key) {
      'barakallah' => l10n.cheerBarakallah,
      'mashallah' => l10n.cheerMashallah,
      'keep_going' => l10n.cheerKeepGoing,
      'dua' => l10n.cheerDua,
      'jazakallah' => l10n.cheerJazakallah,
      'together' => l10n.cheerTogether,
      _ => key,
    };

String reportReasonText(AppLocalizations l10n, String key) => switch (key) {
      'offensive' => l10n.reportOffensive,
      'harassment' => l10n.reportHarassment,
      'spam' => l10n.reportSpam,
      'inappropriate' => l10n.reportInappropriate,
      _ => l10n.reportOther,
    };

/// Community rules (App Store guideline 1.2): must be accepted once before creating or joining a
/// group. Returns true when the user has accepted (now or before).
Future<bool> ensureCommunityTerms(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(communityRepoProvider);
  try {
    if (await repo.termsAccepted()) return true;
  } catch (_) {}
  if (!context.mounted) return false;
  final l10n = context.l10n;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l10n.communityRulesTitle, style: Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final rule in [l10n.communityRule1, l10n.communityRule2, l10n.communityRule3, l10n.communityRule4])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.check_circle_outline, size: 18)),
                const SizedBox(width: 8),
                Expanded(child: Text(rule)),
              ]),
            ),
          TextButton(onPressed: () => launchUrl(Uri.parse(AppConfig.termsUrl)), child: Text(l10n.terms)),
          const SizedBox(height: 8),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l10n.communityAgree)),
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.cancel)),
        ]),
      ),
    ),
  );
  if (ok != true) return false;
  try {
    await repo.acceptTerms();
    return true;
  } catch (e) {
    if (context.mounted) showCommunityError(context, e);
    return false;
  }
}

/// Asks for a report reason. Returns null when cancelled.
Future<String?> pickReportReason(BuildContext context) {
  final l10n = context.l10n;
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(l10n.reportWhy, style: Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),
        for (final r in reportReasons) ListTile(title: Text(reportReasonText(l10n, r)), onTap: () => Navigator.pop(c, r)),
      ]),
    ),
  );
}

/// Report a message or a member, then offer to block them too.
Future<void> reportFlow(BuildContext context, WidgetRef ref,
    {int? messageId, String? groupId, required String userId, required String name, VoidCallback? onDone}) async {
  final reason = await pickReportReason(context);
  if (reason == null || !context.mounted) return;
  final repo = ref.read(communityRepoProvider);
  final l10n = context.l10n;
  try {
    if (messageId != null) {
      await repo.reportMessage(messageId, reason);
    } else {
      await repo.reportMember(groupId!, userId, reason);
    }
  } catch (e) {
    if (context.mounted) showCommunityError(context, e);
    return;
  }
  if (!context.mounted) return;
  final block = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(l10n.reportThanks),
      content: Text(l10n.reportAlsoBlock(name)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.notNow)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l10n.block)),
      ],
    ),
  );
  if (block == true) {
    try {
      await repo.block(userId);
    } catch (e) {
      if (context.mounted) showCommunityError(context, e);
    }
  }
  onDone?.call();
}

Future<void> blockFlow(BuildContext context, WidgetRef ref, {required String userId, required String name, VoidCallback? onDone}) async {
  final l10n = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(l10n.blockTitle(name)),
      content: Text(l10n.blockBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l10n.block)),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await ref.read(communityRepoProvider).block(userId);
    onDone?.call();
  } catch (e) {
    if (context.mounted) showCommunityError(context, e);
  }
}

/// Two-field dialog (e.g. group name + my name). Returns null when cancelled.
Future<(String, String)?> twoFieldDialog(BuildContext context,
    {required String title, required String label1, required String label2, String initial2 = '', bool code = false}) {
  final a = TextEditingController();
  final b = TextEditingController(text: initial2);
  final l10n = context.l10n;
  return showDialog<(String, String)>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: a,
          autofocus: true,
          maxLength: code ? 8 : 40,
          textCapitalization: code ? TextCapitalization.characters : TextCapitalization.sentences,
          decoration: InputDecoration(labelText: label1, counterText: ''),
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
          child: Text(l10n.continueLabel),
        ),
      ],
    ),
  );
}
