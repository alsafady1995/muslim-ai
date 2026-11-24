import 'dart:async';
import 'dart:math';


import '../core/api.dart';
import '../data/models.dart';
import '../data/quran_repository.dart';
import '../data/user_repository.dart';
import '../payments/payment_provider.dart';
import 'demo_ai.dart';
import 'demo_store.dart';

/// Quran content from the bundled demo data instead of Postgres.
class DemoQuranRepository extends QuranRepository {
  DemoQuranRepository(super.db);
  DemoStore get _s => DemoStore.instance;

  @override
  Future<List<Surah>> surahs() async {
    await _s.ensureQuran();
    return _s.surahs.map(Surah.fromJson).toList();
  }

  @override
  Future<List<Ayah>> ayahsOfSurah(int surahId, {int translationId = 20}) async {
    await _s.ensureQuran();
    return _s.idsOfSurah(surahId).map((id) => Ayah.fromJson(_s.ayahRow(id))).toList();
  }

  @override
  Future<List<Ayah>> ayahRange(int fromId, int toId, {int translationId = 20}) async {
    await _s.ensureQuran();
    return [for (var id = fromId; id <= toId; id++) Ayah.fromJson(_s.ayahRow(id))];
  }

  @override
  Future<int> ayahId(int surahId, int ayahNumber) async {
    await _s.ensureQuran();
    return _s.ayahId(surahId, ayahNumber);
  }

  @override
  Future<List<Reciter>> reciters() async =>
      (_s.reference['reciters'] as List).cast<Map<String, dynamic>>().map(Reciter.fromJson).toList();

  @override
  Future<List<DhikrCategory>> adhkarCategories() async =>
      (_s.reference['adhkar_categories'] as List).cast<Map<String, dynamic>>().map(DhikrCategory.fromJson).toList();

  @override
  Future<List<Dhikr>> adhkar(int categoryId) async => (_s.reference['adhkar'] as List)
      .cast<Map<String, dynamic>>()
      .where((d) => d['category_id'] == categoryId)
      .map(Dhikr.fromJson)
      .toList();
}

/// Progress and gamification computed locally with the same rules as the SQL functions.
class DemoUserRepository extends UserRepository {
  DemoUserRepository(super.db);
  DemoStore get _s => DemoStore.instance;

  @override
  Future<Dashboard> dashboard() async {
    final p = _s.profile;
    final xp = p['xp'] as int? ?? 0;
    final level = DemoStore.levelForXp(xp);
    final last = p['last_active_date'] as String?;
    final streakAlive = last == _s.today || last == _s.yesterday;
    final cutoff = DemoStore.dateOf(DateTime.now().subtract(const Duration(days: 30)));
    final history = _s.daily.entries.where((e) => e.key.compareTo(cutoff) > 0).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final items = _s.hifzItems.cast<Map<String, dynamic>>();
    return Dashboard({
      'profile': {
        'display_name': p['display_name'],
        'xp': xp,
        'level': level,
        'level_start_xp': DemoStore.xpForLevel(level),
        'next_level_xp': DemoStore.xpForLevel(level + 1),
        'current_streak': streakAlive ? p['current_streak'] ?? 0 : 0,
        'longest_streak': p['longest_streak'] ?? 0,
        'streak_freezes': p['streak_freezes'] ?? 0,
        'streak_active_today': last == _s.today,
        'referral_code': p['referral_code'],
      },
      'premium': _s.premium,
      'today': {...?_s.daily[_s.today] as Map<String, dynamic>?},
      'goals': [
        for (final e in _s.goals.entries)
          if ((e.value as Map)['active'] == true) {'type': e.key, 'target': (e.value as Map)['daily_target']},
      ],
      'prayers_today': [...?_s.prayers[_s.today] as List?],
      'history': [
        for (final e in history)
          {
            'date': e.key,
            'xp': (e.value as Map)['xp_earned'],
            'ayahs_read': (e.value as Map)['ayahs_read'],
            'goals_met': (e.value as Map)['goals_met'],
          },
      ],
      'hifz_due': items.where((i) => i['status'] != 'new' && (i['due_date'] as String).compareTo(_s.today) <= 0).length,
      'hifz_memorized': items.where((i) => i['status'] == 'review' || i['status'] == 'mastered').length,
      'achievements_unlocked': _s.unlocked.length,
      'achievements_total': (_s.reference['achievements'] as List).length,
      'last_ayah_id': _s.state['last_ayah_id'],
      'recent_recitations': [
        for (final r in _s.recitations.reversed.take(5))
          {'id': (r as Map)['id'], 'score': r['overall_score'], 'created_at': r['created_at']},
      ],
      'hifz_at_risk': items.where((i) => (_retention(i) ?? 1) < 0.8).length,
      'hifz_has_plan': _s.hifzPlans.any((p) => (p as Map)['active'] == true && p['review_only'] != true),
      'value_days': _s.valueDays,
      'days_since_signup': _s.daysSinceSignup,
      'subscription': await subscription(),
    });
  }

  @override
  Future<WeeklyQuota> weeklyQuota() async => WeeklyQuota(await quota());

  @override
  Future<WeeklySummary> weeklySummary() async {
    final days = [for (var i = 0; i < 7; i++) DemoStore.dateOf(DateTime.now().subtract(Duration(days: i)))];
    int sum(String k) => days.fold(0, (a, d) => a + (((_s.daily[d] as Map?)?[k] as int?) ?? 0));
    final items = _s.hifzItems.cast<Map<String, dynamic>>();
    return WeeklySummary({
      'active_days': days.where((d) => (((_s.daily[d] as Map?)?['xp_earned'] as int?) ?? 0) > 0).length,
      'ayahs_read': sum('ayahs_read'),
      'reviews_done': sum('reviews_done'),
      'ayahs_memorized': sum('ayahs_memorized'),
      'recitations': sum('recitations'),
      'hifz_memorized': items.where((i) => i['status'] == 'review' || i['status'] == 'mastered').length,
      'at_risk': items.where((i) => (_retention(i) ?? 1) < 0.8).length,
      'streak': _s.profile['current_streak'] ?? 0,
      'days_since_signup': _s.daysSinceSignup,
    });
  }

  /// Same shape as get_weak_words: free users see the top 3 and a "locked" count.
  @override
  Future<WeakWords> weakWords({int limit = 30}) async {
    await _s.ensureQuran();
    final counts = <String, Map<String, dynamic>>{};
    for (final w in _s.weakWordLog.cast<Map>()) {
      final key = '${w['ayah_id']}:${w['position']}';
      final row = counts.putIfAbsent(key, () {
        final a = _s.ayahRow(w['ayah_id'] as int);
        return {'ayah_id': w['ayah_id'], 'surah_id': a['surah_id'], 'ayah_number': a['ayah_number'], 'word': w['word'], 'misses': 0};
      });
      row['misses'] = (row['misses'] as int) + 1;
    }
    final all = counts.values.toList()..sort((a, b) => (b['misses'] as int).compareTo(a['misses'] as int));
    final shown = _s.premium ? all.take(limit).toList() : all.take(3).toList();
    return WeakWords({'premium': _s.premium, 'total': all.length, 'locked': all.length - shown.length, 'words': shown});
  }

  @override
  Future<int> seedKnownSurahs(List<int> surahs, String title) async {
    await _s.ensureQuran();
    if (surahs.isEmpty) return 0;
    final id = 'plan_known';
    if (!_s.hifzPlans.any((p) => (p as Map)['id'] == id)) {
      _s.hifzPlans.add({'id': id, 'title': title, 'daily_new_ayahs': 0, 'active': true, 'review_only': true,
          'created_at': DateTime.now().toIso8601String()});
    }
    var n = 0;
    final existing = _s.hifzItems.map((e) => (e as Map)['ayah_id']).toSet();
    for (final s in surahs) {
      for (final ayah in _s.idsOfSurah(s)) {
        if (existing.contains(ayah)) continue;
        _s.hifzItems.add({
          'id': _s.hifzItems.length + 1000,
          'plan_id': id,
          'ayah_id': ayah,
          'status': 'review',
          'ease_factor': 2.5,
          'interval_days': 3,
          'repetitions': 2,
          'lapses': 0,
          // Spread over 6 days starting tomorrow, like the server.
          'due_date': DemoStore.dateOf(DateTime.now().add(Duration(days: 1 + n % 6))),
          'last_reviewed_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          'introduced_on': _s.today,
        });
        n++;
      }
    }
    await _s.save();
    return n;
  }

  @override
  Future<void> setPlanActive(String planId, bool active) async {
    for (final p in _s.hifzPlans.cast<Map<String, dynamic>>()) {
      if (p['id'] == planId) p['active'] = active;
    }
    await _s.save();
  }

  @override
  Future<Map<String, dynamic>> profile() async => {..._s.profile};

  @override
  Future<void> updateProfile(Map<String, dynamic> fields) async {
    _s.profile.addAll(fields);
    await _s.save();
  }

  @override
  Future<ActivityResult> logActivity(String kind, int units, {String? ref}) async =>
      ActivityResult(_s.logActivity(kind, units));

  @override
  Future<ActivityResult> logPrayer(String prayer, {bool onTime = true}) async {
    final list = (_s.prayers[_s.today] ??= <dynamic>[]) as List;
    if (list.contains(prayer)) {
      return ActivityResult({'xp_awarded': 0, 'streak': _s.profile['current_streak'] ?? 0});
    }
    list.add(prayer);
    return ActivityResult(_s.logActivity('prayer', 1));
  }

  @override
  Future<Map<String, dynamic>> completeDhikr(int categoryId, int dhikrId) async {
    final key = '${_s.today}:$categoryId';
    final entry = (_s.adhkarProgress[key] ??= <String, dynamic>{'ids': <dynamic>[], 'completed': false}) as Map;
    final ids = entry['ids'] as List;
    if (!ids.contains(dhikrId)) ids.add(dhikrId);
    final total = (_s.reference['adhkar'] as List).where((d) => (d as Map)['category_id'] == categoryId).length;
    if (entry['completed'] != true && ids.length >= total) {
      entry['completed'] = true;
      final r = _s.logActivity('adhkar_set', 1);
      return {...r, 'category_completed': true, 'completed_count': ids.length, 'total': total};
    }
    await _s.save();
    return {'category_completed': entry['completed'], 'completed_count': ids.length, 'total': total, 'xp_awarded': 0};
  }

  @override
  Future<Set<int>> completedDhikrToday(int categoryId) async {
    final entry = _s.adhkarProgress['${_s.today}:$categoryId'] as Map?;
    return {...((entry?['ids'] as List?) ?? const []).map((e) => (e as num).toInt())};
  }

  @override
  Future<void> saveReadingPosition(int ayahId) async {
    _s.state['last_ayah_id'] = ayahId;
    await _s.save();
  }

  @override
  Future<List<Map<String, dynamic>>> goals() async => [
    for (final e in _s.goals.entries)
      {'goal_type': e.key, 'daily_target': (e.value as Map)['daily_target'], 'active': (e.value as Map)['active']},
  ]..sort((a, b) => (a['goal_type'] as String).compareTo(b['goal_type'] as String));

  @override
  Future<void> setGoal(String type, int target, bool active) async {
    _s.goals[type] = {'daily_target': target, 'active': active};
    await _s.save();
  }

  @override
  Future<List<Achievement>> achievements() async {
    final all = (_s.reference['achievements'] as List).cast<Map<String, dynamic>>()
      ..sort((a, b) => (a['sort'] as int).compareTo(b['sort'] as int));
    return all
        .map(
          (a) => Achievement(
            id: a['id'] as String,
            nameAr: a['name_ar'] as String,
            nameEn: a['name_en'] as String,
            descriptionAr: a['description_ar'] as String,
            descriptionEn: a['description_en'] as String,
            icon: a['icon'] as String,
            xpReward: a['xp_reward'] as int,
            unlockedAt: _s.unlocked[a['id']] == null ? null : DateTime.parse(_s.unlocked[a['id']] as String),
          ),
        )
        .toList();
  }

  @override
  Future<Map<String, dynamic>> quota() async => {
    'premium': _s.premium,
    'period': 'week',
    'resets_at': _s.resetsAt.toIso8601String(),
    'clip_seconds': _s.premium ? 180 : 60,
    'onboarding_check_available': _s.state['onboarding_check_used'] != true,
    'features': {
      for (final f in DemoStore.weeklyLimits.keys) f: {'limit': _s.limitFor(f), 'used': _s.usedThisWeek(f)},
    },
  };

  @override
  Future<Map<String, dynamic>> applyReferral(String code) async {
    if (code.trim().toLowerCase() == _s.profile['referral_code']) return {'ok': false, 'reason': 'invalid_code'};
    if (_s.state['referred'] == true) return {'ok': false, 'reason': 'already_referred'};
    if (code.trim().length < 4) return {'ok': false, 'reason': 'invalid_code'};
    _s.state['referred'] = true;
    _s.profile['xp'] = (_s.profile['xp'] as int? ?? 0) + 50;
    await _s.save();
    return {'ok': true};
  }

  // ---- Hifz ----
  double? _retention(Map<String, dynamic> i) {
    final last = i['last_reviewed_at'] as String?;
    if (last == null) return null;
    final days = DateTime.now().difference(DateTime.parse(last)).inSeconds / 86400.0;
    return double.parse(pow(0.9, days / max(i['interval_days'] as int, 1)).toStringAsFixed(3));
  }

  Map<String, dynamic> _card(Map<String, dynamic> i) {
    final a = _s.ayahRow(i['ayah_id'] as int);
    return {
      'item_id': i['id'],
      'ayah_id': i['ayah_id'],
      'surah_id': a['surah_id'],
      'ayah_number': a['ayah_number'],
      'text_uthmani': a['text_uthmani'],
      'status': i['status'],
      'interval_days': i['interval_days'],
      'retention': _retention(i),
      'plan_id': i['plan_id'],
    };
  }

  @override
  Future<HifzQueue> hifzQueue() async {
    await _s.ensureQuran();
    final items = _s.hifzItems.cast<Map<String, dynamic>>();
    final reviews =
        items
            .where((i) => i['status'] != 'new' && (i['due_date'] as String).compareTo(_s.today) <= 0)
            .map(_card)
            .toList()
          ..sort((a, b) => ((a['retention'] as double?) ?? -1).compareTo((b['retention'] as double?) ?? -1));
    final fresh = <Map<String, dynamic>>[];
    for (final p in _s.hifzPlans.cast<Map<String, dynamic>>().where((p) => p['active'] == true)) {
      final introduced = items.where((i) => i['plan_id'] == p['id'] && i['introduced_on'] == _s.today).length;
      final remaining = max(0, (p['daily_new_ayahs'] as int) - introduced);
      fresh.addAll(items.where((i) => i['plan_id'] == p['id'] && i['status'] == 'new').take(remaining).map(_card));
    }
    return HifzQueue.fromJson({'date': _s.today, 'reviews': reviews.take(100).toList(), 'new': fresh});
  }

  @override
  Future<Map<String, dynamic>> hifzStats() async {
    final items = _s.hifzItems.cast<Map<String, dynamic>>();
    final ret = items.map(_retention).whereType<double>().toList();
    final atRisk = items.where((i) => (_retention(i) ?? 1) < 0.8).toList();
    return {
      'total': items.length,
      'new': items.where((i) => i['status'] == 'new').length,
      'learning': items.where((i) => i['status'] == 'learning').length,
      'review': items.where((i) => i['status'] == 'review').length,
      'mastered': items.where((i) => i['status'] == 'mastered').length,
      'avg_retention': ret.isEmpty ? null : ret.reduce((a, b) => a + b) / ret.length,
      'at_risk': atRisk.length,
      'due_today': items
          .where((i) => i['status'] != 'new' && (i['due_date'] as String).compareTo(_s.today) <= 0)
          .length,
      'at_risk_items': [
        for (final i in atRisk.take(20)) {'item_id': i['id'], 'ayah_id': i['ayah_id'], 'retention': _retention(i)},
      ],
    };
  }

  @override
  Future<List<Map<String, dynamic>>> hifzPlans() async => [
    ..._s.hifzPlans.cast<Map<String, dynamic>>().where((p) => p['active'] == true),
    ..._s.hifzPlans.cast<Map<String, dynamic>>().where((p) => p['active'] != true),
  ];

  @override
  Future<String> createHifzPlan(int startAyahId, int endAyahId, int dailyNew, String? title) async {
    if (endAyahId < startAyahId) throw ApiError('invalid_range');
    if (_s.hifzPlans.where((p) => (p as Map)['active'] == true && p['review_only'] != true).length >= 3) {
      throw ApiError('maximum 3 active plans');
    }
    final id = 'plan_${DateTime.now().microsecondsSinceEpoch}';
    _s.hifzPlans.add({
      'id': id,
      'title': title,
      'start_ayah_id': startAyahId,
      'end_ayah_id': endAyahId,
      'daily_new_ayahs': dailyNew,
      'active': true,
      'created_at': DateTime.now().toIso8601String(),
    });
    final existing = _s.hifzItems.map((i) => (i as Map)['ayah_id']).toSet();
    var nextId = _s.hifzItems.fold<int>(0, (m, i) => max(m, (i as Map)['id'] as int)) + 1;
    for (var a = startAyahId; a <= endAyahId; a++) {
      if (existing.contains(a)) continue;
      _s.hifzItems.add({
        'id': nextId++,
        'plan_id': id,
        'ayah_id': a,
        'status': 'new',
        'ease_factor': 2.5,
        'interval_days': 0,
        'repetitions': 0,
        'lapses': 0,
        'due_date': _s.today,
        'last_reviewed_at': null,
        'introduced_on': null,
      });
    }
    await _s.save();
    return id;
  }

  @override
  Future<ActivityResult> recordHifzReview(int itemId, int score) async {
    final r = _s.applyHifzReview(itemId, score);
    await _s.save();
    return ActivityResult(r);
  }

  @override
  Future<List<Map<String, dynamic>>> recitationHistory() async => [
    for (final r in _s.recitations.reversed.take(30)) {...(r as Map).cast<String, dynamic>(), 'status': 'done'},
  ];

  @override
  Future<List<Map<String, dynamic>>> conversations() async => [];

  @override
  Future<Map<String, dynamic>?> subscription() async => _s.premium
      ? {'status': 'active', 'product_id': 'demo_premium_monthly', 'store': 'demo', 'current_period_end': null}
      : null;
}

/// Edge functions answered locally. AI answers are simulated: they cite real
/// verses found by keyword/topic, but the explanation text is a placeholder.
class DemoEdgeApi extends EdgeApi {
  DemoEdgeApi(super.client);
  DemoStore get _s => DemoStore.instance;

  @override
  Future<Map<String, dynamic>> call(String fn, Map<String, dynamic> body) async {
    await Future<void>.delayed(const Duration(milliseconds: 900)); // feel of a network call
    await _s.ensureQuran();
    switch (fn) {
      case 'ask-quran' || 'assistant':
        final remaining = _quota('ask');
        return DemoAi.answer(
          _s,
          '${body['question']}',
          '${body['locale']}',
          conversationId: body['conversation_id'] as String?,
          remaining: remaining,
          premium: _s.premium,
        );
      case 'quran-search':
        final semantic = body['mode'] == 'semantic';
        if (semantic) _quota('search');
        return DemoAi.search(_s, '${body['query']}', semantic: semantic);
      case 'recitation-analyze':
        final hifz = body['mode'] == 'hifz';
        // The first Al-Fatiha check in onboarding is free and not counted (as on the server).
        final onboarding = body['source'] == 'onboarding' &&
            _s.state['onboarding_check_used'] != true &&
            body['start_ayah_id'] == 1 &&
            (body['end_ayah_id'] as int) <= 7;
        if (onboarding) {
          _s.state['onboarding_check_used'] = true;
        } else {
          _quota(hifz ? 'hifz' : 'recitation');
        }
        final res = DemoAi.recitation(_s, body);
        final clip = _s.premium ? 180 : 60;
        res['clip_seconds'] = clip;
        res['clipped'] = ((body['seconds'] as int?) ?? 0) > clip + 5;
        res['onboarding'] = onboarding;
        if (hifz) {
          final updates = <Map<String, dynamic>>[];
          for (final item in _s.hifzItems.cast<Map<String, dynamic>>().toList()) {
            final ayah = item['ayah_id'] as int;
            if (ayah < (body['start_ayah_id'] as int) || ayah > (body['end_ayah_id'] as int)) continue;
            final words = (res['words'] as List).cast<Map>().where((w) => w['ayahId'] == ayah).toList();
            if (words.isEmpty) continue;
            final ok = words.where((w) => w['status'] == 'correct').length;
            final pct = 100 * ok / words.length;
            updates.add(_s.applyHifzReview(item['id'] as int, pct >= 95 ? 5 : pct >= 85 ? 4 : pct >= 70 ? 3 : 2));
          }
          res['hifz'] = updates;
          res['milestone'] = updates.map((u) => u['milestone']).firstWhere((m) => m != null, orElse: () => null);
          await _s.save();
        }
        return res;
      case 'delete-account':
        await _s.reset();
        return {'ok': true};
      default:
        throw ApiError('not_available_in_demo', fn);
    }
  }

  int _quota(String feature) {
    final remaining = _s.consumeQuota(feature);
    if (remaining == null) {
      throw QuotaExceeded(feature, premium: _s.premium, limit: _s.limitFor(feature), resetsAt: _s.resetsAt);
    }
    return remaining;
  }
}

/// Simulated store: "buying" flips premium on locally. No money moves.
class DemoPaymentProvider implements PaymentProvider {
  final _premium = StreamController<bool>.broadcast();
  DemoStore get _s => DemoStore.instance;

  @override
  Future<void> init({required String userId}) async {}
  @override
  Future<void> logIn(String userId) async {}
  @override
  Future<void> logOut() async {}

  @override
  Future<List<PlanOffer>> offers() async => [
    PlanOffer(id: 'monthly', priceString: r'$4.99', period: 'month'),
    PlanOffer(id: 'annual', priceString: r'$29.99', period: 'year', trialDays: 7),
  ];

  @override
  Future<PurchaseOutcome> purchase(PlanOffer offer) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _s.premium = true;
    await _s.save();
    _premium.add(true);
    return PurchaseOutcome(PurchaseStatus.success);
  }

  @override
  Future<bool> restore() async => _s.premium;
  @override
  Future<bool> isPremium() async => _s.premium;
  @override
  Stream<bool> get premiumChanges => _premium.stream;
  @override
  Uri? get manageSubscriptionsUrl => null;
}
