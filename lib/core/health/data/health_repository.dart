import 'package:fitora/core/health/domain/health_models.dart';

abstract class HealthRepository {
  Future<DailyActivitySummary> getDailyActivity(DateTime date);
  Future<List<DailyActivitySummary>> getWeeklyActivity(DateTime startDate);
  Future<SleepSummary> getSleepSummary(DateTime date);
  Future<RecoverySummary> getRecoverySummary(DateTime date);
  Future<HydrationSummary> getHydrationSummary(DateTime date);
}

class MockHealthRepository implements HealthRepository {
  @override
  Future<DailyActivitySummary> getDailyActivity(DateTime date) async {
    return DailyActivitySummary(
      steps: 0,
      stepsGoal: 10000,
      caloriesBurned: 0,
      caloriesGoal: 500,
      activeMinutes: 0,
      activeMinutesGoal: 30,
      distanceKm: 0.0,
      date: date,
    );
  }

  @override
  Future<List<DailyActivitySummary>> getWeeklyActivity(
    DateTime startDate,
  ) async {
    return List.generate(7, (index) {
      final date = startDate.add(Duration(days: index));
      return DailyActivitySummary(
        steps: 0,
        stepsGoal: 10000,
        caloriesBurned: 0,
        caloriesGoal: 500,
        activeMinutes: 0,
        activeMinutesGoal: 30,
        distanceKm: 0.0,
        date: date,
      );
    });
  }

  @override
  Future<SleepSummary> getSleepSummary(DateTime date) async {
    // No real sleep data available without Health Connect
    return SleepSummary(
      totalSleep: Duration.zero,
      remSleep: Duration.zero,
      deepSleep: Duration.zero,
      lightSleep: Duration.zero,
      sleepScore: 0,
      date: date,
    );
  }

  @override
  Future<RecoverySummary> getRecoverySummary(DateTime date) async {
    return RecoverySummary(
      recoveryScore: 0,
      hrv: 0,
      restingHeartRate: 0,
      date: date,
    );
  }

  @override
  Future<HydrationSummary> getHydrationSummary(DateTime date) async {
    return HydrationSummary(
      waterConsumedLiters: 0.0,
      waterGoalLiters: 2.5,
      date: date,
    );
  }
}

// Provider moved to health_providers.dart to avoid duplicates
