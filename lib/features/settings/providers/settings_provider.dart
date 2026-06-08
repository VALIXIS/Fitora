import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/app/providers/theme_mode_provider.dart';
import 'package:fitora/core/services/notification_service.dart';
import 'package:fitora/core/storage/app_preferences.dart';

class SettingsState {
  final bool isDarkMode;
  final bool notificationsEnabled;
  final bool soundEffectsEnabled;
  final bool hapticsEnabled;
  final bool waterReminder;
  final bool workoutReminder;
  final bool dailyGoalReminder;
  final bool isMetric;
  final bool autoplayRest;

  const SettingsState({
    this.isDarkMode = true,
    this.notificationsEnabled = true,
    this.soundEffectsEnabled = false,
    this.hapticsEnabled = true,
    this.waterReminder = true,
    this.workoutReminder = true,
    this.dailyGoalReminder = true,
    this.isMetric = true,
    this.autoplayRest = true,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    bool? notificationsEnabled,
    bool? soundEffectsEnabled,
    bool? hapticsEnabled,
    bool? waterReminder,
    bool? workoutReminder,
    bool? dailyGoalReminder,
    bool? isMetric,
    bool? autoplayRest,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      waterReminder: waterReminder ?? this.waterReminder,
      workoutReminder: workoutReminder ?? this.workoutReminder,
      dailyGoalReminder: dailyGoalReminder ?? this.dailyGoalReminder,
      isMetric: isMetric ?? this.isMetric,
      autoplayRest: autoplayRest ?? this.autoplayRest,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref ref;

  SettingsNotifier(this.ref) : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await AppPreferences.instance();
    state = SettingsState(
      isDarkMode: prefs.getBool('isDarkMode') ?? true,
      notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
      soundEffectsEnabled: prefs.getBool('soundEffectsEnabled') ?? false,
      hapticsEnabled: prefs.getBool('hapticsEnabled') ?? true,
      waterReminder: prefs.getBool('waterReminder') ?? true,
      workoutReminder: prefs.getBool('workoutReminder') ?? true,
      dailyGoalReminder: prefs.getBool('dailyGoalReminder') ?? true,
      isMetric: prefs.getBool('isMetric') ?? true,
      autoplayRest: prefs.getBool('autoplayRest') ?? true,
    );
  }

  Future<void> updateSetting(String key, bool value) async {
    final prefs = await AppPreferences.instance();
    await prefs.setBool(key, value);

    switch (key) {
      case 'isDarkMode':
        state = state.copyWith(isDarkMode: value);
        ref.read(themeModeProvider.notifier).setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
        break;
      case 'notificationsEnabled':
        state = state.copyWith(notificationsEnabled: value);
        if (value) {
          final granted = await ref.read(notificationServiceProvider).requestPermissions();
          if (!granted) {
            state = state.copyWith(notificationsEnabled: false);
            await prefs.setBool('notificationsEnabled', false);
          } else {
            _rescheduleAllNotifications();
          }
        } else {
          await ref.read(notificationServiceProvider).cancelAll();
        }
        break;
      case 'soundEffectsEnabled':
        state = state.copyWith(soundEffectsEnabled: value);
        break;
      case 'hapticsEnabled':
        state = state.copyWith(hapticsEnabled: value);
        break;
      case 'waterReminder':
        state = state.copyWith(waterReminder: value);
        _rescheduleAllNotifications();
        break;
      case 'workoutReminder':
        state = state.copyWith(workoutReminder: value);
        _rescheduleAllNotifications();
        break;
      case 'dailyGoalReminder':
        state = state.copyWith(dailyGoalReminder: value);
        _rescheduleAllNotifications();
        break;
      case 'isMetric':
        state = state.copyWith(isMetric: value);
        break;
      case 'autoplayRest':
        state = state.copyWith(autoplayRest: value);
        break;
    }
  }

  void _rescheduleAllNotifications() {
    if (!state.notificationsEnabled) return;
    final svc = ref.read(notificationServiceProvider);
    svc.cancelAll();

    if (state.waterReminder) {
      svc.scheduleDailyReminder(id: 1, title: 'Hydration', body: 'Time to drink some water!', hour: 9, minute: 0);
      svc.scheduleDailyReminder(id: 2, title: 'Hydration', body: 'Stay hydrated!', hour: 14, minute: 0);
      svc.scheduleDailyReminder(id: 3, title: 'Hydration', body: 'Did you drink enough water today?', hour: 19, minute: 0);
    }
    if (state.workoutReminder) {
      svc.scheduleDailyReminder(id: 4, title: 'Workout Time', body: 'Ready to crush your goals?', hour: 17, minute: 30);
    }
    if (state.dailyGoalReminder) {
      svc.scheduleDailyReminder(id: 5, title: 'Daily Goal', body: 'Check your progress for today!', hour: 20, minute: 0);
    }
  }

  Future<void> resetToDefaults() async {
    final prefs = await AppPreferences.instance();
    final keys = [
      'isDarkMode',
      'notificationsEnabled',
      'soundEffectsEnabled',
      'hapticsEnabled',
      'waterReminder',
      'workoutReminder',
      'dailyGoalReminder',
      'isMetric'
    ];
    for (final key in keys) {
      await prefs.remove(key);
    }
    state = const SettingsState();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});
