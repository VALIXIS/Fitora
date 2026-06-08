import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/app/providers/theme_mode_provider.dart';
import 'package:fitora/core/storage/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPreferences.resetForTests();
  });

  test('defaults to dark mode on first launch', () async {
    final controller = ThemeModeController();

    expect(controller.state, ThemeMode.dark);

    await controller.load();

    expect(controller.state, ThemeMode.dark);
  });

  test('persists selected theme across restart', () async {
    final controller = ThemeModeController();

    await controller.setThemeMode(ThemeMode.light);

    AppPreferences.resetForTests();

    final reloaded = ThemeModeController();
    await reloaded.load();

    expect(reloaded.state, ThemeMode.light);
  });
}