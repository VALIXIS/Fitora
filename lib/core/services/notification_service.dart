import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int _testNotificationId = 9999;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      try {
        final String sysTz = DateTime.now().timeZoneName;
        tz.setLocalLocation(tz.getLocation(sysTz));
      } catch (_) {
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
        } catch (_) {}
      }
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      const channel = AndroidNotificationChannel(
        'health_reminders',
        'Health Reminders',
        description: 'Notifications for health and wellness tracking',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await androidImpl.createNotificationChannel(channel);
    }

    _isInitialized = true;
  }

  Future<bool> canScheduleExact() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return (await androidImpl?.canScheduleExactNotifications()) ?? false;
  }

  Future<void> requestExactAlarmPermission() async {
    await Permission.scheduleExactAlarm.request();
  }

  Future<bool> requestPermissions() async {
    await initialize();

    bool? granted;

    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      final status = await Permission.notification.request();
      granted = status.isGranted;
      try {
        await androidImpl.requestNotificationsPermission();
      } catch (_) {}
    }

    return granted ?? false;
  }

  Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  bool _isInQuietHours(
    DateTime time,
    bool enabled,
    int startHour,
    int endHour,
  ) {
    if (!enabled) return false;
    final h = time.hour;
    if (startHour > endHour) {
      return h >= startHour || h < endHour;
    } else {
      return h >= startHour && h < endHour;
    }
  }

  /// Master scheduling function that schedules for the next 3 days (offsets 0, 1, 2)
  Future<void> scheduleAllReminders({
    required bool hydrationEnabled,
    required int hydrationIntervalMinutes,
    required bool stepEnabled,
    required bool sleepEnabled,
    required bool summaryEnabled,
    required bool quietHoursEnabled,
    required int quietHoursStart,
    required int quietHoursEnd,
    required bool waterGoalMetToday,
    required bool stepGoalMetToday,
  }) async {
    await initialize();

    // 1. Cancel all managed reminders first to prevent duplicates
    await cancelManagedReminders();

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final bool canScheduleExactAlarm = (await androidImpl?.canScheduleExactNotifications()) ?? false;
    final scheduleMode = canScheduleExactAlarm
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final now = tz.TZDateTime.now(tz.local);

    const hydrationMessages = [
      'Time to hydrate! Drink a glass of water.',
      'Stay energized — have some water now!',
      'Hydration check! Keep up the good work.',
      'Your body needs water. Take a sip!',
      'Halfway through your day — drink up!',
      'Evening hydration reminder. Stay refreshed!',
    ];

    const stepMessages = [
      'Keep moving! You are doing great today.',
      'Walk a bit more to crush your daily step goal!',
      'Take a quick walk break to stretch and add some steps.',
    ];

    const sleepMessages = [
      'Time to wind down and prepare for a restful sleep.',
      'Sleep is key for recovery. Rest well tonight.',
    ];

    const summaryMessages = [
      'You did great today! Review your progress in Fitora.',
      'Another step towards your health goals. Keep it up tomorrow!',
    ];

    const androidDetails = AndroidNotificationDetails(
      'health_reminders',
      'Health Reminders',
      channelDescription: 'Notifications for health and wellness tracking',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // Schedule for Today (0), Tomorrow (1), Day After (2)
    for (int dayOffset = 0; dayOffset <= 2; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final isToday = dayOffset == 0;

      // Hydration Reminders
      if (hydrationEnabled && !(isToday && waterGoalMetToday)) {
        final startHour = quietHoursEnabled
            ? quietHoursEnd
            : 8; // If quiet ends at 8, start active at 8
        final limitHour = quietHoursEnabled ? quietHoursStart : 22;

        tz.TZDateTime currentSchedule = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          startHour,
          0,
        );
        tz.TZDateTime endLimit = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          limitHour,
          0,
        );

        if (startHour > limitHour) {
          // Crosses midnight, so endLimit should be next day if we started today
          endLimit = endLimit.add(const Duration(days: 1));
        }

        int slot = 0;
        while (currentSchedule.isBefore(endLimit) && slot < 24) {
          if (!_isInQuietHours(
            currentSchedule,
            quietHoursEnabled,
            quietHoursStart,
            quietHoursEnd,
          )) {
            if (currentSchedule.isAfter(now)) {
              final id = 100 + (dayOffset * 50) + slot;
              await _plugin.zonedSchedule(
                id: id,
                title: 'Hydration Reminder 💧',
                body: hydrationMessages[slot % hydrationMessages.length],
                scheduledDate: currentSchedule,
                notificationDetails: platformDetails,
                androidScheduleMode: scheduleMode,
              );
            }
          }
          currentSchedule = currentSchedule.add(
            Duration(minutes: hydrationIntervalMinutes),
          );
          slot++;
        }
      }

      // Step Goal Reminder (3:00 PM / 15:00)
      if (stepEnabled && !(isToday && stepGoalMetToday)) {
        final schedule = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          15,
          0,
        );
        if (schedule.isAfter(now) &&
            !_isInQuietHours(
              schedule,
              quietHoursEnabled,
              quietHoursStart,
              quietHoursEnd,
            )) {
          final id = 300 + dayOffset;
          await _plugin.zonedSchedule(
            id: id,
            title: 'Step Goal check-in 👟',
            body: stepMessages[dayOffset % stepMessages.length],
            scheduledDate: schedule,
            notificationDetails: platformDetails,
            androidScheduleMode: scheduleMode,
          );
        }
      }

      // Sleep Reminder (10:00 PM / 22:00)
      if (sleepEnabled) {
        final schedule = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          22,
          0,
        );
        if (schedule.isAfter(now)) {
          final id = 400 + dayOffset;
          await _plugin.zonedSchedule(
            id: id,
            title: 'Time to wind down 😴',
            body: sleepMessages[dayOffset % sleepMessages.length],
            scheduledDate: schedule,
            notificationDetails: platformDetails,
            androidScheduleMode: scheduleMode,
          );
        }
      }

      // Daily Summary (9:00 PM / 21:00)
      if (summaryEnabled) {
        final schedule = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          21,
          0,
        );
        if (schedule.isAfter(now)) {
          final id = 500 + dayOffset;
          await _plugin.zonedSchedule(
            id: id,
            title: 'Daily Accomplishment Recap 🌟',
            body: summaryMessages[dayOffset % summaryMessages.length],
            scheduledDate: schedule,
            notificationDetails: platformDetails,
            androidScheduleMode: scheduleMode,
          );
        }
      }
    }
  }

  /// Cancels all managed notification IDs within our designated ranges.
  Future<void> cancelManagedReminders() async {
    await initialize();
    // Hydration IDs: 100 - 249
    for (int i = 100; i <= 249; i++) {
      await _plugin.cancel(id: i);
    }
    // Step, Sleep, Summary IDs: 300-302, 400-402, 500-502
    for (int i = 0; i <= 2; i++) {
      await _plugin.cancel(id: 300 + i);
      await _plugin.cancel(id: 400 + i);
      await _plugin.cancel(id: 500 + i);
    }
    // Cancel legacy daily reminders just in case
    for (int i = 1; i <= 5; i++) {
      await _plugin.cancel(id: i);
    }
  }

  /// Cancel remaining hydration reminders for today only.
  Future<void> cancelRemainingHydrationRemindersForToday() async {
    await initialize();
    // Today's hydration IDs are 100 to 149
    for (int i = 100; i <= 149; i++) {
      await _plugin.cancel(id: i);
    }
  }

  /// Cancel today's step reminder.
  Future<void> cancelStepReminderForToday() async {
    await initialize();
    // Today's step ID is 300
    await _plugin.cancel(id: 300);
  }

  Future<void> showTestNotification() async {
    await initialize();
    await _plugin.show(
      id: _testNotificationId,
      title: 'Fitora Notifications ✅',
      body:
          'Notifications are working! You\'ll receive reminders as scheduled.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'health_reminders',
          'Health Reminders',
          channelDescription: 'Notifications for health and wellness tracking',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showWelcomeNotification() async {
    await initialize();
    await _plugin.show(
      id: 8888,
      title: 'Welcome to Fitora! 🌟',
      body: 'Your health and wellness reminders are now set up. Let\'s crush those goals!',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'health_reminders',
          'Health Reminders',
          channelDescription: 'Notifications for health and wellness tracking',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
