import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int _testNotificationId = 9999;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _isInitialized = true;
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
      granted = await androidImpl.requestNotificationsPermission();
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

    final androidDetails = const AndroidNotificationDetails(
      'health_reminders',
      'Health Reminders',
      channelDescription: 'Notifications for health and wellness tracking',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
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
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
