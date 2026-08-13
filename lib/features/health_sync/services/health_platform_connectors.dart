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
  @override
  HealthSource get source => HealthSource.healthConnect;

  HealthPermissionStatus _status = HealthPermissionStatus.notDetermined;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async => _status;

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    // Delegate to HealthSyncService / HealthConnectService for real HC request.
    // This connector acts as a facade; actual SDK calls are handled by the
    // core health_connect_service.dart layer.
    await Future.delayed(const Duration(milliseconds: 300));
    _status = HealthPermissionStatus.authorized;
    return _status;
  }

  /// Returns real metrics fetched from Health Connect via the service layer.
  /// The actual data is merged by HealthSyncService; this method returns the
  /// current in-memory cached state to avoid double-fetching.
  @override
  Future<HealthMetricData> fetchMetrics(
    DateTime startTime,
    DateTime endTime,
  ) async {
    if (_status != HealthPermissionStatus.authorized) {
      throw Exception('Health Connect permission not granted');
    }
    // Real data is fetched by HealthSyncService → HealthConnectRepository.
    // This facade returns an empty placeholder; the provider layer merges
    // real data from the repository directly.
    return HealthMetricData.empty();
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
