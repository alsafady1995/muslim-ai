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

import '../../core/ai_budget.dart';
import '../../core/analytics.dart';
import '../../core/api.dart';
import '../../core/config.dart';
import '../../core/monetization.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../quran/audio_controller.dart';
import 'coach_result_view.dart';

enum _Phase { pick, ready, recording, analysing, result }

/// AI Quran Coach: user recites a range aloud; we upload the audio and the
/// recitation-analyze function returns word-level mistakes and scores.
///
/// [source]: coach (default) | onboarding (first Al-Fatiha check, free) | hifz | weak_words.
/// When opened from onboarding or a hifz session, the screen returns its
/// [RecitationResult] to the caller (null if the user left without one).
class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key, this.startAyahId, this.endAyahId, this.hifzMode = false, this.source = 'coach'});
  final int? startAyahId;
  final int? endAyahId;
  final bool hifzMode;
  final String source;

  /// Most ayahs one check may cover (recitation_sessions check constraint).
  static const maxAyahs = 50;
  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _recorder = AudioRecorder();
  bool _stopping = false;

  bool get _returnsResult => widget.source == 'onboarding' || widget.hifzMode;
  String get _feature => widget.hifzMode ? 'hifz' : 'recitation';

  /// No Premium offers during onboarding (the router would bounce /paywall back to onboarding).
  bool get _canOffer => widget.source != 'onboarding';

  /// Free checks stop at 60 s, Premium/trial at 3 min (server enforces the same).
  Duration get _maxDuration {
    final q = ref.read(weeklyQuotaProvider).value;
    final premium = ref.read(premiumProvider).value ?? false;
    return Duration(seconds: q?.clipSeconds ?? (premium ? 180 : 60));
  }
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
    if (widget.startAyahId != null) {
      final end = widget.endAyahId ?? widget.startAyahId!;
      _loadRange(widget.startAyahId!, end.clamp(widget.startAyahId!, widget.startAyahId! + CoachScreen.maxAyahs - 1));
    }
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
    final to = (_to < _from ? _from : _to).clamp(_from, _from + CoachScreen.maxAyahs - 1);
    final fromId = await repo.ayahId(_surah, _from);
    final toId = await repo.ayahId(_surah, to);
    await _loadRange(fromId, toId);
  }

  Future<void> _start() async {
    // Check the weekly limit before the user spends a minute reciting, not after.
    final quota = await ref.read(weeklyQuotaProvider.future).catchError((_) => WeeklyQuota(const {}));
    final freeOnboarding = widget.source == 'onboarding' && quota.onboardingCheckAvailable;
    if (!freeOnboarding && quota.raw.isNotEmpty && quota.remaining(_feature) <= 0) {
      if (mounted) {
        await showLimitSheet(
            context, QuotaExceeded(_feature, premium: quota.premium, limit: quota.limit(_feature), resetsAt: quota.resetsAt),
            allowUpgrade: _canOffer);
      }
      return;
    }
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
    final max = _maxDuration;
    setState(() {
      _phase = _Phase.recording;
      _elapsed = Duration.zero;
      _stopping = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
      if (_elapsed >= max) _stopAndAnalyse();
    });
  }

  Future<void> _stopAndAnalyse() async {
    // The timer and a tap can both stop the recording; analyse once.
    if (_stopping || _phase != _Phase.recording) return;
    _stopping = true;
    _timer?.cancel();
    final path = await _recorder.stop() ?? _path;
    if (path == null) {
      setState(() => _phase = _Phase.ready);
      return;
    }
    if (_elapsed.inSeconds < 2) {
      setState(() => _phase = _Phase.ready);
      return;
    }
    setState(() => _phase = _Phase.analysing);
    final db = ref.read(supabaseProvider);
    final uid = db.auth.currentUser!.id;
    final id = const Uuid().v4();
    final storagePath = '$uid/$id.m4a';
    var uploaded = false;
    try {
      if (AppConfig.demoMode) {
        // Preview: nothing is uploaded; the simulated analysis only needs the range.
        final res = await ref.read(edgeApiProvider).call('recitation-analyze', {
          'start_ayah_id': _ayahs.first.id,
          'end_ayah_id': _ayahs.last.id,
          'mode': widget.hifzMode ? 'hifz' : 'read',
          'source': widget.source,
          'seconds': _elapsed.inSeconds,
        });
        _showResult(RecitationResult(res));
        return;
      }
      await db.storage.from('recitations').upload(storagePath, File(path),
          fileOptions: const FileOptions(contentType: 'audio/mp4'));
      uploaded = true;
      await db.from('recitation_sessions').insert({
        'id': id,
        'user_id': uid,
        'mode': widget.hifzMode ? 'hifz' : 'read',
        'start_ayah_id': _ayahs.first.id,
        'end_ayah_id': _ayahs.last.id,
        'audio_path': storagePath,
      });
      Analytics.track(Events.recitationSubmitted, {'seconds': _elapsed.inSeconds});
      final res = await ref
          .read(edgeApiProvider)
          .call('recitation-analyze', {'session_id': id, 'source': widget.source});
      _showResult(RecitationResult(res));
    } on AiBudgetExhausted catch (e) {
      if (!mounted) return;
      setState(() => _phase = _Phase.ready);
      showAiBudgetExhausted(context, e, allowUpgrade: _canOffer);
    } on QuotaExceeded catch (e) {
      ref.invalidate(weeklyQuotaProvider);
      if (!mounted) return;
      setState(() => _phase = _Phase.ready);
      await showLimitSheet(context, e, allowUpgrade: _canOffer);
    } catch (_) {
      // If the upload worked but the session insert or the call failed before the server
      // took over, the recording would stay in storage: remove it (privacy promise).
      if (uploaded) db.storage.from('recitations').remove([storagePath]).ignore();
      if (!mounted) return;
      setState(() => _phase = _Phase.ready);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.analysisFailed)));
    } finally {
      if (!kIsWeb) {
        File(path).delete().ignore();
      }
    }
  }

  void _showResult(RecitationResult result) {
    ref.invalidate(dashboardProvider);
    ref.invalidate(weeklyQuotaProvider);
    Analytics.track(Events.recitationResultViewed, {'overall': result.overall});
    setState(() {
      _result = result;
      _phase = _Phase.result;
    });
    if (mounted) showXpToast(context, result.activity?.xpAwarded ?? 0, achievements: result.activity?.newAchievements ?? []);
  }

  void _finish() => Navigator.of(context).pop(_result);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final premium = ref.watch(premiumProvider).value ?? false;
    final scaffold = Scaffold(
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
            onContinue: _returnsResult ? _finish : null,
            notes: [
              // A plain line, not a popup: never sell right after someone recited.
              if (_result!.clipped && !premium && _canOffer)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton(
                    onPressed: () => context.push('/paywall?source=clip_limit'),
                    child: Text(l10n.clipNoteFree, textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        _ => _recitePanel(context),
      }),
    );
    if (!_returnsResult) return scaffold;
    // Back from a result returns it to the caller (hifz session / onboarding).
    return PopScope(
      canPop: _phase != _Phase.result,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _phase == _Phase.result) _finish();
      },
      child: scaffold,
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
        Expanded(child: _numberField(l10n.fromAyah, _from, max, (v) => setState(() {
                  _from = v;
                  if (_to < v) _to = v;
                  if (_to > v + CoachScreen.maxAyahs - 1) _to = v + CoachScreen.maxAyahs - 1;
                }))),
        const SizedBox(width: 12),
        Expanded(
          child: _numberField(l10n.toAyah, _to, max, (v) => setState(() => _to = v),
              min: _from, cap: _from + CoachScreen.maxAyahs - 1),
        ),
      ]),
      const SizedBox(height: 8),
      Text('${l10n.coachRangeHint} ${l10n.rangeTooLong}', style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 4),
      _checksLeft(context),
      const SizedBox(height: 24),
      FilledButton(onPressed: _pickRange, child: Text(l10n.continueLabel)),
    ]);
  }

  Widget _numberField(String label, int value, int max, ValueChanged<int> onChanged, {int min = 1, int? cap}) {
    final hi = cap == null ? max : (cap < max ? cap : max);
    final lo = min > hi ? hi : min;
    return DropdownButtonFormField<int>(
      key: ValueKey('$label-$lo-$hi'),
      initialValue: value.clamp(lo, hi),
      decoration: InputDecoration(labelText: label),
      items: [for (var i = lo; i <= hi; i++) DropdownMenuItem(value: i, child: Text('$i'))],
      onChanged: (v) => onChanged(v ?? lo),
    );
  }

  /// "7 of 10 checks left this week" for free users; nothing for Premium.
  Widget _checksLeft(BuildContext context) {
    final q = ref.watch(weeklyQuotaProvider).value;
    if (q == null || q.premium || q.limit(_feature) == 0) return const SizedBox.shrink();
    final text = widget.hifzMode
        ? context.l10n.aiTestsLeft(q.remaining(_feature))
        : context.l10n.checksLeft(q.remaining(_feature), q.limit(_feature));
    return Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelMedium);
  }

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
          if (recording)
            Text(l10n.secondsLeft((_maxDuration - _elapsed).inSeconds.clamp(0, 999)),
                style: Theme.of(context).textTheme.labelSmall)
          else if (widget.source != 'onboarding')
            _checksLeft(context),
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
