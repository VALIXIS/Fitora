import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:fitora/app/providers/theme_mode_provider.dart';
import 'package:fitora/core/services/notification_service.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  // Hydration reminder settings
  final bool hydrationReminderEnabled;
  final int hydrationReminderIntervalHours; // 1, 2, 3, or 4
  final int hydrationReminderStartHour;     // 0–23
  final int hydrationReminderEndHour;       // 0–23

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
    this.hydrationReminderEnabled = false,
    this.hydrationReminderIntervalHours = 2,
    this.hydrationReminderStartHour = 8,
    this.hydrationReminderEndHour = 22,
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
    bool? hydrationReminderEnabled,
    int? hydrationReminderIntervalHours,
    int? hydrationReminderStartHour,
    int? hydrationReminderEndHour,
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
      hydrationReminderEnabled: hydrationReminderEnabled ?? this.hydrationReminderEnabled,
      hydrationReminderIntervalHours: hydrationReminderIntervalHours ?? this.hydrationReminderIntervalHours,
      hydrationReminderStartHour: hydrationReminderStartHour ?? this.hydrationReminderStartHour,
      hydrationReminderEndHour: hydrationReminderEndHour ?? this.hydrationReminderEndHour,
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
      hydrationReminderEnabled: prefs.getBool('hydrationReminderEnabled') ?? false,
      hydrationReminderIntervalHours: prefs.getInt('hydrationReminderIntervalHours') ?? 2,
      hydrationReminderStartHour: prefs.getInt('hydrationReminderStartHour') ?? 8,
      hydrationReminderEndHour: prefs.getInt('hydrationReminderEndHour') ?? 22,
    );
  }

  Future<void> updateSetting(String key, dynamic value) async {
    final prefs = await AppPreferences.instance();

    switch (key) {
      case 'isDarkMode':
        final v = value as bool;
        await prefs.setBool(key, v);
        state = state.copyWith(isDarkMode: v);
        ref.read(themeModeProvider.notifier).setThemeMode(v ? ThemeMode.dark : ThemeMode.light);

      case 'notificationsEnabled':
        final v = value as bool;
        await prefs.setBool(key, v);
        if (v) {
          final granted = await ref.read(notificationServiceProvider).requestPermissions();
          if (!granted) {
            state = state.copyWith(notificationsEnabled: false);
            await prefs.setBool('notificationsEnabled', false);
          } else {
            state = state.copyWith(notificationsEnabled: true);
            _rescheduleAllNotifications();
          }
        } else {
          state = state.copyWith(notificationsEnabled: false);
          await ref.read(notificationServiceProvider).cancelAll();
        }

      case 'soundEffectsEnabled':
        final v = value as bool;
        await prefs.setBool(key, v);
        state = state.copyWith(soundEffectsEnabled: v);

      case 'hapticsEnabled':
        final v = value as bool;
        await prefs.setBool(key, v);
        state = state.copyWith(hapticsEnabled: v);

      case 'waterReminder':
        final v = value as bool;
        await prefs.setBool(key, v);
        state = state.copyWith(waterReminder: v);
        _rescheduleAllNotifications();

      case 'workoutReminder':
        final v = value as bool;
        await prefs.setBool(key, v);
        state = state.copyWith(workoutReminder: v);
        _rescheduleAllNotifications();

      case 'dailyGoalReminder':
        final v = value as bool;
        await prefs.setBool(key, v);
        state = state.copyWith(dailyGoalReminder: v);
        _rescheduleAllNotifications();

      case 'isMetric':
        final v = value as bool;
        await prefs.setBool(key, v);
        state = state.copyWith(isMetric: v);

      case 'autoplayRest':
        final v = value as bool;
        await prefs.setBool(key, v);
        state = state.copyWith(autoplayRest: v);

      case 'hydrationReminderEnabled':
        final v = value as bool;
        await prefs.setBool(key, v);
        state = state.copyWith(hydrationReminderEnabled: v);
        _rescheduleHydrationReminders();

      case 'hydrationReminderIntervalHours':
        final v = value as int;
        await prefs.setInt(key, v);
        state = state.copyWith(hydrationReminderIntervalHours: v);
        _rescheduleHydrationReminders();

      case 'hydrationReminderStartHour':
        final v = value as int;
        await prefs.setInt(key, v);
        state = state.copyWith(hydrationReminderStartHour: v);
        _rescheduleHydrationReminders();

      case 'hydrationReminderEndHour':
        final v = value as int;
        await prefs.setInt(key, v);
        state = state.copyWith(hydrationReminderEndHour: v);
        _rescheduleHydrationReminders();
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

    // Re-apply hydration reminders too
    _rescheduleHydrationReminders();
  }

  void _rescheduleHydrationReminders() {
    final svc = ref.read(notificationServiceProvider);
    if (!state.notificationsEnabled || !state.hydrationReminderEnabled) {
      svc.cancelHydrationReminders();
      return;
    }
    svc.scheduleHydrationReminders(
      intervalHours: state.hydrationReminderIntervalHours,
      startHour: state.hydrationReminderStartHour,
      endHour: state.hydrationReminderEndHour,
    );
  }

  /// Returns true if notification permission is currently granted.
  Future<bool> checkNotificationPermission() async {
    final status = await ph.Permission.notification.status;
    return status.isGranted;
  }

  Future<void> resetToDefaults() async {
    final prefs = await AppPreferences.instance();
    const keys = [
      'isDarkMode',
      'notificationsEnabled',
      'soundEffectsEnabled',
      'hapticsEnabled',
      'waterReminder',
      'workoutReminder',
      'dailyGoalReminder',
      'isMetric',
      'hydrationReminderEnabled',
      'hydrationReminderIntervalHours',
      'hydrationReminderStartHour',
      'hydrationReminderEndHour',
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

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});
