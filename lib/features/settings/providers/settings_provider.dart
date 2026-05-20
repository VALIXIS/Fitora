import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/core/constants/storage_keys.dart';
import 'package:fitora/features/settings/domain/settings_model.dart';

final settingsProvider = StateNotifierProvider<SettingsController, SettingsModel>(
  (ref) => SettingsController()..load(),
);

class SettingsController extends StateNotifier<SettingsModel> {
  SettingsController() : super(SettingsModel.defaults());

  Future<void> load() async {
    final prefs = await AppPreferences.instance();
    final raw = prefs.getString(StorageKeys.appSettings);
    if (raw == null) {
      return;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      state = SettingsModel.fromJson(decoded);
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await AppPreferences.instance();
    await prefs.setString(StorageKeys.appSettings, jsonEncode(state.toJson()));
  }

  Future<void> setNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _persist();
  }

  Future<void> setHydrationReminders(bool enabled) async {
    state = state.copyWith(hydrationReminders: enabled);
    await _persist();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    await _persist();
  }

  Future<void> setAutoplayRest(bool enabled) async {
    state = state.copyWith(autoplayRest: enabled);
    await _persist();
  }

  Future<void> setUnits(String units) async {
    state = state.copyWith(units: units);
    await _persist();
  }
}
