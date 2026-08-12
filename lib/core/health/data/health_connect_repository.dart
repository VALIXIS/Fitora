import 'package:flutter/foundation.dart';
import 'package:fitora/core/health/data/health_repository.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/services/health_connect_service.dart';
import 'package:health/health.dart';

class HealthConnectRepository implements HealthRepository {
  final HealthConnectService _service;

  HealthConnectRepository(this._service);

  @override
  Future<DailyActivitySummary> getDailyActivity(DateTime date) async {
    final now = DateTime.now();
    final start = DateTime(date.year, date.month, date.day);
    DateTime end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    if (end.isAfter(now)) {
      end = now;
    }

    if (kDebugMode) {
      print('[HC_DEBUG] Calling Health Connect read... start: $start, end: $end');
    }

    final points = await _service.getHealthData(start, end);
    int steps = (await _service.getSteps(start, end)) ?? 0;

    double activeCal = 0;
    double totalCal = 0;
    double distance = 0;
    int activeMinutes = 0;

    if (kDebugMode) {
      print('[HC_DEBUG] Health Connect raw steps: $steps');
      print('[HC_DEBUG] Health Connect raw points count: ${points.length}');
    }

    for (final p in points) {
      if (p.type == HealthDataType.STEPS) {
        if (steps == 0) {
          steps += (p.value as NumericHealthValue).numericValue.toInt();
        }
      } else if (p.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
        activeCal += (p.value as NumericHealthValue).numericValue.toDouble();
      } else if (p.type == HealthDataType.TOTAL_CALORIES_BURNED) {
        totalCal += (p.value as NumericHealthValue).numericValue.toDouble();
      } else if (p.type == HealthDataType.DISTANCE_DELTA) {
        distance += (p.value as NumericHealthValue).numericValue.toDouble() / 1000.0;
      }
    }

    double calories = activeCal > 0 ? activeCal : totalCal;

    if (kDebugMode) {
      print('[HC_DEBUG] Health Connect raw calories: $calories (active: $activeCal, total: $totalCal)');
      print('[HC_DEBUG] Health Connect raw distance: $distance km');
    }

    final daily = DailyActivitySummary(
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
      lastSyncTime: now,
    );

    if (kDebugMode) {
      print('[HC_DEBUG] Repository DailyActivity: steps=${daily.steps}, cal=${daily.caloriesBurned}, dist=${daily.distanceKm}');
    }

    return daily;
  }

  @override
  Future<SleepSummary> getSleepSummary(DateTime date) async {
    final now = DateTime.now();
    final start = DateTime(date.year, date.month, date.day);
    DateTime end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    if (end.isAfter(now)) {
      end = now;
    }

    final points = await _service.getSleepData(start, end);
    int sleepMinutes = 0;

    for (final p in points) {
      if (p.type == HealthDataType.SLEEP_SESSION) {
        final duration = p.dateTo.difference(p.dateFrom);
        sleepMinutes += duration.inMinutes;
      }
    }

    if (kDebugMode) {
      print('[HC_DEBUG] Health Connect raw sleep: ${sleepMinutes / 60.0} hours');
    }

    return SleepSummary(
      totalSleep: Duration(minutes: sleepMinutes),
      remSleep: Duration.zero,
      deepSleep: Duration.zero,
      lightSleep: Duration(minutes: sleepMinutes),
      sleepScore: sleepMinutes > 0 ? 80 : 0,
      date: start,
    );
  }

  @override
  Future<RecoverySummary> getRecoverySummary(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    return RecoverySummary(
      recoveryScore: 0,
      hrv: 0,
      restingHeartRate: 0,
      date: start,
    );
  }

  @override
  Future<HydrationSummary> getHydrationSummary(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    return HydrationSummary(
      waterConsumedLiters: 0.0,
      waterGoalLiters: 2.5,
      date: start,
    );
  }

  @override
  Future<List<DailyActivitySummary>> getWeeklyActivity(DateTime endOfWeek) async {
    final list = <DailyActivitySummary>[];
    for (int i = 6; i >= 0; i--) {
      final day = endOfWeek.subtract(Duration(days: i));
      list.add(await getDailyActivity(day));
    }
    return list;
  }
}
