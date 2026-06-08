import 'package:fitora/core/services/firebase_initializer.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/core/utils/app_logger.dart';

class AppInitializer {
  static Future<void> initialize() async {
    final s = Stopwatch()..start();
    await FirebaseInitializer.initialize();
    AppLogger.info('AppInitializer: Firebase initialized at ${s.elapsedMilliseconds}ms');
    await AppPreferences.initialize();
    AppLogger.info('AppInitializer: AppPreferences initialized at ${s.elapsedMilliseconds}ms');
  }
}
