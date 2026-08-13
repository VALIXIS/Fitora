import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/utils/app_logger.dart';

class HealthConnectService {
  final Health _health = Health();
  final SharedPreferences _prefs;

  static const _kHealthPermissionsGrantedBeforeKey =
      'health_permissions_granted_before';

  /// Data types used for STEP + ACTIVITY metrics.
  final _activityTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_DELTA,
  ];

  /// Data types used for SLEEP.
  final _sleepTypes = [HealthDataType.SLEEP_SESSION];

  HealthConnectService(this._prefs) {
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
        return HealthConnectStatus.unavailable;
      }

      final allTypes = [..._activityTypes, ..._sleepTypes];
      final grantedTypes = <HealthDataType>[];
      for (final type in allTypes) {
        final granted = await _health.hasPermissions([type]);
        if (granted == true) {
          grantedTypes.add(type);
        }
      }

      final previouslyGranted =
          _prefs.getBool(_kHealthPermissionsGrantedBeforeKey) ?? false;

      if (grantedTypes.length == allTypes.length) {
        if (!previouslyGranted) {
          await _prefs.setBool(_kHealthPermissionsGrantedBeforeKey, true);
        }
        return HealthConnectStatus.connected;
      }

      if (grantedTypes.isNotEmpty) {
        if (!previouslyGranted) {
          await _prefs.setBool(_kHealthPermissionsGrantedBeforeKey, true);
        }
        return HealthConnectStatus.partiallyGranted;
      }

      // No permissions are granted.
      if (previouslyGranted) {
        return HealthConnectStatus.revoked;
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
      final success = await _health.requestAuthorization(allTypes);
      if (success) {
        final allTypes = [..._activityTypes, ..._sleepTypes];
        final grantedTypes = <HealthDataType>[];
        for (final type in allTypes) {
          final granted = await _health.hasPermissions([type]);
          if (granted == true) {
            grantedTypes.add(type);
          }
        }
        if (grantedTypes.isNotEmpty) {
          await _prefs.setBool(_kHealthPermissionsGrantedBeforeKey, true);
        }
      }
      return success;
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

      final hasPermission = await _health.hasPermissions([
        HealthDataType.STEPS,
      ]);
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
  Future<List<HealthDataPoint>> getSleepData(
    DateTime start,
    DateTime end,
  ) async {
    return getHealthData(start, end, types: _sleepTypes);
  }

  /// Runs a direct diagnostic against Health Connect, returning a map
  /// of raw SDK status, permissions, and step record details.
  Future<Map<String, dynamic>> runDirectDiagnostic() async {
    final Map<String, dynamic> diag = {};
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    diag['now'] = now.toIso8601String();
    diag['start'] = start.toIso8601String();
    try {
      final sdkStatus = await _health.getHealthConnectSdkStatus();
      diag['sdkStatus'] = sdkStatus?.name;
      final hasPerm = await _health.hasPermissions(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
      diag['hasPermissionsSteps'] = hasPerm;
      final totalSteps = await _health.getTotalStepsInInterval(start, now);
      diag['totalSteps'] = totalSteps;
      final rawRecords = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.STEPS],
      );
      diag['rawRecordCount'] = rawRecords.length;
      final recList = <Map<String, dynamic>>[];
      for (final r in rawRecords) {
        final val = (r.value as NumericHealthValue).numericValue;
        recList.add({
          'val': val,
          'sourceName': r.sourceName,
          'dateFrom': r.dateFrom.toIso8601String(),
          'dateTo': r.dateTo.toIso8601String(),
        });
      }
      diag['records'] = recList;
    } catch (e, st) {
      AppLogger.error('runDirectDiagnostic error: $e', st);
      diag['exception'] = e.toString();
    }
    return diag;
  }
}
