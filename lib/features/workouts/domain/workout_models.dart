import 'package:fitora/features/personalization/domain/personalization_models.dart';
import 'package:fitora/features/workouts/domain/exercise_models.dart';

enum WorkoutCategory {
  home,
  gym,
  wellness,
}

extension WorkoutCategoryX on WorkoutCategory {
  String get label {
    switch (this) {
      case WorkoutCategory.home:
        return 'Home';
      case WorkoutCategory.gym:
        return 'Gym';
      case WorkoutCategory.wellness:
        return 'Wellness';
    }
  }

  String get description {
    switch (this) {
      case WorkoutCategory.home:
        return 'Sessions designed for minimal equipment.';
      case WorkoutCategory.gym:
        return 'Structured strength and equipment-based plans.';
      case WorkoutCategory.wellness:
        return 'Gentle flows for recovery and balance.';
    }
  }
}

enum WorkoutDifficulty {
  beginner,
  intermediate,
  advanced,
}

extension WorkoutDifficultyX on WorkoutDifficulty {
  String get label {
    switch (this) {
      case WorkoutDifficulty.beginner:
        return 'Beginner';
      case WorkoutDifficulty.intermediate:
        return 'Intermediate';
      case WorkoutDifficulty.advanced:
        return 'Advanced';
    }
  }
}

class Workout {
  final String id;
  final String title;
  final String subtitle;
  final WorkoutCategory category;
  final WorkoutDifficulty difficulty;
  final Duration duration;
  final int calories;
  final List<Exercise> exercises;
  final List<String> tags;
  final List<PersonalizationGoal> recommendedGoals;

  const Workout({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.difficulty,
    required this.duration,
    required this.calories,
    required this.exercises,
    required this.tags,
    required this.recommendedGoals,
  });

  int get exerciseCount => exercises.length;

  String get durationLabel => '${duration.inMinutes} min';

  String get caloriesLabel => '$calories kcal';
}
