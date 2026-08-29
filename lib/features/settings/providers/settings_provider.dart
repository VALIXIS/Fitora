import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:fitora/app/providers/theme_mode_provider.dart';
import 'package:fitora/core/constants/storage_keys.dart';
import 'package:fitora/core/services/notification_service.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fitora/core/health/providers/health_providers.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';
final exactAlarmPermissionProvider = FutureProvider<bool>((ref) async {
  final svc = ref.watch(notificationServiceProvider);
  return await svc.canScheduleExact();
});

final batteryOptimizationExemptProvider = FutureProvider<bool>((ref) async {
  return await ph.Permission.ignoreBatteryOptimizations.isGranted;
});

final batteryWarningDismissedProvider =
    StateNotifierProvider<BatteryWarningDismissedNotifier, bool>((ref) {
  return BatteryWarningDismissedNotifier();
});

class BatteryWarningDismissedNotifier extends StateNotifier<bool> {
  static const _key = 'fitora_battery_warning_dismissed';

  BatteryWarningDismissedNotifier()
      : super(AppPreferences.prefs.getBool(_key) ?? false);

  Future<void> dismiss() async {
    state = true;
    await AppPreferences.prefs.setBool(_key, true);
  }
}

class SettingsState {
  final bool isDarkMode;
  final bool notificationsEnabled;
  final bool soundEffectsEnabled;
  final bool hapticsEnabled;
  final bool isMetric;
  final bool autoplayRest;

  // Granular Reminders
  final bool hydrationReminderEnabled;
  final int hydrationReminderIntervalMinutes;
  final bool stepReminderEnabled;
  final bool sleepReminderEnabled;
  final bool dailySummaryEnabled;

  // Quiet Hours
  final bool quietHoursEnabled;
  final int quietHoursStartHour;
  final int quietHoursEndHour;

  // Sleep Target
  final int sleepTargetDurationMinutes;
  final int sleepTargetBedtimeHour;
  final int sleepTargetBedtimeMinute;
  final int sleepTargetWakeHour;
  final int sleepTargetWakeMinute;

  const SettingsState({
    this.isDarkMode = true,
    this.notificationsEnabled = true,
    this.soundEffectsEnabled = false,
    this.hapticsEnabled = true,
    this.isMetric = true,
    this.autoplayRest = true,
    this.hydrationReminderEnabled = false,
    this.hydrationReminderIntervalMinutes = 120,
    this.stepReminderEnabled = true,
    this.sleepReminderEnabled = true,
    this.dailySummaryEnabled = true,
    this.quietHoursEnabled = true,
    this.quietHoursStartHour = 22,
    this.quietHoursEndHour = 8,
    this.sleepTargetDurationMinutes = 480,
    this.sleepTargetBedtimeHour = 23,
    this.sleepTargetBedtimeMinute = 0,
    this.sleepTargetWakeHour = 7,
    this.sleepTargetWakeMinute = 0,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    bool? notificationsEnabled,
    bool? soundEffectsEnabled,
    bool? hapticsEnabled,
    bool? isMetric,
    bool? autoplayRest,
    bool? hydrationReminderEnabled,
    int? hydrationReminderIntervalMinutes,
    bool? stepReminderEnabled,
    bool? sleepReminderEnabled,
    bool? dailySummaryEnabled,
    bool? quietHoursEnabled,
    int? quietHoursStartHour,
    int? quietHoursEndHour,
    int? sleepTargetDurationMinutes,
    int? sleepTargetBedtimeHour,
    int? sleepTargetBedtimeMinute,
    int? sleepTargetWakeHour,
    int? sleepTargetWakeMinute,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      isMetric: isMetric ?? this.isMetric,
      autoplayRest: autoplayRest ?? this.autoplayRest,
      hydrationReminderEnabled:
          hydrationReminderEnabled ?? this.hydrationReminderEnabled,
      hydrationReminderIntervalMinutes:
          hydrationReminderIntervalMinutes ??
          this.hydrationReminderIntervalMinutes,
      stepReminderEnabled: stepReminderEnabled ?? this.stepReminderEnabled,
      sleepReminderEnabled: sleepReminderEnabled ?? this.sleepReminderEnabled,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStartHour: quietHoursStartHour ?? this.quietHoursStartHour,
      quietHoursEndHour: quietHoursEndHour ?? this.quietHoursEndHour,
      sleepTargetDurationMinutes:
          sleepTargetDurationMinutes ?? this.sleepTargetDurationMinutes,
      sleepTargetBedtimeHour:
          sleepTargetBedtimeHour ?? this.sleepTargetBedtimeHour,
      sleepTargetBedtimeMinute:
          sleepTargetBedtimeMinute ?? this.sleepTargetBedtimeMinute,
      sleepTargetWakeHour: sleepTargetWakeHour ?? this.sleepTargetWakeHour,
      sleepTargetWakeMinute:
          sleepTargetWakeMinute ?? this.sleepTargetWakeMinute,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref ref;

  SettingsNotifier(this.ref) : super(const SettingsState()) {
    _loadSettings();

    // Reactive synchronization for theme mode
    ref.listen<ThemeMode>(themeModeProvider, (previous, next) {
      final isDark = next == ThemeMode.dark;
      if (state.isDarkMode != isDark) {
        state = state.copyWith(isDarkMode: isDark);
      }
    });

    // Setup reactive cancellation for water goals
    ref.listen(wellnessProvider, (previous, next) {
      if (next.hydrationGoalLiters > 0 &&
          next.hydrationLiters >= next.hydrationGoalLiters) {
        if (previous == null ||
            previous.hydrationLiters < previous.hydrationGoalLiters) {
          // Goal just met! Cancel remaining hydration reminders for today
          if (state.notificationsEnabled && state.hydrationReminderEnabled) {
            ref
                .read(notificationServiceProvider)
                .cancelRemainingHydrationRemindersForToday();
          }
        }
      }
    });

    // Setup reactive cancellation for step goals
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    ref.listen(dailyActivityProvider(today), (previous, next) {
      if (next.stepsGoal > 0 && next.steps >= next.stepsGoal) {
        if (previous == null || previous.steps < previous.stepsGoal) {
          // Goal just met! Cancel step reminder for today
          if (state.notificationsEnabled && state.stepReminderEnabled) {
            ref.read(notificationServiceProvider).cancelStepReminderForToday();
          }
        }
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await AppPreferences.instance();
    final themeStr = prefs.getString(StorageKeys.themeMode);
    final isDark = themeStr == null
        ? (prefs.getBool('isDarkMode') ?? true)
        : (themeStr == 'dark' || (themeStr == 'system' && PlatformDispatcher.instance.platformBrightness == Brightness.dark));

    state = SettingsState(
      isDarkMode: isDark,
      notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
      soundEffectsEnabled: prefs.getBool('soundEffectsEnabled') ?? false,
      hapticsEnabled: prefs.getBool('hapticsEnabled') ?? true,
      isMetric: prefs.getBool('isMetric') ?? true,
      autoplayRest: prefs.getBool('autoplayRest') ?? true,
      hydrationReminderEnabled:
          prefs.getBool('hydrationReminderEnabled') ?? false,
      hydrationReminderIntervalMinutes:
          prefs.getInt('hydrationReminderIntervalMinutes') ??
          (prefs.getInt('hydrationReminderIntervalHours') != null
              ? prefs.getInt('hydrationReminderIntervalHours')! * 60
              : 120),
      stepReminderEnabled: prefs.getBool('stepReminderEnabled') ?? true,
      sleepReminderEnabled: prefs.getBool('sleepReminderEnabled') ?? true,
      dailySummaryEnabled: prefs.getBool('dailySummaryEnabled') ?? true,
      quietHoursEnabled: prefs.getBool('quietHoursEnabled') ?? true,
      quietHoursStartHour: prefs.getInt('quietHoursStartHour') ?? 22,
      quietHoursEndHour: prefs.getInt('quietHoursEndHour') ?? 8,
      sleepTargetDurationMinutes: prefs.getInt('sleepTargetDurationMinutes') ?? 480,
      sleepTargetBedtimeHour: prefs.getInt('sleepTargetBedtimeHour') ?? 23,
      sleepTargetBedtimeMinute: prefs.getInt('sleepTargetBedtimeMinute') ?? 0,
      sleepTargetWakeHour: prefs.getInt('sleepTargetWakeHour') ?? 7,
      sleepTargetWakeMinute: prefs.getInt('sleepTargetWakeMinute') ?? 0,
    );
  }

  Future<void> updateSetting(String key, dynamic value) async {
    final prefs = await AppPreferences.instance();

    switch (key) {
      case 'isDarkMode':
        final v = value as bool;
        await prefs.setBool(key, v);
        state = state.copyWith(isDarkMode: v);
        ref
            .read(themeModeProvider.notifier)
            .setThemeMode(v ? ThemeMode.dark : ThemeMode.light);

      case 'notificationsEnabled':
        final v = value as bool;
        await prefs.setBool(key, v);
        if (v) {
          final granted = await ref
              .read(notificationServiceProvider)
              .requestPermissions();
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
        _rescheduleAllNotifications();

      case 'hydrationReminderIntervalMinutes':
        final v = value as int;
        await prefs.setInt(key, v);
        state = state.copyWith(hydrationReminderIntervalMinutes: v);
        _rescheduleAllNotifications();

      case 'stepReminderEnabled':
        final v = value as bool;
        await prefs.setBool(key, v);
        state = state.copyWith(stepReminderEnabled: v);
        _rescheduleAllNotifications();

      case 'sleepReminderEnabled':
        final v = value as bool;
        await prefs.setBool(key, v);
        state = state.copyWith(sleepReminderEnabled: v);
        _rescheduleAllNotifications();

      case 'dailySummaryEnabled':
        final v = value as bool;
        await prefs.setBool(key, v);
        state = state.copyWith(dailySummaryEnabled: v);
        _rescheduleAllNotifications();

      case 'quietHoursEnabled':
        final v = value as bool;
        await prefs.setBool(key, v);
        state = state.copyWith(quietHoursEnabled: v);
        _rescheduleAllNotifications();

      case 'quietHoursStartHour':
        final v = value as int;
        await prefs.setInt(key, v);
        state = state.copyWith(quietHoursStartHour: v);
        _rescheduleAllNotifications();

      case 'quietHoursEndHour':
        final v = value as int;
        await prefs.setInt(key, v);
        state = state.copyWith(quietHoursEndHour: v);
        _rescheduleAllNotifications();

      case 'sleepTargetDurationMinutes':
        final v = value as int;
        await prefs.setInt(key, v);
        state = state.copyWith(sleepTargetDurationMinutes: v);

      case 'sleepTargetBedtimeHour':
        final v = value as int;
        await prefs.setInt(key, v);
        state = state.copyWith(sleepTargetBedtimeHour: v);

      case 'sleepTargetBedtimeMinute':
        final v = value as int;
        await prefs.setInt(key, v);
        state = state.copyWith(sleepTargetBedtimeMinute: v);

      case 'sleepTargetWakeHour':
        final v = value as int;
        await prefs.setInt(key, v);
        state = state.copyWith(sleepTargetWakeHour: v);

      case 'sleepTargetWakeMinute':
        final v = value as int;
        await prefs.setInt(key, v);
        state = state.copyWith(sleepTargetWakeMinute: v);
    }
  }

  Future<void> _rescheduleAllNotifications() async {
    if (!state.notificationsEnabled) return;

    final svc = ref.read(notificationServiceProvider);

    // Show welcome notification if not shown yet
    final prefs = await AppPreferences.instance();
    final welcomeShown = prefs.getBool('fitora_welcome_notification_shown') ?? false;
    if (!welcomeShown) {
      final hasPerm = await svc.hasPermission();
      if (hasPerm) {
        await svc.showWelcomeNotification();
        await prefs.setBool('fitora_welcome_notification_shown', true);
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final wellness = ref.read(wellnessProvider);
    final activity = ref.read(dailyActivityProvider(today));

    bool waterGoalMet =
        wellness.hydrationGoalLiters > 0 &&
        wellness.hydrationLiters >= wellness.hydrationGoalLiters;
    bool stepGoalMet =
        activity.stepsGoal > 0 && activity.steps >= activity.stepsGoal;

    svc.scheduleAllReminders(
      hydrationEnabled: state.hydrationReminderEnabled,
      hydrationIntervalMinutes: state.hydrationReminderIntervalMinutes,
      stepEnabled: state.stepReminderEnabled,
      sleepEnabled: state.sleepReminderEnabled,
      summaryEnabled: state.dailySummaryEnabled,
      quietHoursEnabled: state.quietHoursEnabled,
      quietHoursStart: state.quietHoursStartHour,
      quietHoursEnd: state.quietHoursEndHour,
      waterGoalMetToday: waterGoalMet,
      stepGoalMetToday: stepGoalMet,
    );
  }

  Future<bool> checkNotificationPermission() async {
    final status = await ph.Permission.notification.status;
    return status.isGranted;
  }

  Future<bool> checkExactAlarmPermission() async {
    final svc = ref.read(notificationServiceProvider);
    return await svc.canScheduleExact();
  }

  Future<void> requestExactAlarmPermission() async {
    final svc = ref.read(notificationServiceProvider);
    await svc.requestExactAlarmPermission();
    await _rescheduleAllNotifications();
  }

  Future<void> resetToDefaults() async {
    final prefs = await AppPreferences.instance();
    const keys = [
      'isDarkMode',
      'notificationsEnabled',
      'soundEffectsEnabled',
      'hapticsEnabled',
      'isMetric',
      'hydrationReminderEnabled',
      'hydrationReminderIntervalMinutes',
      'hydrationReminderIntervalHours',
      'stepReminderEnabled',
      'sleepReminderEnabled',
      'dailySummaryEnabled',
      'quietHoursEnabled',
      'quietHoursStartHour',
      'quietHoursEndHour',
      'waterReminder',
      'workoutReminder',
      'dailyGoalReminder',
      'fitora_permissions_shown',
      'fitora_welcome_notification_shown',
    ];
    for (final key in keys) {
      await prefs.remove(key);
    }
    state = const SettingsState();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier(ref);
  },
);

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});
