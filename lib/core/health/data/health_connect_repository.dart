import 'package:fitora/core/health/data/health_repository.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/services/health_connect_service.dart';
import 'package:health/health.dart';

class HealthConnectRepository implements HealthRepository {
  final HealthConnectService _service;

  HealthConnectRepository(this._service);

  // ---------------------------------------------------------------------------
  // Daily Activity
  // ---------------------------------------------------------------------------

  @override
  Future<DailyActivitySummary> getDailyActivity(DateTime date) async {
    // Use local midnight-to-midnight window for accurate timezone handling
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    final now = DateTime.now();

    // Fetch steps independently — null means permission denied or HC unavailable
    final steps = (await _service.getSteps(start, end)) ?? 0;

    // Fetch activity points (calories, distance) — empty if permission denied
    final activityPoints = await _service.getHealthData(start, end);

    double calories = 0;
    double distanceKm = 0;
    int activeMinutes = 0;

    for (final p in activityPoints) {
      if (p.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
        calories += (p.value as NumericHealthValue).numericValue.toDouble();
      } else if (p.type == HealthDataType.DISTANCE_DELTA) {
        // Health Connect returns distance in metres
        distanceKm +=
            (p.value as NumericHealthValue).numericValue.toDouble() / 1000.0;
      }
    }

    // Active minutes: heuristic — 1 active minute per 100 steps (conservative)
    activeMinutes = (steps / 100).floor();

    return DailyActivitySummary(
      steps: steps,
      stepsGoal: 10000,
      caloriesBurned: calories,
      caloriesGoal: 500,
      activeMinutes: activeMinutes,
      activeMinutesGoal: 30,
      distanceKm: distanceKm,
      date: start,
      healthConnectStatus: HealthConnectStatus.connected,
      dataSource: DataSource.healthConnectOnly,
      lastSyncTime: now,
    );
  }

  // ---------------------------------------------------------------------------
  // Weekly Activity
  // ---------------------------------------------------------------------------

  @override
  Future<List<DailyActivitySummary>> getWeeklyActivity(
      DateTime startDate) async {
    final List<DailyActivitySummary> week = [];
    for (int i = 0; i < 7; i++) {
      final day = DateTime(
        startDate.year,
        startDate.month,
        startDate.day + i,
      );
      week.add(await getDailyActivity(day));
    }
    return week;
  }

  // ---------------------------------------------------------------------------
  // Sleep
  // ---------------------------------------------------------------------------

  @override
  Future<SleepSummary> getSleepSummary(DateTime date) async {
    // Query noon-yesterday → noon-today to capture full nightly sleep window
    final start = DateTime(date.year, date.month, date.day, 12, 0)
        .subtract(const Duration(days: 1));
    final end = DateTime(date.year, date.month, date.day, 12, 0);

    final sleepPoints = await _service.getSleepData(start, end);

    int totalMinutes = 0;
    for (final p in sleepPoints) {
      if (p.type == HealthDataType.SLEEP_SESSION) {
        totalMinutes += p.dateTo.difference(p.dateFrom).inMinutes;
      }
    }

    final sleepScore = totalMinutes > 0
        ? ((totalMinutes / 480.0) * 100).round().clamp(0, 100)
        : 0;

    return SleepSummary(
      totalSleep: Duration(minutes: totalMinutes),
      remSleep: Duration.zero,
      deepSleep: Duration.zero,
      lightSleep: Duration(minutes: totalMinutes),
      sleepScore: sleepScore,
      date: date,
    );
  }

  // ---------------------------------------------------------------------------
  // Recovery & Hydration — not available via Health Connect; return empty
  // ---------------------------------------------------------------------------

  @override
  Future<RecoverySummary> getRecoverySummary(DateTime date) async {
    return RecoverySummary(
        recoveryScore: 0, hrv: 0, restingHeartRate: 0, date: date);
  }

  @override
  Future<HydrationSummary> getHydrationSummary(DateTime date) async {
    return HydrationSummary(
        waterConsumedLiters: 0, waterGoalLiters: 2.5, date: date);
  }
}
