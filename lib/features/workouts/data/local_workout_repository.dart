import 'package:fitora/features/workouts/data/mock_workouts.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/workouts/domain/workout_repository.dart';

class LocalWorkoutRepository implements WorkoutRepository {
  final List<Workout> _workouts;

  LocalWorkoutRepository({List<Workout>? seed})
      : _workouts = List.unmodifiable(seed ?? mockWorkouts);

  @override
  Future<List<Workout>> fetchWorkouts() async {
    return _workouts;
  }

  @override
  Future<Workout?> fetchWorkout(String id) async {
    for (final workout in _workouts) {
      if (workout.id == id) {
        return workout;
      }
    }
    return null;
  }
}
