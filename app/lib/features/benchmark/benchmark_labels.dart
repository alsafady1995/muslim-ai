/// Ground-truth labels for one accuracy-benchmark clip.
///
/// Every word starts as correct. Tapping a word cycles correct → wrong → skipped → correct.
/// What is saved (benchmark_clips.mistakes) lists only the words that were not correct;
/// scripts/accuracy treats every other word of the range as recited correctly.
library;

enum WordLabel { correct, wrong, skipped }

class BenchmarkWord {
  const BenchmarkWord({required this.ayahId, required this.position, required this.text});
  final int ayahId;
  final int position;
  final String text;

  String get key => '$ayahId:$position';

  factory BenchmarkWord.fromJson(Map<String, dynamic> j) => BenchmarkWord(
        ayahId: (j['ayah_id'] as num).toInt(),
        position: (j['position'] as num).toInt(),
        text: j['text_uthmani'] as String,
      );
}

class ClipLabels {
  final _labels = <String, WordLabel>{};

  WordLabel of(BenchmarkWord w) => _labels[w.key] ?? WordLabel.correct;

  /// Next label in the cycle; returns it.
  WordLabel cycle(BenchmarkWord w) {
    final next = WordLabel.values[(of(w).index + 1) % WordLabel.values.length];
    if (next == WordLabel.correct) {
      _labels.remove(w.key);
    } else {
      _labels[w.key] = next;
    }
    return next;
  }

  int get mistakeCount => _labels.length;

  void clear() => _labels.clear();

  /// benchmark_clips.mistakes, in reading order.
  List<Map<String, Object>> toMistakes(List<BenchmarkWord> words) => [
        for (final w in words)
          if (_labels[w.key] case final label?)
            {'ayah_id': w.ayahId, 'position': w.position, 'type': label.name},
      ];
}
