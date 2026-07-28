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

// ---------------------------------------------------------------------------
// Core Services
// ---------------------------------------------------------------------------

final healthCacheServiceProvider = Provider<HealthCacheService>((ref) {
  return HealthCacheService(AppPreferences.prefs);
});

final healthConnectServiceProvider = Provider<HealthConnectService>((ref) {
  return HealthConnectService();
});

final healthConnectRepositoryProvider = Provider<HealthConnectRepository>((ref) {
  return HealthConnectRepository(ref.watch(healthConnectServiceProvider));
});

final healthSyncServiceProvider = StateNotifierProvider<HealthSyncService, SyncStatus>((ref) {
  return HealthSyncService(
    ref.watch(healthConnectRepositoryProvider),
    ref.watch(sensorHealthRepositoryProvider),
    ref.watch(healthCacheServiceProvider),
  );
});

// ---------------------------------------------------------------------------
// Sensor permission status — drives gating of live data
// ---------------------------------------------------------------------------

final sensorStatusProvider = StateNotifierProvider<SensorStatusNotifier, SensorStatus>(
  (ref) => SensorStatusNotifier(ref),
);

class SensorStatusNotifier extends StateNotifier<SensorStatus> {
  final Ref _ref;

  SensorStatusNotifier(this._ref) : super(SensorStatus.unknown) {
    _checkPermission();
  }

  Future<void> _checkPermission() async {
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

final healthConnectStatusProvider = StateNotifierProvider<HealthConnectStatusNotifier, HealthConnectStatus>((ref) {
  return HealthConnectStatusNotifier(ref.read(healthConnectServiceProvider));
});

class HealthConnectStatusNotifier extends StateNotifier<HealthConnectStatus> {
  final HealthConnectService _service;
  
  HealthConnectStatusNotifier(this._service) : super(HealthConnectStatus.unknown) {
    checkStatus();
  }
  
  Future<void> checkStatus() async {
    state = await _service.getStatus();
  }
  
  Future<void> requestPermissions() async {
    state = HealthConnectStatus.syncing;
    final granted = await _service.requestPermissions();
    state = granted ? HealthConnectStatus.connected : HealthConnectStatus.permissionRequired;
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

final dailyActivityProvider = Provider.family<DailyActivitySummary, DateTime>((ref, date) {
  // Rebuild UI when background sync completes
  ref.watch(healthSyncServiceProvider);
  
  final cache = ref.watch(healthCacheServiceProvider);
  final cached = cache.getDailyActivity(date) ?? DailyActivitySummary.empty();

  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    final liveSteps = ref.watch(liveStepsProvider);
    return liveSteps.when(
      data: (sensorSteps) {
        return cached.copyWith(
          steps: max(cached.steps, sensorSteps),
        );
      },
      loading: () => cached,
      error: (_, _) => cached,
    );
  }
  
  return cached;
});

final weeklyActivityProvider = Provider.family<List<DailyActivitySummary>, DateTime>((ref, startDate) {
  ref.watch(healthSyncServiceProvider);
  final cache = ref.watch(healthCacheServiceProvider);
  return cache.getWeeklyActivity() ?? List.generate(7, (i) => DailyActivitySummary.empty(date: startDate.add(Duration(days: i))));
});

final sleepSummaryProvider = Provider.family<SleepSummary, DateTime>((ref, date) {
  ref.watch(healthSyncServiceProvider);
  final cache = ref.watch(healthCacheServiceProvider);
  return cache.getSleepSummary(date) ?? SleepSummary(
    totalSleep: Duration.zero, remSleep: Duration.zero, deepSleep: Duration.zero, lightSleep: Duration.zero, sleepScore: 0, date: date,
  );
});

final recoverySummaryProvider = Provider.family<RecoverySummary, DateTime>((ref, date) {
  return RecoverySummary(recoveryScore: 0, hrv: 0, restingHeartRate: 0, date: date);
});

final hydrationSummaryProvider = Provider.family<HydrationSummary, DateTime>((ref, date) {
  return HydrationSummary(waterConsumedLiters: 0.0, waterGoalLiters: 2.5, date: date);
});

// ---------------------------------------------------------------------------
// Debug snapshot provider
// ---------------------------------------------------------------------------

final sensorDebugSnapshotProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.read(sensorRepositoryProvider);
  return repo.getDebugSnapshot();
});
