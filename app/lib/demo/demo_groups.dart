import 'dart:math';

import '../data/groups_repository.dart';
import 'demo_store.dart';

/// Family groups in the web preview: one sample family group kept in memory, so every screen
/// (calls, khatma, weekly board) can be tried without a backend. Push is not simulated.
class DemoGroupsRepository extends GroupsRepository {
  DemoGroupsRepository(super.db);

  static const _me = 'demo-me';
  static final _rnd = Random(7);
  static int _seq = 100;
  static final Map<String, _G> _groups = {};
  static bool _seeded = false;

  @override
  String? get uid => _me;

  String get _myName => (DemoStore.instance.profile['display_name'] as String?)?.trim().isNotEmpty == true
      ? DemoStore.instance.profile['display_name'] as String
      : 'أنا';

  void _seed() {
    if (_seeded) return;
    _seeded = true;
    final g = _G('demo-family', 'العيلة', 'FAM12345');
    g.members.addAll([
      _M('u-abu', 'أبو أحمد', owner: true),
      _M('u-umm', 'أم أحمد'),
      _M(_me, _myName),
      _M('u-sara', 'سارة'),
      _M('u-omar', 'عمر'),
    ]);
    g.reason = 'deceased';
    g.dedication = 'جدي أبو محمد';
    final others = ['u-abu', 'u-umm', 'u-sara', 'u-omar'];
    for (var j = 1; j <= 30; j++) {
      final p = _P(j);
      if (j <= 11) {
        p.assignee = others[j % 4];
        p.doneBy = p.assignee;
      } else if (j <= 18) {
        p.assignee = others[j % 4];
      }
      g.parts.add(p);
    }
    final now = DateTime.now();
    g.calls.addAll([
      _C(++_seq, 'u-umm', 'salawat', null, null, now.subtract(const Duration(minutes: 40)))..responses.addAll({'u-umm': 300, 'u-sara': 100}),
      _C(++_seq, 'u-abu', 'khatma', 'deceased', 'جدي أبو محمد', now.subtract(const Duration(days: 2)), round: 1)
        ..responses.addAll({'u-abu': 1, 'u-umm': 1, 'u-sara': 1, 'u-omar': 1}),
      _C(++_seq, 'u-sara', 'adhkar_morning', null, null, now.subtract(const Duration(hours: 30))),
    ]);
    g.board = {'u-abu': [180, 60, 4, 0, 6], 'u-umm': [240, 85, 6, 12, 9], 'u-sara': [150, 40, 3, 20, 4], 'u-omar': [60, 15, 1, 0, 2]};
    _groups[g.id] = g;
  }

  _G _g(String id) {
    _seed();
    final g = _groups[id];
    if (g == null || !g.has(_me)) throw CommunityException('not_member');
    return g;
  }

  Map<String, dynamic> _callJson(_G g, _C c) => {
        'id': c.id,
        'group_id': g.id,
        'group_name': g.name,
        'sender_id': c.sender,
        'sender_name': g.member(c.sender)?.name,
        'kind': c.kind,
        'reason': c.reason,
        'dedication': c.dedication,
        'round': c.round,
        'created_at': c.at.toUtc().toIso8601String(),
        'open': c.kind == 'khatma' ? c.round == g.round : DateTime.now().difference(c.at).inHours < 24,
        'total': c.responses.values.fold<int>(0, (a, b) => a + b),
        'responders': c.responses.length,
        'mine': c.responses[_me] ?? 0,
        'juz_done': c.kind == 'khatma' ? (c.round == g.round ? g.parts.where((p) => p.doneBy != null).length : 30) : null,
      };

  @override
  Future<List<GroupSummary>> myGroups() async {
    _seed();
    return [
      for (final g in _groups.values.where((g) => g.has(_me)))
        GroupSummary({
          'id': g.id,
          'name': g.name,
          'round': g.round,
          'khatmas_completed': g.round - 1,
          'role': g.member(_me)!.owner ? 'owner' : 'member',
          'muted': g.member(_me)!.muted,
          'member_count': g.members.length,
          'done_count': g.parts.where((p) => p.doneBy != null).length,
          'open_calls': (await pendingCalls()).where((c) => c.groupId == g.id).length,
          'my_juz': [for (final p in g.parts) if (p.assignee == _me && p.doneBy == null) p.juz],
        }),
    ];
  }

  @override
  Future<String> create(String name, String displayName) async {
    _seed();
    final id = 'demo-${++_seq}';
    final code = List.generate(8, (_) => 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'[_rnd.nextInt(32)]).join();
    final g = _G(id, name.trim(), code)..members.add(_M(_me, displayName.trim(), owner: true));
    for (var j = 1; j <= 30; j++) {
      g.parts.add(_P(j));
    }
    _groups[id] = g;
    return id;
  }

  @override
  Future<String> join(String code, String displayName) async {
    _seed();
    for (final g in _groups.values) {
      if (g.code == code.trim().toUpperCase()) {
        if (!g.has(_me)) g.members.add(_M(_me, displayName.trim()));
        return g.id;
      }
    }
    throw CommunityException('invalid_code');
  }

  @override
  Future<void> leave(String groupId) async => _g(groupId).members.removeWhere((m) => m.id == _me);

  @override
  Future<GroupDetail> group(String groupId) async {
    final g = _g(groupId);
    return GroupDetail(
      id: g.id,
      name: g.name,
      inviteCode: g.code,
      round: g.round,
      khatmasCompleted: g.round - 1,
      roundReason: g.reason,
      roundDedication: g.dedication,
      members: [
        for (final m in g.members)
          GroupMember({'user_id': m.id, 'display_name': m.name, 'role': m.owner ? 'owner' : 'member', 'muted': m.muted}),
      ],
      parts: [
        for (final p in g.parts)
          KhatmaPart({'juz': p.juz, 'assignee': p.assignee, 'done_by': p.doneBy, 'done_at': p.doneBy == null ? null : 'x'}),
      ],
    );
  }

  @override
  Future<GroupBoard> board(String groupId) async {
    final g = _g(groupId);
    final p = DemoStore.instance.profile;
    final rows = [
      for (final m in g.members)
        () {
          final s = m.id == _me
              ? [min((p['xp'] as int? ?? 0), 400), 0, 0, 0, p['current_streak'] as int? ?? 0]
              : (g.board[m.id] ?? [0, 0, 0, 0, 0]);
          return {
            'user_id': m.id,
            'display_name': m.name,
            'xp_week': s[0],
            'ayahs_week': s[1],
            'adhkar_week': s[2],
            'hifz_week': s[3],
            'streak': s[4],
            'juz_round': g.parts.where((x) => x.doneBy == m.id).length,
            'calls_week': g.calls.where((c) => c.responses.containsKey(m.id)).length,
          };
        }(),
    ]..sort((a, b) => (b['xp_week'] as int).compareTo(a['xp_week'] as int));
    return GroupBoard({
      'rows': rows,
      'last_week_champion': g.id == 'demo-family' ? {'display_name': 'أم أحمد'} : null,
    });
  }

  @override
  Future<List<GroupCall>> calls(String groupId) async {
    final g = _g(groupId);
    final list = [...g.calls]..sort((a, b) => b.at.compareTo(a.at));
    return [for (final c in list) GroupCall(_callJson(g, c))];
  }

  @override
  Future<List<GroupCall>> pendingCalls() async {
    _seed();
    return [
      for (final g in _groups.values.where((g) => g.has(_me)))
        for (final c in g.calls)
          if (c.sender != _me && c.kind != 'khatma_done' && !c.responses.containsKey(_me))
            if (_callJson(g, c)['open'] == true) GroupCall(_callJson(g, c)),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<int> sendCall(String groupId, String kind, {String? reason, String? dedication}) async {
    final g = _g(groupId);
    if (g.calls.any((c) => c.kind == kind && DateTime.now().difference(c.at).inMinutes < 30)) {
      throw CommunityException('call_too_soon');
    }
    final withReason = kind == 'khatma' || kind == 'dua';
    final r = withReason ? (reason ?? 'general') : null;
    final d = r != null && r != 'general' && (dedication ?? '').trim().isNotEmpty ? dedication!.trim() : null;
    if (kind == 'khatma') {
      if (g.parts.any((p) => p.doneBy != null)) throw CommunityException('khatma_in_progress');
      g.reason = r;
      g.dedication = d;
    }
    final c = _C(++_seq, _me, kind, r, d, DateTime.now(), round: kind == 'khatma' ? g.round : null);
    g.calls.add(c);
    return c.id;
  }

  @override
  Future<void> announce(int callId) async {}

  @override
  Future<int> respond(int callId, {int count = 1}) async {
    _seed();
    for (final g in _groups.values) {
      for (final c in g.calls) {
        if (c.id != callId) continue;
        if (isCounterCall(c.kind)) {
          c.responses[_me] = (c.responses[_me] ?? 0) + count.clamp(1, 1000);
        } else {
          c.responses[_me] = 1;
        }
        return c.responses[_me]!;
      }
    }
    throw CommunityException('not_found');
  }

  _P _part(String g, int juz) => _g(g).parts.firstWhere((p) => p.juz == juz);

  @override
  Future<void> claim(String g, int juz) async {
    final p = _part(g, juz);
    if (p.doneBy != null || (p.assignee != null && p.assignee != _me)) throw CommunityException('juz_taken');
    p.assignee = _me;
  }

  @override
  Future<void> release(String g, int juz) async => _part(g, juz).assignee = null;

  @override
  Future<void> assign(String g, int juz, String? userId) async => _part(g, juz).assignee = userId;

  @override
  Future<int> distribute(String g) async {
    final grp = _g(g);
    var i = 0;
    var n = 0;
    for (final p in grp.parts.where((p) => p.assignee == null && p.doneBy == null)) {
      p.assignee = grp.members[i++ % grp.members.length].id;
      n++;
    }
    return n;
  }

  @override
  Future<bool> complete(String g, int juz) async {
    final grp = _g(g);
    final p = _part(g, juz);
    if (p.assignee != null && p.assignee != _me) throw CommunityException('juz_taken');
    p.assignee = _me;
    p.doneBy = _me;
    if (grp.parts.every((x) => x.doneBy != null)) {
      grp.calls.add(_C(++_seq, null, 'khatma_done', grp.reason, grp.dedication, DateTime.now(), round: grp.round));
      grp.round++;
      grp.reason = null;
      grp.dedication = null;
      for (final x in grp.parts) {
        x.assignee = null;
        x.doneBy = null;
      }
      return true;
    }
    return false;
  }

  @override
  Future<void> uncomplete(String g, int juz) async => _part(g, juz).doneBy = null;

  @override
  Future<void> setMuted(String g, bool muted) async => _g(g).member(_me)!.muted = muted;

  @override
  Future<void> removeMember(String g, String userId, {bool ban = true}) async =>
      _g(g).members.removeWhere((m) => m.id == userId);

  @override
  Future<String> newInviteCode(String g) async =>
      _g(g).code = List.generate(8, (_) => 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'[_rnd.nextInt(32)]).join();

  @override
  Future<void> rename(String g, String name) async => _g(g).name = name.trim();

  @override
  Future<void> setDisplayName(String g, String name) async => _g(g).member(_me)!.name = name.trim();

  @override
  Future<void> registerPushToken(String token, String platform) async {}
}

class _G {
  _G(this.id, this.name, this.code);
  final String id;
  String name;
  String code;
  int round = 1;
  String? reason;
  String? dedication;
  final members = <_M>[];
  final parts = <_P>[];
  final calls = <_C>[];
  Map<String, List<int>> board = {};
  bool has(String user) => members.any((m) => m.id == user);
  _M? member(String? user) {
    for (final m in members) {
      if (m.id == user) return m;
    }
    return null;
  }
}

class _M {
  _M(this.id, this.name, {this.owner = false});
  final String id;
  String name;
  final bool owner;
  bool muted = false;
}

class _P {
  _P(this.juz);
  final int juz;
  String? assignee;
  String? doneBy;
}

class _C {
  _C(this.id, this.sender, this.kind, this.reason, this.dedication, this.at, {this.round});
  final int id;
  final String? sender;
  final String kind;
  final String? reason;
  final String? dedication;
  final DateTime at;
  final int? round;
  final responses = <String, int>{};
}
