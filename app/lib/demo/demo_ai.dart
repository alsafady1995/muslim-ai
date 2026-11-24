import 'dart:math';

import 'demo_store.dart';

/// Simulated AI for the web preview. No model is called: answers cite real
/// verses (picked by topic keywords or plain keyword search over the bundled
/// Quran text), and the explanation says plainly that it is a placeholder.
abstract final class DemoAi {
  /// topic keywords (ar/en, diacritics-free) -> verse keys
  static const _topics = <List<String>, List<String>>{
    ['قلق', 'توتر', 'هم', 'حزن', 'ضيق', 'stress', 'anxiety', 'anxious', 'worry', 'sad']: [
      '13:28',
      '94:5',
      '94:6',
      '2:286',
      '65:3',
    ],
    ['عفو', 'مغفره', 'توبه', 'ذنب', 'forgive', 'forgiveness', 'repent', 'sin']: ['39:53', '3:134', '24:22', '4:110'],
    ['غضب', 'anger', 'angry']: ['3:134', '42:37', '41:34'],
    ['شكر', 'gratitude', 'grateful', 'thank']: ['14:7', '2:152', '31:12'],
    ['صبر', 'patience', 'patient']: ['2:153', '2:155', '39:10'],
    ['اسره', 'والدين', 'اهل', 'family', 'parents']: ['17:23', '17:24', '31:14'],
    ['نجاح', 'فلاح', 'success']: ['23:1', '87:14', '91:9'],
    ['احسان', 'لطف', 'kindness', 'kind']: ['16:90', '2:83', '4:36'],
    ['تجاره', 'بيع', 'business', 'trade']: ['2:275', '4:29', '83:1'],
  };

  static List<int> _topicAyahs(DemoStore s, String text) {
    final q = DemoStore.simplify(text.toLowerCase());
    for (final e in _topics.entries) {
      if (e.key.any(q.contains)) {
        return [for (final k in e.value) s.ayahId(int.parse(k.split(':')[0]), int.parse(k.split(':')[1]))];
      }
    }
    return [];
  }

  static List<int> _find(DemoStore s, String text, int limit) {
    final topic = _topicAyahs(s, text);
    if (topic.isNotEmpty) return topic.take(limit).toList();
    // fall back to the longest words of the question as keywords
    final words = text.split(RegExp(r'[\s،,.?؟!]+')).where((w) => w.length >= 4).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final w in words) {
      final hits = s.keywordSearch(w, limit: limit);
      if (hits.isNotEmpty) return hits;
    }
    return [];
  }

  static Map<String, dynamic> _cite(DemoStore s, int id, bool ar) {
    final row = s.ayahRow(id);
    final surah = s.surahs[(row['surah_id'] as int) - 1];
    return {
      'verse_key': '${row['surah_id']}:${row['ayah_number']}',
      'ayah_id': id,
      'surah_id': row['surah_id'],
      'ayah_number': row['ayah_number'],
      'surah_name_ar': surah['name_ar'],
      'surah_name_en': surah['transliteration'],
      'arabic': row['text_uthmani'],
      'translation': (row['ayah_translations'] as List).first['text'],
      'why_relevant': ar
          ? 'محاكاة: اختيرت هذه الآية بالبحث بالكلمات، وفي النسخة الحقيقية يشرح الذكاء الاصطناعي صلتها بسؤالك.'
          : 'Simulated: picked by keyword match. The real app explains why it is relevant.',
    };
  }

  static Map<String, dynamic> answer(
    DemoStore s,
    String question,
    String locale, {
    String? conversationId,
    required int remaining,
    required bool premium,
  }) {
    final ar = locale == 'ar';
    final ids = _find(s, question, 3);
    return {
      'conversation_id': conversationId ?? 'demo_${DateTime.now().millisecondsSinceEpoch}',
      'answer_type': 'answer',
      'explanation': ar
          ? '⚠️ هذه إجابة تجريبية (محاكاة) لأن الذكاء الاصطناعي غير موصول في نسخة المعاينة.\n\n'
                'في التطبيق الحقيقي يقرأ النموذج سؤالك: «$question» ثم يكتب شرحاً مبنياً فقط على الآيات والأحاديث المسترجعة من قاعدة البيانات، '
                '${ids.isEmpty ? 'ولم نجد آيات مطابقة بالبحث البسيط هنا.' : 'مثل الآيات المعروضة أدناه (نصها حقيقي من المصحف).'}'
          : '⚠️ This is a simulated answer: the AI is not connected in this preview.\n\n'
                'In the real app the model reads your question "$question" and writes an explanation grounded only in the '
                'verses and hadith retrieved from the database, '
                '${ids.isEmpty ? 'but the simple keyword search here found no matching verses.' : 'such as the verses below (their text is real).'}',
      'scholarly_differences': null,
      'disclaimer': ar
          ? 'نسخة تجريبية: ليست فتوى. استشر عالماً موثوقاً في المسائل الشخصية.'
          : 'Preview build: not a fatwa. Consult a qualified scholar for personal rulings.',
      'quran': [for (final id in ids) _cite(s, id, ar)],
      'hadith': <Map<String, dynamic>>[],
      'follow_up_questions': ar
          ? ['آيات عن الصبر', 'كيف أتعامل مع القلق والتوتر؟']
          : ['Verses about patience', 'How do I deal with stress?'],
      'quota': {'remaining': remaining, 'limit': s.limitFor('ask'), 'premium': premium},
    };
  }

  static Map<String, dynamic> search(DemoStore s, String query, {required bool semantic}) {
    final ids = semantic ? _find(s, query, 10) : s.keywordSearch(query, limit: 20);
    final ar = RegExp('[؀-ۿ]').hasMatch(query);
    return {
      'mode': semantic ? 'semantic' : 'keyword',
      'results': [for (final id in ids) _cite(s, id, ar)..remove('why_relevant')],
    };
  }

  /// Fake recitation analysis: most words correct, one or two flagged, so the
  /// result screen can be tried. It does not listen to the audio.
  static Map<String, dynamic> recitation(DemoStore s, Map<String, dynamic> body) {
    final from = body['start_ayah_id'] as int;
    final to = body['end_ayah_id'] as int;
    final r = Random();
    final words = <Map<String, dynamic>>[];
    for (var id = from; id <= to; id++) {
      final text = s.ayahRow(id)['text_uthmani'] as String;
      final parts = text.split(' ').where((w) => w.trim().isNotEmpty && !RegExp(r'^[ۖ-ۭ]+$').hasMatch(w));
      var pos = 1;
      for (final w in parts) {
        words.add({'ayahId': id, 'position': pos++, 'text': w, 'status': 'correct'});
      }
    }
    final mistakes = <Map<String, dynamic>>[];
    if (words.length > 3) {
      final w = words[r.nextInt(words.length)];
      w['status'] = 'mispronounced';
      w['heard'] = w['text'];
      mistakes.add({
        'type': 'mispronounced',
        'ayahId': w['ayahId'],
        'position': w['position'],
        'expected': w['text'],
        'heard': w['text'],
      });
    }
    final correct = words.where((w) => w['status'] == 'correct').length;
    final accuracy = words.isEmpty ? 0.0 : (100.0 * correct / words.length);
    final activity = s.logActivity('recitation', 1);
    final overall = double.parse((accuracy * 0.8 + 18).clamp(0, 100).toStringAsFixed(1));
    s.dayOf(s.today); // ensure exists
    s.recitations.add({
      'id': 'rec_${DateTime.now().millisecondsSinceEpoch}',
      'start_ayah_id': from,
      'end_ayah_id': to,
      'overall_score': overall,
      'accuracy_score': double.parse(accuracy.toStringAsFixed(1)),
      'mode': body['mode'] ?? 'read',
      'created_at': DateTime.now().toIso8601String(),
    });
    s.save();
    return {
      'session_id': 'demo',
      'transcript': '',
      'scores': {
        'overall': overall,
        'accuracy': double.parse(accuracy.toStringAsFixed(1)),
        'fluency': 85.0,
        'tajweed': null,
      },
      'words_total': words.length,
      'words_correct': correct,
      'completed': true,
      'words': words,
      'mistakes': mistakes,
      'activity': activity,
    };
  }
}
