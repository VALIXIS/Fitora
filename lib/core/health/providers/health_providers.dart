import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/data/sensor_repository.dart';
import 'package:fitora/core/health/data/sensor_health_repository.dart';
import 'package:fitora/core/health/services/health_connect_service.dart';
import 'package:fitora/core/health/data/health_connect_repository.dart';
import 'package:fitora/core/health/services/health_cache_service.dart';
import 'package:fitora/core/health/services/health_sync_service.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'dart:math';
import 'package:fitora/core/health/services/health_permissions_service.dart';

import 'package:fitora/core/constants/storage_keys.dart';
import 'package:fitora/core/health/utils/goal_calculator.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/health_sync/providers/health_sync_provider.dart';

// ---------------------------------------------------------------------------
// Core Services
// ---------------------------------------------------------------------------

final healthCacheServiceProvider = Provider<HealthCacheService>((ref) {
  return HealthCacheService(AppPreferences.prefs);
});

final healthConnectServiceProvider = Provider<HealthConnectService>((ref) {
  return HealthConnectService(AppPreferences.prefs);
});

final healthConnectRepositoryProvider = Provider<HealthConnectRepository>((
  ref,
) {
  return HealthConnectRepository(ref.watch(healthConnectServiceProvider));
});

final healthSyncServiceProvider =
    StateNotifierProvider<HealthSyncService, SyncStatus>((ref) {
      return HealthSyncService(
        ref.watch(healthConnectRepositoryProvider),
        ref.watch(sensorHealthRepositoryProvider),
        ref.watch(healthCacheServiceProvider),
      );
    });
// ---------------------------------------------------------------------------
// Custom Step Goal Provider
// ---------------------------------------------------------------------------

final customStepGoalProvider =
    StateNotifierProvider<CustomStepGoalNotifier, int?>((ref) {
      return CustomStepGoalNotifier()..load();
    });

class CustomStepGoalNotifier extends StateNotifier<int?> {
  CustomStepGoalNotifier() : super(null);

  Future<void> load() async {
    try {
      final prefs = await AppPreferences.instance();
      final saved = prefs.getInt(StorageKeys.customStepGoal);
      if (saved != null && saved > 0) {
        state = saved;
      }
    } catch (_) {}
  }

  Future<void> setGoal(int steps) async {
    final clamped = steps.clamp(1000, 50000);
    state = clamped;
    try {
      final prefs = await AppPreferences.instance();
      await prefs.setInt(StorageKeys.customStepGoal, clamped);
    } catch (_) {}
  }
}

// ---------------------------------------------------------------------------
// Sensor permission status — drives gating of live data
// ---------------------------------------------------------------------------

final sensorStatusProvider =
    StateNotifierProvider<SensorStatusNotifier, SensorStatus>(
      (ref) => SensorStatusNotifier(ref),
    );

class SensorStatusNotifier extends StateNotifier<SensorStatus> {
  final Ref _ref;

  SensorStatusNotifier(this._ref) : super(SensorStatus.unknown) {
    checkPermission();
  }

  Future<void> checkPermission() async {
    final svc = _ref.read(healthPermissionsServiceProvider);
    final status = await svc.checkStatus();
    state = status;
  }

  Future<void> requestPermission() async {
    final svc = _ref.read(healthPermissionsServiceProvider);
    final status = await svc.requestPermission();
    state = status;
  }
}

// ---------------------------------------------------------------------------
// Health Connect Status
// ---------------------------------------------------------------------------

final healthConnectStatusProvider =
    StateNotifierProvider<HealthConnectStatusNotifier, HealthConnectStatus>((
      ref,
    ) {
      return HealthConnectStatusNotifier();
    });

class HealthConnectStatusNotifier extends StateNotifier<HealthConnectStatus> {
  HealthConnectStatusNotifier()
    : super(HealthConnectStatus.unavailable) {
    checkStatus();
  }

  Future<void> checkStatus() async {
    state = HealthConnectStatus.unavailable;
  }

  Future<void> requestPermissions() async {
    state = HealthConnectStatus.unavailable;
  }
}

// ---------------------------------------------------------------------------
// Live step stream (real-time updates from native sensor)
// ---------------------------------------------------------------------------

final liveStepsProvider = StreamProvider<int>((ref) async* {
  final status = ref.watch(sensorStatusProvider);
  if (status != SensorStatus.active) {
    yield 0;
    return;
  }

  final repo = ref.read(sensorRepositoryProvider);
  final initial = await repo.getCurrentSteps();
  if (initial != null) {
    yield initial;
  }

  yield* repo.stepStream;
});

// ---------------------------------------------------------------------------
// Activity Providers (Driven by Cache & Merged with Live Steps)
// ---------------------------------------------------------------------------

final dailyActivityProvider = Provider.family<DailyActivitySummary, DateTime>((
  ref,
  date,
) {
  // Rebuild UI when health sync state updates
  ref.watch(healthSyncProvider);
  ref.watch(healthSyncServiceProvider);

  final profile = ref.watch(personalizationControllerProvider).profile;
  final customStepGoal = ref.watch(customStepGoalProvider);

  final computedGoals = HealthGoalCalculator.calculateGoals(
    profile: profile,
    customStepGoal: customStepGoal,
  );

  final cache = ref.watch(healthCacheServiceProvider);
  final cached = cache.getDailyActivity(date) ?? DailyActivitySummary.empty(date: date);

  final now = DateTime.now();
  final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

  final sensorStatus = isToday ? ref.watch(sensorStatusProvider) : cached.sensorStatus;
  final healthConnectStatus = isToday ? ref.watch(healthConnectStatusProvider) : cached.healthConnectStatus;

  final summaryWithDynamicGoals = cached.copyWith(
    date: date,
    stepsGoal: computedGoals.stepsGoal,
    caloriesGoal: computedGoals.caloriesGoal,
    sensorStatus: sensorStatus,
    healthConnectStatus: healthConnectStatus,
  );

  final isHCConnected = healthConnectStatus == HealthConnectStatus.connected ||
      healthConnectStatus == HealthConnectStatus.partiallyGranted;

  if (isToday) {
    if (isHCConnected) {
      return summaryWithDynamicGoals;
    }

    final liveSteps = ref.watch(liveStepsProvider);
    return liveSteps.when(
      data: (sensorSteps) {
        final totalSteps = sensorSteps;
        final dist = double.parse((totalSteps * 0.00075).toStringAsFixed(2));
        final cal = double.parse((totalSteps * 0.04).toStringAsFixed(1));
        final activeMins = (totalSteps / 100).floor();

        return summaryWithDynamicGoals.copyWith(
          steps: totalSteps,
          distanceKm: dist,
          caloriesBurned: cal,
          activeMinutes: activeMins,
        );
      },
      loading: () => summaryWithDynamicGoals,
      error: (_, _) => summaryWithDynamicGoals,
    );
  }

  return summaryWithDynamicGoals;
});

final weeklyActivityProvider =
    Provider.family<List<DailyActivitySummary>, DateTime>((ref, startDate) {
      ref.watch(healthSyncProvider);
      ref.watch(healthSyncServiceProvider);
      final cache = ref.watch(healthCacheServiceProvider);

      final cachedList = cache.getWeeklyActivity();
      final Map<String, DailyActivitySummary> cachedMap = {};
      if (cachedList != null) {
        for (final item in cachedList) {
          final key = "${item.date.year}-${item.date.month}-${item.date.day}";
          cachedMap[key] = item;
        }
      }

      final List<DailyActivitySummary> list = [];
      for (int i = 0; i < 7; i++) {
        final dayDate = startDate.add(Duration(days: i));
        final daily = ref.watch(dailyActivityProvider(dayDate));
        final key = "${dayDate.year}-${dayDate.month}-${dayDate.day}";
        final cached = cachedMap[key];

        if (cached != null) {
          list.add(
            daily.copyWith(
              steps: max(daily.steps, cached.steps),
              caloriesBurned: max(daily.caloriesBurned, cached.caloriesBurned),
              distanceKm: max(daily.distanceKm, cached.distanceKm),
              activeMinutes: max(daily.activeMinutes, cached.activeMinutes),
            ),
          );
        } else {
          list.add(daily);
        }
      }
      return list;
    });

final healthActivityRangeProvider =
    Provider.family<List<DailyActivitySummary>, int>((ref, daysCount) {
      ref.watch(healthSyncServiceProvider);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startDate = today.subtract(Duration(days: daysCount - 1));

      return List.generate(daysCount, (i) {
        final date = startDate.add(Duration(days: i));
        return ref.watch(dailyActivityProvider(date));
      });
    });

final sleepSummaryProvider = Provider.family<SleepSummary, DateTime>((
  ref,
  date,
) {
  ref.watch(healthSyncServiceProvider);
  final cache = ref.watch(healthCacheServiceProvider);
  return cache.getSleepSummary(date) ??
      SleepSummary(
        totalSleep: Duration.zero,
        remSleep: Duration.zero,
        deepSleep: Duration.zero,
        lightSleep: Duration.zero,
        sleepScore: 0,
        date: date,
      );
});

final recoverySummaryProvider = Provider.family<RecoverySummary, DateTime>((
  ref,
  date,
) {
  return RecoverySummary(
    recoveryScore: 0,
    hrv: 0,
    restingHeartRate: 0,
    date: date,
  );
});

final hydrationSummaryProvider = Provider.family<HydrationSummary, DateTime>((
  ref,
  date,
) {
  final profile = ref.watch(personalizationControllerProvider).profile;
  final computedGoals = HealthGoalCalculator.calculateGoals(profile: profile);
  return HydrationSummary(
    waterConsumedLiters: 0.0,
    waterGoalLiters: computedGoals.hydrationGoalLiters,
    date: date,
  );
});

// ---------------------------------------------------------------------------
// Debug snapshot provider
// ---------------------------------------------------------------------------

final sensorDebugSnapshotProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.read(sensorRepositoryProvider);
  return repo.getDebugSnapshot();
});
