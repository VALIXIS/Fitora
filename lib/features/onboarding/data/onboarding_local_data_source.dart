import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/constants/storage_keys.dart';
import 'package:fitora/core/storage/app_preferences.dart';

final onboardingLocalDataSourceProvider =
    Provider<OnboardingLocalDataSource>((ref) {
  return OnboardingLocalDataSource();
});

class OnboardingLocalDataSource {
  Future<bool> isCompleted() async {
    final prefs = await AppPreferences.instance();
    return prefs.getBool(StorageKeys.onboardingCompleted) ?? false;
  }

  Future<void> setCompleted(bool value) async {
    final prefs = await AppPreferences.instance();
    await prefs.setBool(StorageKeys.onboardingCompleted, value);
  }
}
