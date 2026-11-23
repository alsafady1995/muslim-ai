import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_ai/data/models.dart';

void main() {
  test('reciter builds EveryAyah URLs with zero padding', () {
    final r = Reciter(id: 1, nameEn: 'A', nameAr: 'ب', template: 'https://x/{surah3}{ayah3}.mp3', isPremium: false);
    expect(r.urlFor(2, 7), 'https://x/002007.mp3');
  });

  test('dashboard maps goals to today progress', () {
    final d = Dashboard({
      'profile': {'xp': 120, 'level': 2, 'level_start_xp': 50, 'next_level_xp': 200, 'current_streak': 3},
      'today': {'ayahs_read': 4, 'prayers_logged': 5},
      'goals': [
        {'type': 'quran_read', 'target': 5},
        {'type': 'prayer', 'target': 5},
      ],
      'premium': false,
    });
    expect(d.goals['quran_read'], (4, 5));
    expect(d.goals['prayer'], (5, 5));
    expect(d.streak, 3);
    expect(d.premium, isFalse);
  });

  test('grounded answer keeps quran, hadith and interpretation separate', () {
    final a = GroundedAnswer({
      'answer_type': 'answer',
      'quran': [
        {'verse_key': '2:153', 'arabic': 'نص', 'surah_id': 2, 'ayah_number': 153, 'why_relevant': 'patience'},
      ],
      'hadith': [
        {'reference': 'Muslim 2999', 'text_ar': 'نص', 'grade': 'Sahih'},
      ],
      'explanation': 'e',
      'scholarly_differences': null,
      'follow_up_questions': ['q1'],
      'disclaimer': 'd',
    });
    expect(a.quran.single.verseKey, '2:153');
    expect(a.hadith.single.grade, 'Sahih');
    expect(a.scholarlyDifferences, isNull);
    expect(a.followUps, ['q1']);
  });

  test('recitation result exposes word statuses', () {
    final r = RecitationResult({
      'scores': {'overall': 88.5, 'accuracy': 90, 'fluency': 80, 'tajweed': null},
      'completed': true,
      'words': [
        {'ayahId': 1, 'position': 1, 'text': 'بِسْمِ', 'status': 'correct'},
        {'ayahId': 1, 'position': 2, 'text': 'ٱللَّهِ', 'status': 'skipped'},
      ],
      'mistakes': [
        {'type': 'skipped', 'ayahId': 1, 'position': 2},
      ],
    });
    expect(r.overall, 88.5);
    expect(r.tajweed, isNull);
    expect(r.words.map((w) => w.status), ['correct', 'skipped']);
  });
}
