import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';
import 'package:fitora/features/progress/providers/progress_controller.dart';
import 'package:fitora/features/workouts/data/local_workout_repository.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/workouts/domain/workout_recommendation.dart';
import 'package:fitora/features/workouts/domain/workout_repository.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return LocalWorkoutRepository();
});

final workoutCatalogProvider = FutureProvider<List<Workout>>((ref) async {
  final repository = ref.read(workoutRepositoryProvider);
  return repository.fetchWorkouts();
});

final workoutByIdProvider = FutureProvider.family<Workout?, String>(
  (ref, id) async {
    final workouts = await ref.watch(workoutCatalogProvider.future);
    for (final workout in workouts) {
      if (workout.id == id) {
        return workout;
      }
    }
    return null;
  },
);

final workoutBrowseProvider = Provider<AsyncValue<WorkoutBrowseData>>((ref) {
  final workoutsAsync = ref.watch(workoutCatalogProvider);
  final profile = ref.watch(
    personalizationControllerProvider.select((state) => state.profile),
  );
  
  // Watch wellness recovery score and progress history
  final wellness = ref.watch(wellnessProvider);
  final progress = ref.watch(progressControllerProvider);

  return workoutsAsync.whenData((workouts) {
    final featured =
        workouts.where((workout) => workout.tags.contains('featured')).toList();
    final starter =
        workouts.where((workout) => workout.tags.contains('starter')).toList();

    final recommender = WorkoutRecommendationService();
    var recommended = recommender.recommend(
      workouts: workouts,
      profile: profile,
      recoveryScore: wellness.recoveryScore,
      history: progress.history,
      limit: 4,
    );
    if (recommended.isEmpty) {
      recommended = (starter.isNotEmpty ? starter : workouts).take(4).toList();
    }

    final categories = <WorkoutCategoryGroup>[];
    for (final category in WorkoutCategory.values) {
      final categoryWorkouts =
          workouts.where((workout) => workout.category == category).toList();
      if (categoryWorkouts.isEmpty) {
        continue;
      }
      categories.add(
        WorkoutCategoryGroup(category: category, workouts: categoryWorkouts),
      );
    }

    return WorkoutBrowseData(
      featured: featured,
      recommended: recommended,
      categories: categories,
    );
  });
});

class WorkoutBrowseData {
  final List<Workout> featured;
  final List<Workout> recommended;
  final List<WorkoutCategoryGroup> categories;

  const WorkoutBrowseData({
    required this.featured,
    required this.recommended,
    required this.categories,
  });
}

class WorkoutCategoryGroup {
  final WorkoutCategory category;
  final List<Workout> workouts;

  const WorkoutCategoryGroup({
    required this.category,
    required this.workouts,
  });
}
