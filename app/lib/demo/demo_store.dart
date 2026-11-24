import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// In-browser stand-in for the Supabase database, used only by the web preview
/// (`--dart-define=DEMO_MODE=true`). It mirrors the server rules closely enough
/// to try every screen (XP, levels, streaks, goals, achievements, SM-2 hifz),
/// and keeps the user's state in local storage.
///
/// Quran text comes from `demo-data/quran.json`, which the web-preview workflow
/// downloads at build time. Reference data (adhkar, reciters, achievements)
/// comes from `assets/demo/reference.json`, generated from the SQL migration.
class DemoStore {
  DemoStore._(this._prefs, this.reference, this._state);

  static const _key = 'demo_state_v1';
  static DemoStore? _instance;
  static DemoStore get instance => _instance!;

  final SharedPreferences _prefs;
  final Map<String, dynamic> reference;
  final Map<String, dynamic> _state;

  static Future<DemoStore> init(SharedPreferences prefs) async {
    final ref = jsonDecode(await rootBundle.loadString('assets/demo/reference.json')) as Map<String, dynamic>;
    Map<String, dynamic> state;
    try {
      state = (jsonDecode(prefs.getString(_key) ?? '') as Map).cast<String, dynamic>();
    } catch (_) {
      state = {};
    }
    return _instance = DemoStore._(prefs, ref, state);
  }

  Map<String, dynamic> get state => _state;

  Future<void> save() => _prefs.setString(_key, jsonEncode(_state));

  /// Wipes all demo progress (used by "delete account" and sign out).
  Future<void> reset() async {
    _state.clear();
    await _prefs.remove(_key);
  }

  // ---------------------------------------------------------------- Quran data
  List<Map<String, dynamic>>? _surahs;
  List<List<dynamic>>? _ayahs; // [surah, number, text, translation, page, juz]
  Future<void>? _loading;

  Future<void> ensureQuran() => _loading ??= _loadQuran();

  Future<void> _loadQuran() async {
    final res = await http.get(Uri.base.resolve('demo-data/quran.json'));
    if (res.statusCode != 200) {
      _loading = null;
      throw StateError('quran.json HTTP ${res.statusCode}');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    _surahs = (data['surahs'] as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
    _ayahs = (data['ayahs'] as List).map((e) => e as List<dynamic>).toList();
  }

  List<Map<String, dynamic>> get surahs => _surahs!;
  int get ayahCount => _ayahs!.length;

  /// Ayah row in the same shape PostgREST returns (global id is 1-based).
  Map<String, dynamic> ayahRow(int id) {
    final a = _ayahs![id - 1];
    return {
      'id': id,
      'surah_id': a[0],
      'ayah_number': a[1],
      'text_uthmani': a[2],
      'page': a[4],
      'juz': a[5],
      'ayah_translations': [
        {'text': a[3]},
      ],
    };
  }

  int ayahId(int surah, int number) {
    var id = 1;
    for (final s in _surahs!) {
      final sid = s['id'] as int;
      if (sid == surah) return id + number - 1;
      id += s['ayah_count'] as int;
    }
    throw StateError('no ayah $surah:$number');
  }

  Iterable<int> idsOfSurah(int surah) sync* {
    final first = ayahId(surah, 1);
    final count = _surahs![surah - 1]['ayah_count'] as int;
    for (var i = 0; i < count; i++) {
      yield first + i;
    }
  }

  /// Arabic without diacritics, for keyword search.
  static String simplify(String s) => s
      .replaceAll(RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]'), '')
      .replaceAll(RegExp('[آأإٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه');

  List<String>? _simple;

  /// Keyword search over Arabic (diacritics ignored) and the English translation.
  List<int> keywordSearch(String query, {int limit = 20}) {
    _simple ??= [for (final a in _ayahs!) simplify(a[2] as String)];
    final q = query.trim();
    if (q.isEmpty) return [];
    final arabic = RegExp('[؀-ۿ]').hasMatch(q);
    final needle = arabic ? simplify(q) : q.toLowerCase();
    final out = <int>[];
    for (var i = 0; i < _ayahs!.length && out.length < limit; i++) {
      final hay = arabic ? _simple![i] : (_ayahs![i][3] as String).toLowerCase();
      if (hay.contains(needle)) out.add(i + 1);
    }
    return out;
  }

  // ------------------------------------------------------------- user state
  static String dateOf(DateTime d) => d.toIso8601String().substring(0, 10);
  String get today => dateOf(DateTime.now());
  String get yesterday => dateOf(DateTime.now().subtract(const Duration(days: 1)));
  String get twoDaysAgo => dateOf(DateTime.now().subtract(const Duration(days: 2)));

  Map<String, dynamic> _map(String key) => (_state[key] ??= <String, dynamic>{}) as Map<String, dynamic>;
  List<dynamic> _list(String key) => (_state[key] ??= <dynamic>[]) as List<dynamic>;

  Map<String, dynamic> get profile => _map('profile');
  Map<String, dynamic> get goals => _map('goals');
  Map<String, dynamic> get daily => _map('daily');
  Map<String, dynamic> get prayers => _map('prayers');
  Map<String, dynamic> get adhkarProgress => _map('adhkar_progress');
  Map<String, dynamic> get unlocked => _map('achievements');
  Map<String, dynamic> get aiUsage => _map('ai_usage');
  List<dynamic> get hifzPlans => _list('hifz_plans');
  List<dynamic> get hifzItems => _list('hifz_items');
  List<dynamic> get recitations => _list('recitations');

  bool get premium => _state['premium'] == true;
  set premium(bool v) => _state['premium'] = v;

  /// Called when the (simulated) guest account is created.
  void bootstrapUser(String locale) {
    _state.clear();
    _state['created_at'] = DateTime.now().toIso8601String();
    final r = Random();
    _state['profile'] = {
      'display_name': null,
      'xp': 0,
      'current_streak': 0,
      'longest_streak': 0,
      'streak_freezes': 0,
      'last_active_date': null,
      'referral_code': List.generate(6, (_) => 'abcdefghjkmnpqrstuvwxyz23456789'[r.nextInt(31)]).join(),
      'locale': locale,
    };
    _state['goals'] = {
      'quran_read': {'daily_target': 5, 'active': true},
      'adhkar': {'daily_target': 2, 'active': true},
      'prayer': {'daily_target': 5, 'active': true},
    };
  }

  static int levelForXp(int xp) => sqrt(max(xp, 0) / 50.0).floor() + 1;
  static int xpForLevel(int level) => (50 * pow(max(level, 1) - 1, 2)).toInt();

  Map<String, dynamic> dayOf(String date) =>
      (daily[date] ??= <String, dynamic>{
            'ayahs_read': 0,
            'minutes_listened': 0,
            'adhkar_completed': 0,
            'prayers_logged': 0,
            'ayahs_memorized': 0,
            'reviews_done': 0,
            'recitations': 0,
            'xp_earned': 0,
            'goals_met': false,
          })
          as Map<String, dynamic>;

  void _awardXp(int amount) {
    if (amount <= 0) return;
    final xp = (profile['xp'] as int? ?? 0) + amount;
    profile['xp'] = xp;
    final day = dayOf(today);
    day['xp_earned'] = (day['xp_earned'] as int) + amount;
  }

  int _touchStreak() {
    final last = profile['last_active_date'] as String?;
    var streak = profile['current_streak'] as int? ?? 0;
    var freezes = profile['streak_freezes'] as int? ?? 0;
    if (last == today) return streak;
    if (last == yesterday) {
      streak++;
    } else if (last == twoDaysAgo && freezes > 0) {
      streak++;
      freezes--;
    } else {
      streak = 1;
    }
    if (streak % 7 == 0) freezes = min(freezes + 1, 5);
    profile['current_streak'] = streak;
    profile['longest_streak'] = max(profile['longest_streak'] as int? ?? 0, streak);
    profile['streak_freezes'] = freezes;
    profile['last_active_date'] = today;
    return streak;
  }

  int _goalProgress(String type, Map<String, dynamic> d) => switch (type) {
    'quran_read' => d['ayahs_read'] as int,
    'memorize' => (d['ayahs_memorized'] as int) + (d['reviews_done'] as int),
    'adhkar' => d['adhkar_completed'] as int,
    'prayer' => d['prayers_logged'] as int,
    'listen' => d['minutes_listened'] as int,
    _ => 0,
  };

  bool _evaluateGoals() {
    final d = dayOf(today);
    var any = false, met = true;
    goals.forEach((type, g) {
      if ((g as Map)['active'] != true) return;
      any = true;
      if (_goalProgress(type, d) < (g['daily_target'] as int)) met = false;
    });
    d['goals_met'] = any && met;
    return any && met;
  }

  List<Map<String, dynamic>> _checkAchievements() {
    int total(String col) => daily.values.fold(0, (s, d) => s + ((d as Map)[col] as int? ?? 0));
    final fresh = <Map<String, dynamic>>[];
    final all = (reference['achievements'] as List).cast<Map<String, dynamic>>()
      ..sort((a, b) => (a['sort'] as int).compareTo(b['sort'] as int));
    for (final a in all) {
      if (unlocked.containsKey(a['id'])) continue;
      final xp = profile['xp'] as int? ?? 0;
      final value = switch (a['metric']) {
        'streak' => profile['longest_streak'] as int? ?? 0,
        'xp' => xp,
        'level' => levelForXp(xp),
        'ayahs_read' => total('ayahs_read'),
        'ayahs_memorized' => total('ayahs_memorized'),
        'adhkar' => total('adhkar_completed'),
        'recitations' => total('recitations'),
        'prayers' => total('prayers_logged'),
        _ => 0,
      };
      if (value >= (a['threshold'] as int)) {
        unlocked[a['id'] as String] = DateTime.now().toIso8601String();
        fresh.add({
          'id': a['id'],
          'name_ar': a['name_ar'],
          'name_en': a['name_en'],
          'icon': a['icon'],
          'xp': a['xp_reward'],
        });
        _awardXp(a['xp_reward'] as int);
      }
    }
    return fresh;
  }

  /// Same rules as public._log_activity (daily caps per kind).
  Map<String, dynamic> logActivity(String kind, int units) {
    final rule = (reference['xp_rules'] as List).cast<Map<String, dynamic>>().firstWhere((r) => r['kind'] == kind);
    final col = rule['activity_column'] as String;
    final day = dayOf(today);
    final used = day[col] as int;
    day[col] = used + units;
    final counted = max(0, min(units, (rule['daily_unit_cap'] as int) - used));
    final xp = counted * (rule['xp_per_unit'] as int);
    _awardXp(xp);
    final streak = _touchStreak();
    final goalsMet = _evaluateGoals();
    final fresh = _checkAchievements();
    final level = levelForXp(profile['xp'] as int);
    save();
    return {
      'xp_awarded': xp,
      'total_xp': profile['xp'],
      'level': level,
      'next_level_xp': xpForLevel(level + 1),
      'streak': streak,
      'goals_met': goalsMet,
      'new_achievements': fresh,
    };
  }

  // ------------------------------------------------------------ AI quota
  /// Weekly limits, same numbers as public.plan_limits (free_weekly / premium_weekly).
  static const weeklyLimits = <String, (int, int)>{
    'recitation': (10, 150),
    'hifz': (5, 150),
    'ask': (15, 100),
    'search': (30, 300),
  };

  /// Weeks start on Friday, as on the server (_week_start).
  static DateTime weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: (day.weekday - DateTime.friday + 7) % 7));
  }

  String get week => dateOf(weekStart(DateTime.now()));
  DateTime get resetsAt => weekStart(DateTime.now()).add(const Duration(days: 7));

  int limitFor(String feature) {
    final l = weeklyLimits[feature] ?? (0, 0);
    return premium ? l.$2 : l.$1;
  }

  int usedThisWeek(String feature) => aiUsage['$week:$feature'] as int? ?? 0;

  /// Returns remaining after consuming one, or null when the weekly limit is hit.
  int? consumeQuota(String feature) {
    final limit = limitFor(feature);
    final used = usedThisWeek(feature);
    if (used >= limit) return null;
    aiUsage['$week:$feature'] = used + 1;
    save();
    return limit - used - 1;
  }

  /// Days with real value (recitation check, AI hifz test or review), as get_dashboard.value_days.
  int get valueDays => daily.values
      .where((d) => ((d as Map)['recitations'] as int? ?? 0) > 0 || (d['reviews_done'] as int? ?? 0) > 0)
      .length;

  int get daysSinceSignup {
    final created = DateTime.tryParse('${_state['created_at'] ?? ''}');
    if (created == null) {
      final first = (daily.keys.toList()..sort()).firstOrNull;
      return first == null ? 0 : DateTime.now().difference(DateTime.parse(first)).inDays;
    }
    return DateTime.now().difference(created).inDays;
  }

  // ------------------------------------------------------------ hifz
  List<dynamic> get weakWordLog => _list('weak_words');
  List<dynamic> get milestones => _list('milestones');

  /// SM-2, same as public._hifz_apply_review, including the "surah memorized" milestone.
  Map<String, dynamic> applyHifzReview(int itemId, int score) {
    final i = hifzItems.cast<Map<String, dynamic>>().firstWhere((e) => e['id'] == itemId);
    final wasNew = i['status'] == 'new';
    final ef = max(1.3, (i['ease_factor'] as num) + (0.1 - (5 - score) * (0.08 + (5 - score) * 0.02)));
    int interval, reps;
    String status;
    if (score < 3) {
      reps = 0;
      interval = 1;
      if (!wasNew) i['lapses'] = (i['lapses'] as int) + 1;
      status = 'learning';
    } else {
      reps = (i['repetitions'] as int) + 1;
      interval = switch (reps) {
        1 => 1,
        2 => 3,
        _ => (max(i['interval_days'] as int, 1) * ef).ceil(),
      };
      interval = min(interval, 180);
      status = interval >= 30 ? 'mastered' : (reps >= 2 ? 'review' : 'learning');
    }
    i
      ..['ease_factor'] = ef
      ..['interval_days'] = interval
      ..['repetitions'] = reps
      ..['status'] = status
      ..['due_date'] = dateOf(DateTime.now().add(Duration(days: interval)))
      ..['last_reviewed_at'] = DateTime.now().toIso8601String()
      ..['introduced_on'] = i['introduced_on'] ?? today;
    final milestone = _milestoneFor(i['ayah_id'] as int);
    final activity = logActivity(wasNew && score >= 3 ? 'ayah_memorized' : 'hifz_review', 1);
    return {'item_id': itemId, 'status': status, 'interval_days': interval, 'milestone': milestone, ...activity};
  }

  Map<String, dynamic>? _milestoneFor(int ayahId) {
    final surah = ayahRow(ayahId)['surah_id'] as int;
    if (milestones.any((m) => (m as Map)['surah_id'] == surah)) return null;
    final ids = idsOfSurah(surah).toSet();
    final items = hifzItems.cast<Map<String, dynamic>>().where((e) => ids.contains(e['ayah_id'])).toList();
    final covered = items.map((e) => e['ayah_id']).toSet();
    if (covered.length < ids.length || items.any((e) => e['status'] != 'review' && e['status'] != 'mastered')) return null;
    final first = milestones.isEmpty;
    milestones.add({'surah_id': surah, 'at': DateTime.now().toIso8601String()});
    _awardXp(100);
    final info = surahs[surah - 1];
    return {'surah_id': surah, 'name_ar': info['name_ar'], 'transliteration': info['transliteration'], 'xp': 100, 'first': first};
  }
}
