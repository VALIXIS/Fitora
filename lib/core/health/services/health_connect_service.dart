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

  Future<Map<String, dynamic>> runDirectDiagnostic() async {
    final Map<String, dynamic> diag = {};
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = now;

    print('[HC_DIRECT] now = $now');
    print('[HC_DIRECT] start = $start');
    print('[HC_DIRECT] end = $end');
    diag['now'] = now.toIso8601String();
    diag['start'] = start.toIso8601String();
    diag['end'] = end.toIso8601String();

    try {
      final sdkStatus = await _health.getHealthConnectSdkStatus();
      print('[HC_DIRECT] SDK status = $sdkStatus');
      diag['sdkStatus'] = sdkStatus?.name;

      final hasPerm = await _health.hasPermissions(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
      print('[HC_DIRECT] permissions (hasPermissions STEPS) = $hasPerm');
      diag['hasPermissionsSteps'] = hasPerm;

      print('[HC_DIRECT] requesting permissions...');
      final authResult = await _health.requestAuthorization(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
      print('[HC_DIRECT] authorization result = $authResult');
      diag['authorizationResult'] = authResult;

      final totalSteps = await _health.getTotalStepsInInterval(start, end);
      print('[HC_DIRECT] total steps result = $totalSteps');
      diag['totalSteps'] = totalSteps;

      final rawRecords = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.STEPS],
      );
      print('[HC_DIRECT] raw step record count = ${rawRecords.length}');
      diag['rawRecordCount'] = rawRecords.length;

      final List<Map<String, dynamic>> recList = [];
      for (int i = 0; i < rawRecords.length; i++) {
        final r = rawRecords[i];
        final val = (r.value as NumericHealthValue).numericValue;
        print('[HC_DIRECT] record ${i + 1} = val:$val, source:${r.sourceName}, app:${r.sourceId}, dateFrom:${r.dateFrom}, dateTo:${r.dateTo}');
        recList.add({
          'val': val,
          'sourceName': r.sourceName,
          'sourceId': r.sourceId,
          'dateFrom': r.dateFrom.toIso8601String(),
          'dateTo': r.dateTo.toIso8601String(),
        });
      }
      diag['records'] = recList;
    } catch (e, st) {
      print('[HC_DIRECT] EXCEPTION: $e');
      print('[HC_DIRECT] STACKTRACE: $st');
      diag['exception'] = e.toString();
    }

    return diag;
  }

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
