import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/ads/ad_service.dart';
import 'package:fitora/features/sleep/domain/soundscape_model.dart';
import 'package:fitora/core/utils/app_logger.dart';

class SoundscapeState {
  final SoundscapeTrack? activeTrack;
  final bool isPlaying;
  final double volume;
  final int? sleepTimerMinutes;
  final int? remainingSeconds;
  final Set<String> unlockedTrackIds;

  const SoundscapeState({
    this.activeTrack,
    this.isPlaying = false,
    this.volume = 0.8,
    this.sleepTimerMinutes,
    this.remainingSeconds,
    this.unlockedTrackIds = const {},
  });

  SoundscapeState copyWith({
    SoundscapeTrack? activeTrack,
    bool? isPlaying,
    double? volume,
    int? sleepTimerMinutes,
    int? remainingSeconds,
    Set<String>? unlockedTrackIds,
    bool clearActiveTrack = false,
  }) {
    return SoundscapeState(
      activeTrack: clearActiveTrack ? null : (activeTrack ?? this.activeTrack),
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
      sleepTimerMinutes: sleepTimerMinutes ?? this.sleepTimerMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      unlockedTrackIds: unlockedTrackIds ?? this.unlockedTrackIds,
    );
  }
}

final soundscapeProvider =
    StateNotifierProvider<SoundscapeNotifier, SoundscapeState>((ref) {
  return SoundscapeNotifier();
});

class SoundscapeNotifier extends StateNotifier<SoundscapeState> {
  final AudioPlayer? _audioPlayer;
  Timer? _countdownTimer;

  SoundscapeNotifier([AudioPlayer? audioPlayer])
      : _audioPlayer = audioPlayer,
        super(const SoundscapeState()) {
    _initAudio();
  }

  void _initAudio() {
    try {
      _audioPlayer?.setReleaseMode(ReleaseMode.loop);
      if (_audioPlayer != null) {
        _audioPlayer.setVolume(state.volume);
      }
    } catch (_) {}
    
    // Sync initial session unlocks from AdService
    final unlocked = <String>{};
    for (final track in SoundscapeTrack.defaultTracks) {
      if (!track.isPremium || AdService.isSoundscapeUnlocked(track.id)) {
        unlocked.add(track.id);
      }
    }
    state = state.copyWith(unlockedTrackIds: unlocked);
  }

  bool isTrackUnlocked(SoundscapeTrack track) {
    if (!track.isPremium) return true;
    return state.unlockedTrackIds.contains(track.id) ||
        AdService.isSoundscapeUnlocked(track.id);
  }

  void markTrackUnlocked(String trackId) {
    AdService.unlockSoundscape(trackId);
    final updated = Set<String>.from(state.unlockedTrackIds)..add(trackId);
    state = state.copyWith(unlockedTrackIds: updated);
  }

  Future<void> playTrack(SoundscapeTrack track) async {
    if (!isTrackUnlocked(track)) return;

    try {
      if (state.activeTrack?.id == track.id && state.isPlaying) {
        await pause();
        return;
      }

      state = state.copyWith(activeTrack: track, isPlaying: true);
      await _audioPlayer?.stop();
      await _audioPlayer?.setSource(AssetSource(track.audioAsset));
      await _audioPlayer?.resume();
      AppLogger.info('Playing soundscape: ${track.title}');
    } catch (e) {
      AppLogger.error('Soundscape playback error: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (state.activeTrack == null) return;
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer?.pause();
      state = state.copyWith(isPlaying: false);
    } catch (_) {}
  }

  Future<void> resume() async {
    if (state.activeTrack == null) return;
    try {
      await _audioPlayer?.resume();
      state = state.copyWith(isPlaying: true);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _audioPlayer?.stop();
      _countdownTimer?.cancel();
      state = state.copyWith(
        isPlaying: false,
        clearActiveTrack: true,
        sleepTimerMinutes: null,
        remainingSeconds: null,
      );
    } catch (_) {}
  }

  Future<void> setVolume(double val) async {
    final clamped = val.clamp(0.0, 1.0);
    state = state.copyWith(volume: clamped);
    try {
      await _audioPlayer?.setVolume(clamped);
    } catch (_) {}
  }

  void setSleepTimer(int minutes) {
    _countdownTimer?.cancel();
    if (minutes <= 0) {
      state = state.copyWith(sleepTimerMinutes: null, remainingSeconds: null);
      return;
    }

    final totalSeconds = minutes * 60;
    state = state.copyWith(
      sleepTimerMinutes: minutes,
      remainingSeconds: totalSeconds,
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final rem = (state.remainingSeconds ?? 0) - 1;
      if (rem <= 0) {
        timer.cancel();
        stop();
      } else {
        state = state.copyWith(remainingSeconds: rem);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }
}
