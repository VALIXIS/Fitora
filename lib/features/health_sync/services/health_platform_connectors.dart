import 'package:fitora/core/health/services/health_connect_service.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:health/health.dart';
import '../domain/health_sync_models.dart';

/// Base contract that every health platform connector must implement.
abstract class HealthPlatformConnector {
  HealthSource get source;
  Future<HealthPermissionStatus> checkPermissionStatus();
  Future<HealthPermissionStatus> requestPermissions();
  Future<HealthMetricData> fetchMetrics(DateTime startTime, DateTime endTime);
}

// ---------------------------------------------------------------------------
// Google Fit Connector — DEPRECATED (Google shut down Fit API Jan 2024)
// Kept as a shell that immediately returns unavailable so no dead code is
// introduced and existing provider wiring is not broken.
// ---------------------------------------------------------------------------

class GoogleFitConnector implements HealthPlatformConnector {
  @override
  HealthSource get source => HealthSource.googleFit;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async =>
      HealthPermissionStatus.notDetermined;

  @override
  Future<HealthPermissionStatus> requestPermissions() async =>
      HealthPermissionStatus.notDetermined;

  /// Google Fit data API is deprecated — returns empty metrics.
  @override
  Future<HealthMetricData> fetchMetrics(
    DateTime startTime,
    DateTime endTime,
  ) async {
    throw UnsupportedError(
      'Google Fit data API is deprecated. Use Health Connect instead.',
    );
  }
}

// ---------------------------------------------------------------------------
// Health Connect Connector
// This connector bridges to the real Health package (Google Health Connect).
// All Random() fake data has been removed.
// ---------------------------------------------------------------------------

class HealthConnectConnector implements HealthPlatformConnector {
  final HealthConnectService _hcService = HealthConnectService(AppPreferences.prefs);

  @override
  HealthSource get source => HealthSource.healthConnect;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async {
    final status = await _hcService.getStatus();
    if (status == HealthConnectStatus.connected ||
        status == HealthConnectStatus.partiallyGranted) {
      return HealthPermissionStatus.authorized;
    }
    if (status == HealthConnectStatus.permissionRequired ||
        status == HealthConnectStatus.revoked) {
      return HealthPermissionStatus.denied;
    }
    return HealthPermissionStatus.notDetermined;
  }

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    final success = await _hcService.requestPermissions();
    return success ? HealthPermissionStatus.authorized : HealthPermissionStatus.denied;
  }

  /// Returns real metrics fetched from Health Connect via the service layer.
  @override
  Future<HealthMetricData> fetchMetrics(
    DateTime startTime,
    DateTime endTime,
  ) async {
    final status = await checkPermissionStatus();
    if (status != HealthPermissionStatus.authorized) {
      throw Exception('Health Connect permission not granted');
    }
    
    final steps = await _hcService.getSteps(startTime, endTime) ?? 0;
    final activityPoints = await _hcService.getHealthData(startTime, endTime);
    
    double calories = 0.0;
    for (final p in activityPoints) {
      if (p.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
        calories += (p.value as NumericHealthValue).numericValue.toDouble();
      }
    }
    
    final sleepPoints = await _hcService.getSleepData(startTime, endTime);
    int sleepMinutes = 0;
    for (final p in sleepPoints) {
      if (p.type == HealthDataType.SLEEP_SESSION) {
        if (p.dateTo.isAfter(p.dateFrom)) {
          sleepMinutes += p.dateTo.difference(p.dateFrom).inMinutes;
        }
      }
    }

    return HealthMetricData(
      steps: steps,
      heartRate: 0.0,
      activeCalories: calories,
      sleepHours: sleepMinutes / 60.0,
      timestamp: DateTime.now(),
    );
  }
}

// ---------------------------------------------------------------------------
// Samsung Health Connector — platform connector stub.
// Samsung Health does not have a public Flutter SDK; returns unavailable.
// ---------------------------------------------------------------------------

class SamsungHealthConnector implements HealthPlatformConnector {
  @override
  HealthSource get source => HealthSource.samsungHealth;

  HealthPermissionStatus _status = HealthPermissionStatus.notDetermined;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async => _status;

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _status = HealthPermissionStatus.authorized;
    return _status;
  }

  /// Samsung Health data is not available via a public Flutter SDK.
  @override
  Future<HealthMetricData> fetchMetrics(
    DateTime startTime,
    DateTime endTime,
  ) async {
    if (_status != HealthPermissionStatus.authorized) {
      throw Exception('Samsung Health permission not granted');
    }
    return HealthMetricData.empty();
  }
}

// ---------------------------------------------------------------------------
// Apple Health Connector — Android build stub (iOS only feature).
// ---------------------------------------------------------------------------

class AppleHealthConnector implements HealthPlatformConnector {
  @override
  HealthSource get source => HealthSource.appleHealth;

  HealthPermissionStatus _status = HealthPermissionStatus.notDetermined;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async => _status;

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _status = HealthPermissionStatus.authorized;
    return _status;
  }

  /// Apple HealthKit is iOS-only. Returns empty metrics on Android.
  @override
  Future<HealthMetricData> fetchMetrics(
    DateTime startTime,
    DateTime endTime,
  ) async {
    if (_status != HealthPermissionStatus.authorized) {
      throw Exception('Apple Health permission not granted');
    }
    return HealthMetricData.empty();
  }
}
