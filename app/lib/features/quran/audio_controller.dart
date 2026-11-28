import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/analytics.dart';
import '../../core/providers.dart';
import '../../data/models.dart';

class AudioState {
  const AudioState({this.ayahs = const [], this.currentAyahId, this.playing = false, this.speed = 1.0, this.repeatEach = 1, this.loop = false});
  final List<Ayah> ayahs;
  final int? currentAyahId;
  final bool playing;
  final double speed;
  final int repeatEach;
  final bool loop;

  AudioState copyWith({List<Ayah>? ayahs, int? currentAyahId, bool? playing, double? speed, int? repeatEach, bool? loop}) =>
      AudioState(
        ayahs: ayahs ?? this.ayahs,
        currentAyahId: currentAyahId ?? this.currentAyahId,
        playing: playing ?? this.playing,
        speed: speed ?? this.speed,
        repeatEach: repeatEach ?? this.repeatEach,
        loop: loop ?? this.loop,
      );
}

/// Verse-by-verse Quran playback with per-verse repetition (memorization mode),
/// range looping and adjustable speed. Per-ayah files are streamed and cached by the
/// platform player; full offline download is Phase 2.
class AudioController extends Notifier<AudioState> {
  final _player = AudioPlayer();
  final _subs = <StreamSubscription>[];
  List<int> _indexToAyah = [];
  DateTime? _playStartedAt;
  int _listenedSeconds = 0;

  @override
  AudioState build() {
    _subs.add(_player.currentIndexStream.listen((i) {
      if (i != null && i < _indexToAyah.length) state = state.copyWith(currentAyahId: _indexToAyah[i]);
    }));
    _subs.add(_player.playingStream.listen((p) {
      state = state.copyWith(playing: p);
      if (p) {
        _playStartedAt = DateTime.now();
      } else {
        _accumulateListening();
      }
    }));
    // At the end of the playlist just_audio keeps `playing == true`, so listening time would
    // keep counting until the next pause (hours later) and inflate the "listen" goal and XP.
    // Pause at the end and rewind, which also makes the play button start over.
    _subs.add(_player.processingStateStream.listen((s) {
      if (s == ProcessingState.completed) {
        _player.pause().then((_) => _player.seek(Duration.zero, index: 0)).ignore();
      }
    }));
    ref.onDispose(() {
      for (final s in _subs) {
        s.cancel();
      }
      _player.dispose();
    });
    return AudioState(speed: (ref.read(prefsProvider)['speed'] as double?) ?? 1.0);
  }

  void _accumulateListening() {
    if (_playStartedAt == null) return;
    _listenedSeconds += DateTime.now().difference(_playStartedAt!).inSeconds;
    _playStartedAt = null;
    final minutes = _listenedSeconds ~/ 60;
    if (minutes > 0) {
      _listenedSeconds -= minutes * 60;
      ref.read(userRepoProvider).logActivity('listen_minute', minutes).then((_) => ref.invalidate(dashboardProvider)).ignore();
    }
  }

  Future<void> play(List<Ayah> ayahs, {required int startIndex, int? repeatEach, bool? loop}) async {
    final reciters = await ref.read(recitersProvider.future);
    final reciterId = ref.read(prefsProvider)['reciter_id'] as int? ?? 1;
    final reciter = reciters.firstWhere((r) => r.id == reciterId, orElse: () => reciters.first);
    final repeat = repeatEach ?? state.repeatEach;
    final sources = <AudioSource>[];
    _indexToAyah = [];
    for (final a in ayahs) {
      for (var r = 0; r < repeat; r++) {
        sources.add(AudioSource.uri(Uri.parse(reciter.urlFor(a.surahId, a.ayahNumber))));
        _indexToAyah.add(a.id);
      }
    }
    state = state.copyWith(ayahs: ayahs, repeatEach: repeat, loop: loop ?? state.loop, currentAyahId: ayahs[startIndex].id);
    await _player.setAudioSources(sources, initialIndex: startIndex * repeat);
    await _player.setLoopMode(state.loop ? LoopMode.all : LoopMode.off);
    await _player.setSpeed(state.speed);
    Analytics.track(Events.audioPlayed, {'reciter': reciter.id, 'repeat': repeat, 'ayahs': ayahs.length});
    unawaited(_player.play());
  }

  Future<void> toggle() => _player.playing ? _player.pause() : _player.play();
  Future<void> next() => _player.seekToNext();
  Future<void> previous() => _player.seekToPrevious();

  Future<void> stop() async {
    await _player.stop();
    state = AudioState(speed: state.speed, repeatEach: state.repeatEach);
  }

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    await _player.setSpeed(speed);
    await ref.read(prefsProvider.notifier).setValue('speed', speed);
  }

  Future<void> setLoop(bool loop) async {
    state = state.copyWith(loop: loop);
    await _player.setLoopMode(loop ? LoopMode.all : LoopMode.off);
  }
}

final audioProvider = NotifierProvider<AudioController, AudioState>(AudioController.new);
