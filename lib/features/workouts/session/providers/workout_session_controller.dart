import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/workouts/session/domain/workout_session_models.dart';

final workoutSessionControllerProvider = StateNotifierProvider.autoDispose
    .family<WorkoutSessionController, WorkoutSessionState, Workout>(
  (ref, workout) => WorkoutSessionController(workout),
);

class WorkoutSessionController extends StateNotifier<WorkoutSessionState> {
  WorkoutSessionController(Workout workout)
      : super(WorkoutSessionState.start(workout));

  void nextExercise() {
    if (!state.hasNext) {
      return;
    }
    state = state.copyWith(currentIndex: state.currentIndex + 1);
  }

  void previousExercise() {
    if (!state.hasPrevious) {
      return;
    }
    state = state.copyWith(currentIndex: state.currentIndex - 1);
  }

  void pauseSession() {
    if (!state.isActive) {
      return;
    }
    state = state.copyWith(status: WorkoutSessionStatus.paused);
  }

  void resumeSession() {
    if (!state.isPaused) {
      return;
    }
    state = state.copyWith(status: WorkoutSessionStatus.active);
  }

  void endSession() {
    state = state.copyWith(status: WorkoutSessionStatus.ended);
  }
}
