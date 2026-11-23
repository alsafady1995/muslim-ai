import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

/// Read-only Quran content. Content rarely changes, so results are cached in memory
/// for the app session (offline download support is Phase 2).
class QuranRepository {
  QuranRepository(this._db);
  final SupabaseClient _db;

  List<Surah>? _surahs;
  List<Reciter>? _reciters;
  final _ayahCache = <String, List<Ayah>>{};

  Future<List<Surah>> surahs() async {
    if (_surahs != null) return _surahs!;
    final rows = await _db.from('surahs').select().order('id');
    return _surahs = rows.map(Surah.fromJson).toList();
  }

  Future<Surah> surah(int id) async => (await surahs()).firstWhere((s) => s.id == id);

  Future<List<Ayah>> ayahsOfSurah(int surahId, {int translationId = 20}) async {
    final key = '$surahId:$translationId';
    if (_ayahCache.containsKey(key)) return _ayahCache[key]!;
    final rows = await _db
        .from('ayahs')
        .select('id, surah_id, ayah_number, text_uthmani, page, juz, ayah_translations(text)')
        .eq('surah_id', surahId)
        .eq('ayah_translations.translation_id', translationId)
        .order('ayah_number');
    return _ayahCache[key] = rows.map(Ayah.fromJson).toList();
  }

  Future<List<Ayah>> ayahRange(int fromId, int toId, {int translationId = 20}) async {
    final rows = await _db
        .from('ayahs')
        .select('id, surah_id, ayah_number, text_uthmani, page, juz, ayah_translations(text)')
        .gte('id', fromId)
        .lte('id', toId)
        .eq('ayah_translations.translation_id', translationId)
        .order('id');
    return rows.map(Ayah.fromJson).toList();
  }

  /// Global ayah id for a surah:ayah reference.
  Future<int> ayahId(int surahId, int ayahNumber) async {
    final row = await _db.from('ayahs').select('id').eq('surah_id', surahId).eq('ayah_number', ayahNumber).single();
    return (row['id'] as num).toInt();
  }

  Future<List<Reciter>> reciters() async {
    if (_reciters != null) return _reciters!;
    final rows = await _db.from('reciters').select().order('sort');
    return _reciters = rows.map(Reciter.fromJson).toList();
  }

  Future<List<DhikrCategory>> adhkarCategories() async {
    final rows = await _db.from('adhkar_categories').select().order('sort');
    return rows.map(DhikrCategory.fromJson).toList();
  }

  Future<List<Dhikr>> adhkar(int categoryId) async {
    final rows = await _db.from('adhkar').select().eq('category_id', categoryId).order('sort');
    return rows.map(Dhikr.fromJson).toList();
  }
}
