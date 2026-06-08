import 'package:fitora/core/health/data/health_repository.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/services/health_connect_service.dart';
import 'package:health/health.dart';

class HealthConnectRepository implements HealthRepository {
  final HealthConnectService _service;

  HealthConnectRepository(this._service);

  @override
  Future<DailyActivitySummary> getDailyActivity(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    
    final points = await _service.getHealthData(start, end);
    int steps = (await _service.getSteps(start, end)) ?? 0;
    
    double calories = 0;
    double distance = 0;
    int activeMinutes = 0;

    for (final p in points) {
      if (p.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
        calories += (p.value as NumericHealthValue).numericValue.toDouble();
      } else if (p.type == HealthDataType.DISTANCE_DELTA) {
        distance += (p.value as NumericHealthValue).numericValue.toDouble() / 1000.0;
      } else if (p.type == HealthDataType.WORKOUT) {
        activeMinutes += p.dateTo.difference(p.dateFrom).inMinutes;
      }
    }

    return DailyActivitySummary(
      steps: steps,
      stepsGoal: 10000,
      caloriesBurned: calories,
      caloriesGoal: 500,
      activeMinutes: activeMinutes,
      activeMinutesGoal: 30,
      distanceKm: distance,
      date: start,
      healthConnectStatus: HealthConnectStatus.connected,
      dataSource: DataSource.healthConnectOnly,
      lastSyncTime: DateTime.now(),
    );
  }

  @override
  Future<List<DailyActivitySummary>> getWeeklyActivity(DateTime startDate) async {
    final List<DailyActivitySummary> week = [];
    for (int i = 0; i < 7; i++) {
      week.add(await getDailyActivity(startDate.add(Duration(days: i))));
    }
    return week;
  }

  @override
  Future<SleepSummary> getSleepSummary(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day, 12, 0).subtract(const Duration(days: 1)); // noon yesterday
    final end = DateTime(date.year, date.month, date.day, 12, 0); // noon today
    
    final points = await _service.getHealthData(start, end);
    final sleepPoints = points.where((p) => p.type == HealthDataType.SLEEP_SESSION).toList();
    
    int totalMinutes = 0;
    for (final p in sleepPoints) {
      totalMinutes += p.dateTo.difference(p.dateFrom).inMinutes;
    }
    
    return SleepSummary(
      totalSleep: Duration(minutes: totalMinutes),
      remSleep: Duration.zero,
      deepSleep: Duration.zero,
      lightSleep: Duration(minutes: totalMinutes),
      sleepScore: totalMinutes > 0 ? 80 : 0,
      date: date,
    );
  }

  @override
  Future<RecoverySummary> getRecoverySummary(DateTime date) async {
    return RecoverySummary(recoveryScore: 0, hrv: 0, restingHeartRate: 0, date: date);
  }

  @override
  Future<HydrationSummary> getHydrationSummary(DateTime date) async {
    return HydrationSummary(waterConsumedLiters: 0, waterGoalLiters: 2.5, date: date);
  }
}
