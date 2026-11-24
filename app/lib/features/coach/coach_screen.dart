import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/analytics.dart';
import '../../core/api.dart';
import '../../core/config.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../quran/audio_controller.dart';
import 'coach_result_view.dart';

enum _Phase { pick, ready, recording, analysing, result }

/// AI Quran Coach: user recites a range aloud; we upload the audio and the
/// recitation-analyze function returns word-level mistakes and scores.
class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key, this.startAyahId, this.endAyahId, this.hifzMode = false});
  final int? startAyahId;
  final int? endAyahId;
  final bool hifzMode;
  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  static const maxDuration = Duration(minutes: 3);
  final _recorder = AudioRecorder();
  _Phase _phase = _Phase.pick;
  List<Ayah> _ayahs = [];
  int _surah = 1, _from = 1, _to = 7;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  String? _path;
  RecitationResult? _result;
  late bool _hideText = widget.hifzMode;

  @override
  void initState() {
    super.initState();
    if (widget.startAyahId != null) _loadRange(widget.startAyahId!, widget.endAyahId ?? widget.startAyahId!);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _loadRange(int fromId, int toId) async {
    final ayahs = await ref.read(quranRepoProvider).ayahRange(fromId, toId);
    if (!mounted) return;
    setState(() {
      _ayahs = ayahs;
      _phase = _Phase.ready;
    });
  }

  Future<void> _pickRange() async {
    final repo = ref.read(quranRepoProvider);
    final fromId = await repo.ayahId(_surah, _from);
    final toId = await repo.ayahId(_surah, _to < _from ? _from : _to);
    await _loadRange(fromId, toId);
  }

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.micPermissionNeeded)));
      return;
    }
    await ref.read(audioProvider.notifier).stop();
    // On web the recorder keeps audio in memory (blob URL); there is no temp dir.
    var encoder = AudioEncoder.aacLc;
    if (kIsWeb) {
      _path = '';
      if (!await _recorder.isEncoderSupported(encoder)) {
        encoder = AudioEncoder.opus;
      }
    } else {
      final dir = await getTemporaryDirectory();
      _path = '${dir.path}/recitation_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }
    await _recorder.start(
      RecordConfig(encoder: encoder, sampleRate: 16000, numChannels: 1, bitRate: 48000),
      path: _path!,
    );
    Analytics.track(Events.recitationStarted, {'ayahs': _ayahs.length, 'mode': widget.hifzMode ? 'hifz' : 'read'});
    setState(() {
      _phase = _Phase.recording;
      _elapsed = Duration.zero;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
      if (_elapsed >= maxDuration) _stopAndAnalyse();
    });
  }

  Future<void> _stopAndAnalyse() async {
    _timer?.cancel();
    final path = await _recorder.stop() ?? _path;
    if (path == null) return;
    if (_elapsed.inSeconds < 2) {
      setState(() => _phase = _Phase.ready);
      return;
    }
    setState(() => _phase = _Phase.analysing);
    final db = ref.read(supabaseProvider);
    final uid = db.auth.currentUser!.id;
    final id = const Uuid().v4();
    final storagePath = '$uid/$id.m4a';
    try {
      if (AppConfig.demoMode) {
        // Preview: nothing is uploaded; the simulated analysis only needs the range.
        final res = await ref.read(edgeApiProvider).call('recitation-analyze', {
          'start_ayah_id': _ayahs.first.id,
          'end_ayah_id': _ayahs.last.id,
          'mode': widget.hifzMode ? 'hifz' : 'read',
        });
        _showResult(RecitationResult(res));
        return;
      }
      await db.storage.from('recitations').upload(storagePath, File(path),
          fileOptions: const FileOptions(contentType: 'audio/mp4'));
      await db.from('recitation_sessions').insert({
        'id': id,
        'user_id': uid,
        'mode': widget.hifzMode ? 'hifz' : 'read',
        'start_ayah_id': _ayahs.first.id,
        'end_ayah_id': _ayahs.last.id,
        'audio_path': storagePath,
      });
      Analytics.track(Events.recitationSubmitted, {'seconds': _elapsed.inSeconds});
      final res = await ref.read(edgeApiProvider).call('recitation-analyze', {'session_id': id});
      _showResult(RecitationResult(res));
    } on QuotaExceeded {
      Analytics.track(Events.quotaHit, {'feature': 'recitation'});
      setState(() => _phase = _Phase.ready);
      if (mounted) context.push('/paywall?source=recitation_quota');
    } catch (_) {
      setState(() => _phase = _Phase.ready);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.analysisFailed)));
    } finally {
      if (!kIsWeb) {
        File(path).delete().ignore();
      }
    }
  }

  void _showResult(RecitationResult result) {
    ref.invalidate(dashboardProvider);
    Analytics.track(Events.recitationResultViewed, {'overall': result.overall});
    setState(() {
      _result = result;
      _phase = _Phase.result;
    });
    if (mounted) showXpToast(context, result.activity?.xpAwarded ?? 0, achievements: result.activity?.newAchievements ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hifzMode ? l10n.hifzTest : l10n.aiCoach),
        actions: [
          if (_phase == _Phase.ready || _phase == _Phase.recording)
            IconButton(
              icon: Icon(_hideText ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _hideText = !_hideText),
            ),
        ],
      ),
      body: SafeArea(child: switch (_phase) {
        _Phase.pick => _picker(context),
        _Phase.analysing => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.analysing),
            ]),
          ),
        _Phase.result => CoachResultView(
            result: _result!,
            ayahs: _ayahs,
            onRetry: () => setState(() => _phase = _Phase.ready),
            onListen: () => ref.read(audioProvider.notifier).play(_ayahs, startIndex: 0, repeatEach: 1),
          ),
        _ => _recitePanel(context),
      }),
    );
  }

  Widget _picker(BuildContext context) {
    final l10n = context.l10n;
    final surahs = ref.watch(surahsProvider).value ?? [];
    final surah = surahs.where((s) => s.id == _surah).firstOrNull;
    final max = surah?.ayahCount ?? 7;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text(l10n.chooseWhatToRecite, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      DropdownButtonFormField<int>(
        initialValue: _surah,
        decoration: InputDecoration(labelText: l10n.surah),
        items: [for (final s in surahs) DropdownMenuItem(value: s.id, child: Text('${s.id}. ${context.isArabic ? s.nameAr : s.transliteration}'))],
        onChanged: (v) => setState(() {
          _surah = v ?? 1;
          _from = 1;
          _to = 1;
        }),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _numberField(l10n.fromAyah, _from, max, (v) => setState(() => _from = v))),
        const SizedBox(width: 12),
        Expanded(child: _numberField(l10n.toAyah, _to, max, (v) => setState(() => _to = v))),
      ]),
      const SizedBox(height: 8),
      Text(l10n.coachRangeHint, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 24),
      FilledButton(onPressed: _pickRange, child: Text(l10n.continueLabel)),
    ]);
  }

  Widget _numberField(String label, int value, int max, ValueChanged<int> onChanged) => DropdownButtonFormField<int>(
        initialValue: value.clamp(1, max),
        decoration: InputDecoration(labelText: label),
        items: [for (var i = 1; i <= max; i++) DropdownMenuItem(value: i, child: Text('$i'))],
        onChanged: (v) => onChanged(v ?? 1),
      );

  Widget _recitePanel(BuildContext context) {
    final l10n = context.l10n;
    final recording = _phase == _Phase.recording;
    final scheme = Theme.of(context).colorScheme;
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          if (_hideText)
            Card(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.reciteFromMemory, textAlign: TextAlign.center)))
          else
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(_ayahs.map((a) => '${a.textUthmani} ﴿${a.ayahNumber}﴾').join(' '),
                  style: AppTheme.quran(context), textAlign: TextAlign.justify),
            ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text(recording ? '${_elapsed.inMinutes}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}' : l10n.tapToRecite,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: recording ? _stopAndAnalyse : _start,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: recording ? 96 : 84,
              height: recording ? 96 : 84,
              decoration: BoxDecoration(shape: BoxShape.circle, color: recording ? AppColors.error : scheme.primary),
              child: Icon(recording ? Icons.stop : Icons.mic, color: Colors.white, size: 40),
            ),
          ),
        ]),
      ),
    ]);
  }
}
