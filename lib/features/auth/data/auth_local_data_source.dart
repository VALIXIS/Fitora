import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/constants/storage_keys.dart';
import 'package:fitora/core/storage/app_preferences.dart';

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource();
});

class AuthLocalDataSource {
  Future<bool> isCompleted() async {
    final prefs = await AppPreferences.instance();
    return prefs.getBool(StorageKeys.authCompleted) ?? false;
  }

  Future<void> setCompleted(bool value) async {
    final prefs = await AppPreferences.instance();
    await prefs.setBool(StorageKeys.authCompleted, value);
  }
}