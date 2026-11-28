import 'package:supabase_flutter/supabase_flutter.dart';

/// Preset calls a member can send to the group (no free text). The app renders each one in the
/// reader's language; the push function does the same on the server.
const callKinds = ['khatma', 'salawat', 'istighfar', 'adhkar_morning', 'adhkar_evening', 'dua'];

/// Counter calls add up a number (salawat, istighfar); the others are a single "done".
bool isCounterCall(String kind) => kind == 'salawat' || kind == 'istighfar';

/// Preset intentions for a khatma or a dua. Every one except 'general' can carry a short name.
const callReasons = ['general', 'deceased', 'sick', 'exam', 'travel', 'newborn', 'hardship', 'rizq'];

int _i(Object? v) => (v as num?)?.toInt() ?? 0;

class GroupSummary {
  GroupSummary(Map<String, dynamic> j)
      : id = j['id'] as String,
        name = j['name'] as String,
        round = _i(j['round']),
        khatmasCompleted = _i(j['khatmas_completed']),
        isOwner = j['role'] == 'owner',
        muted = j['muted'] == true,
        memberCount = _i(j['member_count']),
        doneCount = _i(j['done_count']),
        openCalls = _i(j['open_calls']),
        roundReason = j['round_reason'] as String?,
        roundDedication = j['round_dedication'] as String?,
        myJuz = [for (final v in (j['my_juz'] as List? ?? const [])) _i(v)];
  final String id;
  final String name;
  final int round;
  final int khatmasCompleted;
  final bool isOwner;
  final bool muted;
  final int memberCount;
  final int doneCount;
  final int openCalls;
  final String? roundReason;
  final String? roundDedication;
  final List<int> myJuz;
}

class GroupMember {
  GroupMember(Map<String, dynamic> j)
      : userId = j['user_id'] as String,
        displayName = j['display_name'] as String,
        isOwner = j['role'] == 'owner',
        muted = j['muted'] == true;
  final String userId;
  final String displayName;
  final bool isOwner;
  final bool muted;
}

class KhatmaPart {
  KhatmaPart(Map<String, dynamic> j)
      : juz = _i(j['juz']),
        assignee = j['assignee'] as String?,
        doneBy = j['done_by'] as String?,
        done = j['done_at'] != null;
  final int juz;
  final String? assignee;
  final String? doneBy;
  final bool done;
}

class GroupDetail {
  GroupDetail({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.round,
    required this.khatmasCompleted,
    required this.roundReason,
    required this.roundDedication,
    required this.members,
    required this.parts,
  });
  final String id;
  final String name;
  final String inviteCode;
  final int round;
  final int khatmasCompleted;
  final String? roundReason;
  final String? roundDedication;
  final List<GroupMember> members;
  final List<KhatmaPart> parts;

  GroupMember? member(String? userId) {
    for (final m in members) {
      if (m.userId == userId) return m;
    }
    return null;
  }
}

class GroupCall {
  GroupCall(Map<String, dynamic> j)
      : id = _i(j['id']),
        groupId = j['group_id'] as String,
        groupName = j['group_name'] as String?,
        senderId = j['sender_id'] as String?,
        senderName = j['sender_name'] as String?,
        kind = j['kind'] as String,
        reason = j['reason'] as String?,
        dedication = j['dedication'] as String?,
        round = (j['round'] as num?)?.toInt(),
        createdAt = DateTime.parse(j['created_at'] as String).toLocal(),
        open = j['open'] == true,
        total = _i(j['total']),
        responders = _i(j['responders']),
        mine = _i(j['mine']),
        juzDone = (j['juz_done'] as num?)?.toInt();
  final int id;
  final String groupId;
  final String? groupName;
  final String? senderId;
  final String? senderName;
  final String kind;
  final String? reason;
  final String? dedication;
  final int? round;
  final DateTime createdAt;
  final bool open;
  final int total;
  final int responders;
  final int mine;
  final int? juzDone;
}

class BoardRow {
  BoardRow(Map<String, dynamic> j)
      : userId = j['user_id'] as String,
        displayName = j['display_name'] as String,
        xpWeek = _i(j['xp_week']),
        ayahsWeek = _i(j['ayahs_week']),
        adhkarWeek = _i(j['adhkar_week']),
        hifzWeek = _i(j['hifz_week']),
        streak = _i(j['streak']),
        juzRound = _i(j['juz_round']),
        callsWeek = _i(j['calls_week']);
  final String userId;
  final String displayName;
  final int xpWeek;
  final int ayahsWeek;
  final int adhkarWeek;
  final int hifzWeek;
  final int streak;
  final int juzRound;
  final int callsWeek;
}

class GroupBoard {
  GroupBoard(Map<String, dynamic> j)
      : rows = [for (final r in (j['rows'] as List? ?? const [])) BoardRow((r as Map).cast())],
        championName = (j['last_week_champion'] as Map?)?['display_name'] as String?,
        resetsAt = DateTime.tryParse('${j['resets_at'] ?? ''}')?.toLocal();
  final List<BoardRow> rows;
  final String? championName;
  final DateTime? resetsAt;
}

/// A server refusal with a known reason (`community:<reason>` in the family groups migration).
class CommunityException implements Exception {
  CommunityException(this.reason);
  final String reason;
  @override
  String toString() => 'community:$reason';

  static Object wrap(Object e) {
    if (e is PostgrestException) {
      final m = RegExp(r'community:([a-z_]+)').firstMatch(e.message);
      if (m != null) return CommunityException(m.group(1)!);
    }
    return e;
  }
}

/// Family groups. Every write goes through a server RPC that checks membership, the name filter
/// and limits; the client only reads through RLS.
class GroupsRepository {
  GroupsRepository(this._db);
  final SupabaseClient _db;

  String? get uid => _db.auth.currentUser?.id;

  Future<void> _exec(String fn, [Map<String, dynamic>? params]) async {
    try {
      await _db.rpc(fn, params: params);
    } catch (e) {
      throw CommunityException.wrap(e);
    }
  }

  Future<T> _rpc<T>(String fn, [Map<String, dynamic>? params]) async {
    try {
      return await _db.rpc(fn, params: params) as T;
    } catch (e) {
      throw CommunityException.wrap(e);
    }
  }

  Future<List<GroupSummary>> myGroups() async {
    final res = await _rpc<List>('get_my_khatma_groups');
    return [for (final g in res) GroupSummary((g as Map).cast())];
  }

  Future<String> create(String name, String displayName) async {
    final res = await _rpc<Map>('create_khatma_group', {'p_name': name, 'p_display_name': displayName});
    return res['id'] as String;
  }

  Future<String> join(String code, String displayName) =>
      _rpc<String>('join_khatma_group', {'p_code': code, 'p_display_name': displayName});

  Future<void> leave(String groupId) => _exec('leave_khatma_group', {'p_group': groupId});

  Future<GroupDetail> group(String groupId) async {
    final g = await _db
        .from('khatma_groups')
        .select('id, name, invite_code, round, khatmas_completed, round_reason, round_dedication')
        .eq('id', groupId)
        .single();
    final round = _i(g['round']);
    final members =
        await _db.from('khatma_members').select('user_id, display_name, role, muted').eq('group_id', groupId).order('joined_at');
    final parts = await _db
        .from('khatma_parts')
        .select('juz, assignee, done_by, done_at')
        .eq('group_id', groupId)
        .eq('round', round)
        .order('juz');
    return GroupDetail(
      id: g['id'] as String,
      name: g['name'] as String,
      inviteCode: g['invite_code'] as String,
      round: round,
      khatmasCompleted: _i(g['khatmas_completed']),
      roundReason: g['round_reason'] as String?,
      roundDedication: g['round_dedication'] as String?,
      members: [for (final m in members) GroupMember(m)],
      parts: [for (final p in parts) KhatmaPart(p)],
    );
  }

  Future<GroupBoard> board(String groupId) async =>
      GroupBoard((await _rpc<Map>('get_group_board', {'p_group': groupId})).cast());

  Future<List<GroupCall>> calls(String groupId) async {
    final res = await _rpc<List>('get_group_calls', {'p_group': groupId});
    return [for (final c in res) GroupCall((c as Map).cast())];
  }

  Future<List<GroupCall>> pendingCalls() async {
    final res = await _rpc<List>('get_my_pending_calls');
    return [for (final c in res) GroupCall((c as Map).cast())];
  }

  /// Sends a preset call and asks the server to notify the other members. The push is
  /// best-effort: members also see the call when they open the app.
  Future<int> sendCall(String groupId, String kind, {String? reason, String? dedication}) async {
    final id = (await _rpc<num>('send_group_call',
            {'p_group': groupId, 'p_kind': kind, 'p_reason': reason, 'p_dedication': dedication}))
        .toInt();
    await announce(id);
    return id;
  }

  Future<void> announce(int callId) async {
    try {
      await _db.functions.invoke('group-push', body: {'call_id': callId});
    } catch (_) {}
  }

  /// Returns my new total for the call.
  Future<int> respond(int callId, {int count = 1}) async {
    final res = await _rpc<Map>('respond_group_call', {'p_call': callId, 'p_count': count});
    return _i(res['mine']);
  }

  Future<void> claim(String g, int juz) => _exec('claim_khatma_juz', {'p_group': g, 'p_juz': juz});
  Future<void> release(String g, int juz) => _exec('release_khatma_juz', {'p_group': g, 'p_juz': juz});
  Future<void> assign(String g, int juz, String? userId) =>
      _exec('assign_khatma_juz', {'p_group': g, 'p_juz': juz, 'p_user': userId});
  Future<int> distribute(String g) async => (await _rpc<num>('distribute_khatma_juz', {'p_group': g})).toInt();

  /// True when this juz' completed the khatma (the server then posts a "khatma done" call).
  Future<bool> complete(String g, int juz) async {
    final res = await _rpc<Map>('complete_khatma_juz', {'p_group': g, 'p_juz': juz});
    final call = (res['call_id'] as num?)?.toInt();
    if (call != null) await announce(call);
    return res['khatma_completed'] == true;
  }

  Future<void> uncomplete(String g, int juz) => _exec('uncomplete_khatma_juz', {'p_group': g, 'p_juz': juz});

  Future<void> setMuted(String g, bool muted) => _exec('set_group_muted', {'p_group': g, 'p_muted': muted});
  Future<void> removeMember(String g, String userId, {bool ban = true}) =>
      _exec('remove_khatma_member', {'p_group': g, 'p_user': userId, 'p_ban': ban});
  Future<String> newInviteCode(String g) => _rpc<String>('regenerate_khatma_invite', {'p_group': g});
  Future<void> rename(String g, String name) => _exec('rename_khatma_group', {'p_group': g, 'p_name': name});
  Future<void> setDisplayName(String g, String name) =>
      _exec('set_khatma_display_name', {'p_group': g, 'p_display_name': name});

  Future<void> registerPushToken(String token, String platform) =>
      _exec('register_push_token', {'p_token': token, 'p_platform': platform});
}
