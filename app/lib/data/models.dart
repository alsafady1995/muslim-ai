// Plain data classes mapped from Supabase rows / edge function JSON.

int _i(dynamic v, [int d = 0]) => v is num ? v.toInt() : int.tryParse('$v') ?? d;
double? _dn(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');

class Surah {
  Surah({required this.id, required this.nameAr, required this.nameEn, required this.transliteration,
      required this.revelationPlace, required this.ayahCount});
  final int id;
  final String nameAr;
  final String nameEn;
  final String transliteration;
  final String revelationPlace;
  final int ayahCount;

  factory Surah.fromJson(Map<String, dynamic> j) => Surah(
        id: _i(j['id']),
        nameAr: j['name_ar'] as String,
        nameEn: j['name_en'] as String,
        transliteration: j['transliteration'] as String,
        revelationPlace: j['revelation_place'] as String,
        ayahCount: _i(j['ayah_count']),
      );
}

class Ayah {
  Ayah({required this.id, required this.surahId, required this.ayahNumber, required this.textUthmani,
      this.translation, this.page = 0, this.juz = 0});
  final int id;
  final int surahId;
  final int ayahNumber;
  final String textUthmani;
  final String? translation;
  final int page;
  final int juz;

  String get verseKey => '$surahId:$ayahNumber';

  factory Ayah.fromJson(Map<String, dynamic> j) {
    final tr = j['ayah_translations'];
    return Ayah(
      id: _i(j['id']),
      surahId: _i(j['surah_id']),
      ayahNumber: _i(j['ayah_number']),
      textUthmani: j['text_uthmani'] as String,
      translation: tr is List && tr.isNotEmpty ? tr.first['text'] as String? : null,
      page: _i(j['page']),
      juz: _i(j['juz']),
    );
  }
}

class Reciter {
  Reciter({required this.id, required this.nameEn, required this.nameAr, required this.template, required this.isPremium});
  final int id;
  final String nameEn;
  final String nameAr;
  final String template;
  final bool isPremium;

  String urlFor(int surah, int ayah) => template
      .replaceAll('{surah3}', surah.toString().padLeft(3, '0'))
      .replaceAll('{ayah3}', ayah.toString().padLeft(3, '0'));

  factory Reciter.fromJson(Map<String, dynamic> j) => Reciter(
        id: _i(j['id']),
        nameEn: j['name_en'] as String,
        nameAr: j['name_ar'] as String,
        template: j['audio_url_template'] as String,
        isPremium: j['is_premium'] == true,
      );
}

class DhikrCategory {
  DhikrCategory({required this.id, required this.slug, required this.nameAr, required this.nameEn});
  final int id;
  final String slug;
  final String nameAr;
  final String nameEn;
  factory DhikrCategory.fromJson(Map<String, dynamic> j) =>
      DhikrCategory(id: _i(j['id']), slug: j['slug'] as String, nameAr: j['name_ar'] as String, nameEn: j['name_en'] as String);
}

class Dhikr {
  Dhikr({required this.id, required this.categoryId, required this.textAr, required this.translationEn,
      required this.repeatCount, required this.reference, this.audioUrl});
  final int id;
  final int categoryId;
  final String textAr;
  final String translationEn;
  final int repeatCount;
  final String reference;
  final String? audioUrl;
  factory Dhikr.fromJson(Map<String, dynamic> j) => Dhikr(
        id: _i(j['id']),
        categoryId: _i(j['category_id']),
        textAr: j['text_ar'] as String,
        translationEn: j['translation_en'] as String,
        repeatCount: _i(j['repeat_count'], 1),
        reference: j['reference'] as String,
        audioUrl: j['audio_url'] as String?,
      );
}

class Achievement {
  Achievement({required this.id, required this.nameAr, required this.nameEn, required this.descriptionAr,
      required this.descriptionEn, required this.icon, required this.xpReward, this.unlockedAt});
  final String id;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String icon;
  final int xpReward;
  final DateTime? unlockedAt;
  bool get unlocked => unlockedAt != null;
}

/// Result of any gamified action (log_activity and friends).
class ActivityResult {
  ActivityResult(this.raw);
  final Map<String, dynamic> raw;
  int get xpAwarded => _i(raw['xp_awarded']);
  int get level => _i(raw['level'], 1);
  int get streak => _i(raw['streak']);
  bool get goalsMet => raw['goals_met'] == true;
  List<Map<String, dynamic>> get newAchievements =>
      ((raw['new_achievements'] as List?) ?? const []).cast<Map<String, dynamic>>();

  /// Set when this review completed a surah (first time only).
  HifzMilestone? get milestone => HifzMilestone.tryParse(raw['milestone']);
}

/// "You've memorized Surah X" (server: hifz_milestones).
class HifzMilestone {
  HifzMilestone(this.raw);
  final Map<String, dynamic> raw;
  int get surahId => _i(raw['surah_id']);
  String get nameAr => '${raw['name_ar'] ?? ''}';
  String get transliteration => '${raw['transliteration'] ?? raw['name_en'] ?? ''}';
  int get xp => _i(raw['xp']);
  bool get first => raw['first'] == true;

  static HifzMilestone? tryParse(Object? v) => v is Map ? HifzMilestone(v.cast<String, dynamic>()) : null;
}

/// Weekly AI limits (get_my_quota). Limits renew every Friday at 00:00 local time.
class WeeklyQuota {
  WeeklyQuota(this.raw);
  final Map<String, dynamic> raw;
  bool get premium => raw['premium'] == true;
  DateTime? get resetsAt => DateTime.tryParse('${raw['resets_at'] ?? ''}')?.toLocal();
  int get clipSeconds => _i(raw['clip_seconds'], 60);
  bool get onboardingCheckAvailable => raw['onboarding_check_available'] == true;
  Map<String, dynamic> _f(String feature) => ((raw['features'] as Map?)?[feature] as Map?)?.cast<String, dynamic>() ?? const {};
  int limit(String feature) => _i(_f(feature)['limit']);
  int used(String feature) => _i(_f(feature)['used']);
  int remaining(String feature) => (limit(feature) - used(feature)).clamp(0, 1 << 30);
}

/// Last 7 days (get_weekly_summary).
class WeeklySummary {
  WeeklySummary(this.raw);
  final Map<String, dynamic> raw;
  int get activeDays => _i(raw['active_days']);
  int get ayahsRead => _i(raw['ayahs_read']);
  int get reviewsDone => _i(raw['reviews_done']);
  int get ayahsMemorized => _i(raw['ayahs_memorized']);
  int get recitations => _i(raw['recitations']);
  double? get bestScore => _dn(raw['best_score']);
  int get hifzMemorized => _i(raw['hifz_memorized']);
  int get atRisk => _i(raw['at_risk']);
  int get streak => _i(raw['streak']);
  int get daysSinceSignup => _i(raw['days_since_signup']);
}

class WeakWord {
  WeakWord(this.raw);
  final Map<String, dynamic> raw;
  int get ayahId => _i(raw['ayah_id']);
  int get surahId => _i(raw['surah_id']);
  int get ayahNumber => _i(raw['ayah_number']);
  String get word => '${raw['word'] ?? ''}';
  int get misses => _i(raw['misses']);
}

class WeakWords {
  WeakWords(this.raw);
  final Map<String, dynamic> raw;
  bool get premium => raw['premium'] == true;
  int get total => _i(raw['total']);
  int get locked => _i(raw['locked']);
  List<WeakWord> get words => ((raw['words'] as List?) ?? const []).map((e) => WeakWord((e as Map).cast())).toList();
}

class Dashboard {
  Dashboard(this.raw);
  final Map<String, dynamic> raw;
  Map<String, dynamic> get profile => (raw['profile'] as Map).cast<String, dynamic>();
  Map<String, dynamic> get today => ((raw['today'] as Map?) ?? const {}).cast<String, dynamic>();
  int get xp => _i(profile['xp']);
  int get level => _i(profile['level'], 1);
  int get levelStartXp => _i(profile['level_start_xp']);
  int get nextLevelXp => _i(profile['next_level_xp'], 50);
  int get streak => _i(profile['current_streak']);
  int get longestStreak => _i(profile['longest_streak']);
  int get streakFreezes => _i(profile['streak_freezes']);
  bool get activeToday => profile['streak_active_today'] == true;
  String get referralCode => '${profile['referral_code'] ?? ''}';
  bool get premium => raw['premium'] == true;
  int get hifzDue => _i(raw['hifz_due']);
  int get hifzMemorized => _i(raw['hifz_memorized']);
  int get achievementsUnlocked => _i(raw['achievements_unlocked']);
  int get achievementsTotal => _i(raw['achievements_total']);
  int? get lastAyahId => raw['last_ayah_id'] == null ? null : _i(raw['last_ayah_id']);
  List<String> get prayersToday => ((raw['prayers_today'] as List?) ?? const []).map((e) => '$e').toList();
  List<Map<String, dynamic>> get history => ((raw['history'] as List?) ?? const []).cast<Map<String, dynamic>>();
  List<Map<String, dynamic>> get recentRecitations =>
      ((raw['recent_recitations'] as List?) ?? const []).cast<Map<String, dynamic>>();
  int get hifzAtRisk => _i(raw['hifz_at_risk']);
  bool get hifzHasPlan => raw['hifz_has_plan'] == true;

  /// Distinct days with a recitation check, an AI hifz test or a completed review.
  int get valueDays => _i(raw['value_days']);
  int get daysSinceSignup => _i(raw['days_since_signup']);
  Map<String, dynamic>? get subscription => (raw['subscription'] as Map?)?.cast<String, dynamic>();
  String? get subscriptionStatus => subscription?['status'] as String?;
  bool get inTrial => subscription?['period_type'] == 'trial' && premium;
  bool get billingProblem => subscriptionStatus == 'billing_issue' || subscriptionStatus == 'grace_period';
  DateTime? get periodEnd => DateTime.tryParse('${subscription?['current_period_end'] ?? ''}')?.toLocal();

  /// goal type -> (progress, target)
  Map<String, (int, int)> get goals {
    final out = <String, (int, int)>{};
    for (final g in ((raw['goals'] as List?) ?? const []).cast<Map>()) {
      final type = '${g['type']}';
      final progress = switch (type) {
        'quran_read' => _i(today['ayahs_read']),
        'memorize' => _i(today['ayahs_memorized']) + _i(today['reviews_done']),
        'adhkar' => _i(today['adhkar_completed']),
        'prayer' => _i(today['prayers_logged']),
        'listen' => _i(today['minutes_listened']),
        _ => 0,
      };
      out[type] = (progress, _i(g['target'], 1));
    }
    return out;
  }
}

class HifzCard {
  HifzCard({required this.itemId, required this.ayahId, required this.surahId, required this.ayahNumber,
      required this.text, required this.isNew, this.retention});
  final int itemId;
  final int ayahId;
  final int surahId;
  final int ayahNumber;
  final String text;
  final bool isNew;
  final double? retention;

  factory HifzCard.fromJson(Map<String, dynamic> j, {required bool isNew}) => HifzCard(
        itemId: _i(j['item_id']),
        ayahId: _i(j['ayah_id']),
        surahId: _i(j['surah_id']),
        ayahNumber: _i(j['ayah_number']),
        text: j['text_uthmani'] as String,
        isNew: isNew,
        retention: _dn(j['retention']),
      );
}

class HifzQueue {
  HifzQueue({required this.reviews, required this.fresh});
  final List<HifzCard> reviews;
  final List<HifzCard> fresh;
  bool get isEmpty => reviews.isEmpty && fresh.isEmpty;
  factory HifzQueue.fromJson(Map<String, dynamic> j) => HifzQueue(
        reviews: ((j['reviews'] as List?) ?? const [])
            .map((e) => HifzCard.fromJson((e as Map).cast(), isNew: false))
            .toList(),
        fresh: ((j['new'] as List?) ?? const []).map((e) => HifzCard.fromJson((e as Map).cast(), isNew: true)).toList(),
      );
}

class WordResult {
  WordResult({required this.ayahId, required this.position, required this.text, required this.status, this.heard});
  final int ayahId;
  final int position;
  final String text;
  final String status; // correct | mispronounced | wrong | skipped | unclear | not_recited
  final String? heard;
  factory WordResult.fromJson(Map<String, dynamic> j) => WordResult(
        ayahId: _i(j['ayahId']),
        position: _i(j['position']),
        text: j['text'] as String,
        status: j['status'] as String,
        heard: j['heard'] as String?,
      );
}

class RecitationResult {
  RecitationResult(this.raw);
  final Map<String, dynamic> raw;
  Map<String, dynamic> get scores => (raw['scores'] as Map).cast<String, dynamic>();
  double get overall => _dn(scores['overall']) ?? 0;
  double get accuracy => _dn(scores['accuracy']) ?? 0;
  double get fluency => _dn(scores['fluency']) ?? 0;
  double? get tajweed => _dn(scores['tajweed']);
  bool get completed => raw['completed'] == true;
  List<WordResult> get words =>
      ((raw['words'] as List?) ?? const []).map((e) => WordResult.fromJson((e as Map).cast())).toList();
  List<Map<String, dynamic>> get mistakes => ((raw['mistakes'] as List?) ?? const []).cast<Map<String, dynamic>>();
  ActivityResult? get activity => raw['activity'] is Map ? ActivityResult((raw['activity'] as Map).cast()) : null;

  /// AI hifz test: the ayahs that were graded (SM-2 updates). Empty when nothing was covered.
  List<Map<String, dynamic>> get hifzUpdates => ((raw['hifz'] as List?) ?? const []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  HifzMilestone? get milestone => HifzMilestone.tryParse(raw['milestone']);

  /// The free 60-second clip cut the recording short.
  bool get clipped => raw['clipped'] == true;
}

class CitedAyah {
  CitedAyah(this.raw);
  final Map<String, dynamic> raw;
  String get verseKey => raw['verse_key'] as String;
  String get surahNameAr => '${raw['surah_name_ar'] ?? ''}';
  String get surahNameEn => '${raw['surah_name_en'] ?? ''}';
  String get arabic => raw['arabic'] as String;
  String? get translation => raw['translation'] as String?;
  String? get tafsir => (raw['tafsir'] ?? raw['explanation']) as String?;
  String? get tafsirSource => raw['tafsir_source'] as String?;
  String? get whyRelevant => raw['why_relevant'] as String?;
  int get ayahId => _i(raw['ayah_id']);
  int get surahId => _i(raw['surah_id']);
  int get ayahNumber => _i(raw['ayah_number']);
}

class CitedHadith {
  CitedHadith(this.raw);
  final Map<String, dynamic> raw;
  String get reference => raw['reference'] as String;
  String? get grade => raw['grade'] as String?;
  String get textAr => raw['text_ar'] as String;
  String? get textEn => raw['text_en'] as String?;
  String? get whyRelevant => raw['why_relevant'] as String?;
}

class GroundedAnswer {
  GroundedAnswer(this.raw);
  final Map<String, dynamic> raw;
  String? get conversationId => raw['conversation_id'] as String?;
  String get answerType => '${raw['answer_type'] ?? 'answer'}';
  String get explanation => '${raw['explanation'] ?? ''}';
  String? get scholarlyDifferences => raw['scholarly_differences'] as String?;
  String get disclaimer => '${raw['disclaimer'] ?? ''}';
  List<CitedAyah> get quran => ((raw['quran'] as List?) ?? const []).map((e) => CitedAyah((e as Map).cast())).toList();
  List<CitedHadith> get hadith =>
      ((raw['hadith'] as List?) ?? const []).map((e) => CitedHadith((e as Map).cast())).toList();
  List<String> get followUps => ((raw['follow_up_questions'] as List?) ?? const []).map((e) => '$e').toList();
  int? get remaining => raw['quota'] is Map ? _i((raw['quota'] as Map)['remaining']) : null;
}
