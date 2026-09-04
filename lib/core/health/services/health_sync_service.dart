import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/data/health_connect_repository.dart';
import 'package:fitora/core/health/data/sensor_health_repository.dart';
import 'package:fitora/core/health/services/health_cache_service.dart';
import 'package:fitora/core/utils/app_logger.dart';

/// Maximum number of exponential backoff retry attempts before giving up.
const _kMaxRetries = 4;

class HealthSyncService extends StateNotifier<SyncStatus>
    with WidgetsBindingObserver {
  final HealthConnectRepository _hcRepo;
  final SensorHealthRepository _sensorRepo;
  final HealthCacheService _cache;

  Timer? _pollingTimer;
  int _retryCount = 0;
  Timer? _retryTimer;

  HealthSyncService(this._hcRepo, this._sensorRepo, this._cache)
    : super(SyncStatus.offline) {
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
    // Trigger initial sync on startup
    Future.microtask(() => syncNow());
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Trigger immediate sync and restart polling on foreground
      _retryCount = 0;
      _retryTimer?.cancel();
      syncNow();
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      final bgEnabled = _cache.getBgSyncEnabled();
      if (!bgEnabled) {
        // Cancel polling to avoid unnecessary wakeups while app is in background and background sync is disabled
        _pollingTimer?.cancel();
      } else {
        // Trigger a sync immediately when app moves to background
        syncNow();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Polling (background sync every 15 minutes)
  // ---------------------------------------------------------------------------

  void _startPolling() {
    _pollingTimer?.cancel();
    final intervalMinutes = max(15, _cache.getBgSyncInterval());
    _pollingTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => _backgroundSyncNow(),
    );
  }

  /// Background sync — protects against zero-data overwrites.
  Future<void> _backgroundSyncNow() async {
    await syncNow(isBackground: true);
  }

  // ---------------------------------------------------------------------------
  // Sync (Manual + Background)
  // ---------------------------------------------------------------------------

  /// Syncs health data from Health Connect and the physical sensor.
  ///
  /// When [isBackground] is true, merging logic **never** overwrites valid
  /// cached non-zero data with zero values — protecting against permissions
  /// being revoked or Health Connect being temporarily unavailable.
  Future<void> syncNow({bool isBackground = false}) async {
    if (!mounted) return;
    if (state == SyncStatus.syncing) return;
    state = SyncStatus.syncing;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 1. Fetch Health Connect (real data; null/empty on permission denied)
      DailyActivitySummary? hcSummary;
      try {
        hcSummary = await _hcRepo.getDailyActivity(today);
      } catch (e) {
        AppLogger.error('HC daily fetch failed: $e');
        // Leave hcSummary null — handled in merge below
      }

      // 2. Fetch Sensor
      DailyActivitySummary? sensorSummary;
      try {
        sensorSummary = await _sensorRepo.getDailyActivity(today);
      } catch (e) {
        AppLogger.error('Sensor daily fetch failed: $e');
      }

      // 3. Load existing cached data — used for zero-data protection
      final cachedSummary = _cache.getDailyActivity(today);
      final existingSteps = cachedSummary?.steps ?? 0;
      final existingCalories = cachedSummary?.caloriesBurned ?? 0.0;
      final existingDistance = cachedSummary?.distanceKm ?? 0.0;
      final existingActiveMinutes = cachedSummary?.activeMinutes ?? 0;

      // 4. Merge: prevent zero overwrites but allow non-zero data updates/corrections
      DailyActivitySummary mergedSummary;

      final hcActive =
          hcSummary != null &&
          (hcSummary.healthConnectStatus == HealthConnectStatus.connected ||
              hcSummary.healthConnectStatus ==
                  HealthConnectStatus.partiallyGranted);

      int mergedSteps;
      double mergedCalories;
      double mergedDistance;
      int mergedActiveMinutes;

      if (hcActive && sensorSummary != null) {
        final incomingSteps = max(hcSummary.steps, sensorSummary.steps);
        final incomingCalories = max(hcSummary.caloriesBurned, sensorSummary.caloriesBurned);
        final incomingDistance = max(hcSummary.distanceKm, sensorSummary.distanceKm);
        final incomingActiveMinutes = max(hcSummary.activeMinutes, sensorSummary.activeMinutes);

        mergedSteps = incomingSteps == 0 ? existingSteps : incomingSteps;
        mergedCalories = incomingCalories == 0.0 ? existingCalories : incomingCalories;
        mergedDistance = incomingDistance == 0.0 ? existingDistance : incomingDistance;
        mergedActiveMinutes = incomingActiveMinutes == 0 ? existingActiveMinutes : incomingActiveMinutes;

        mergedSummary = hcSummary.copyWith(
          steps: mergedSteps,
          caloriesBurned: mergedCalories,
          distanceKm: mergedDistance,
          activeMinutes: mergedActiveMinutes,
          dataSource: DataSource.healthConnectAndSensor,
          lastSyncTime: now,
        );
      } else if (hcActive) {
        mergedSteps = hcSummary.steps == 0 ? existingSteps : hcSummary.steps;
        mergedCalories = hcSummary.caloriesBurned == 0.0 ? existingCalories : hcSummary.caloriesBurned;
        mergedDistance = hcSummary.distanceKm == 0.0 ? existingDistance : hcSummary.distanceKm;
        mergedActiveMinutes = hcSummary.activeMinutes == 0 ? existingActiveMinutes : hcSummary.activeMinutes;

        mergedSummary = hcSummary.copyWith(
          steps: mergedSteps,
          caloriesBurned: mergedCalories,
          distanceKm: mergedDistance,
          activeMinutes: mergedActiveMinutes,
          dataSource: DataSource.healthConnectOnly,
          lastSyncTime: now,
        );
      } else if (sensorSummary != null) {
        mergedSteps = sensorSummary.steps == 0 ? existingSteps : sensorSummary.steps;
        mergedCalories = sensorSummary.caloriesBurned == 0.0 ? existingCalories : sensorSummary.caloriesBurned;
        mergedDistance = sensorSummary.distanceKm == 0.0 ? existingDistance : sensorSummary.distanceKm;
        mergedActiveMinutes = sensorSummary.activeMinutes == 0 ? existingActiveMinutes : sensorSummary.activeMinutes;

        final hcStatus =
            hcSummary?.healthConnectStatus ?? HealthConnectStatus.unknown;
        mergedSummary = sensorSummary.copyWith(
          steps: mergedSteps,
          caloriesBurned: mergedCalories,
          distanceKm: mergedDistance,
          activeMinutes: mergedActiveMinutes,
          healthConnectStatus: hcStatus,
          dataSource: DataSource.sensorOnly,
          lastSyncTime: now,
        );
      } else {
        // Both failed or unavailable — keep existing cache; do NOT overwrite with zeroes
        final hcStatus =
            hcSummary?.healthConnectStatus ?? HealthConnectStatus.unknown;
        mergedSummary = (cachedSummary ?? DailyActivitySummary.empty())
            .copyWith(healthConnectStatus: hcStatus, lastSyncTime: now);
        state = SyncStatus.error;
        _scheduleRetry();
        return;
      }

      // 5. Persist daily activity
      await _cache.saveDailyActivity(mergedSummary);

      // 6. Weekly update — only if HC data is available
      if (hcActive) {
        try {
          final lastWeek = today.subtract(const Duration(days: 6));
          final weekly = await _hcRepo.getWeeklyActivity(lastWeek);

          // Replace today's entry using date-component comparison
          final updatedWeekly = weekly.map((s) {
            if (s.date.year == today.year &&
                s.date.month == today.month &&
                s.date.day == today.day) {
              return mergedSummary;
            }
            return s;
          }).toList();

          await _cache.saveWeeklyActivity(updatedWeekly);
        } catch (e) {
          AppLogger.error('Weekly activity update failed: $e');
        }
      }

      // 7. Sleep — only if HC data is available; never overwrite valid sleep cache
      if (hcActive) {
        try {
          final sleep = await _hcRepo.getSleepSummary(today);
          // Only overwrite if new sleep score is non-zero or cache has no sleep
          final cachedSleep = _cache.getSleepSummary(today);
          if (sleep.totalSleep.inMinutes > 0 ||
              cachedSleep == null ||
              cachedSleep.totalSleep.inMinutes == 0) {
            await _cache.saveSleepSummary(sleep);
          }
        } catch (e) {
          AppLogger.error('Sleep update failed: $e');
        }
      }

      _retryCount = 0; // Reset retry counter on success
      if (mounted) {
        state = SyncStatus.synced;
      }
    } catch (e, st) {
      AppLogger.error('Sync error: $e', st);
      if (mounted) {
        state = SyncStatus.error;
        _scheduleRetry();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Exponential Backoff Retry
  // ---------------------------------------------------------------------------

  /// Schedules a retry with exponential backoff capped at [_kMaxRetries].
  void _scheduleRetry() {
    if (_retryCount >= _kMaxRetries) {
      AppLogger.error(
        'Health sync: max retries reached ($_kMaxRetries). Giving up.',
      );
      return;
    }
    _retryTimer?.cancel();
    final delaySeconds = (pow(2, _retryCount) * 30)
        .round(); // 30s, 60s, 120s, 240s
    _retryCount++;
    AppLogger.error('Health sync: retry $_retryCount in ${delaySeconds}s');
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (state != SyncStatus.syncing) {
        syncNow();
      }
    });
  }
}
