import 'package:health/health.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/utils/app_logger.dart';

class HealthConnectService {
  final Health _health = Health();

  final _dataTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.SLEEP_SESSION,
  ];

  HealthConnectService() {
    _health.configure();
  }

  List<HealthDataAccess> get _permissions =>
      _dataTypes.map((_) => HealthDataAccess.READ).toList();

  Future<HealthConnectStatus> getStatus() async {
    try {
      final sdkStatus = await _health.getHealthConnectSdkStatus();
      if (sdkStatus == HealthConnectSdkStatus.sdkUnavailable) {
        return HealthConnectStatus.notInstalled;
      }

      final stepsPerm = await _health.hasPermissions(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );

      if (stepsPerm == true) {
        return HealthConnectStatus.connected;
      }

      return HealthConnectStatus.permissionRequired;
    } catch (e, st) {
      AppLogger.error('Health Connect status error: $e', st);
      return HealthConnectStatus.permissionRequired;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      bool granted = false;
      try {
        granted = await _health.requestAuthorization(
          _dataTypes,
          permissions: _permissions,
        );
      } catch (e) {
        AppLogger.error('Full authorization request failed, trying steps fallback: $e');
        try {
          granted = await _health.requestAuthorization(
            [HealthDataType.STEPS],
            permissions: [HealthDataAccess.READ],
          );
        } catch (_) {}
      }

      if (granted) return true;

      final stepsPerm = await _health.hasPermissions(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );

      return stepsPerm ?? true;
    } catch (e, st) {
      AppLogger.error('Health Connect permission error: $e', st);
      return true;
    }
  }

  Future<List<HealthDataPoint>> getHealthData(DateTime start, DateTime end) async {
    try {
      return await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: _dataTypes,
      );
    } catch (e, st) {
      AppLogger.error('Health Connect data error: $e', st);
      return [];
    }
  }

  Future<int?> getSteps(DateTime start, DateTime end) async {
    try {
      return await _health.getTotalStepsInInterval(start, end);
    } catch (e, st) {
      AppLogger.error('Health Connect steps error: $e', st);
      return null;
    }
  }
}
