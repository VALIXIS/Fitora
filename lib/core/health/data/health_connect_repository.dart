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
    // Use local midnight-to-midnight window for accurate timezone handling, but never query into the future
    final start = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final end = (date.year == now.year && date.month == now.month && date.day == now.day)
        ? now
        : DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    print('[HC_DIAG] HealthConnectRepository.getDailyActivity:\n'
        '  - requested date: $date\n'
        '  - device local DateTime.now(): $now\n'
        '  - query start: $start\n'
        '  - query end: $end\n'
        '  - timezone/offset: ${now.timeZoneName} / ${now.timeZoneOffset}');

    final status = await _service.getStatus();

    print('[HC_DIAG] HealthConnectRepository.getDailyActivity: status=$status');

    if (status != HealthConnectStatus.connected &&
        status != HealthConnectStatus.partiallyGranted) {
      return DailyActivitySummary(
        steps: 0,
        stepsGoal: 10000,
        caloriesBurned: 0.0,
        caloriesGoal: 500,
        activeMinutes: 0,
        activeMinutesGoal: 30,
        distanceKm: 0.0,
        date: start,
        healthConnectStatus: status,
        dataSource: DataSource.cache,
        lastSyncTime: now,
      );
    }

    // Fetch steps independently — null means permission denied or HC unavailable
    final steps = (await _service.getSteps(start, end)) ?? 0;

    print('[HC_DIAG] HealthConnectRepository.getDailyActivity: steps=$steps');

    // Fetch activity points (calories, distance) — empty if permission denied
    final activityPoints = await _service.getHealthData(start, end);

    print('[HC_DIAG] HealthConnectRepository.getDailyActivity: fetched ${activityPoints.length} activity points');

    // Deduplicate activity points by UUID
    final uniquePoints = activityPoints
        .fold<Map<String, HealthDataPoint>>({}, (map, p) {
          map[p.uuid] = p;
          return map;
        })
        .values
        .toList();

    double calories = 0;
    double distanceKm = 0;
    int activeMinutes = 0;

    for (final p in uniquePoints) {
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

    final summary = DailyActivitySummary(
      steps: steps,
      stepsGoal: 10000,
      caloriesBurned: calories,
      caloriesGoal: 500,
      activeMinutes: activeMinutes,
      activeMinutesGoal: 30,
      distanceKm: distanceKm,
      date: start,
      healthConnectStatus: status,
      dataSource: DataSource.healthConnectOnly,
      lastSyncTime: now,
    );

    print('[HC_DIAG] HealthConnectRepository.getDailyActivity aggregated result:\n'
        '  - steps: ${summary.steps}\n'
        '  - calories: ${summary.caloriesBurned}\n'
        '  - distanceKm: ${summary.distanceKm}\n'
        '  - activeMinutes: ${summary.activeMinutes}');
    return summary;
  }

  // ---------------------------------------------------------------------------
  // Weekly Activity
  // ---------------------------------------------------------------------------

  @override
  Future<List<DailyActivitySummary>> getWeeklyActivity(
    DateTime startDate,
  ) async {
    final List<DailyActivitySummary> week = [];
    for (int i = 0; i < 7; i++) {
      final day = DateTime(startDate.year, startDate.month, startDate.day + i);
      week.add(await getDailyActivity(day));
    }
    return week;
  }

  // ---------------------------------------------------------------------------
  // Sleep
  // ---------------------------------------------------------------------------

  @override
  Future<SleepSummary> getSleepSummary(DateTime date) async {
    final status = await _service.getStatus();
    if (status != HealthConnectStatus.connected &&
        status != HealthConnectStatus.partiallyGranted) {
      return SleepSummary(
        totalSleep: Duration.zero,
        remSleep: Duration.zero,
        deepSleep: Duration.zero,
        lightSleep: Duration.zero,
        sleepScore: 0,
        date: date,
      );
    }

    // Query noon-date → noon-(date+1) to capture full nightly sleep window belonging to this sleep day
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      12,
      0,
    );
    final end = start.add(const Duration(days: 1));

    final sleepPoints = await _service.getSleepData(start, end);

    final intervals = <_TimeInterval>[];
    for (final p in sleepPoints) {
      if (p.type == HealthDataType.SLEEP_SESSION) {
        if (p.dateTo.isAfter(p.dateFrom)) {
          intervals.add(_TimeInterval(p.dateFrom, p.dateTo));
        }
      }
    }

    final merged = _mergeIntervals(intervals);
    int totalMinutes = 0;
    for (final interval in merged) {
      totalMinutes += interval.end.difference(interval.start).inMinutes;
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
      startTime: merged.isNotEmpty ? merged.first.start : null,
      endTime: merged.isNotEmpty ? merged.last.end : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Recovery & Hydration — not available via Health Connect; return empty
  // ---------------------------------------------------------------------------

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
      waterConsumedLiters: 0,
      waterGoalLiters: 2.5,
      date: date,
    );
  }
}

class _TimeInterval {
  final DateTime start;
  final DateTime end;
  _TimeInterval(this.start, this.end);
}

List<_TimeInterval> _mergeIntervals(List<_TimeInterval> intervals) {
  if (intervals.isEmpty) return [];

  // Sort intervals by start time
  intervals.sort((a, b) => a.start.compareTo(b.start));

  final merged = <_TimeInterval>[intervals.first];

  for (int i = 1; i < intervals.length; i++) {
    final current = intervals[i];
    final lastMerged = merged.last;

    if (current.start.isBefore(lastMerged.end) ||
        current.start.isAtSameMomentAs(lastMerged.end)) {
      // Overlap: merge by updating the end time if the current end is later
      if (current.end.isAfter(lastMerged.end)) {
        merged[merged.length - 1] = _TimeInterval(
          lastMerged.start,
          current.end,
        );
      }
    } else {
      // No overlap: add to merged list
      merged.add(current);
    }
  }

  return merged;
}
