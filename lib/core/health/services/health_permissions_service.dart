import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/data/sensor_repository.dart';

final healthPermissionsServiceProvider = Provider<HealthPermissionsService>(
  (ref) => HealthPermissionsService(ref.read(sensorRepositoryProvider)),
);

class HealthPermissionsService {
  final SensorRepository _sensorRepo;

  HealthPermissionsService(this._sensorRepo);

  /// Returns the current sensor permission status without requesting.
  Future<SensorStatus> checkStatus() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      // Sensor integration is Android-only for now
      return SensorStatus.unavailable;
    }

    final snap = await _sensorRepo.getDebugSnapshot();
    if (!snap.sensorAvailable) {
      return SensorStatus.unavailable;
    }

    // On Android < 10 (API 29) ACTIVITY_RECOGNITION doesn't exist
    // and the step counter sensor is freely accessible — treat as active.
    if (await _isPreAndroid10()) {
      return SensorStatus.active;
    }

    final status = await Permission.activityRecognition.status;
    if (status.isGranted) return SensorStatus.active;
    return SensorStatus.permissionRequired;
  }

  /// Requests the permission and returns the resulting status.
  Future<SensorStatus> requestPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return SensorStatus.unavailable;
    }

    final snap = await _sensorRepo.getDebugSnapshot();
    if (!snap.sensorAvailable) {
      return SensorStatus.unavailable;
    }

    // Pre-Android 10: no runtime permission required
    if (await _isPreAndroid10()) {
      return SensorStatus.active;
    }

    final result = await Permission.activityRecognition.request();
    if (result.isGranted) return SensorStatus.active;
    return SensorStatus.permissionRequired;
  }

  Future<bool> _isPreAndroid10() async {
    // permission_handler returns PermissionStatus.granted on pre-API-29
    // because the permission simply doesn't exist (always granted by OS).
    // We check by querying the permission — if it doesn't require a dialog
    // it will come back granted immediately on older APIs.
    try {
      final status = await Permission.activityRecognition.status;
      // If status is restricted it means the OS doesn't support it → treat as free
      return status.isRestricted;
    } catch (_) {
      return false;
    }
  }
}
