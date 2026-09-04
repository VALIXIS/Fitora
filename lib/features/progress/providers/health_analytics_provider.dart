import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/providers/health_providers.dart';
import 'package:fitora/features/progress/domain/progress_models.dart';
import 'package:fitora/features/wellness/domain/wellness_models.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';

final healthTimeframeProvider = StateProvider.autoDispose<HealthTimeframe>((ref) {
  return HealthTimeframe.sevenDays;
});

final healthSelectedMetricProvider = StateProvider.autoDispose<HealthMetricType>((ref) {
  return HealthMetricType.steps;
});

class HealthAnalyticsCalculator {
  static WeeklyHealthSummaryData calculateWeeklySummary({
    required List<DailyActivitySummary> last14DaysActivities,
    required Map<String, int> sleepLogHistory,
    required Map<String, double> waterLogHistory,
    List<WaterLogEntry> waterLogs = const [],
    required Map<String, int> sleepScoreHistory,
    required double currentTodayWater,
  }) {
    if (last14DaysActivities.isEmpty) {
      return WeeklyHealthSummaryData.empty();
    }

    // Split 14 days into current week (last 7 days, indices 7..13) and prior week (indices 0..6)
    final currentWeek = last14DaysActivities.length >= 7
        ? last14DaysActivities.sublist(last14DaysActivities.length - 7)
        : last14DaysActivities;

    final priorWeek = last14DaysActivities.length >= 14
        ? last14DaysActivities.sublist(
            last14DaysActivities.length - 14,
            last14DaysActivities.length - 7,
          )
        : <DailyActivitySummary>[];

    // Current Week Totals
    int totalSteps = 0;
    double totalCalories = 0.0;
    for (final act in currentWeek) {
      totalSteps += act.steps;
      totalCalories += act.caloriesBurned;
    }

    // Current Week Water & Sleep
    double totalWater = 0.0;
    int totalSleepMins = 0;

    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    String bestStepDay = 'N/A';
    int maxStepVal = 0;

    String bestWaterDay = 'N/A';
    double maxWaterVal = 0.0;

    for (var i = 0; i < currentWeek.length; i++) {
      final act = currentWeek[i];
      final dateStr = _dateToStr(act.date);
      final dayName = dayNames[act.date.weekday - 1];

      // Best step check
      if (act.steps > maxStepVal) {
        maxStepVal = act.steps;
        bestStepDay = dayName;
      }

      // Water lookup
      final dayWater = _getDailyWater(
        dateStr: dateStr,
        date: act.date,
        waterLogHistory: waterLogHistory,
        waterLogs: waterLogs,
        currentTodayWater: currentTodayWater,
      );
      totalWater += dayWater;

      if (dayWater > maxWaterVal) {
        maxWaterVal = dayWater;
        bestWaterDay = dayName;
      }

      // Sleep lookup
      final sleepMins = sleepLogHistory[dateStr] ?? 0;
      totalSleepMins += sleepMins;
    }

    // Prior Week Totals
    int priorSteps = 0;
    double priorCalories = 0.0;
    double priorWater = 0.0;
    int priorSleepMins = 0;

    for (final act in priorWeek) {
      priorSteps += act.steps;
      priorCalories += act.caloriesBurned;
      final dateStr = _dateToStr(act.date);
      priorWater += _getDailyWater(
        dateStr: dateStr,
        date: act.date,
        waterLogHistory: waterLogHistory,
        waterLogs: waterLogs,
        currentTodayWater: currentTodayWater,
      );
      priorSleepMins += (sleepLogHistory[dateStr] ?? 0);
    }

    // Calculations
    final double avgSleepMinutes = currentWeek.isNotEmpty
        ? totalSleepMins / currentWeek.length
        : 0.0;
    final double priorAvgSleepMins = priorWeek.isNotEmpty
        ? priorSleepMins / priorWeek.length
        : 0.0;

    // Deltas
    final double stepsDeltaPct = priorSteps == 0
        ? (totalSteps > 0 ? 100.0 : 0.0)
        : ((totalSteps - priorSteps) / priorSteps) * 100.0;

    final double caloriesDeltaPct = priorCalories == 0.0
        ? (totalCalories > 0.0 ? 100.0 : 0.0)
        : ((totalCalories - priorCalories) / priorCalories) * 100.0;

    final double waterDeltaLiters = totalWater - priorWater;
    final double sleepDeltaHours = (avgSleepMinutes - priorAvgSleepMins) / 60.0;

    return WeeklyHealthSummaryData(
      totalSteps: totalSteps,
      totalWaterLiters: totalWater,
      avgSleepMinutes: avgSleepMinutes,
      totalActiveCalories: totalCalories,
      stepsDeltaPct: stepsDeltaPct.isNaN || stepsDeltaPct.isInfinite
          ? 0.0
          : stepsDeltaPct,
      waterDeltaLiters: waterDeltaLiters.isNaN || waterDeltaLiters.isInfinite
          ? 0.0
          : waterDeltaLiters,
      sleepDeltaHours: sleepDeltaHours.isNaN || sleepDeltaHours.isInfinite
          ? 0.0
          : sleepDeltaHours,
      caloriesDeltaPct: caloriesDeltaPct.isNaN || caloriesDeltaPct.isInfinite
          ? 0.0
          : caloriesDeltaPct,
      bestStepDay: maxStepVal > 0 ? bestStepDay : 'N/A',
      bestStepValue: maxStepVal > 0 ? maxStepVal : 0,
      bestHydrationDay: maxWaterVal > 0 ? bestWaterDay : 'N/A',
      bestHydrationValue: maxWaterVal > 0 ? maxWaterVal : 0.0,
    );
  }

  static double _getDailyWater({
    required String dateStr,
    required DateTime date,
    required Map<String, double> waterLogHistory,
    required List<WaterLogEntry> waterLogs,
    required double currentTodayWater,
  }) {
    if (waterLogHistory.containsKey(dateStr)) {
      return waterLogHistory[dateStr]!;
    }
    final logsForDay = waterLogs.where(
      (e) =>
          e.timestamp.year == date.year &&
          e.timestamp.month == date.month &&
          e.timestamp.day == date.day,
    );
    if (logsForDay.isNotEmpty) {
      final totalMl = logsForDay.fold<int>(0, (sum, e) => sum + e.amountMl);
      return totalMl / 1000.0;
    }
    final isToday = _isSameDay(date, DateTime.now());
    return isToday ? currentTodayWater : 0.0;
  }

  static String _dateToStr(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

final weeklyHealthSummaryProvider = Provider.autoDispose<WeeklyHealthSummaryData>((ref) {
  final last14Days = ref.watch(healthActivityRangeProvider(14));
  final wellness = ref.watch(wellnessProvider);

  return HealthAnalyticsCalculator.calculateWeeklySummary(
    last14DaysActivities: last14Days,
    sleepLogHistory: wellness.sleepLogHistory,
    waterLogHistory: wellness.waterLogHistory,
    waterLogs: wellness.waterLogs,
    sleepScoreHistory: wellness.sleepScoreHistory,
    currentTodayWater: wellness.hydrationLiters,
  );
});
