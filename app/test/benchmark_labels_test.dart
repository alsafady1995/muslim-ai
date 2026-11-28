import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_ai/features/benchmark/benchmark_labels.dart';

void main() {
  const words = [
    BenchmarkWord(ayahId: 2, position: 1, text: 'ٱلْحَمْدُ'),
    BenchmarkWord(ayahId: 2, position: 2, text: 'لِلَّهِ'),
    BenchmarkWord(ayahId: 2, position: 3, text: 'رَبِّ'),
  ];

  test('every word starts correct and a clean clip saves no mistakes', () {
    final labels = ClipLabels();
    expect(words.map(labels.of), everyElement(WordLabel.correct));
    expect(labels.toMistakes(words), isEmpty);
  });

  test('tapping cycles correct, wrong, skipped, correct', () {
    final labels = ClipLabels();
    expect(labels.cycle(words[1]), WordLabel.wrong);
    expect(labels.cycle(words[1]), WordLabel.skipped);
    expect(labels.cycle(words[1]), WordLabel.correct);
    expect(labels.mistakeCount, 0);
  });

  test('mistakes are saved in reading order with the server field names', () {
    final labels = ClipLabels()
      ..cycle(words[2])
      ..cycle(words[0])
      ..cycle(words[0]);
    expect(labels.toMistakes(words), [
      {'ayah_id': 2, 'position': 1, 'type': 'skipped'},
      {'ayah_id': 2, 'position': 3, 'type': 'wrong'},
    ]);
  });

  test('words parse from ayah_words rows', () {
    final w = BenchmarkWord.fromJson({'ayah_id': 5, 'position': 2, 'text_uthmani': 'x'});
    expect(w.key, '5:2');
  });
}
