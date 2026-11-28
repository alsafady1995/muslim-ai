import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../data/groups_repository.dart';
import '../../l10n/app_localizations.dart';

final groupsRepoProvider = Provider<GroupsRepository>((ref) => GroupsRepository(ref.watch(supabaseProvider)));

final myGroupsProvider = FutureProvider.autoDispose<List<GroupSummary>>((ref) {
  ref.watch(currentUserProvider);
  return ref.watch(groupsRepoProvider).myGroups();
});

/// Calls in all my groups that I haven't answered (home screen card).
final pendingCallsProvider = FutureProvider.autoDispose<List<GroupCall>>((ref) {
  ref.watch(currentUserProvider);
  return ref.watch(groupsRepoProvider).pendingCalls();
});

final groupDetailProvider =
    FutureProvider.autoDispose.family<GroupDetail, String>((ref, id) => ref.watch(groupsRepoProvider).group(id));
final groupCallsProvider =
    FutureProvider.autoDispose.family<List<GroupCall>, String>((ref, id) => ref.watch(groupsRepoProvider).calls(id));
final groupBoardProvider =
    FutureProvider.autoDispose.family<GroupBoard, String>((ref, id) => ref.watch(groupsRepoProvider).board(id));

String communityErrorText(AppLocalizations l10n, Object e) {
  if (e is! CommunityException) return l10n.errorGeneric;
  return switch (e.reason) {
    'offensive' => l10n.communityErrOffensive,
    'contact' => l10n.communityErrContact,
    'too_long' => l10n.communityErrTooLong,
    'empty' => l10n.communityErrEmpty,
    'slow_down' => l10n.communityErrSlowDown,
    'call_too_soon' => l10n.communityErrCallTooSoon,
    'khatma_in_progress' => l10n.communityErrKhatmaInProgress,
    'call_expired' => l10n.communityErrCallEnded,
    'invalid_code' => l10n.communityErrInvalidCode,
    'group_full' => l10n.communityErrGroupFull,
    'too_many_groups' => l10n.communityErrTooManyGroups,
    'juz_taken' => l10n.communityErrJuzTaken,
    'not_member' || 'not_owner' => l10n.communityErrNotAllowed,
    _ => l10n.errorGeneric,
  };
}

void showCommunityError(BuildContext context, Object e) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(communityErrorText(context.l10n, e))));
}

/// "for the soul of X", "for the sick", "with a general intention"...
String reasonText(AppLocalizations l10n, String? reason, String? name) {
  final n = (name ?? '').trim();
  final has = n.isNotEmpty;
  return switch (reason) {
    'deceased' => has ? l10n.reasonDeceased(n) : l10n.reasonDeceasedAny,
    'sick' => has ? l10n.reasonSick(n) : l10n.reasonSickAny,
    'exam' => has ? l10n.reasonExam(n) : l10n.reasonExamAny,
    'travel' => has ? l10n.reasonTravel(n) : l10n.reasonTravelAny,
    'newborn' => has ? l10n.reasonNewborn(n) : l10n.reasonNewbornAny,
    'hardship' => has ? l10n.reasonHardship(n) : l10n.reasonHardshipAny,
    'rizq' => has ? l10n.reasonRizq(n) : l10n.reasonRizqAny,
    _ => l10n.reasonGeneral,
  };
}

String reasonLabel(AppLocalizations l10n, String reason) => switch (reason) {
      'deceased' => l10n.reasonLabelDeceased,
      'sick' => l10n.reasonLabelSick,
      'exam' => l10n.reasonLabelExam,
      'travel' => l10n.reasonLabelTravel,
      'newborn' => l10n.reasonLabelNewborn,
      'hardship' => l10n.reasonLabelHardship,
      'rizq' => l10n.reasonLabelRizq,
      _ => l10n.reasonLabelGeneral,
    };

String callButtonLabel(AppLocalizations l10n, String kind) => switch (kind) {
      'khatma' => l10n.callKhatma,
      'salawat' => l10n.callSalawat,
      'istighfar' => l10n.callIstighfar,
      'adhkar_morning' => l10n.callAdhkarMorning,
      'adhkar_evening' => l10n.callAdhkarEvening,
      _ => l10n.callDua,
    };

IconData callIcon(String kind) => switch (kind) {
      'khatma' || 'khatma_done' => Icons.menu_book,
      'salawat' => Icons.favorite,
      'istighfar' => Icons.spa_outlined,
      'adhkar_morning' => Icons.wb_sunny_outlined,
      'adhkar_evening' => Icons.nights_stay_outlined,
      _ => Icons.volunteer_activism_outlined,
    };

/// The line shown for a call in the group feed and on Home.
String callText(AppLocalizations l10n, GroupCall c) {
  final name = c.senderName ?? l10n.formerMember;
  final reason = reasonText(l10n, c.reason, c.dedication);
  return switch (c.kind) {
    'khatma' => l10n.feedKhatma(name, reason),
    'salawat' => l10n.feedSalawat(name),
    'istighfar' => l10n.feedIstighfar(name),
    'adhkar_morning' => l10n.feedAdhkarMorning(name),
    'adhkar_evening' => l10n.feedAdhkarEvening(name),
    'dua' => l10n.feedDua(name, reason),
    _ => l10n.feedKhatmaDone(reason),
  };
}

/// Where "Done" on a call takes you (adhkar → the adhkar screen, khatma → the juz' grid).
String? callDestination(GroupCall c) => switch (c.kind) {
      'adhkar_morning' => '/adhkar/1',
      'adhkar_evening' => '/adhkar/2',
      'khatma' => '/groups/${c.groupId}?tab=khatma',
      _ => null,
    };
