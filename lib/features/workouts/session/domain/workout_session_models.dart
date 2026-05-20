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
  final int totalElapsedSeconds;
  final int? currentRemainingSeconds; // null for rep-based
  final bool isResting;
  final int? restRemainingSeconds;

  const WorkoutSessionState({
    required this.workout,
    required this.currentIndex,
    required this.status,
    required this.totalElapsedSeconds,
    required this.currentRemainingSeconds,
    required this.isResting,
    required this.restRemainingSeconds,
  });

  factory WorkoutSessionState.start(Workout workout) {
    final first = workout.exercises.isNotEmpty ? workout.exercises[0] : null;
    final initialRemaining = first?.dose.duration?.inSeconds;
    return WorkoutSessionState(
      workout: workout,
      currentIndex: 0,
      status: WorkoutSessionStatus.active,
      totalElapsedSeconds: 0,
      currentRemainingSeconds: initialRemaining,
      isResting: false,
      restRemainingSeconds: null,
    );
  }

  WorkoutSessionState copyWith({
    int? currentIndex,
    WorkoutSessionStatus? status,
    int? totalElapsedSeconds,
    int? currentRemainingSeconds,
    bool? isResting,
    int? restRemainingSeconds,
  }) {
    return WorkoutSessionState(
      workout: workout,
      currentIndex: currentIndex ?? this.currentIndex,
      status: status ?? this.status,
      totalElapsedSeconds: totalElapsedSeconds ?? this.totalElapsedSeconds,
      currentRemainingSeconds:
          currentRemainingSeconds ?? this.currentRemainingSeconds,
      isResting: isResting ?? this.isResting,
      restRemainingSeconds: restRemainingSeconds ?? this.restRemainingSeconds,
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

  Duration get totalElapsed => Duration(seconds: totalElapsedSeconds);

  String get totalElapsedLabel {
    final d = totalElapsed;
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    if (minutes > 0) return '$minutes:${seconds.toString().padLeft(2, '0')}';
    return '0:${seconds.toString().padLeft(2, '0')}';
  }
}
