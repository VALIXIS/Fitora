enum MetricAvailability { available, permissionRequired, unavailable }

class GoalMetric {
  final String key; // 'steps', 'water', 'sleep', 'calories'
  final String name;
  final double current;
  final double goal;
  final String unit;
  final bool isCompleted;
  final MetricAvailability availability;

  const GoalMetric({
    required this.key,
    required this.name,
    required this.current,
    required this.goal,
    required this.unit,
    required this.isCompleted,
    required this.availability,
  });

  double get percentage => goal > 0 ? (current / goal) * 100 : 0.0;
  double get progressFraction =>
      goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
}

class DailyGoalStatus {
  final DateTime date;
  final List<GoalMetric> metrics;
  final bool isDailyGoalCompleted;
  final double completionPercentage;

  const DailyGoalStatus({
    required this.date,
    required this.metrics,
    required this.isDailyGoalCompleted,
    required this.completionPercentage,
  });
}

class GoalsStreakState {
  final Map<String, Map<String, bool>>
  history; // YYYY-MM-DD -> {metricKey -> isCompleted}
  final int currentStreak;
  final int longestStreak;

  const GoalsStreakState({
    required this.history,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory GoalsStreakState.initial() =>
      const GoalsStreakState(history: {}, currentStreak: 0, longestStreak: 0);

  GoalsStreakState copyWith({
    Map<String, Map<String, bool>>? history,
    int? currentStreak,
    int? longestStreak,
  }) {
    return GoalsStreakState(
      history: history ?? this.history,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }
}
