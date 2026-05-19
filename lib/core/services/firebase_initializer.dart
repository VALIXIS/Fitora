import 'package:firebase_core/firebase_core.dart';
import 'package:fitora/firebase_options.dart';
import 'package:fitora/core/utils/app_logger.dart';

class FirebaseInitializer {
  static bool _initialized = false;
  static Future<void>? _initializing;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initializing ??= _initializeInternal();
    await _initializing;
  }

  static Future<void> _initializeInternal() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _initialized = true;
      AppLogger.info('Firebase initialized');
    } catch (error, stackTrace) {
      _initialized = false;
      AppLogger.error(error, stackTrace);
    }
  }
}
