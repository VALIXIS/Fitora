import 'package:flutter/widgets.dart';
import 'package:health/health.dart';
import 'package:workmanager/workmanager.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/services/health_cache_service.dart';
import 'package:fitora/core/health/services/health_connect_service.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/core/utils/app_logger.dart';
import 'package:fitora/features/health_sync/services/health_sync_service.dart' as feature_sync;

/// Unique task identifier for periodic background health synchronization.
const String kFitoraBackgroundSyncTask = 'com.valixis.fitora.background_health_sync';

/// Unique tag for WorkManager task identification.
const String kFitoraBackgroundSyncTag = 'fitora_health_sync_tag';

/// Top-level callback entry point required by package:workmanager.
/// Executed in an isolated background thread by Android WorkManager / iOS BGTaskScheduler.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    return await executeBackgroundHealthSyncTask(taskName: taskName);
  });
}

/// Standalone, testable function for executing background health synchronization.
Future<bool> executeBackgroundHealthSyncTask({String? taskName}) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await AppPreferences.initialize();

    final prefs = AppPreferences.prefs;
    final hcService = HealthConnectService(prefs);
    final cacheService = HealthCacheService(prefs);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final status = await hcService.getStatus();
    if (status == HealthConnectStatus.connected ||
        status == HealthConnectStatus.partiallyGranted) {
      final steps = await hcService.getSteps(today, now);
      final healthData = await hcService.getHealthData(
        today,
        now,
        types: [
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.DISTANCE_DELTA,
        ],
      );

      final existingSummary = cacheService.getDailyActivity(today);
      final existingSteps = existingSummary?.steps ?? 0;
      final existingCalories = existingSummary?.caloriesBurned ?? 0.0;
      final existingDistance = existingSummary?.distanceKm ?? 0.0;

      int fetchedSteps = steps ?? 0;
      double fetchedCalories = 0.0;
      double fetchedDistance = 0.0;

      for (final point in healthData) {
        if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
          final val = (point.value as NumericHealthValue).numericValue.toDouble();
          fetchedCalories += val;
        } else if (point.type == HealthDataType.DISTANCE_DELTA) {
          final val = (point.value as NumericHealthValue).numericValue.toDouble();
          fetchedDistance += val / 1000.0; // Convert meters to km
        }
      }

      final updatedSteps = fetchedSteps > 0 ? fetchedSteps : existingSteps;
      final updatedCalories = fetchedCalories > 0.0 ? fetchedCalories : existingCalories;
      final updatedDistance = fetchedDistance > 0.0 ? fetchedDistance : existingDistance;

      final summary = (existingSummary ?? DailyActivitySummary.empty()).copyWith(
        date: today,
        steps: updatedSteps,
        caloriesBurned: updatedCalories,
        distanceKm: updatedDistance,
        healthConnectStatus: status,
        dataSource: DataSource.healthConnectAndSensor,
        lastSyncTime: now,
      );

      // Save to local cache so dashboard step rings are instantaneously updated on open
      await cacheService.saveDailyActivity(summary);

      // Silently update feature-level cache as well
      final featureSyncService = feature_sync.HealthSyncService(prefs);
      final cachedMetrics = featureSyncService.loadCachedData();
      await featureSyncService.saveCachedData(
        cachedMetrics.copyWith(
          steps: updatedSteps,
          activeCalories: updatedCalories,
          timestamp: now,
        ),
      );

      AppLogger.info(
        'Background WorkManager sync completed: steps=$updatedSteps, calories=$updatedCalories',
      );
    }
    return true;
  } catch (e, st) {
    AppLogger.error('Background WorkManager health sync error: $e', st);
    return true; // Return true so WorkManager handles completion cleanly
  }
}

/// Manager class for initializing WorkManager and scheduling 1-hour periodic health sync.
class BackgroundSyncManager {
  static bool _isInitialized = false;

  /// Initializes WorkManager and schedules 1-hour periodic health sync.
  static Future<void> initialize({bool isTesting = false}) async {
    if (_isInitialized && !isTesting) return;
    try {
      if (!isTesting) {
        await Workmanager().initialize(
          callbackDispatcher,
        );
        await schedulePeriodicSync();
      }
      _isInitialized = true;
      AppLogger.info('BackgroundSyncManager initialized successfully');
    } catch (e, st) {
      AppLogger.error('BackgroundSyncManager initialization error: $e', st);
    }
  }

  /// Schedules periodic 1-hour background sync task using package:workmanager.
  static Future<void> schedulePeriodicSync() async {
    try {
      await Workmanager().registerPeriodicTask(
        'fitora_periodic_health_sync',
        kFitoraBackgroundSyncTask,
        frequency: const Duration(hours: 1),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
        ),
        tag: kFitoraBackgroundSyncTag,
      );
      AppLogger.info('Scheduled periodic background health sync task (every 1h)');
    } catch (e, st) {
      AppLogger.error('Failed to schedule periodic health sync task: $e', st);
    }
  }

  /// Cancels background sync task if needed.
  static Future<void> cancelSync() async {
    try {
      await Workmanager().cancelByTag(kFitoraBackgroundSyncTag);
      _isInitialized = false;
    } catch (e, st) {
      AppLogger.error('Failed to cancel background sync task: $e', st);
    }
  }
}
