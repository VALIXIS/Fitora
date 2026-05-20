import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/features/progress/providers/progress_controller.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/workouts/session/domain/workout_session_models.dart';

final workoutSessionControllerProvider = StateNotifierProvider.autoDispose
    .family<WorkoutSessionController, WorkoutSessionState, Workout>(
  (ref, workout) {
    final progressController = ref.read(progressControllerProvider.notifier);
    final autoplayRest =
        ref.read(settingsProvider.select((state) => state.autoplayRest));
    final controller = WorkoutSessionController(
      workout,
      autoplayRest: autoplayRest,
      onSessionCompleted: (session) => progressController.recordWorkout(
        workout: workout,
        session: session,
      ),
    );

    ref.listen(
      settingsProvider.select((state) => state.autoplayRest),
      (_, next) => controller.setAutoplayRest(next),
    );

    return controller;
  },
);

class WorkoutSessionController extends StateNotifier<WorkoutSessionState> {
  final Future<void> Function(WorkoutSessionState) _onSessionCompleted;
  Timer? _ticker;
  bool _autoplayRest;
  bool _hasRecordedCompletion = false;

  WorkoutSessionController(
    Workout workout, {
    required bool autoplayRest,
    required Future<void> Function(WorkoutSessionState) onSessionCompleted,
  })  : _autoplayRest = autoplayRest,
        _onSessionCompleted = onSessionCompleted,
        super(WorkoutSessionState.start(workout)) {
    _ensureTickerRunning();
  }

  void setAutoplayRest(bool value) {
    _autoplayRest = value;
  }

  void nextExercise() {
    if (!state.hasNext) {
      return;
    }
    final nextIndex = state.currentIndex + 1;
    final nextExercise = state.workout.exercises[nextIndex];
    state = state.copyWith(
      currentIndex: nextIndex,
      currentRemainingSeconds: nextExercise.dose.duration?.inSeconds,
      isResting: false,
      restRemainingSeconds: null,
    );
    _ensureTickerRunning();
  }

  void previousExercise() {
    if (!state.hasPrevious) {
      return;
    }
    final prevIndex = state.currentIndex - 1;
    final prevExercise = state.workout.exercises[prevIndex];
    state = state.copyWith(
      currentIndex: prevIndex,
      currentRemainingSeconds: prevExercise.dose.duration?.inSeconds,
      isResting: false,
      restRemainingSeconds: null,
    );
    _ensureTickerRunning();
  }

  void pauseSession() {
    if (!state.isActive) {
      return;
    }
    state = state.copyWith(status: WorkoutSessionStatus.paused);
    _stopTicker();
  }

  void resumeSession() {
    if (!state.isPaused) {
      return;
    }
    state = state.copyWith(status: WorkoutSessionStatus.active);
    _ensureTickerRunning();
  }

  void endSession() {
    _completeSession(totalElapsedSeconds: state.totalElapsedSeconds);
  }

  void skipRest() {
    if (!state.isResting) return;
    // move to next exercise or end
    if (state.hasNext) {
      final nextIndex = state.currentIndex + 1;
      final nextExercise = state.workout.exercises[nextIndex];
      state = state.copyWith(
        currentIndex: nextIndex,
        isResting: false,
        restRemainingSeconds: null,
        currentRemainingSeconds: nextExercise.dose.duration?.inSeconds,
      );
      _ensureTickerRunning();
    } else {
      _completeSession(totalElapsedSeconds: state.totalElapsedSeconds);
    }
  }

  void _ensureTickerRunning() {
    if (state.isPaused || state.status == WorkoutSessionStatus.ended) return;
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _tick() {
    // increment total elapsed
    final total = state.totalElapsedSeconds + 1;

    if (state.isResting) {
      final remaining = (state.restRemainingSeconds ?? 0) - 1;
      if (remaining <= 0) {
        if (_autoplayRest) {
          // finish rest -> advance
          if (state.hasNext) {
            final nextIndex = state.currentIndex + 1;
            final nextExercise = state.workout.exercises[nextIndex];
            state = state.copyWith(
              totalElapsedSeconds: total,
              currentIndex: nextIndex,
              isResting: false,
              restRemainingSeconds: null,
              currentRemainingSeconds: nextExercise.dose.duration?.inSeconds,
            );
          } else {
            _completeSession(totalElapsedSeconds: total);
          }
        } else {
          state = state.copyWith(
            totalElapsedSeconds: total,
            restRemainingSeconds: 0,
          );
        }
      } else {
        state = state.copyWith(
          totalElapsedSeconds: total,
          restRemainingSeconds: remaining,
        );
      }
      return;
    }

    // not resting
    final currentExercise = state.currentExercise;
    final durationSec = currentExercise.dose.duration?.inSeconds;
    if (durationSec != null) {
      final remaining = (state.currentRemainingSeconds ?? durationSec) - 1;
      if (remaining <= 0) {
        // finished exercise
        // start rest if defined
        final restSec = currentExercise.dose.rest?.inSeconds;
        if (restSec != null && restSec > 0 && state.hasNext) {
          state = state.copyWith(
            totalElapsedSeconds: total,
            isResting: true,
            restRemainingSeconds: restSec,
            currentRemainingSeconds: null,
          );
        } else if (state.hasNext) {
          // move to next exercise
          final nextIndex = state.currentIndex + 1;
          final nextExercise = state.workout.exercises[nextIndex];
          state = state.copyWith(
            totalElapsedSeconds: total,
            currentIndex: nextIndex,
            currentRemainingSeconds: nextExercise.dose.duration?.inSeconds,
          );
        } else {
          // end session
          _completeSession(totalElapsedSeconds: total);
        }
      } else {
        state = state.copyWith(
          totalElapsedSeconds: total,
          currentRemainingSeconds: remaining,
        );
      }
    } else {
      // rep-based: only update elapsed
      state = state.copyWith(totalElapsedSeconds: total);
    }
  }

  void _completeSession({required int totalElapsedSeconds}) {
    if (state.status == WorkoutSessionStatus.ended) {
      _stopTicker();
      return;
    }
    state = state.copyWith(
      totalElapsedSeconds: totalElapsedSeconds,
      status: WorkoutSessionStatus.ended,
      isResting: false,
      restRemainingSeconds: null,
      currentRemainingSeconds: null,
    );
    _stopTicker();
    _recordCompletion();
  }

  void _recordCompletion() {
    if (_hasRecordedCompletion) {
      return;
    }
    _hasRecordedCompletion = true;
    unawaited(_onSessionCompleted(state));
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
