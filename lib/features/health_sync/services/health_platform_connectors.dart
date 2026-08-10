import 'dart:math';
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

class GoogleFitConnector implements HealthPlatformConnector {
  @override
  HealthSource get source => HealthSource.googleFit;

  HealthPermissionStatus _status = HealthPermissionStatus.notDetermined;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async {
    return _status;
  }

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate OS popup delay
    _status = HealthPermissionStatus.authorized;
    return _status;
  }

  @override
  Future<HealthMetricData> fetchMetrics(DateTime startTime, DateTime endTime) async {
    if (_status != HealthPermissionStatus.authorized) {
      throw Exception('Permission to Google Fit not granted');
    }
    await Future.delayed(const Duration(milliseconds: 400)); // Simulate query delay

    final random = Random();
    return HealthMetricData(
      steps: 7200 + random.nextInt(2500),
      heartRate: 68.0 + random.nextDouble() * 15.0,
      activeCalories: 340.0 + random.nextInt(150),
      sleepHours: 7.2 + random.nextDouble() * 1.5,
      timestamp: DateTime.now(),
    );
  }
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
      if (status == HealthConnectStatus.connected) {
        return HealthPermissionStatus.authorized;
      }
      return HealthPermissionStatus.denied;
    } catch (_) {
      return HealthPermissionStatus.denied;
    }
  }

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    try {
      final granted = await _service.requestPermissions();
      if (granted) {
        return HealthPermissionStatus.authorized;
      }
      return HealthPermissionStatus.denied;
    } catch (_) {
      return HealthPermissionStatus.denied;
    }
  }

  @override
  Future<HealthMetricData> fetchMetrics(DateTime startTime, DateTime endTime) async {
    final status = await checkPermissionStatus();
    if (status != HealthPermissionStatus.authorized) {
      final requested = await requestPermissions();
      if (requested != HealthPermissionStatus.authorized) {
        return HealthMetricData.empty();
      }
    }

    final now = DateTime.now();
    final daily = await _repository.getDailyActivity(now);
    final sleep = await _repository.getSleepSummary(now);

    return HealthMetricData(
      steps: daily.steps,
      heartRate: 0.0,
      activeCalories: daily.caloriesBurned,
      sleepHours: sleep.totalSleep.inMinutes / 60.0,
      timestamp: DateTime.now(),
    );
  }
}

class SamsungHealthConnector implements HealthPlatformConnector {
  @override
  HealthSource get source => HealthSource.samsungHealth;

  HealthPermissionStatus _status = HealthPermissionStatus.notDetermined;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async {
    return _status;
  }

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _status = HealthPermissionStatus.authorized;
    return _status;
  }

  @override
  Future<HealthMetricData> fetchMetrics(DateTime startTime, DateTime endTime) async {
    if (_status != HealthPermissionStatus.authorized) {
      throw Exception('Permission to Samsung Health not granted');
    }
    await Future.delayed(const Duration(milliseconds: 300));

    final random = Random();
    return HealthMetricData(
      steps: 6400 + random.nextInt(2100),
      heartRate: 67.0 + random.nextDouble() * 14.0,
      activeCalories: 280.0 + random.nextInt(120),
      sleepHours: 7.0 + random.nextDouble() * 1.0,
      timestamp: DateTime.now(),
    );
  }
}

class AppleHealthConnector implements HealthPlatformConnector {
  @override
  HealthSource get source => HealthSource.appleHealth;

  HealthPermissionStatus _status = HealthPermissionStatus.notDetermined;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async {
    return _status;
  }

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    await Future.delayed(const Duration(milliseconds: 700));
    _status = HealthPermissionStatus.authorized;
    return _status;
  }

  @override
  Future<HealthMetricData> fetchMetrics(DateTime startTime, DateTime endTime) async {
    if (_status != HealthPermissionStatus.authorized) {
      throw Exception('Permission to Apple Health not granted');
    }
    await Future.delayed(const Duration(milliseconds: 500));

    final random = Random();
    return HealthMetricData(
      steps: 9400 + random.nextInt(1500),
      heartRate: 62.0 + random.nextDouble() * 10.0,
      activeCalories: 420.0 + random.nextInt(200),
      sleepHours: 7.8 + random.nextDouble() * 0.8,
      timestamp: DateTime.now(),
    );
  }
}
