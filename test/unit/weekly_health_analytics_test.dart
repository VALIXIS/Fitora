import 'package:flutter_test/flutter_test.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/features/progress/domain/progress_models.dart';
import 'package:fitora/features/progress/providers/health_analytics_provider.dart';

void main() {
  group('HealthAnalyticsCalculator Tests', () {
    test('calculateWeeklySummary returns empty summary when 14-day list is empty', () {
      final summary = HealthAnalyticsCalculator.calculateWeeklySummary(
        last14DaysActivities: [],
        sleepLogHistory: {},
        waterLogHistory: {},
        sleepScoreHistory: {},
        currentTodayWater: 0.0,
      );

      expect(summary.totalSteps, 0);
      expect(summary.totalWaterLiters, 0.0);
      expect(summary.avgSleepMinutes, 0.0);
      expect(summary.totalActiveCalories, 0.0);
      expect(summary.stepsDeltaPct, 0.0);
      expect(summary.bestStepDay, 'N/A');
      expect(summary.bestHydrationDay, 'N/A');
    });

    test('calculateWeeklySummary calculates correct totals and WoW deltas', () {
      final now = DateTime(2026, 8, 12);

      // Create 14 days of activities:
      // Prior week (days 0..6): 5000 steps each day (35,000 total), 200 kcal each (1,400 total)
      // Current week (days 7..13): 10000 steps each day (70,000 total), 300 kcal each (2,100 total)
      final activities = List<DailyActivitySummary>.generate(14, (i) {
        final date = now.subtract(Duration(days: 13 - i));
        final isCurrentWeek = i >= 7;
        return DailyActivitySummary(
          steps: isCurrentWeek ? 10000 : 5000,
          stepsGoal: 10000,
          activeMinutes: isCurrentWeek ? 45 : 30,
          activeMinutesGoal: 30,
          distanceKm: isCurrentWeek ? 7.0 : 3.5,
          caloriesBurned: isCurrentWeek ? 300.0 : 200.0,
          caloriesGoal: 500.0,
          lastSyncTime: DateTime.now(),
          date: date,
        );
      });

      final waterHistory = <String, double>{};
      final sleepHistory = <String, int>{};

      for (var i = 0; i < 14; i++) {
        final date = now.subtract(Duration(days: 13 - i));
        final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        // Water: prior week = 2.0L/day, current week = 3.0L/day
        waterHistory[dateStr] = i >= 7 ? 3.0 : 2.0;
        // Sleep: prior week = 420 mins (7h), current week = 480 mins (8h)
        sleepHistory[dateStr] = i >= 7 ? 480 : 420;
      }

      final summary = HealthAnalyticsCalculator.calculateWeeklySummary(
        last14DaysActivities: activities,
        sleepLogHistory: sleepHistory,
        waterLogHistory: waterHistory,
        sleepScoreHistory: {},
        currentTodayWater: 3.0,
      );

      // Current 7-day Totals
      expect(summary.totalSteps, 70000);
      expect(summary.totalActiveCalories, 2100.0);
      expect(summary.totalWaterLiters, 21.0);
      expect(summary.avgSleepMinutes, 480.0);

      // Deltas vs Prior Week
      // Steps: (70000 - 35000) / 35000 = +100%
      expect(summary.stepsDeltaPct, 100.0);

      // Calories: (2100 - 1400) / 1400 = +50%
      expect(summary.caloriesDeltaPct, 50.0);

      // Water: 21.0L - 14.0L = +7.0L
      expect(summary.waterDeltaLiters, 7.0);

      // Sleep: (480 - 420) / 60 = +1.0h
      expect(summary.sleepDeltaHours, 1.0);
    });

    test('calculateWeeklySummary identifies best day correctly', () {
      final now = DateTime(2026, 8, 12); // Wednesday (weekday 3)

      final activities = List<DailyActivitySummary>.generate(14, (i) {
        final date = now.subtract(Duration(days: 13 - i));
        // Give one specific day in current week the highest steps (15,000 steps)
        final steps = i == 11 ? 15000 : 8000;
        return DailyActivitySummary(
          steps: steps,
          stepsGoal: 10000,
          activeMinutes: 30,
          activeMinutesGoal: 30,
          distanceKm: 5.0,
          caloriesBurned: 300.0,
          caloriesGoal: 500.0,
          lastSyncTime: DateTime.now(),
          date: date,
        );
      });

      final summary = HealthAnalyticsCalculator.calculateWeeklySummary(
        last14DaysActivities: activities,
        sleepLogHistory: {},
        waterLogHistory: {},
        sleepScoreHistory: {},
        currentTodayWater: 2.5,
      );

      expect(summary.bestStepValue, 15000);
      expect(summary.bestStepDay, isNotEmpty);
      expect(summary.bestStepDay, isNot('N/A'));
    });
  });

  group('HealthTimeframe & HealthMetricType Enums', () {
    test('HealthTimeframe returns correct day counts', () {
      expect(HealthTimeframe.sevenDays.days, 7);
      expect(HealthTimeframe.thirtyDays.days, 30);
    });

    test('HealthMetricType exposes valid names and units', () {
      expect(HealthMetricType.steps.displayName, 'Steps');
      expect(HealthMetricType.steps.unit, 'steps');
      expect(HealthMetricType.distance.unit, 'km');
      expect(HealthMetricType.calories.unit, 'kcal');
      expect(HealthMetricType.sleep.unit, 'hrs');
      expect(HealthMetricType.water.unit, 'L');
    });
  });
}
