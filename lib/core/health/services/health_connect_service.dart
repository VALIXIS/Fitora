import 'package:health/health.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/utils/app_logger.dart';

class HealthConnectService {
  final Health _health = Health();

  /// Data types used for STEP + ACTIVITY metrics.
  final _activityTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_DELTA,
  ];

  /// Data types used for SLEEP.
  final _sleepTypes = [
    HealthDataType.SLEEP_SESSION,
  ];

  HealthConnectService() {
    _health.configure();
  }

  // ---------------------------------------------------------------------------
  // Health Connect Availability & Permission Status
  // ---------------------------------------------------------------------------

  /// Checks whether Health Connect is installed and whether permissions have
  /// been granted. Returns a granular [HealthConnectStatus].
  Future<HealthConnectStatus> getStatus() async {
    try {
      // Check SDK availability first (Health Connect must be installed)
      final sdkStatus = await _health.getHealthConnectSdkStatus();
      if (sdkStatus != HealthConnectSdkStatus.sdkAvailable) {
        return HealthConnectStatus.notInstalled;
      }

      // Check if all activity permissions are granted
      final activityGranted = await _health.hasPermissions(_activityTypes);
      final sleepGranted = await _health.hasPermissions(_sleepTypes);

      if (activityGranted == true && sleepGranted == true) {
        return HealthConnectStatus.connected;
      }
      if (activityGranted == true || sleepGranted == true) {
        // At least one category is granted
        return HealthConnectStatus.connected;
      }
      return HealthConnectStatus.permissionRequired;
    } catch (e, st) {
      AppLogger.error('Health Connect status error: $e', st);
      return HealthConnectStatus.error;
    }
  }

  /// Requests permissions for activity and sleep independently.
  /// Returns true if at least activity permissions are granted.
  Future<bool> requestPermissions() async {
    try {
      // Request all types together; partial grants are handled at read time
      final allTypes = [..._activityTypes, ..._sleepTypes];
      return await _health.requestAuthorization(allTypes);
    } catch (e, st) {
      AppLogger.error('Health Connect permission request error: $e', st);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Data Fetching (real Health Connect reads, no mock fallbacks)
  // ---------------------------------------------------------------------------

  /// Fetches steps for the given [start]–[end] window.
  /// Returns null if the permission is unavailable or the SDK is not installed.
  Future<int?> getSteps(DateTime start, DateTime end) async {
    try {
      final sdkStatus = await _health.getHealthConnectSdkStatus();
      if (sdkStatus != HealthConnectSdkStatus.sdkAvailable) return null;

      final hasPermission = await _health.hasPermissions([HealthDataType.STEPS]);
      if (hasPermission != true) return null;

      return await _health.getTotalStepsInInterval(start, end);
    } catch (e, st) {
      AppLogger.error('Health Connect getSteps error: $e', st);
      return null;
    }
  }

  /// Fetches health data points for [types] in [start]–[end].
  /// Returns an empty list on any error or unavailability — never throws.
  Future<List<HealthDataPoint>> getHealthData(
    DateTime start,
    DateTime end, {
    List<HealthDataType>? types,
  }) async {
    try {
      final sdkStatus = await _health.getHealthConnectSdkStatus();
      if (sdkStatus != HealthConnectSdkStatus.sdkAvailable) return [];

      final queryTypes = types ?? _activityTypes;
      // Only query types where permission was actually granted to avoid crashing
      final grantedTypes = <HealthDataType>[];
      for (final t in queryTypes) {
        final ok = await _health.hasPermissions([t]);
        if (ok == true) grantedTypes.add(t);
      }
      if (grantedTypes.isEmpty) return [];

      return await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: grantedTypes,
      );
    } catch (e, st) {
      AppLogger.error('Health Connect getHealthData error: $e', st);
      return [];
    }
  }

  /// Fetches sleep data points for the given [start]–[end] window.
  Future<List<HealthDataPoint>> getSleepData(DateTime start, DateTime end) async {
    return getHealthData(start, end, types: _sleepTypes);
  }
}
