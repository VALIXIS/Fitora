import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/features/progress/data/progress_local_data_source.dart';
import 'package:fitora/features/progress/data/progress_repository.dart';
import 'package:fitora/features/progress/domain/progress_models.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final local = ref.read(progressLocalDataSourceProvider);
  return LocalProgressRepository(local);
});

final progressControllerProvider =
    StateNotifierProvider<ProgressController, ProgressState>((ref) {
  final repository = ref.read(progressRepositoryProvider);
  return ProgressController(repository);
});

class ProgressState {
  final bool isLoading;
  final List<WorkoutHistoryEntry> history;
  final ProgressSummary summary;
  final StreakInfo streak;
  final List<DailyActivity> weeklyActivity;
  final List<WeeklyTrend> weeklyTrends;
  final List<WorkoutHistoryEntry> recentWorkouts;

  const ProgressState({
    required this.isLoading,
    required this.history,
    required this.summary,
    required this.streak,
    required this.weeklyActivity,
    required this.weeklyTrends,
    required this.recentWorkouts,
  });

  factory ProgressState.initial() => ProgressState(
        isLoading: true,
        history: const [],
        summary: ProgressSummary.empty(),
        streak: StreakInfo.empty(),
        weeklyActivity: const [],
        weeklyTrends: const [],
        recentWorkouts: const [],
      );
}

class ProgressController extends StateNotifier<ProgressState> {
  final ProgressRepository _repository;
  late final Future<void> _loadFuture;

  ProgressController(this._repository) : super(ProgressState.initial()) {
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final history = await _repository.fetchHistory();
    state = _buildState(history, isLoading: false);
  }

  Future<void> ensureLoaded() => _loadFuture;



  ProgressState _buildState(
    List<WorkoutHistoryEntry> history, {
    required bool isLoading,
  }) {
    final sorted = [...history]
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    final dailyTotals = _aggregateByDay(sorted);
    final weeklyActivity = _buildWeeklyActivity(dailyTotals);
    final summary = _buildSummary(sorted, weeklyActivity);
    final streak = _buildStreak(sorted);
    final weeklyTrends = _buildWeeklyTrends(dailyTotals);
    final recent = sorted.reversed.take(5).toList();

    return ProgressState(
      isLoading: isLoading,
      history: List.unmodifiable(sorted),
      summary: summary,
      streak: streak,
      weeklyActivity: List.unmodifiable(weeklyActivity),
      weeklyTrends: List.unmodifiable(weeklyTrends),
      recentWorkouts: List.unmodifiable(recent),
    );
  }

  ProgressSummary _buildSummary(
    List<WorkoutHistoryEntry> history,
    List<DailyActivity> weeklyActivity,
  ) {
    var totalMinutes = 0;
    var totalCalories = 0;
    var totalExercises = 0;

    for (final entry in history) {
      totalMinutes += entry.durationMinutes;
      totalCalories += entry.calories;
      totalExercises += entry.exercisesCompleted;
    }

    var weeklyWorkouts = 0;
    var weeklyMinutes = 0;
    var weeklyCalories = 0;
    for (final day in weeklyActivity) {
      weeklyWorkouts += day.workouts;
      weeklyMinutes += day.minutes;
      weeklyCalories += day.calories;
    }

    return ProgressSummary(
      totalWorkouts: history.length,
      totalMinutes: totalMinutes,
      totalCalories: totalCalories,
      totalExercises: totalExercises,
      weeklyWorkouts: weeklyWorkouts,
      weeklyMinutes: weeklyMinutes,
      weeklyCalories: weeklyCalories,
    );
  }

  StreakInfo _buildStreak(List<WorkoutHistoryEntry> history) {
    if (history.isEmpty) {
      return StreakInfo.empty();
    }

    final uniqueDays = {
      for (final entry in history) _dateOnly(entry.completedAt)
    }.toList()
      ..sort();

    final lastDay = uniqueDays.last;
    final today = _dateOnly(DateTime.now());
    final daysSinceLast = today.difference(lastDay).inDays;

    var currentStreak = 0;
    if (daysSinceLast <= 1) {
      currentStreak = 1;
      for (var i = uniqueDays.length - 1; i > 0; i--) {
        final gap = uniqueDays[i].difference(uniqueDays[i - 1]).inDays;
        if (gap == 1) {
          currentStreak += 1;
        } else {
          break;
        }
      }
    }

    var longestStreak = 0;
    var running = 0;
    for (var i = 0; i < uniqueDays.length; i++) {
      if (i == 0) {
        running = 1;
      } else {
        final gap = uniqueDays[i].difference(uniqueDays[i - 1]).inDays;
        running = gap == 1 ? running + 1 : 1;
      }
      if (running > longestStreak) {
        longestStreak = running;
      }
    }

    return StreakInfo(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastCompletedDate: lastDay,
    );
  }

  List<DailyActivity> _buildWeeklyActivity(
    Map<DateTime, _DailyTotals> dailyTotals,
  ) {
    final today = _dateOnly(DateTime.now());
    final start = today.subtract(const Duration(days: 6));
    final days = <DailyActivity>[];

    for (var i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final totals = dailyTotals[day] ?? const _DailyTotals.empty();
      days.add(
        DailyActivity(
          date: day,
          workouts: totals.workouts,
          minutes: totals.minutes,
          calories: totals.calories,
        ),
      );
    }

    return days;
  }

  List<WeeklyTrend> _buildWeeklyTrends(
    Map<DateTime, _DailyTotals> dailyTotals,
  ) {
    final today = _dateOnly(DateTime.now());
    final trends = <WeeklyTrend>[];

    for (var weekIndex = 3; weekIndex >= 0; weekIndex--) {
      final end = today.subtract(Duration(days: weekIndex * 7));
      final start = end.subtract(const Duration(days: 6));
      var workouts = 0;
      var minutes = 0;
      var calories = 0;

      for (var i = 0; i < 7; i++) {
        final day = start.add(Duration(days: i));
        final totals = dailyTotals[day];
        if (totals != null) {
          workouts += totals.workouts;
          minutes += totals.minutes;
          calories += totals.calories;
        }
      }

      trends.add(
        WeeklyTrend(
          start: start,
          end: end,
          workouts: workouts,
          minutes: minutes,
          calories: calories,
        ),
      );
    }

    return trends;
  }

  Map<DateTime, _DailyTotals> _aggregateByDay(
    List<WorkoutHistoryEntry> history,
  ) {
    final totals = <DateTime, _DailyTotals>{};
    for (final entry in history) {
      final day = _dateOnly(entry.completedAt);
      final existing = totals[day] ?? const _DailyTotals.empty();
      totals[day] = existing.add(entry);
    }
    return totals;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _DailyTotals {
  final int workouts;
  final int minutes;
  final int calories;

  const _DailyTotals({
    required this.workouts,
    required this.minutes,
    required this.calories,
  });

  const _DailyTotals.empty()
      : workouts = 0,
        minutes = 0,
        calories = 0;

  _DailyTotals add(WorkoutHistoryEntry entry) {
    return _DailyTotals(
      workouts: workouts + 1,
      minutes: minutes + entry.durationMinutes,
      calories: calories + entry.calories,
    );
  }
}
