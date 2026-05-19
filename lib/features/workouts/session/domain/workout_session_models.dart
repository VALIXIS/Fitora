import 'package:fitora/features/workouts/domain/exercise_models.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';

enum WorkoutSessionStatus {
  active,
  paused,
  ended,
}

class WorkoutSessionState {
  final Workout workout;
  final int currentIndex;
  final WorkoutSessionStatus status;

  const WorkoutSessionState({
    required this.workout,
    required this.currentIndex,
    required this.status,
  });

  factory WorkoutSessionState.start(Workout workout) {
    return WorkoutSessionState(
      workout: workout,
      currentIndex: 0,
      status: WorkoutSessionStatus.active,
    );
  }

  WorkoutSessionState copyWith({
    int? currentIndex,
    WorkoutSessionStatus? status,
  }) {
    return WorkoutSessionState(
      workout: workout,
      currentIndex: currentIndex ?? this.currentIndex,
      status: status ?? this.status,
    );
  }

  Exercise get currentExercise => workout.exercises[currentIndex];

  int get totalExercises => workout.exercises.length;

  bool get hasNext => currentIndex < totalExercises - 1;

  bool get hasPrevious => currentIndex > 0;

  int get completedExercises => totalExercises == 0 ? 0 : currentIndex + 1;

  double get progress =>
      totalExercises == 0 ? 0 : completedExercises / totalExercises;

  bool get isPaused => status == WorkoutSessionStatus.paused;

  bool get isActive => status == WorkoutSessionStatus.active;
}
