import 'dart:async';
import 'dart:math';
import '../domain/health_sync_models.dart';

class PedometerService {
  static final PedometerService _instance = PedometerService._internal();
  factory PedometerService() => _instance;
  PedometerService._internal();

  StreamController<int>? _stepStreamController;
  Timer? _simulationTimer;
  int _currentSteps = 8420; // Starting steps count
  bool _isWalking = false;
  HealthPermissionStatus _permissionStatus = HealthPermissionStatus.notDetermined;

  bool get isWalking => _isWalking;
  int get currentSteps => _currentSteps;
  HealthPermissionStatus get permissionStatus => _permissionStatus;

  // Stream of realtime steps count
  Stream<int> get stepStream {
    if (_stepStreamController == null || _stepStreamController!.isClosed) {
      _stepStreamController = StreamController<int>.broadcast(
        onListen: _startSimulation,
        onCancel: _stopSimulation,
      );
    }
    return _stepStreamController!.stream;
  }

  void setInitialSteps(int steps) {
    if (steps > _currentSteps) {
      _currentSteps = steps;
    }
  }

  Future<HealthPermissionStatus> checkPermissionStatus() async {
    return _permissionStatus;
  }

  Future<HealthPermissionStatus> requestPermissions() async {
    await Future.delayed(const Duration(milliseconds: 600)); // OS pop-up speed
    _permissionStatus = HealthPermissionStatus.authorized;
    _emitCurrentSteps();
    return _permissionStatus;
  }

  void toggleWalkSimulation() {
    _isWalking = !_isWalking;
    if (_isWalking) {
      _emitCurrentSteps();
      _startSimulation();
    } else {
      _stopSimulation();
    }
  }

  void _emitCurrentSteps() {
    if (_stepStreamController != null &&
        !_stepStreamController!.isClosed &&
        _stepStreamController!.hasListener) {
      _stepStreamController!.add(max(0, _currentSteps));
    }
  }

  void _startSimulation() {
    _simulationTimer?.cancel();
    // Simulate walking: increments step counter by 1-2 steps every 900ms
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (_isWalking && _permissionStatus == HealthPermissionStatus.authorized) {
        _currentSteps += 1 + Random().nextInt(2);
        _emitCurrentSteps();
      }
    });
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }
}
