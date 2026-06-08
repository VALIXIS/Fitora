import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static SharedPreferences? _instance;

  static Future<void> initialize() async {
    _instance = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs => _instance!;

  static Future<SharedPreferences> instance() async {
    return _instance ??= await SharedPreferences.getInstance();
  }

  static void resetForTests() {
    _instance = null;
  }
}
