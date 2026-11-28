import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_ai/data/groups_repository.dart';
import 'package:muslim_ai/features/groups/groups_common.dart';
import 'package:muslim_ai/l10n/app_localizations_ar.dart';
import 'package:muslim_ai/l10n/app_localizations_en.dart';

GroupCall _call(String kind, {String? reason, String? name, String? sender = 'أم أحمد'}) => GroupCall({
      'id': 1,
      'group_id': 'g',
      'sender_id': sender == null ? null : 'u',
      'sender_name': sender,
      'kind': kind,
      'reason': reason,
      'dedication': name,
      'created_at': '2026-11-28T07:00:00Z',
      'open': true,
      'total': 0,
      'responders': 0,
      'mine': 0,
    });

void main() {
  final ar = AppLocalizationsAr();
  final en = AppLocalizationsEn();

  test('khatma call reads with its intention and name', () {
    expect(callText(ar, _call('khatma', reason: 'deceased', name: 'جدي')), 'أم أحمد: هيا نختم ختمة لروح جدي');
    expect(callText(en, _call('khatma', reason: 'sick')), "أم أحمد: let's complete a khatma for the sick");
    expect(callText(ar, _call('dua', reason: 'general', name: 'ignored')), 'أم أحمد: ادعوا بنية عامة');
  });

  test('khatma done has no sender', () {
    expect(callText(ar, _call('khatma_done', reason: 'exam', name: 'سارة', sender: null)), 'تمّت الختمة بالتوفيق لـسارة. تقبّل الله منكم');
  });

  test('counter calls and reasons', () {
    expect(isCounterCall('salawat'), isTrue);
    expect(isCounterCall('istighfar'), isTrue);
    expect(isCounterCall('adhkar_morning'), isFalse);
    expect(callReasons.first, 'general');
    for (final r in callReasons) {
      expect(reasonLabel(ar, r), isNotEmpty);
    }
  });

  test('board parses rows and the champion', () {
    final b = GroupBoard({
      'rows': [
        {'user_id': 'a', 'display_name': 'سارة', 'xp_week': 120, 'ayahs_week': 40, 'adhkar_week': 2, 'hifz_week': 8,
         'streak': 3, 'juz_round': 2, 'calls_week': 1},
      ],
      'last_week_champion': {'display_name': 'عمر'},
      'resets_at': '2026-11-27T21:00:00Z',
    });
    expect(b.rows.single.hifzWeek, 8);
    expect(b.championName, 'عمر');
    expect(b.resetsAt, isNotNull);
  });
}
