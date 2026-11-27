import 'package:supabase_flutter/supabase_flutter.dart';

/// Preset encouragement phrases (rendered in the reader's language by the app).
const cheerKeys = ['barakallah', 'mashallah', 'keep_going', 'dua', 'jazakallah', 'together'];
const reportReasons = ['offensive', 'harassment', 'spam', 'inappropriate', 'other'];

class KhatmaGroupSummary {
  KhatmaGroupSummary(Map<String, dynamic> j)
      : id = j['id'] as String,
        name = j['name'] as String,
        round = (j['round'] as num).toInt(),
        khatmasCompleted = (j['khatmas_completed'] as num).toInt(),
        isOwner = j['role'] == 'owner',
        memberCount = (j['member_count'] as num).toInt(),
        doneCount = (j['done_count'] as num).toInt(),
        myJuz = [for (final v in (j['my_juz'] as List? ?? const [])) (v as num).toInt()];
  final String id;
  final String name;
  final int round;
  final int khatmasCompleted;
  final bool isOwner;
  final int memberCount;
  final int doneCount;
  final List<int> myJuz;
}

class KhatmaMember {
  KhatmaMember(Map<String, dynamic> j)
      : userId = j['user_id'] as String,
        displayName = j['display_name'] as String,
        isOwner = j['role'] == 'owner';
  final String userId;
  final String displayName;
  final bool isOwner;
}

class KhatmaPart {
  KhatmaPart(Map<String, dynamic> j)
      : juz = (j['juz'] as num).toInt(),
        assignee = j['assignee'] as String?,
        doneBy = j['done_by'] as String?,
        done = j['done_at'] != null;
  final int juz;
  final String? assignee;
  final String? doneBy;
  final bool done;
}

class KhatmaMessage {
  KhatmaMessage(Map<String, dynamic> j)
      : id = (j['id'] as num).toInt(),
        userId = j['user_id'] as String?,
        kind = j['kind'] as String,
        body = j['body'] as String,
        meta = ((j['meta'] as Map?) ?? const {}).cast<String, dynamic>(),
        createdAt = DateTime.parse(j['created_at'] as String).toLocal();
  final int id;
  final String? userId;
  final String kind; // text | cheer | system
  final String body;
  final Map<String, dynamic> meta;
  final DateTime createdAt;
}

class LeaderboardRow {
  LeaderboardRow(Map<String, dynamic> j)
      : userId = j['user_id'] as String,
        displayName = j['display_name'] as String,
        juzThisRound = (j['juz_this_round'] as num).toInt(),
        juzTotal = (j['juz_total'] as num).toInt(),
        ayahs7d = (j['ayahs_7d'] as num).toInt(),
        streak = (j['streak'] as num).toInt();
  final String userId;
  final String displayName;
  final int juzThisRound;
  final int juzTotal;
  final int ayahs7d;
  final int streak;
}

class KhatmaGroupDetail {
  KhatmaGroupDetail({required this.id, required this.name, required this.inviteCode, required this.round,
      required this.khatmasCompleted, required this.members, required this.parts});
  final String id;
  final String name;
  final String inviteCode;
  final int round;
  final int khatmasCompleted;
  final List<KhatmaMember> members;
  final List<KhatmaPart> parts;

  KhatmaMember? member(String? userId) {
    for (final m in members) {
      if (m.userId == userId) return m;
    }
    return null;
  }
}

/// A server refusal with a known reason (see `community:<reason>` in the khatma migration).
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

/// Khatma groups. Every write goes through a server RPC that checks membership, the
/// content filter, rate limits and bans; the client only reads through RLS.
class CommunityRepository {
  CommunityRepository(this._db);
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

  Future<bool> termsAccepted() async {
    final row = await _db.from('profiles').select('community_terms_at').eq('id', uid!).maybeSingle();
    return row?['community_terms_at'] != null;
  }

  Future<void> acceptTerms() => _exec('accept_community_terms');

  Future<List<KhatmaGroupSummary>> myGroups() async {
    final res = await _rpc<List>('get_my_khatma_groups');
    return [for (final g in res) KhatmaGroupSummary((g as Map).cast())];
  }

  Future<String> create(String name, String displayName) async {
    final res = await _rpc<Map>('create_khatma_group', {'p_name': name, 'p_display_name': displayName});
    return res['id'] as String;
  }

  Future<String> join(String code, String displayName) =>
      _rpc<String>('join_khatma_group', {'p_code': code, 'p_display_name': displayName});

  Future<void> leave(String groupId) => _exec('leave_khatma_group', {'p_group': groupId});

  Future<KhatmaGroupDetail> group(String groupId) async {
    final g = await _db.from('khatma_groups').select('id, name, invite_code, round, khatmas_completed').eq('id', groupId).single();
    final round = (g['round'] as num).toInt();
    final members = await _db.from('khatma_members').select('user_id, display_name, role').eq('group_id', groupId).order('joined_at');
    final parts = await _db
        .from('khatma_parts')
        .select('juz, assignee, done_by, done_at')
        .eq('group_id', groupId)
        .eq('round', round)
        .order('juz');
    return KhatmaGroupDetail(
      id: g['id'] as String,
      name: g['name'] as String,
      inviteCode: g['invite_code'] as String,
      round: round,
      khatmasCompleted: (g['khatmas_completed'] as num).toInt(),
      members: [for (final m in members) KhatmaMember(m)],
      parts: [for (final p in parts) KhatmaPart(p)],
    );
  }

  /// Newest last. With [afterId], only messages newer than it.
  Future<List<KhatmaMessage>> messages(String groupId, {int? afterId, int limit = 100}) async {
    var q = _db.from('khatma_messages').select('id, user_id, kind, body, meta, created_at').eq('group_id', groupId);
    if (afterId != null) q = q.gt('id', afterId);
    final rows = await q.order('id', ascending: false).limit(limit);
    return [for (final r in rows.reversed) KhatmaMessage(r)];
  }

  Future<List<LeaderboardRow>> leaderboard(String groupId) async {
    final res = await _rpc<List>('get_khatma_leaderboard', {'p_group': groupId});
    return [for (final r in res) LeaderboardRow((r as Map).cast())];
  }

  Future<void> claim(String g, int juz) => _exec('claim_khatma_juz', {'p_group': g, 'p_juz': juz});
  Future<void> release(String g, int juz) => _exec('release_khatma_juz', {'p_group': g, 'p_juz': juz});
  Future<void> assign(String g, int juz, String? userId) =>
      _exec('assign_khatma_juz', {'p_group': g, 'p_juz': juz, 'p_user': userId});
  Future<int> distribute(String g) async => ((await _rpc<num>('distribute_khatma_juz', {'p_group': g}))).toInt();
  Future<bool> complete(String g, int juz) async {
    final res = await _rpc<Map>('complete_khatma_juz', {'p_group': g, 'p_juz': juz});
    return res['khatma_completed'] == true;
  }

  Future<void> uncomplete(String g, int juz) => _exec('uncomplete_khatma_juz', {'p_group': g, 'p_juz': juz});

  Future<void> post(String g, String body) => _exec('post_khatma_message', {'p_group': g, 'p_body': body});
  Future<void> cheer(String g, String key, {String? to}) =>
      _exec('send_khatma_cheer', {'p_group': g, 'p_cheer': key, 'p_to': to});
  Future<void> deleteMessage(int id) => _exec('delete_khatma_message', {'p_message': id});

  Future<void> reportMessage(int messageId, String reason) =>
      _exec('report_content', {'p_reason': reason, 'p_message': messageId});
  Future<void> reportMember(String groupId, String userId, String reason) =>
      _exec('report_content', {'p_reason': reason, 'p_user': userId, 'p_group': groupId});

  Future<void> block(String userId) => _exec('block_user', {'p_user': userId});
  Future<void> unblock(String userId) => _exec('unblock_user', {'p_user': userId});
  Future<List<Map<String, dynamic>>> blocks() async =>
      [for (final b in await _rpc<List>('get_my_blocks')) (b as Map).cast<String, dynamic>()];

  Future<void> removeMember(String g, String userId, {bool ban = true}) =>
      _exec('remove_khatma_member', {'p_group': g, 'p_user': userId, 'p_ban': ban});
  Future<String> newInviteCode(String g) => _rpc<String>('regenerate_khatma_invite', {'p_group': g});
  Future<void> rename(String g, String name) => _exec('rename_khatma_group', {'p_group': g, 'p_name': name});
}
