import 'dart:math';
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
      workouts: [
        HealthSyncWorkout(
          id: 'gf_workout_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Morning Cardio Run',
          category: 'cardio',
          durationMinutes: 32,
          caloriesBurned: 280,
          completedAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ],
      timestamp: DateTime.now(),
    );
  }
}

class HealthConnectConnector implements HealthPlatformConnector {
  @override
  HealthSource get source => HealthSource.healthConnect;

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
      throw Exception('Permission to Health Connect not granted');
    }
    await Future.delayed(const Duration(milliseconds: 300));

    final random = Random();
    return HealthMetricData(
      steps: 8100 + random.nextInt(2000),
      heartRate: 65.0 + random.nextDouble() * 12.0,
      activeCalories: 390.0 + random.nextInt(180),
      sleepHours: 6.8 + random.nextDouble() * 1.2,
      workouts: [
        HealthSyncWorkout(
          id: 'hc_workout_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Intense HIIT Session',
          category: 'gym',
          durationMinutes: 45,
          caloriesBurned: 350,
          completedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ],
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
      workouts: [
        HealthSyncWorkout(
          id: 'sh_workout_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Samsung Active Walk',
          category: 'cardio',
          durationMinutes: 25,
          caloriesBurned: 190,
          completedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ],
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
      workouts: [
        HealthSyncWorkout(
          id: 'ah_workout_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Sunset Hatha Yoga',
          category: 'wellness',
          durationMinutes: 50,
          caloriesBurned: 180,
          completedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
      timestamp: DateTime.now(),
    );
  }
}
