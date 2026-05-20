import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/constants/storage_keys.dart';
import 'package:fitora/core/storage/app_preferences.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) => ThemeModeController()..load(),
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.light);

  Future<void> load() async {
    final prefs = await AppPreferences.instance();
    final value = prefs.getString(StorageKeys.themeMode);
    if (value == null) {
      state = ThemeMode.light;
      return;
    }

    state = ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.light,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await AppPreferences.instance();
    await prefs.setString(StorageKeys.themeMode, mode.name);
  }
}
