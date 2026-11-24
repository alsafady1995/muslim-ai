import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

/// User progress, gamification and settings. All writes that affect XP go through
/// server RPCs so they can't be forged from the client.
class UserRepository {
  UserRepository(this._db);
  final SupabaseClient _db;

  String get _uid => _db.auth.currentUser!.id;

  Future<Dashboard> dashboard() async =>
      Dashboard((await _db.rpc('get_dashboard') as Map).cast<String, dynamic>());

  Future<Map<String, dynamic>> profile() async => await _db.from('profiles').select().eq('id', _uid).single();

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    await _db.from('profiles').update(fields).eq('id', _uid);
  }

  Future<ActivityResult> logActivity(String kind, int units, {String? ref}) async {
    final res = await _db.rpc('log_activity', params: {'p_kind': kind, 'p_units': units, 'p_ref': ref});
    return ActivityResult((res as Map).cast());
  }

  Future<ActivityResult> logPrayer(String prayer, {bool onTime = true}) async {
    final res = await _db.rpc('log_prayer', params: {'p_prayer': prayer, 'p_on_time': onTime});
    return ActivityResult((res as Map).cast());
  }

  Future<Map<String, dynamic>> completeDhikr(int categoryId, int dhikrId) async {
    final res = await _db.rpc('complete_dhikr', params: {'p_category_id': categoryId, 'p_dhikr_id': dhikrId});
    return (res as Map).cast();
  }

  Future<Set<int>> completedDhikrToday(int categoryId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final row = await _db
        .from('adhkar_progress')
        .select('completed_ids')
        .eq('category_id', categoryId)
        .eq('progress_date', today)
        .maybeSingle();
    return {...((row?['completed_ids'] as List?) ?? const []).map((e) => (e as num).toInt())};
  }

  Future<void> saveReadingPosition(int ayahId) async {
    await _db.from('reading_progress').upsert({'user_id': _uid, 'last_ayah_id': ayahId});
  }

  Future<List<Map<String, dynamic>>> goals() async =>
      await _db.from('goals').select().eq('user_id', _uid).order('goal_type');

  Future<void> setGoal(String type, int target, bool active) async {
    await _db.from('goals').upsert({'user_id': _uid, 'goal_type': type, 'daily_target': target, 'active': active});
  }

  Future<List<Achievement>> achievements() async {
    final all = await _db.from('achievements').select().order('sort');
    final mine = await _db.from('user_achievements').select('achievement_id, unlocked_at');
    final unlocked = {for (final m in mine) m['achievement_id'] as String: DateTime.parse(m['unlocked_at'] as String)};
    return all
        .map((a) => Achievement(
              id: a['id'] as String,
              nameAr: a['name_ar'] as String,
              nameEn: a['name_en'] as String,
              descriptionAr: a['description_ar'] as String,
              descriptionEn: a['description_en'] as String,
              icon: a['icon'] as String,
              xpReward: (a['xp_reward'] as num).toInt(),
              unlockedAt: unlocked[a['id']],
            ))
        .toList();
  }

  Future<Map<String, dynamic>> quota() async => ((await _db.rpc('get_my_quota')) as Map).cast();

  Future<WeeklyQuota> weeklyQuota() async => WeeklyQuota(await quota());

  Future<WeeklySummary> weeklySummary() async =>
      WeeklySummary(((await _db.rpc('get_weekly_summary')) as Map).cast());

  Future<WeakWords> weakWords({int limit = 30}) async =>
      WeakWords(((await _db.rpc('get_weak_words', params: {'p_limit': limit})) as Map).cast());

  /// Onboarding: surahs the user already knows go straight into spaced review.
  Future<int> seedKnownSurahs(List<int> surahs, String title) async {
    if (surahs.isEmpty) return 0;
    final res = await _db.rpc('seed_known_surahs', params: {'p_surahs': surahs, 'p_title': title});
    return ((res as Map)['items'] as num?)?.toInt() ?? 0;
  }

  Future<void> setPlanActive(String planId, bool active) async {
    await _db.from('hifz_plans').update({'active': active}).eq('id', planId);
  }

  Future<Map<String, dynamic>> applyReferral(String code) async =>
      ((await _db.rpc('apply_referral', params: {'p_code': code})) as Map).cast();

  // ---- Hifz ----
  Future<HifzQueue> hifzQueue() async => HifzQueue.fromJson(((await _db.rpc('get_hifz_queue')) as Map).cast());

  Future<Map<String, dynamic>> hifzStats() async => ((await _db.rpc('get_hifz_stats')) as Map).cast();

  /// Active plans first, then paused ones (paused plans add no new ayahs; reviews continue).
  Future<List<Map<String, dynamic>>> hifzPlans() async =>
      await _db.from('hifz_plans').select().order('active', ascending: false).order('created_at');

  Future<String> createHifzPlan(int startAyahId, int endAyahId, int dailyNew, String? title) async {
    final id = await _db.rpc('create_hifz_plan', params: {
      'p_start_ayah': startAyahId,
      'p_end_ayah': endAyahId,
      'p_daily_new': dailyNew,
      'p_title': title,
    });
    return id as String;
  }

  Future<ActivityResult> recordHifzReview(int itemId, int score) async {
    final res = await _db.rpc('hifz_record_review', params: {'p_item': itemId, 'p_score': score});
    return ActivityResult((res as Map).cast());
  }

  Future<List<Map<String, dynamic>>> recitationHistory() async => await _db
      .from('recitation_sessions')
      .select('id, start_ayah_id, end_ayah_id, overall_score, accuracy_score, status, mode, created_at')
      .eq('status', 'done')
      .order('created_at', ascending: false)
      .limit(30);

  Future<List<Map<String, dynamic>>> conversations() async => await _db
      .from('ai_conversations')
      .select('id, kind, title, updated_at')
      .order('updated_at', ascending: false)
      .limit(30);

  Future<Map<String, dynamic>?> subscription() async =>
      await _db.from('subscriptions').select().eq('user_id', _uid).maybeSingle();
}
