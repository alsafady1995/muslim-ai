import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../quran/audio_controller.dart';
import 'benchmark_labels.dart';

/// Records labelled clips for the recitation accuracy benchmark (scripts/accuracy).
///
/// Only reachable in builds made with --dart-define=BENCHMARK_RECORDER=true (Settings).
/// Flow: consent → who is reciting → pick a range → record → mark mistakes → save.
/// The clip goes to the private "benchmark-clips" bucket and a benchmark_clips row.
class BenchmarkRecorderScreen extends ConsumerStatefulWidget {
  const BenchmarkRecorderScreen({super.key});

  /// Same cap as the coach and the benchmark_clips check constraint.
  static const maxAyahs = 50;
  static const maxDuration = Duration(minutes: 3);

  @override
  ConsumerState<BenchmarkRecorderScreen> createState() => _BenchmarkRecorderScreenState();
}

enum _Step { consent, setup, ready, recording, label, saving, saved }

const _consentKey = 'bench_consented_at';
const _speakerKey = 'bench_speaker';
const _nativeKey = 'bench_native';
const _envKey = 'bench_environment';

class _BenchmarkRecorderScreenState extends ConsumerState<BenchmarkRecorderScreen> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final _labels = ClipLabels();

  late _Step _step = _prefs.getString(_consentKey) == null ? _Step.consent : _Step.setup;
  late String _speaker = _prefs.getString(_speakerKey) ?? 'man';
  late bool _native = _prefs.getBool(_nativeKey) ?? true;
  late String _environment = _prefs.getString(_envKey) ?? 'quiet';

  int _surah = 1, _from = 1, _to = 7;
  int _fromId = 0, _toId = 0;
  List<BenchmarkWord> _words = [];
  String? _path;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  int? _savedCount;

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);
  SupabaseClient get _db => ref.read(supabaseProvider);

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _player.dispose();
    _deleteLocal();
    super.dispose();
  }

  void _deleteLocal() {
    final p = _path;
    if (p != null && p.isNotEmpty) File(p).delete().ignore();
    _path = null;
  }

  Future<void> _refreshCount() async {
    try {
      final rows = await _db.from('benchmark_clips').select('id');
      if (mounted) setState(() => _savedCount = rows.length);
    } catch (_) {/* count is informational */}
  }

  void _snack(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _agree() async {
    await _prefs.setString(_consentKey, DateTime.now().toUtc().toIso8601String());
    setState(() => _step = _Step.setup);
  }

  Future<void> _loadRange() async {
    final repo = ref.read(quranRepoProvider);
    final to = _to.clamp(_from, _from + BenchmarkRecorderScreen.maxAyahs - 1);
    _fromId = await repo.ayahId(_surah, _from);
    _toId = await repo.ayahId(_surah, to);
    final rows = await _db
        .from('ayah_words')
        .select('ayah_id, position, text_uthmani')
        .gte('ayah_id', _fromId)
        .lte('ayah_id', _toId)
        .order('ayah_id')
        .order('position')
        .limit(5000);
    await _prefs.setString(_speakerKey, _speaker);
    await _prefs.setBool(_nativeKey, _native);
    await _prefs.setString(_envKey, _environment);
    if (!mounted) return;
    setState(() {
      _words = rows.map(BenchmarkWord.fromJson).toList();
      _labels.clear();
      _step = _Step.ready;
    });
  }

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) _snack(context.l10n.micPermissionNeeded);
      return;
    }
    await ref.read(audioProvider.notifier).stop();
    _deleteLocal();
    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/bench_${DateTime.now().millisecondsSinceEpoch}.m4a';
    // Same settings as the coach, so the benchmark hears what real users send.
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000, numChannels: 1, bitRate: 48000),
      path: _path!,
    );
    setState(() {
      _step = _Step.recording;
      _elapsed = Duration.zero;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
      if (_elapsed >= BenchmarkRecorderScreen.maxDuration) _stop();
    });
  }

  Future<void> _stop() async {
    if (_step != _Step.recording) return;
    _timer?.cancel();
    final path = await _recorder.stop() ?? _path;
    if (!mounted) return;
    if (path == null || _elapsed.inSeconds < 2) {
      setState(() => _step = _Step.ready);
      return;
    }
    _path = path;
    await _player.setFilePath(path);
    setState(() => _step = _Step.label);
  }

  Future<void> _save() async {
    final path = _path;
    if (path == null) return;
    setState(() => _step = _Step.saving);
    final uid = _db.auth.currentUser!.id;
    final id = const Uuid().v4();
    final storagePath = '$uid/$id.m4a';
    try {
      await _db.storage
          .from('benchmark-clips')
          .upload(storagePath, File(path), fileOptions: const FileOptions(contentType: 'audio/mp4'));
      await _db.from('benchmark_clips').insert({
        'id': id,
        'user_id': uid,
        'start_ayah_id': _fromId,
        'end_ayah_id': _toId,
        'audio_path': storagePath,
        'speaker_group': _speaker,
        'native_arabic': _native,
        'environment': _environment,
        'mistakes': _labels.toMistakes(_words),
        'duration_ms': _elapsed.inMilliseconds,
        'consented_at': _prefs.getString(_consentKey),
      });
      _deleteLocal();
      await _refreshCount();
      if (mounted) setState(() => _step = _Step.saved);
    } catch (_) {
      // A file without its row would never be exported; remove it so a retry starts clean.
      _db.storage.from('benchmark-clips').remove([storagePath]).ignore();
      if (mounted) {
        setState(() => _step = _Step.label);
        _snack(context.l10n.benchSaveFailed);
      }
    }
  }

  void _discard() {
    _player.stop();
    _deleteLocal();
    setState(() {
      _labels.clear();
      _step = _Step.ready;
    });
  }

  Future<void> _deleteAll() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.benchDeleteAll),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final rows = await _db.from('benchmark_clips').select('id, audio_path');
      final paths = [for (final r in rows) r['audio_path'] as String];
      if (paths.isNotEmpty) await _db.storage.from('benchmark-clips').remove(paths);
      await _db.from('benchmark_clips').delete().eq('user_id', _db.auth.currentUser!.id);
      await _refreshCount();
      _snack(l10n.benchDeleted);
    } catch (_) {
      _snack(l10n.errorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.benchTitle),
        actions: [
          if (_step != _Step.consent)
            PopupMenuButton<int>(
              onSelected: (_) => _deleteAll(),
              itemBuilder: (_) => [PopupMenuItem(value: 0, child: Text(l10n.benchDeleteAll))],
            ),
        ],
      ),
      body: SafeArea(
        child: switch (_step) {
          _Step.consent => _consent(context),
          _Step.setup => _setup(context),
          _Step.ready || _Step.recording => _recite(context),
          _Step.label || _Step.saving => _label(context),
          _Step.saved => _saved(context),
        },
      ),
    );
  }

  Widget _consent(BuildContext context) {
    final l10n = context.l10n;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text(l10n.benchConsentTitle, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Text(l10n.benchConsentBody),
      const SizedBox(height: 12),
      Text(l10n.benchConsentChild, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 24),
      FilledButton(onPressed: _agree, child: Text(l10n.benchAgree)),
    ]);
  }

  Widget _setup(BuildContext context) {
    final l10n = context.l10n;
    final surahs = ref.watch(surahsProvider).value ?? [];
    final surah = surahs.where((s) => s.id == _surah).firstOrNull;
    final max = surah?.ayahCount ?? 7;
    final toCap = (_from + BenchmarkRecorderScreen.maxAyahs - 1).clamp(_from, max);
    return ListView(padding: const EdgeInsets.all(20), children: [
      if (_savedCount != null) Text(l10n.benchCount(_savedCount!), style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 8),
      Text(l10n.benchSpeaker, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      SegmentedButton<String>(
        segments: [
          ButtonSegment(value: 'man', label: Text(l10n.benchMan)),
          ButtonSegment(value: 'woman', label: Text(l10n.benchWoman)),
          ButtonSegment(value: 'child', label: Text(l10n.benchChild)),
        ],
        selected: {_speaker},
        onSelectionChanged: (v) => setState(() => _speaker = v.first),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.benchNative),
        value: _native,
        onChanged: (v) => setState(() => _native = v),
      ),
      Text(l10n.benchEnvironment, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      SegmentedButton<String>(
        segments: [
          ButtonSegment(value: 'quiet', label: Text(l10n.benchQuiet)),
          ButtonSegment(value: 'noisy', label: Text(l10n.benchNoisy)),
        ],
        selected: {_environment},
        onSelectionChanged: (v) => setState(() => _environment = v.first),
      ),
      const SizedBox(height: 20),
      DropdownButtonFormField<int>(
        initialValue: _surah,
        decoration: InputDecoration(labelText: l10n.surah),
        items: [
          for (final s in surahs)
            DropdownMenuItem(value: s.id, child: Text('${s.id}. ${context.isArabic ? s.nameAr : s.transliteration}')),
        ],
        onChanged: (v) => setState(() {
          _surah = v ?? 1;
          final count = surahs.where((s) => s.id == _surah).firstOrNull?.ayahCount ?? 1;
          _from = 1;
          _to = count.clamp(1, BenchmarkRecorderScreen.maxAyahs);
        }),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: _numberField(l10n.fromAyah, _from, 1, max, (v) => setState(() {
                _from = v;
                _to = _to.clamp(v, (v + BenchmarkRecorderScreen.maxAyahs - 1).clamp(v, max));
              })),
        ),
        const SizedBox(width: 12),
        Expanded(child: _numberField(l10n.toAyah, _to.clamp(_from, toCap), _from, toCap, (v) => setState(() => _to = v))),
      ]),
      const SizedBox(height: 24),
      FilledButton(onPressed: _loadRange, child: Text(l10n.continueLabel)),
    ]);
  }

  Widget _numberField(String label, int value, int lo, int hi, ValueChanged<int> onChanged) {
    return DropdownButtonFormField<int>(
      key: ValueKey('$label-$lo-$hi'),
      initialValue: value.clamp(lo, hi),
      decoration: InputDecoration(labelText: label),
      items: [for (var i = lo; i <= hi; i++) DropdownMenuItem(value: i, child: Text('$i'))],
      onChanged: (v) => onChanged(v ?? lo),
    );
  }

  Widget _wordsView(BuildContext context, {required bool labelling}) {
    final scheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(spacing: 6, runSpacing: 8, children: [
        for (final w in _words)
          Builder(builder: (_) {
            final label = _labels.of(w);
            final (bg, fg) = switch (label) {
              WordLabel.correct => (scheme.surfaceContainerHighest, scheme.onSurface),
              WordLabel.wrong => (scheme.errorContainer, scheme.onErrorContainer),
              WordLabel.skipped => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
            };
            final chip = Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(w.text, style: TextStyle(fontSize: 22, color: fg)),
                if (label != WordLabel.correct)
                  Text(label == WordLabel.wrong ? context.l10n.benchWrong : context.l10n.benchSkipped,
                      style: TextStyle(fontSize: 11, color: fg)),
              ]),
            );
            return labelling ? InkWell(onTap: () => setState(() => _labels.cycle(w)), child: chip) : chip;
          }),
      ]),
    );
  }

  Widget _recite(BuildContext context) {
    final l10n = context.l10n;
    final recording = _step == _Step.recording;
    final mm = _elapsed.inMinutes.toString().padLeft(2, '0');
    final ss = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(l10n.benchRecitePrompt),
          const SizedBox(height: 16),
          _wordsView(context, labelling: false),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          if (recording) Text('$mm:$ss', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: recording
                ? FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                    onPressed: _stop,
                    icon: const Icon(Icons.stop),
                    label: Text(l10n.benchStopRecording),
                  )
                : FilledButton.icon(onPressed: _start, icon: const Icon(Icons.mic), label: Text(l10n.benchStartRecording)),
          ),
          if (!recording)
            TextButton(onPressed: () => setState(() => _step = _Step.setup), child: Text(l10n.cancel)),
        ]),
      ),
    ]);
  }

  Widget _label(BuildContext context) {
    final l10n = context.l10n;
    final saving = _step == _Step.saving;
    final n = _labels.mistakeCount;
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(l10n.benchLabelTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(l10n.benchLabelHint),
          const SizedBox(height: 12),
          StreamBuilder<bool>(
            stream: _player.playingStream,
            builder: (_, snap) {
              final playing = snap.data ?? false;
              return OutlinedButton.icon(
                onPressed: () async {
                  if (playing) {
                    await _player.pause();
                  } else {
                    if (_player.processingState == ProcessingState.completed) await _player.seek(Duration.zero);
                    await _player.play();
                  }
                },
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                label: Text(l10n.benchListenBack),
              );
            },
          ),
          const SizedBox(height: 16),
          _wordsView(context, labelling: !saving),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text(n == 0 ? l10n.benchNoMistakes : l10n.benchMistakesMarked(n)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: saving ? null : _save,
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.benchSave),
            ),
          ),
          TextButton(onPressed: saving ? null : _discard, child: Text(l10n.benchDiscard)),
        ]),
      ),
    ]);
  }

  Widget _saved(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_outline, size: 56),
          const SizedBox(height: 12),
          Text(l10n.benchSaved, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          if (_savedCount != null) ...[const SizedBox(height: 8), Text(l10n.benchCount(_savedCount!))],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => setState(() {
              _labels.clear();
              _step = _Step.setup;
            }),
            child: Text(l10n.benchAnother),
          ),
        ]),
      ),
    );
  }
}
