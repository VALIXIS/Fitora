import 'package:fitora/core/services/firebase_initializer.dart';
import 'package:fitora/core/storage/app_preferences.dart';

class AppInitializer {
  static Future<void> initialize() async {
    await FirebaseInitializer.initialize();
    await AppPreferences.initialize();
  }
}
