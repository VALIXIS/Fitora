import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // ID ranges — hydration slots use 100–123 (max 24 per day)
  static const int _hydrationIdBase = 100;
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

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      granted = await iosImpl.requestPermissions(alert: true, badge: true, sound: true);
    }

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      granted = await androidImpl.requestNotificationsPermission();
    }

    return granted ?? false;
  }

  /// Check current notification permission status without requesting.
  Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily Reminders',
          channelDescription: 'Daily notifications for health and workouts',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedules repeating hydration reminders every [intervalHours] within
  /// the active window from [startHour] to [endHour].
  /// Always cancels previous hydration reminders first to prevent duplicates.
  Future<void> scheduleHydrationReminders({
    required int intervalHours,
    required int startHour,
    required int endHour,
  }) async {
    await initialize();

    // Cancel previous hydration reminders before scheduling new ones
    await cancelHydrationReminders();

    final now = tz.TZDateTime.now(tz.local);

    int slotIndex = 0;
    int currentHour = startHour;

    const messages = [
      'Time to hydrate! Drink a glass of water.',
      'Stay energized — have some water now!',
      'Hydration check! Keep up the good work.',
      'Your body needs water. Take a sip!',
      'Halfway through your day — drink up!',
      'Evening hydration reminder. Stay refreshed!',
    ];

    while (currentHour < endHour && slotIndex < 24) {
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        currentHour,
        0,
      );
      // If time already passed today, push to tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: _hydrationIdBase + slotIndex,
        title: 'Hydration Reminder 💧',
        body: messages[slotIndex % messages.length],
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'hydration_reminders',
            'Hydration Reminders',
            channelDescription: 'Periodic reminders to drink water throughout the day',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@drawable/ic_notification',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      currentHour += intervalHours;
      slotIndex++;
    }
  }

  /// Cancel all hydration reminder notifications (IDs 100–123).
  Future<void> cancelHydrationReminders() async {
    await initialize();
    for (int i = 0; i < 24; i++) {
      await _plugin.cancel(id: _hydrationIdBase + i);
    }
  }

  /// Immediately fires a test notification to verify the channel is working.
  Future<void> showTestNotification() async {
    await initialize();
    await _plugin.show(
      id: _testNotificationId,
      title: 'Fitora Notifications ✅',
      body: 'Notifications are working! You\'ll receive hydration reminders as scheduled.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'hydration_reminders',
          'Hydration Reminders',
          channelDescription: 'Periodic reminders to drink water throughout the day',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
