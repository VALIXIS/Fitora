import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:fitora/core/health/domain/health_models.dart';

class HealthConnectService {
  final Health _health = Health();

  final _dataTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.WORKOUT,
    HealthDataType.SLEEP_SESSION,
  ];

  HealthConnectService() {
    _health.configure();
  }

  Future<HealthConnectStatus> getStatus() async {
    try {
      final available = await _health.hasPermissions(_dataTypes);
      if (available == null) return HealthConnectStatus.permissionRequired;
      if (available) return HealthConnectStatus.connected;
      return HealthConnectStatus.permissionRequired;
    } catch (e) {
      debugPrint('Health Connect status error: $e');
      return HealthConnectStatus.error;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      return await _health.requestAuthorization(_dataTypes);
    } catch (e) {
      debugPrint('Health Connect permission error: $e');
      return false;
    }
  }

  Future<List<HealthDataPoint>> getHealthData(DateTime start, DateTime end) async {
    try {
      return await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: _dataTypes,
      );
    } catch (e) {
      debugPrint('Health Connect data error: $e');
      return [];
    }
  }

  Future<int?> getSteps(DateTime start, DateTime end) async {
    try {
      return await _health.getTotalStepsInInterval(start, end);
    } catch (e) {
      debugPrint('Health Connect steps error: $e');
      return null;
    }
  }
}
