import 'dart:async';
import 'dart:math';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/core/utils/app_logger.dart';
import '../domain/health_sync_models.dart';

class PedometerService {
  static final PedometerService _instance = PedometerService._internal();
  factory PedometerService() => _instance;
  PedometerService._internal();

  StreamController<int>? _stepStreamController;
  int _currentSteps = 0;
  int _baseSteps = -1;
  String _currentDate = '';
  
  bool _isWalking = false;
  HealthPermissionStatus _permissionStatus = HealthPermissionStatus.notDetermined;
  StreamSubscription<StepCount>? _pedometerSub;

  bool get isWalking => _isWalking;
  int get currentSteps => _currentSteps;
  HealthPermissionStatus get permissionStatus => _permissionStatus;

  Stream<int> get stepStream {
    if (_stepStreamController == null || _stepStreamController!.isClosed) {
      _stepStreamController = StreamController<int>.broadcast(
        onListen: _startListeningToPedometer,
        onCancel: _stopListeningToPedometer,
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
    await Permission.activityRecognition.request();
    _permissionStatus = HealthPermissionStatus.authorized;
    _emitCurrentSteps();
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

  Future<void> _startListeningToPedometer() async {
    _pedometerSub?.cancel();
    final prefs = await SharedPreferences.getInstance();

    _pedometerSub = Pedometer.stepCountStream.listen(
      (StepCount event) async {
        final now = DateTime.now();
        final dateStr = '${now.year}-${now.month}-${now.day}';
        
        if (_currentDate != dateStr) {
          _currentDate = dateStr;
          final savedDate = prefs.getString('fitora_step_date');
          
          if (savedDate == dateStr) {
            _baseSteps = prefs.getInt('fitora_base_steps') ?? event.steps;
          } else {
            _baseSteps = event.steps;
            await prefs.setString('fitora_step_date', _currentDate);
            await prefs.setInt('fitora_base_steps', _baseSteps);
          }
        }

        if (event.steps < _baseSteps) {
           _baseSteps = 0;
           await prefs.setInt('fitora_base_steps', _baseSteps);
        }
        
        _currentSteps = event.steps - _baseSteps;
        _emitCurrentSteps();
      },
      onError: (error) {
        AppLogger.error('Pedometer error', error);
      },
    );
  }

  void _stopListeningToPedometer() {
    _pedometerSub?.cancel();
    _pedometerSub = null;
  }
}
