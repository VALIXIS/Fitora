import 'package:fitora/core/health/data/health_repository.dart';
import 'package:fitora/core/health/data/sensor_repository.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Health repository that uses the Android step-counter sensor for step/calorie/distance data.
/// For sleep, recovery, and hydration it delegates to the mock repository until
/// Health Connect integration is added in Phase 4.3.
class SensorHealthRepository implements HealthRepository {
  final SensorRepository _sensorRepo;
  final HealthRepository _fallback;

  SensorHealthRepository({
    required SensorRepository sensorRepo,
    required HealthRepository fallback,
  }) : _sensorRepo = sensorRepo,
       _fallback = fallback;

  @override
  Future<DailyActivitySummary> getDailyActivity(DateTime date) async {
    // Try to get live sensor steps
    final liveSteps = await _sensorRepo.getCurrentSteps();

    if (liveSteps == null) {
      // Sensor not available — use mock data with status flag
      final mock = await _fallback.getDailyActivity(date);
      return mock.copyWith(sensorStatus: SensorStatus.unavailable);
    }

    return _buildSummary(steps: liveSteps, date: date);
  }

  @override
  Future<List<DailyActivitySummary>> getWeeklyActivity(
    DateTime startDate,
  ) async {
    // For historical days we use mock data (sensor only has today's data)
    final week = await _fallback.getWeeklyActivity(startDate);

    // Override the last day (today) with live sensor data
    final today = startDate.add(const Duration(days: 6));
    final liveSummary = await getDailyActivity(today);

    final updatedWeek = List<DailyActivitySummary>.from(week);
    if (updatedWeek.isNotEmpty) {
      updatedWeek[updatedWeek.length - 1] = liveSummary;
    }

    return updatedWeek;
  }

  @override
  Future<SleepSummary> getSleepSummary(DateTime date) =>
      _fallback.getSleepSummary(date);

  @override
  Future<RecoverySummary> getRecoverySummary(DateTime date) =>
      _fallback.getRecoverySummary(date);

  @override
  Future<HydrationSummary> getHydrationSummary(DateTime date) =>
      _fallback.getHydrationSummary(date);

  /// Derives calories, distance, and active minutes from a step count.
  DailyActivitySummary _buildSummary({
    required int steps,
    required DateTime date,
  }) {
    // Heuristic conversions (well-accepted approximations):
    //   1 step ≈ 0.762 m  (average stride for mixed population)
    //   ~1 kcal per 20 steps (moderate pace)
    //   Active minutes: every 100 steps/min = 1 active minute
    final distanceKm = steps * 0.000762;
    final calories = steps / 20.0;
    // We estimate active minutes conservatively at ~1 min per 100 steps
    final activeMinutes = (steps / 100).floor();

    return DailyActivitySummary(
      steps: steps,
      stepsGoal: 10000,
      caloriesBurned: calories,
      caloriesGoal: 500,
      activeMinutes: activeMinutes,
      activeMinutesGoal: 30,
      distanceKm: distanceKm,
      date: date,
      sensorStatus: SensorStatus.active,
    );
  }
}

final sensorHealthRepositoryProvider = Provider<SensorHealthRepository>((ref) {
  return SensorHealthRepository(
    sensorRepo: ref.read(sensorRepositoryProvider),
    fallback: MockHealthRepository(),
  );
});
