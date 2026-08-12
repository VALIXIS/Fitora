import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/utils/app_logger.dart';

class HealthConnectService {
  // Singleton — configure() is expensive and must only run once
  static final HealthConnectService _instance = HealthConnectService._internal();
  factory HealthConnectService() => _instance;

  final Health _health = Health();

  static const _stepsTypes = [HealthDataType.STEPS];
  static const _stepsPerms = [HealthDataAccess.READ];

  final _dataTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.SLEEP_SESSION,
  ];

  HealthConnectService._internal() {
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
        _stepsTypes,
        permissions: _stepsPerms,
      );
      print('[HC_DIRECT] hasPermissions (STEPS READ) = $hasPerm');
      diag['hasPermissionsSteps'] = hasPerm;

      print('[HC_DIRECT] requesting STEPS authorization...');
      bool authResult = false;
      try {
        authResult = await _health.requestAuthorization(
          _stepsTypes,
          permissions: _stepsPerms,
        );
      } catch (e) {
        print('[HC_DIRECT] requestAuthorization threw: $e');
        diag['requestAuthError'] = e.toString();
      }
      print('[HC_DIRECT] authorization result = $authResult');
      diag['authorizationResult'] = authResult;

      // Try reading regardless of auth result — Android may have permissions even if hasPermissions returns null
      int? totalSteps;
      try {
        totalSteps = await _health.getTotalStepsInInterval(start, end);
      } catch (e) {
        print('[HC_DIRECT] getTotalStepsInInterval THREW: $e');
        diag['stepsException'] = e.toString();
      }
      print('[HC_DIRECT] total steps result = $totalSteps');
      diag['totalSteps'] = totalSteps;

      List<HealthDataPoint> rawRecords = [];
      try {
        rawRecords = await _health.getHealthDataFromTypes(
          startTime: start,
          endTime: end,
          types: _stepsTypes,
        );
      } catch (e) {
        print('[HC_DIRECT] getHealthDataFromTypes THREW: $e');
        diag['recordsException'] = e.toString();
      }
      print('[HC_DIRECT] raw step record count = ${rawRecords.length}');
      diag['rawRecordCount'] = rawRecords.length;

      final List<Map<String, dynamic>> recList = [];
      for (int i = 0; i < rawRecords.length; i++) {
        final r = rawRecords[i];
        final val = (r.value as NumericHealthValue).numericValue;
        print('[HC_DIRECT] record ${i + 1}: val=$val source=${r.sourceName} app=${r.sourceId} from=${r.dateFrom} to=${r.dateTo}');
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
      print('[HC_DIRECT] OUTER EXCEPTION: $e');
      print('[HC_DIRECT] STACKTRACE: $st');
      diag['exception'] = e.toString();
    }

    return diag;
  }

  Future<HealthConnectStatus> getStatus() async {
    try {
      final sdkStatus = await _health.getHealthConnectSdkStatus();
      if (kDebugMode) print('[HC_DEBUG] SDK status: $sdkStatus');
      if (sdkStatus == HealthConnectSdkStatus.sdkUnavailable) {
        return HealthConnectStatus.notInstalled;
      }

      final hasPerm = await _health.hasPermissions(
        _stepsTypes,
        permissions: _stepsPerms,
      );
      if (kDebugMode) print('[HC_DEBUG] hasPermissions(STEPS): $hasPerm');

      // null means indeterminate — treat as permissionRequired so UI shows Connect button
      if (hasPerm == true) return HealthConnectStatus.connected;
      return HealthConnectStatus.permissionRequired;
    } catch (e, st) {
      AppLogger.error('Health Connect status error: $e', st);
      return HealthConnectStatus.permissionRequired;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      // Request all types so we don't get partial permission issues
      bool granted = false;
      try {
        granted = await _health.requestAuthorization(
          _dataTypes,
          permissions: _permissions,
        );
        if (kDebugMode) print('[HC_DEBUG] requestAuthorization full result: $granted');
      } catch (e) {
        AppLogger.error('Full permission request failed: $e');
        // Fallback: request only steps
        try {
          granted = await _health.requestAuthorization(
            _stepsTypes,
            permissions: _stepsPerms,
          );
          if (kDebugMode) print('[HC_DEBUG] requestAuthorization steps-only result: $granted');
        } catch (e2) {
          AppLogger.error('Steps-only permission request also failed: $e2');
        }
      }
      return granted;
    } catch (e, st) {
      AppLogger.error('Health Connect requestPermissions error: $e', st);
      return false;
    }
  }

  Future<List<HealthDataPoint>> getHealthData(DateTime start, DateTime end) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: _dataTypes,
      );
      if (kDebugMode) print('[HC_DEBUG] getHealthData returned ${points.length} points');
      return points;
    } catch (e, st) {
      AppLogger.error('Health Connect getHealthData error: $e', st);
      if (kDebugMode) print('[HC_DEBUG] getHealthData THREW: $e');
      return [];
    }
  }

  Future<int?> getSteps(DateTime start, DateTime end) async {
    try {
      final steps = await _health.getTotalStepsInInterval(start, end);
      if (kDebugMode) print('[HC_DEBUG] getSteps returned: $steps');
      return steps;
    } catch (e, st) {
      AppLogger.error('Health Connect getSteps error: $e', st);
      if (kDebugMode) print('[HC_DEBUG] getSteps THREW: $e');
      return null;
    }
  }
}
