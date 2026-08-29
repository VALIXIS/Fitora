import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/core/health/providers/health_providers.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';
import 'package:fitora/features/home/domain/goals_streak_models.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';

final dailyGoalStatusProvider = Provider.family<DailyGoalStatus, DateTime>((
  ref,
  date,
) {
  final now = DateTime.now();
  final isToday =
      date.year == now.year && date.month == now.month && date.day == now.day;
  final dateStr = formatDate(date);

  // 1. Steps Goal
  final activity = ref.watch(dailyActivityProvider(date));
  final stepsCurrent = activity.steps.toDouble();
  final stepsGoal = activity.stepsGoal.toDouble();

  MetricAvailability stepsAvailability;
  if (activity.sensorStatus == SensorStatus.active ||
      activity.healthConnectStatus == HealthConnectStatus.connected ||
      activity.steps > 0 ||
      stepsGoal > 0) {
    stepsAvailability = MetricAvailability.available;
  } else if (activity.sensorStatus == SensorStatus.permissionRequired ||
      activity.healthConnectStatus == HealthConnectStatus.permissionRequired) {
    stepsAvailability = MetricAvailability.permissionRequired;
  } else {
    stepsAvailability = MetricAvailability.available;
  }

  final stepsMetric = GoalMetric(
    key: 'steps',
    name: 'Steps',
    current: stepsCurrent,
    goal: stepsGoal,
    unit: 'steps',
    isCompleted:
        stepsAvailability == MetricAvailability.available &&
        stepsCurrent >= stepsGoal &&
        stepsGoal > 0,
    availability: stepsAvailability,
  );

  // 2. Water Goal
  final wellness = ref.watch(wellnessProvider);
  double waterCurrent = 0.0;
  double waterGoal = wellness.hydrationGoalLiters;

  if (isToday) {
    waterCurrent = wellness.hydrationLiters;
  } else {
    // Read directly from SharedPreferences to avoid dependency on goalsStreakProvider
    bool wasCompleted = false;
    try {
      final historyRaw = AppPreferences.prefs.getString('fitora_goals_completion_history_v1');
      if (historyRaw != null) {
        final decoded = jsonDecode(historyRaw) as Map<String, dynamic>;
        final dayData = decoded[dateStr];
        if (dayData is Map<String, dynamic>) {
          wasCompleted = dayData['water'] as bool? ?? false;
        }
      }
    } catch (_) {}
    waterCurrent = wasCompleted ? waterGoal : 0.0;
  }

  final waterMetric = GoalMetric(
    key: 'water',
    name: 'Water',
    current: waterCurrent,
    goal: waterGoal,
    unit: 'L',
    isCompleted: waterGoal > 0 && waterCurrent >= waterGoal,
    availability: MetricAvailability.available,
  );

  // 3. Sleep Goal
  final sleep = ref.watch(sleepSummaryProvider(date));
  final hcSleepMinutes = sleep.totalSleep.inMinutes.toDouble();
  final manualSleepMinutes = isToday
      ? wellness.sleepMinutes.toDouble()
      : (wellness.sleepLogHistory[dateStr]?.toDouble() ?? 0.0);
  final sleepCurrent = max(hcSleepMinutes, manualSleepMinutes);
  final sleepGoal = ref.watch(settingsProvider).sleepTargetDurationMinutes.toDouble();

  MetricAvailability sleepAvailability;
  if (sleepCurrent > 0 || manualSleepMinutes > 0) {
    sleepAvailability = MetricAvailability.available;
  } else if (activity.healthConnectStatus ==
      HealthConnectStatus.permissionRequired) {
    sleepAvailability = MetricAvailability.permissionRequired;
  } else {
    sleepAvailability = MetricAvailability.unavailable;
  }

  final sleepMetric = GoalMetric(
    key: 'sleep',
    name: 'Sleep',
    current: sleepCurrent,
    goal: sleepGoal,
    unit: 'min',
    isCompleted:
        sleepAvailability == MetricAvailability.available &&
        sleepCurrent >= sleepGoal,
    availability: sleepAvailability,
  );

  // 4. Calories Goal
  final caloriesCurrent = activity.caloriesBurned;
  final caloriesGoal = activity.caloriesGoal;

  MetricAvailability caloriesAvailability;
  if (activity.healthConnectStatus == HealthConnectStatus.connected ||
      activity.sensorStatus == SensorStatus.active ||
      activity.caloriesBurned > 0) {
    caloriesAvailability = MetricAvailability.available;
  } else if (activity.healthConnectStatus ==
      HealthConnectStatus.permissionRequired) {
    caloriesAvailability = MetricAvailability.permissionRequired;
  } else {
    caloriesAvailability = MetricAvailability.unavailable;
  }

  final caloriesMetric = GoalMetric(
    key: 'calories',
    name: 'Calories',
    current: caloriesCurrent,
    goal: caloriesGoal,
    unit: 'kcal',
    isCompleted:
        caloriesAvailability == MetricAvailability.available &&
        caloriesCurrent >= caloriesGoal &&
        caloriesGoal > 0,
    availability: caloriesAvailability,
  );

  final metrics = [stepsMetric, waterMetric, sleepMetric, caloriesMetric];

  // Daily goal condition met if at least one goal condition was satisfied
  final isDailyGoalCompleted =
      stepsMetric.isCompleted ||
      waterMetric.isCompleted ||
      sleepMetric.isCompleted ||
      caloriesMetric.isCompleted;

  // Percentage of completed goals relative to available goals
  int availableCount = 0;
  int completedCount = 0;
  for (final m in metrics) {
    if (m.availability == MetricAvailability.available) {
      availableCount++;
      if (m.isCompleted) {
        completedCount++;
      }
    }
  }
  final completionPercentage = availableCount > 0
      ? (completedCount / availableCount) * 100
      : 0.0;

  return DailyGoalStatus(
    date: date,
    metrics: metrics,
    isDailyGoalCompleted: isDailyGoalCompleted,
    completionPercentage: completionPercentage,
  );
});

final goalsStreakProvider =
    StateNotifierProvider<GoalsStreakNotifier, GoalsStreakState>((ref) {
      final notifier = GoalsStreakNotifier(ref);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Listen to today's goal completion changes reactively and auto-persist updates
      ref.listen<DailyGoalStatus>(dailyGoalStatusProvider(today), (
        previous,
        next,
      ) {
        notifier.recordDayCompletion(
          date: next.date,
          stepsMet: next.metrics
              .firstWhere((m) => m.key == 'steps')
              .isCompleted,
          waterMet: next.metrics
              .firstWhere((m) => m.key == 'water')
              .isCompleted,
          sleepMet: next.metrics
              .firstWhere((m) => m.key == 'sleep')
              .isCompleted,
          caloriesMet: next.metrics
              .firstWhere((m) => m.key == 'calories')
              .isCompleted,
        );
      });

      return notifier;
    });

class GoalsStreakNotifier extends StateNotifier<GoalsStreakState> {
  final Ref _ref;

  GoalsStreakNotifier(this._ref) : super(GoalsStreakState.initial()) {
    _load();
  }

  static const _historyKey = 'fitora_goals_completion_history_v1';
  static const _longestStreakKey = 'fitora_longest_streak_v1';

  Future<void> _load() async {
    try {
      final prefs = await AppPreferences.instance();

      // Load history
      final historyRaw = prefs.getString(_historyKey);
      Map<String, Map<String, bool>> history = {};
      if (historyRaw != null) {
        final decoded = jsonDecode(historyRaw) as Map<String, dynamic>;
        decoded.forEach((dateStr, val) {
          if (val is Map<String, dynamic>) {
            history[dateStr] = val.map((k, v) => MapEntry(k, v as bool));
          }
        });
      }

      // Load longest streak
      final longestStreak = prefs.getInt(_longestStreakKey) ?? 0;

      state = GoalsStreakState(
        history: history,
        currentStreak: 0,
        longestStreak: longestStreak,
      );

      // Force sync history on startup for recent days
      syncGoals();
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await AppPreferences.instance();
      await prefs.setString(_historyKey, jsonEncode(state.history));
      await prefs.setInt(_longestStreakKey, state.longestStreak);
    } catch (_) {}
  }

  /// Forces recalculation of history for the last 7 days and updates current/longest streaks.
  void syncGoals() {
    final today = DateTime.now();
    final wellness = _ref.read(wellnessProvider);
    final updatedHistory = Map<String, Map<String, bool>>.from(state.history);

    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr = formatDate(date);
      final isToday = (i == 0);

      final activity = _ref.read(dailyActivityProvider(date));
      final sleep = _ref.read(sleepSummaryProvider(date));

      // 1. Steps
      final isStepsAvailable =
          activity.sensorStatus == SensorStatus.active ||
          activity.healthConnectStatus == HealthConnectStatus.connected;
      final stepsMet = isStepsAvailable && activity.steps >= activity.stepsGoal;

      // 2. Calories
      final isCaloriesAvailable =
          activity.healthConnectStatus == HealthConnectStatus.connected;
      final caloriesMet =
          isCaloriesAvailable &&
          activity.caloriesBurned >= activity.caloriesGoal;

      // 3. Sleep (Health Connect sleep or manually logged wellness sleep)
      final hcSleepMinutes = sleep.totalSleep.inMinutes.toDouble();
      final manualSleepMinutes = isToday
          ? wellness.sleepMinutes.toDouble()
          : (wellness.sleepLogHistory[dateStr]?.toDouble() ?? 0.0);
      final totalSleepMinutes = max(hcSleepMinutes, manualSleepMinutes);
      final sleepMet = totalSleepMinutes >= 480.0;

      // 4. Hydration (Today's live entry, or preserved past history)
      bool waterMet = false;
      if (isToday) {
        waterMet =
            wellness.hydrationGoalLiters > 0 &&
            wellness.hydrationLiters >= wellness.hydrationGoalLiters;
      } else {
        waterMet = updatedHistory[dateStr]?['water'] ?? false;
      }

      updatedHistory[dateStr] = {
        'steps': stepsMet,
        'water': waterMet,
        'sleep': sleepMet,
        'calories': caloriesMet,
      };
    }

    final currentStreak = _calculateCurrentStreak(updatedHistory);
    final calculatedLongest = _calculateLongestStreak(updatedHistory);
    final longestStreak = max(state.longestStreak, calculatedLongest);

    state = state.copyWith(
      history: updatedHistory,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );

    _persist();
  }

  /// Records target goals completion for a specific day.
  Future<void> recordDayCompletion({
    required DateTime date,
    required bool stepsMet,
    required bool waterMet,
    required bool sleepMet,
    required bool caloriesMet,
  }) async {
    final dateStr = formatDate(date);
    final updatedHistory = Map<String, Map<String, bool>>.from(state.history);

    updatedHistory[dateStr] = {
      'steps': stepsMet,
      'water': waterMet,
      'sleep': sleepMet,
      'calories': caloriesMet,
    };

    final currentStreak = _calculateCurrentStreak(updatedHistory);
    final calculatedLongest = _calculateLongestStreak(updatedHistory);
    final longestStreak = max(state.longestStreak, calculatedLongest);

    state = state.copyWith(
      history: updatedHistory,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );

    await _persist();
  }

  int _calculateCurrentStreak(Map<String, Map<String, bool>> history) {
    final todayStr = formatDate(DateTime.now());
    final yesterdayStr = formatDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    bool isDayCompleted(String dateStr) {
      final metrics = history[dateStr];
      if (metrics == null) return false;
      return (metrics['steps'] ?? false) ||
          (metrics['water'] ?? false) ||
          (metrics['sleep'] ?? false) ||
          (metrics['calories'] ?? false);
    }

    if (isDayCompleted(todayStr)) {
      int streak = 0;
      var checkDate = DateTime.now();
      while (isDayCompleted(formatDate(checkDate))) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      return streak;
    } else if (isDayCompleted(yesterdayStr)) {
      int streak = 0;
      var checkDate = DateTime.now().subtract(const Duration(days: 1));
      while (isDayCompleted(formatDate(checkDate))) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      return streak;
    } else {
      return 0;
    }
  }

  int _calculateLongestStreak(Map<String, Map<String, bool>> history) {
    if (history.isEmpty) return 0;

    bool isDayCompleted(String dateStr) {
      final metrics = history[dateStr];
      if (metrics == null) return false;
      return (metrics['steps'] ?? false) ||
          (metrics['water'] ?? false) ||
          (metrics['sleep'] ?? false) ||
          (metrics['calories'] ?? false);
    }

    final sortedDates = history.keys.toList()..sort();
    if (sortedDates.isEmpty) return 0;

    int maxStreak = 0;
    int currentRun = 0;
    DateTime? prevDate;

    for (final dateStr in sortedDates) {
      if (!isDayCompleted(dateStr)) {
        currentRun = 0;
        prevDate = null;
        continue;
      }

      final date = DateTime.parse(dateStr);
      if (prevDate == null) {
        currentRun = 1;
      } else {
        final difference = date.difference(prevDate).inDays;
        if (difference == 1) {
          currentRun++;
        } else if (difference > 1) {
          currentRun = 1;
        }
      }

      if (currentRun > maxStreak) {
        maxStreak = currentRun;
      }
      prevDate = date;
    }

    return maxStreak;
  }
}

String formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return "${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}";
}
