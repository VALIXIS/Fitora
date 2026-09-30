import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/core/utils/app_logger.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(ForegroundStepTaskHandler());
}

class ForegroundStepTaskHandler extends TaskHandler {
  StreamSubscription<StepCount>? _stepCountStream;
  int _stepsToday = 0;
  int _baseSteps = -1;
  String _currentDate = '';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    AppLogger.info('ForegroundStepTaskHandler: onStart');
    
    final prefs = await SharedPreferences.getInstance();
    
    _stepCountStream = Pedometer.stepCountStream.listen(
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
        
        _stepsToday = event.steps - _baseSteps;

        FlutterForegroundTask.updateService(
          notificationTitle: 'Fitora Tracking',
          notificationText: 'Steps today: $_stepsToday',
        );
        FlutterForegroundTask.sendDataToMain(_stepsToday);
      },
      onError: (error) {
        AppLogger.error('Pedometer error in foreground', error);
      },
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    FlutterForegroundTask.updateService(
      notificationTitle: 'Fitora Tracking',
      notificationText: 'Steps today: $_stepsToday',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    AppLogger.info('ForegroundStepTaskHandler: onDestroy');
    await _stepCountStream?.cancel();
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}
}

class ForegroundStepService {
  static final ForegroundStepService _instance = ForegroundStepService._internal();
  factory ForegroundStepService() => _instance;
  ForegroundStepService._internal();

  bool _isInitialized = false;
  final StreamController<int> _stepStreamController = StreamController<int>.broadcast();
  int _lastSteps = 0;

  Stream<int> get stepStream => _stepStreamController.stream;
  int get currentSteps => _lastSteps;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'fitora_foreground_service',
        channelName: 'Fitora Step Tracking',
        channelDescription: 'Keeps Fitora alive to track steps in the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    _isInitialized = true;
  }

  Future<void> startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      _listenToData();
      return;
    }

    final ServiceRequestResult result = await FlutterForegroundTask.startService(
      notificationTitle: 'Fitora Tracking',
      notificationText: 'Initializing...',
      callback: startCallback,
    );

    if (result is ServiceRequestSuccess) {
      _listenToData();
    }
  }

  void _listenToData() {
    FlutterForegroundTask.addTaskDataCallback((data) {
      if (data is int) {
        _lastSteps = data;
        _stepStreamController.add(_lastSteps);
      }
    });
  }

  Future<void> stopService() async {
    await FlutterForegroundTask.stopService();
  }
}
