import 'dart:async';
import 'dart:math';
import 'package:fitora/core/health/services/foreground_step_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../domain/health_sync_models.dart';

class PedometerService {
  static final PedometerService _instance = PedometerService._internal();
  factory PedometerService() => _instance;
  PedometerService._internal();

  StreamController<int>? _stepStreamController;
  int _currentSteps = 0;
  bool _isWalking = false;
  HealthPermissionStatus _permissionStatus = HealthPermissionStatus.notDetermined;
  StreamSubscription<int>? _foregroundSub;

  bool get isWalking => _isWalking;
  int get currentSteps => _currentSteps;
  HealthPermissionStatus get permissionStatus => _permissionStatus;

  Stream<int> get stepStream {
    if (_stepStreamController == null || _stepStreamController!.isClosed) {
      _stepStreamController = StreamController<int>.broadcast(
        onListen: _startListeningToForeground,
        onCancel: _stopListeningToForeground,
      );
    }
    return _stepStreamController!.stream;
  }

  void setInitialSteps(int steps) {
    if (steps >= 0) {
      _currentSteps = steps;
      _emitCurrentSteps();
    }
  }

  Future<HealthPermissionStatus> checkPermissionStatus() async {
    return _permissionStatus;
  }

  Future<HealthPermissionStatus> requestPermissions() async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Request activity recognition
    await Permission.activityRecognition.request();
    // Request notification permission for the foreground service
    await Permission.notification.request();
    
    _permissionStatus = HealthPermissionStatus.authorized;
    _emitCurrentSteps();
    
    // Start foreground service when permission is granted
    await ForegroundStepService().startService();
    
    return _permissionStatus;
  }

  void toggleWalkSimulation() {
    _isWalking = !_isWalking;
    if (_isWalking) {
      _emitCurrentSteps();
    }
  }

  void _emitCurrentSteps() {
    if (_stepStreamController != null &&
        !_stepStreamController!.isClosed &&
        _stepStreamController!.hasListener) {
      _stepStreamController!.add(max(0, _currentSteps));
    }
  }

  void _startListeningToForeground() {
    _foregroundSub?.cancel();
    _foregroundSub = ForegroundStepService().stepStream.listen((steps) {
      _currentSteps = steps;
      _emitCurrentSteps();
    });
  }

  void _stopListeningToForeground() {
    _foregroundSub?.cancel();
    _foregroundSub = null;
  }
}
