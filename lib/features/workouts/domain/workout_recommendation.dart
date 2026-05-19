import 'package:fitora/features/personalization/domain/personalization_models.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';

class WorkoutRecommendationService {
  List<Workout> recommend({
    required List<Workout> workouts,
    required PersonalizationProfile profile,
    int limit = 4,
  }) {
    if (workouts.isEmpty) {
      return const [];
    }

    final scored = workouts
        .map((workout) => _ScoredWorkout(workout, _score(workout, profile)))
        .toList();

    scored.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return a.workout.duration.compareTo(b.workout.duration);
    });

    final filtered = scored.where((item) => item.score > 0).toList();
    final selection = (filtered.isNotEmpty ? filtered : scored)
        .take(limit)
        .map((item) => item.workout)
        .toList();

    return selection;
  }

  int _score(Workout workout, PersonalizationProfile profile) {
    var score = 0;

    if (profile.goal != null &&
        workout.recommendedGoals.contains(profile.goal)) {
      score += 3;
    }

    if (profile.workoutPreference != null) {
      final preference = profile.workoutPreference!;
      if (preference == WorkoutPreference.mixed &&
          workout.category != WorkoutCategory.wellness) {
        score += 2;
      } else if (preference == WorkoutPreference.home &&
          workout.category == WorkoutCategory.home) {
        score += 2;
      } else if (preference == WorkoutPreference.gym &&
          workout.category == WorkoutCategory.gym) {
        score += 2;
      }
    }

    if (profile.experienceLevel != null) {
      final level = profile.experienceLevel!;
      if (level == ExperienceLevel.beginner &&
          workout.difficulty == WorkoutDifficulty.beginner) {
        score += 2;
      } else if (level == ExperienceLevel.intermediate &&
          workout.difficulty == WorkoutDifficulty.intermediate) {
        score += 2;
      } else if (level == ExperienceLevel.advanced &&
          workout.difficulty == WorkoutDifficulty.advanced) {
        score += 2;
      } else if (level == ExperienceLevel.beginner &&
          workout.tags.contains('low-impact')) {
        score += 1;
      } else if (level == ExperienceLevel.advanced &&
          workout.difficulty == WorkoutDifficulty.intermediate) {
        score += 1;
      }
    }

    if (profile.goal == PersonalizationGoal.loseWeight &&
        workout.tags.contains('fat-burn')) {
      score += 2;
    }

    if ((profile.goal == PersonalizationGoal.improveWellness ||
            profile.goal == PersonalizationGoal.reduceStress) &&
        workout.category == WorkoutCategory.wellness) {
      score += 2;
    }

    if (profile.goal == PersonalizationGoal.buildHabits &&
        workout.tags.contains('starter')) {
      score += 1;
    }

    return score;
  }
}

class _ScoredWorkout {
  final Workout workout;
  final int score;

  const _ScoredWorkout(this.workout, this.score);
}
