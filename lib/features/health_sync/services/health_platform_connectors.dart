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

class HealthConnectConnector implements HealthPlatformConnector {
  final HealthConnectService _service = HealthConnectService();
  late final HealthConnectRepository _repository = HealthConnectRepository(_service);

  @override
  HealthSource get source => HealthSource.healthConnect;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async {
    try {
      final status = await _service.getStatus();
      if (kDebugMode) {
        print('[HC_DEBUG] Health Connect status: $status');
      }
      if (status == HealthConnectStatus.connected) {
        return HealthPermissionStatus.authorized;
      }
      if (status == HealthConnectStatus.permissionRequired) {
        return HealthPermissionStatus.notDetermined;
      }
      return HealthPermissionStatus.denied;
    } catch (e) {
      if (kDebugMode) {
        print('[HC_DEBUG] Health Connect status error: $e');
      }
      return HealthPermissionStatus.notDetermined;
    }
  }

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    try {
      final granted = await _service.requestPermissions();
      if (kDebugMode) {
        print('[HC_DEBUG] Health Connect requestPermissions result: $granted');
      }
      if (granted) {
        return HealthPermissionStatus.authorized;
      }
      return HealthPermissionStatus.denied;
    } catch (e) {
      if (kDebugMode) {
        print('[HC_DEBUG] Health Connect requestPermissions exception: $e');
      }
      return HealthPermissionStatus.denied;
    }
  }

  @override
  Future<HealthMetricData> fetchMetrics(DateTime startTime, DateTime endTime) async {
    final status = await checkPermissionStatus();
    if (kDebugMode) {
      print('[HC_DEBUG] HealthConnectConnector.fetchMetrics status check: $status');
    }

    final now = DateTime.now();
    final daily = await _repository.getDailyActivity(now);
    final sleep = await _repository.getSleepSummary(now);

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
  }
}

class GoogleFitConnector implements HealthPlatformConnector {
  final HealthConnectConnector _hcConnector = HealthConnectConnector();

  @override
  HealthSource get source => HealthSource.googleFit;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async {
    final status = await _hcConnector.checkPermissionStatus();
    if (kDebugMode) {
      print('[HC_DEBUG] Google Fit status: $status');
    }
    return status;
  }

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    return await _hcConnector.requestPermissions();
  }

  @override
  Future<HealthMetricData> fetchMetrics(DateTime startTime, DateTime endTime) async {
    return await _hcConnector.fetchMetrics(startTime, endTime);
  }
}

class SamsungHealthConnector implements HealthPlatformConnector {
  final HealthConnectConnector _hcConnector = HealthConnectConnector();

  @override
  HealthSource get source => HealthSource.samsungHealth;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async {
    return await _hcConnector.checkPermissionStatus();
  }

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    return await _hcConnector.requestPermissions();
  }

  @override
  Future<HealthMetricData> fetchMetrics(DateTime startTime, DateTime endTime) async {
    return await _hcConnector.fetchMetrics(startTime, endTime);
  }
}

class AppleHealthConnector implements HealthPlatformConnector {
  final HealthConnectConnector _hcConnector = HealthConnectConnector();

  @override
  HealthSource get source => HealthSource.appleHealth;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async {
    return await _hcConnector.checkPermissionStatus();
  }

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    return await _hcConnector.requestPermissions();
  }

  @override
  Future<HealthMetricData> fetchMetrics(DateTime startTime, DateTime endTime) async {
    return await _hcConnector.fetchMetrics(startTime, endTime);
  }
}
