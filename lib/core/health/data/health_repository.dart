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
    return SleepSummary(
      totalSleep: const Duration(hours: 7, minutes: 15),
      remSleep: const Duration(hours: 1, minutes: 45),
      deepSleep: const Duration(hours: 1, minutes: 30),
      lightSleep: const Duration(hours: 4, minutes: 0),
      sleepScore: 82,
      date: date,
    );
  }

  @override
  Future<RecoverySummary> getRecoverySummary(DateTime date) async {
    return RecoverySummary(
      recoveryScore: 87,
      hrv: 65,
      restingHeartRate: 52,
      date: date,
    );
  }

  @override
  Future<HydrationSummary> getHydrationSummary(DateTime date) async {
    return HydrationSummary(
      waterConsumedLiters: 2.1,
      waterGoalLiters: 2.5,
      date: date,
    );
  }
}

// Provider moved to health_providers.dart to avoid duplicates
