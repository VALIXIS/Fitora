import 'package:fitora/features/workouts/domain/workout_models.dart';

abstract class WorkoutRepository {
  Future<List<Workout>> fetchWorkouts();
  Future<Workout?> fetchWorkout(String id);
}
