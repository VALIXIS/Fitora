import 'package:fitora/features/personalization/domain/personalization_models.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/progress/domain/progress_models.dart';

class WorkoutRecommendationService {
  List<Workout> recommend({
    required List<Workout> workouts,
    required PersonalizationProfile profile,
    required int recoveryScore,
    required List<WorkoutHistoryEntry> history,
    int limit = 4,
  }) {
    if (workouts.isEmpty) {
      return const [];
    }

    // Identify recently completed workout IDs to avoid immediate repetition
    final recentlyCompletedIds = history
        .map((entry) => entry.workoutId)
        .toList();

    final scored = workouts
        .map((workout) => _ScoredWorkout(
              workout,
              _score(
                workout: workout,
                profile: profile,
                recoveryScore: recoveryScore,
                recentlyCompletedIds: recentlyCompletedIds,
              ),
            ))
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

  int _score({
    required Workout workout,
    required PersonalizationProfile profile,
    required int recoveryScore,
    required List<String> recentlyCompletedIds,
  }) {
    var score = 0;

    // 1. Recovery Score Adaptation
    if (recoveryScore < 50) {
      // Body is fatigued: prioritize wellness/recovery, penalize high-intensity
      if (workout.category == WorkoutCategory.wellness) {
        score += 6;
      } else if (workout.difficulty == WorkoutDifficulty.advanced) {
        score -= 4;
      }
    } else if (recoveryScore >= 80) {
      // Body is in optimal recovery: recommend tougher strength/cardio workouts!
      if (workout.difficulty == WorkoutDifficulty.advanced || 
          workout.difficulty == WorkoutDifficulty.intermediate) {
        score += 4;
      }
      if (workout.category == WorkoutCategory.gym) {
        score += 2;
      }
    }

    // 2. Personal Goal Matching
    if (profile.goal != null &&
        workout.recommendedGoals.contains(profile.goal)) {
      score += 3;
    }

    // 3. Category Preferences
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

    // 4. Experience Level Scaling
    if (profile.experienceLevel != null) {
      final level = profile.experienceLevel!;
      if (level == ExperienceLevel.beginner &&
          workout.difficulty == WorkoutDifficulty.beginner) {
        score += 3;
      } else if (level == ExperienceLevel.intermediate &&
          workout.difficulty == WorkoutDifficulty.intermediate) {
        score += 3;
      } else if (level == ExperienceLevel.advanced &&
          workout.difficulty == WorkoutDifficulty.advanced) {
        score += 3;
      } else if (level == ExperienceLevel.beginner &&
          workout.tags.contains('low-impact')) {
        score += 2;
      }
    }

    // 5. Avoid immediate repetition of recently completed workouts
    if (recentlyCompletedIds.contains(workout.id)) {
      // Penalize slightly if done very recently
      if (recentlyCompletedIds.first == workout.id) {
        score -= 5;
      } else {
        score -= 2;
      }
    }

    return score;
  }
}

class _ScoredWorkout {
  final Workout workout;
  final int score;

  const _ScoredWorkout(this.workout, this.score);
}
