import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static SharedPreferences? _instance;

  static Future<void> initialize() async {
    _instance = await SharedPreferences.getInstance();
  }

  static Future<SharedPreferences> instance() async {
    return _instance ??= await SharedPreferences.getInstance();
  }
}
