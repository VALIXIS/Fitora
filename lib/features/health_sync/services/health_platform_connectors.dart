import 'package:flutter/foundation.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/services/health_connect_service.dart';
import 'package:fitora/core/health/data/health_connect_repository.dart';
import '../domain/health_sync_models.dart';

abstract class HealthPlatformConnector {
  HealthSource get source;
  Future<HealthPermissionStatus> checkPermissionStatus();
  Future<HealthPermissionStatus> requestPermissions();
  Future<HealthMetricData> fetchMetrics(DateTime startTime, DateTime endTime);
}

// Singleton HealthConnectService so configure() is only called once
final sharedHcService = HealthConnectService();
final sharedHcRepo = HealthConnectRepository(sharedHcService);

class HealthConnectConnector implements HealthPlatformConnector {
  @override
  HealthSource get source => HealthSource.healthConnect;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async {
    try {
      final status = await sharedHcService.getStatus();
      if (kDebugMode) print('[HC_DEBUG] HealthConnectConnector status: $status');
      if (status == HealthConnectStatus.connected) return HealthPermissionStatus.authorized;
      if (status == HealthConnectStatus.permissionRequired) return HealthPermissionStatus.notDetermined;
      return HealthPermissionStatus.denied;
    } catch (e) {
      if (kDebugMode) print('[HC_DEBUG] HealthConnectConnector status error: $e');
      return HealthPermissionStatus.notDetermined;
    }
  }

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    try {
      final granted = await sharedHcService.requestPermissions();
      if (kDebugMode) print('[HC_DEBUG] HealthConnectConnector requestPermissions: $granted');
      return granted ? HealthPermissionStatus.authorized : HealthPermissionStatus.denied;
    } catch (e) {
      if (kDebugMode) print('[HC_DEBUG] HealthConnectConnector requestPermissions error: $e');
      return HealthPermissionStatus.denied;
    }
  }

  @override
  Future<HealthMetricData> fetchMetrics(DateTime startTime, DateTime endTime) async {
    // DIRECT READ — do not gate on permission check here.
    // Permissions must already be granted via the UI button.
    // If not granted, the read will throw and we'll see the real error.
    try {
      final now = DateTime.now();
      if (kDebugMode) print('[HC_DEBUG] Connector.fetchMetrics calling repo');
      final daily = await sharedHcRepo.getDailyActivity(now);
      final sleep = await sharedHcRepo.getSleepSummary(now);

      final result = HealthMetricData(
        steps: daily.steps,
        heartRate: 0.0,
        activeCalories: daily.caloriesBurned,
        sleepHours: sleep.totalSleep.inMinutes / 60.0,
        timestamp: now,
      );
      if (kDebugMode) {
        print('[HC_DEBUG] Connector result: steps=${result.steps}, cal=${result.activeCalories}, sleep=${result.sleepHours}');
      }
      return result;
    } catch (e) {
      if (kDebugMode) print('[HC_DEBUG] Connector.fetchMetrics EXCEPTION: $e');
      rethrow;
    }
  }
}

/// On Android, Google Fit is NOT a separate native source (deprecated in health pkg v11+).
/// Google Fit data flows through Health Connect. This connector delegates to HC.
class GoogleFitConnector implements HealthPlatformConnector {
  final _hc = HealthConnectConnector();

  @override
  HealthSource get source => HealthSource.googleFit;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() => _hc.checkPermissionStatus();

  @override
  Future<HealthPermissionStatus> requestPermissions() => _hc.requestPermissions();

  @override
  Future<HealthMetricData> fetchMetrics(DateTime startTime, DateTime endTime) =>
      _hc.fetchMetrics(startTime, endTime);
}

/// Samsung Health on Android also flows through Health Connect.
class SamsungHealthConnector implements HealthPlatformConnector {
  final _hc = HealthConnectConnector();

  @override
  HealthSource get source => HealthSource.samsungHealth;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() => _hc.checkPermissionStatus();

  @override
  Future<HealthPermissionStatus> requestPermissions() => _hc.requestPermissions();

  @override
  Future<HealthMetricData> fetchMetrics(DateTime startTime, DateTime endTime) =>
      _hc.fetchMetrics(startTime, endTime);
}

class AppleHealthConnector implements HealthPlatformConnector {
  final _hc = HealthConnectConnector();

  @override
  HealthSource get source => HealthSource.appleHealth;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() => _hc.checkPermissionStatus();

  @override
  Future<HealthPermissionStatus> requestPermissions() => _hc.requestPermissions();

  @override
  Future<HealthMetricData> fetchMetrics(DateTime startTime, DateTime endTime) =>
      _hc.fetchMetrics(startTime, endTime);
}
