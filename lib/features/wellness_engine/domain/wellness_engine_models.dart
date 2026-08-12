import 'package:flutter/material.dart';

enum ReadinessLevel {
  optimal,
  good,
  recovering,
  fatigued,
}

extension ReadinessLevelX on ReadinessLevel {
  String get label {
    switch (this) {
      case ReadinessLevel.optimal:
        return 'Optimal Readiness';
      case ReadinessLevel.good:
        return 'Good Balance';
      case ReadinessLevel.recovering:
        return 'Active Recovery Needed';
      case ReadinessLevel.fatigued:
        return 'Deep Rest Required';
    }
  }

  String get description {
    switch (this) {
      case ReadinessLevel.optimal:
        return 'Your body is fully primed for high-performance and intense training.';
      case ReadinessLevel.good:
        return 'A balanced state. Good energy levels to maintain your routine.';
      case ReadinessLevel.recovering:
        return 'Slight fatigue detected. Focus on stretching, light flow, or walking.';
      case ReadinessLevel.fatigued:
        return 'Elevated physical stress. Prioritize deep sleep, hydration, and gentle breathing.';
    }
  }
}

class ReadinessState {
  final int score; // 0 to 100
  final ReadinessLevel level;
  final String description;

  const ReadinessState({
    required this.score,
    required this.level,
    required this.description,
  });

  factory ReadinessState.initial() => const ReadinessState(
        score: 82,
        level: ReadinessLevel.good,
        description: 'A balanced state. Good energy levels to maintain your routine.',
      );
}

class AdaptiveWorkoutRecommendation {
  final String title;
  final String intensity; // 'High', 'Moderate', 'Recovery'
  final String reason;
  final String actionLabel;
  final String categoryLabel; // 'Home', 'Gym', 'Wellness'

  const AdaptiveWorkoutRecommendation({
    required this.title,
    required this.intensity,
    required this.reason,
    required this.actionLabel,
    required this.categoryLabel,
  });
}

class WellnessInsightCard {
  final String title;
  final String message;
  final String type; // 'hydration', 'sleep', 'stress', 'recovery', 'stretching'
  final IconData icon;
  final Color accentColor;

  const WellnessInsightCard({
    required this.title,
    required this.message,
    required this.type,
    required this.icon,
    required this.accentColor,
  });
}

class DailyGoals {
  final int stepsGoal;
  final double hydrationGoalLiters;
  final int mindfulnessMinutesGoal;
  final double sleepHoursGoal;

  const DailyGoals({
    required this.stepsGoal,
    required this.hydrationGoalLiters,
    required this.mindfulnessMinutesGoal,
    required this.sleepHoursGoal,
  });

  factory DailyGoals.initial() => const DailyGoals(
        stepsGoal: 8000,
        hydrationGoalLiters: 2.5,
        mindfulnessMinutesGoal: 10,
        sleepHoursGoal: 8.0,
      );
}

class StreakReport {
  final int workoutStreak;
  final int hydrationStreak;
  final int sleepConsistencyScore; // 0 - 100
  final int mindfulnessStreak;

  const StreakReport({
    required this.workoutStreak,
    required this.hydrationStreak,
    required this.sleepConsistencyScore,
    required this.mindfulnessStreak,
  });

  factory StreakReport.initial() => const StreakReport(
        workoutStreak: 3,
        hydrationStreak: 4,
        sleepConsistencyScore: 88,
        mindfulnessStreak: 2,
      );
}

class WellnessEngineState {
  final ReadinessState readiness;
  final List<AdaptiveWorkoutRecommendation> recommendations;
  final List<WellnessInsightCard> insights;
  final DailyGoals goals;
  final StreakReport streaks;
  final bool isLoaded;

  const WellnessEngineState({
    required this.readiness,
    required this.recommendations,
    required this.insights,
    required this.goals,
    required this.streaks,
    this.isLoaded = false,
  });

  factory WellnessEngineState.initial() => WellnessEngineState(
        readiness: ReadinessState.initial(),
        recommendations: const [],
        insights: const [],
        goals: DailyGoals.initial(),
        streaks: StreakReport.initial(),
        isLoaded: false,
      );

  WellnessEngineState copyWith({
    ReadinessState? readiness,
    List<AdaptiveWorkoutRecommendation>? recommendations,
    List<WellnessInsightCard>? insights,
    DailyGoals? goals,
    StreakReport? streaks,
    bool? isLoaded,
  }) {
    return WellnessEngineState(
      readiness: readiness ?? this.readiness,
      recommendations: recommendations ?? this.recommendations,
      insights: insights ?? this.insights,
      goals: goals ?? this.goals,
      streaks: streaks ?? this.streaks,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}
