import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/data/health_connect_repository.dart';
import 'package:fitora/core/health/data/sensor_health_repository.dart';
import 'package:fitora/core/health/services/health_cache_service.dart';
import 'package:fitora/core/utils/app_logger.dart';

class HealthSyncService extends StateNotifier<SyncStatus> with WidgetsBindingObserver {
  final HealthConnectRepository _hcRepo;
  final SensorHealthRepository _sensorRepo;
  final HealthCacheService _cache;
  Timer? _pollingTimer;

  HealthSyncService(this._hcRepo, this._sensorRepo, this._cache) : super(SyncStatus.offline) {
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncNow();
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _pollingTimer?.cancel();
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(minutes: 15), (_) => syncNow());
  }

  Future<void> syncNow() async {
    if (state == SyncStatus.syncing) return;
    state = SyncStatus.syncing;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // 1. Fetch Health Connect
      DailyActivitySummary? hcSummary;
      try {
        hcSummary = await _hcRepo.getDailyActivity(today);
      } catch (_) {
        // Health Connect might be unavailable or permission denied
      }

      // 2. Fetch Sensor
      DailyActivitySummary? sensorSummary;
      try {
        sensorSummary = await _sensorRepo.getDailyActivity(today);
      } catch (_) {}

      // 3. Merge Data
      DailyActivitySummary mergedSummary;
      final cachedSummary = _cache.getDailyActivity(today);
      final existingSteps = cachedSummary?.steps ?? 0;

      if (hcSummary != null && sensorSummary != null) {
        final calcSteps = max(existingSteps, max(hcSummary.steps, sensorSummary.steps));
        mergedSummary = hcSummary.copyWith(
          steps: calcSteps,
          dataSource: DataSource.healthConnectAndSensor,
          lastSyncTime: now,
        );
      } else if (hcSummary != null) {
        final calcSteps = max(existingSteps, hcSummary.steps);
        mergedSummary = hcSummary.copyWith(
          steps: calcSteps,
          dataSource: DataSource.healthConnectOnly,
          lastSyncTime: now,
        );
      } else if (sensorSummary != null) {
        final calcSteps = max(existingSteps, sensorSummary.steps);
        mergedSummary = sensorSummary.copyWith(
          steps: calcSteps,
          dataSource: DataSource.sensorOnly,
          lastSyncTime: now,
        );
      } else {
        // Both failed, fallback to cache or empty
        mergedSummary = cachedSummary ?? DailyActivitySummary.empty();
      }

      // 4. Save Daily Activity to Cache
      if (mergedSummary.dataSource != DataSource.cache) {
        await _cache.saveDailyActivity(mergedSummary);
      }

      // 5. Fetch Weekly & Sleep (Assuming Health Connect takes priority for history/sleep)
      try {
        final lastWeek = today.subtract(const Duration(days: 6));
        final weekly = await _hcRepo.getWeeklyActivity(lastWeek);
        
        // Merge today's data into the weekly array using date component comparison
        final updatedWeekly = weekly.map((s) {
          if (s.date.year == today.year &&
              s.date.month == today.month &&
              s.date.day == today.day) {
            return mergedSummary;
          }
          return s;
        }).toList();
        
        await _cache.saveWeeklyActivity(updatedWeekly);

        final sleep = await _hcRepo.getSleepSummary(today);
        await _cache.saveSleepSummary(sleep);
      } catch (_) {}

      state = SyncStatus.synced;
    } catch (e, st) {
      AppLogger.error('Sync error: $e', st);
      state = SyncStatus.error;
    }
  }
}
