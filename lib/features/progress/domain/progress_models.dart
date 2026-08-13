class WorkoutHistoryEntry {
  final String id;
  final String workoutId;
  final String title;
  final DateTime completedAt;
  final int durationSeconds;
  final int calories;
  final int exercisesCompleted;

  const WorkoutHistoryEntry({
    required this.id,
    required this.workoutId,
    required this.title,
    required this.completedAt,
    required this.durationSeconds,
    required this.calories,
    required this.exercisesCompleted,
  });

  int get durationMinutes => (durationSeconds / 60).round();

  String get durationLabel {
    final minutes = durationMinutes;
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return '${hours}h ${remaining}m';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'workoutId': workoutId,
    'title': title,
    'completedAt': completedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'calories': calories,
    'exercisesCompleted': exercisesCompleted,
  };

  factory WorkoutHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutHistoryEntry(
      id: json['id'] as String? ?? '',
      workoutId: json['workoutId'] as String? ?? '',
      title: json['title'] as String? ?? 'Workout',
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.now(),
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      calories: json['calories'] as int? ?? 0,
      exercisesCompleted: json['exercisesCompleted'] as int? ?? 0,
    );
  }
}

class StreakInfo {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;

  const StreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletedDate,
  });

  factory StreakInfo.empty() => const StreakInfo(
    currentStreak: 0,
    longestStreak: 0,
    lastCompletedDate: null,
  );
}

class ProgressSummary {
  final int totalWorkouts;
  final int totalMinutes;
  final int totalCalories;
  final int totalExercises;
  final int weeklyWorkouts;
  final int weeklyMinutes;
  final int weeklyCalories;

  const ProgressSummary({
    required this.totalWorkouts,
    required this.totalMinutes,
    required this.totalCalories,
    required this.totalExercises,
    required this.weeklyWorkouts,
    required this.weeklyMinutes,
    required this.weeklyCalories,
  });

  factory ProgressSummary.empty() => const ProgressSummary(
    totalWorkouts: 0,
    totalMinutes: 0,
    totalCalories: 0,
    totalExercises: 0,
    weeklyWorkouts: 0,
    weeklyMinutes: 0,
    weeklyCalories: 0,
  );
}

class DailyActivity {
  final DateTime date;
  final int workouts;
  final int minutes;
  final int calories;

  const DailyActivity({
    required this.date,
    required this.workouts,
    required this.minutes,
    required this.calories,
  });
}

class WeeklyTrend {
  final DateTime start;
  final DateTime end;
  final int workouts;
  final int minutes;
  final int calories;

  const WeeklyTrend({
    required this.start,
    required this.end,
    required this.workouts,
    required this.minutes,
    required this.calories,
  });
}

enum HealthTimeframe {
  sevenDays,
  thirtyDays;

  int get days => this == HealthTimeframe.sevenDays ? 7 : 30;
  String get label => this == HealthTimeframe.sevenDays ? '7 Days' : '30 Days';
}

enum HealthMetricType {
  steps,
  distance,
  calories,
  sleep,
  water;

  String get displayName {
    switch (this) {
      case HealthMetricType.steps:
        return 'Steps';
      case HealthMetricType.distance:
        return 'Distance';
      case HealthMetricType.calories:
        return 'Calories';
      case HealthMetricType.sleep:
        return 'Sleep';
      case HealthMetricType.water:
        return 'Water';
    }
  }

  String get unit {
    switch (this) {
      case HealthMetricType.steps:
        return 'steps';
      case HealthMetricType.distance:
        return 'km';
      case HealthMetricType.calories:
        return 'kcal';
      case HealthMetricType.sleep:
        return 'hrs';
      case HealthMetricType.water:
        return 'L';
    }
  }
}

class WeeklyHealthSummaryData {
  final int totalSteps;
  final double totalWaterLiters;
  final double avgSleepMinutes;
  final double totalActiveCalories;

  // Week-over-Week Comparison Deltas (Current 7d vs Prior 7d)
  final double stepsDeltaPct;
  final double waterDeltaLiters;
  final double sleepDeltaHours;
  final double caloriesDeltaPct;

  // Best Day Highlights
  final String bestStepDay;
  final int bestStepValue;
  final String bestHydrationDay;
  final double bestHydrationValue;

  const WeeklyHealthSummaryData({
    required this.totalSteps,
    required this.totalWaterLiters,
    required this.avgSleepMinutes,
    required this.totalActiveCalories,
    required this.stepsDeltaPct,
    required this.waterDeltaLiters,
    required this.sleepDeltaHours,
    required this.caloriesDeltaPct,
    required this.bestStepDay,
    required this.bestStepValue,
    required this.bestHydrationDay,
    required this.bestHydrationValue,
  });

  factory WeeklyHealthSummaryData.empty() => const WeeklyHealthSummaryData(
    totalSteps: 0,
    totalWaterLiters: 0.0,
    avgSleepMinutes: 0.0,
    totalActiveCalories: 0.0,
    stepsDeltaPct: 0.0,
    waterDeltaLiters: 0.0,
    sleepDeltaHours: 0.0,
    caloriesDeltaPct: 0.0,
    bestStepDay: 'N/A',
    bestStepValue: 0,
    bestHydrationDay: 'N/A',
    bestHydrationValue: 0.0,
  );
}
