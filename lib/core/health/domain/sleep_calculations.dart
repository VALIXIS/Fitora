import 'dart:math';
import 'package:fitora/core/health/domain/health_models.dart';

class SleepCalculations {
  /// Calculates the duration between two date times, handling potential invalid input.
  static Duration calculateDuration(DateTime start, DateTime end) {
    if (end.isBefore(start)) {
      return Duration.zero;
    }
    return end.difference(start);
  }

  /// Calculates target duration from target hour and minute targets.
  static Duration calculateTargetDuration(
    int bedtimeHour,
    int bedtimeMinute,
    int wakeHour,
    int wakeMinute,
  ) {
    final bedtimeMinutes = bedtimeHour * 60 + bedtimeMinute;
    final wakeMinutes = wakeHour * 60 + wakeMinute;
    int diffMinutes = wakeMinutes - bedtimeMinutes;
    if (diffMinutes < 0) {
      diffMinutes += 24 * 60;
    }
    return Duration(minutes: diffMinutes);
  }

  /// Assigns a sleep session to a specific sleep day using the noon-to-noon rule.
  /// A sleep session starting after 12:00 PM on D and before 12:00 PM on D+1 belongs to sleep day D.
  static DateTime assignDateForSession(DateTime start) {
    if (start.hour >= 12) {
      return DateTime(start.year, start.month, start.day);
    } else {
      return DateTime(start.year, start.month, start.day).subtract(const Duration(days: 1));
    }
  }

  /// Calculates the circular difference in minutes between two times of day.
  static int getMinutesDifferenceCircular(int h1, int m1, int h2, int m2) {
    final t1 = h1 * 60 + m1;
    final t2 = h2 * 60 + m2;
    final diff = (t1 - t2).abs();
    return min(diff, 1440 - diff);
  }

  /// Checks if the bedtime is within 30 minutes of the target bedtime.
  static bool isBedtimeConsistent(DateTime? startTime, int targetHour, int targetMinute) {
    if (startTime == null) return false;
    final diff = getMinutesDifferenceCircular(startTime.hour, startTime.minute, targetHour, targetMinute);
    return diff <= 30;
  }

  /// Checks if the wake-up time is within 30 minutes of the target wake-up time.
  static bool isWakeTimeConsistent(DateTime? endTime, int targetHour, int targetMinute) {
    if (endTime == null) return false;
    final diff = getMinutesDifferenceCircular(endTime.hour, endTime.minute, targetHour, targetMinute);
    return diff <= 30;
  }

  /// Checks if both bedtime and wake-up target conditions are met.
  static bool isScheduleAchieved(
    DateTime? startTime,
    DateTime? endTime,
    int targetBedHour,
    int targetBedMinute,
    int targetWakeHour,
    int targetWakeMinute,
  ) {
    if (startTime == null || endTime == null) return false;
    return isBedtimeConsistent(startTime, targetBedHour, targetBedMinute) &&
           isWakeTimeConsistent(endTime, targetWakeHour, targetWakeMinute);
  }

  /// Checks if actual sleep duration meets the configured target.
  static bool isDurationTargetAchieved(Duration actualDuration, int targetDurationMinutes) {
    return actualDuration.inMinutes >= targetDurationMinutes;
  }

  /// Counts how many valid sleep days achieved bedtime and wake targets.
  static int countAchievedDays(
    List<SleepSummary> summaries,
    int targetBedHour,
    int targetBedMinute,
    int targetWakeHour,
    int targetWakeMinute,
  ) {
    final validDays = summaries.where((s) => s.totalSleep.inMinutes > 0).toList();
    int count = 0;
    for (final s in validDays) {
      if (isScheduleAchieved(
        s.startTime,
        s.endTime,
        targetBedHour,
        targetBedMinute,
        targetWakeHour,
        targetWakeMinute,
      )) {
        count++;
      }
    }
    return count;
  }

  /// Calculates 7-day average sleep duration of valid sleep days only.
  static Duration calculate7DayAverage(List<SleepSummary> summaries) {
    final validDays = summaries.where((s) => s.totalSleep.inMinutes > 0).toList();
    if (validDays.isEmpty) return Duration.zero;
    final totalMinutes = validDays.map((s) => s.totalSleep.inMinutes).reduce((a, b) => a + b);
    return Duration(minutes: (totalMinutes / validDays.length).round());
  }

  /// Generates non-medical guidance statements based on actual sleep history and targets.
  static String generateBedtimeGuidance({
    required List<SleepSummary> summaries,
    required int targetDurationMinutes,
    required int targetBedHour,
    required int targetBedMinute,
    required int targetWakeHour,
    required int targetWakeMinute,
  }) {
    final validDays = summaries.where((s) => s.totalSleep.inMinutes > 0).toList();
    if (validDays.isEmpty) {
      return 'No sleep data recorded this week. Connect Health Connect to get personalized bedtime guidance.';
    }

    final avgDuration = calculate7DayAverage(summaries);
    final avgMinutes = avgDuration.inMinutes;

    final bedtimeInconsistentDays = validDays
        .where((s) => !isBedtimeConsistent(s.startTime, targetBedHour, targetBedMinute))
        .length;
    final wakeInconsistentDays = validDays
        .where((s) => !isWakeTimeConsistent(s.endTime, targetWakeHour, targetWakeMinute))
        .length;

    if (avgMinutes < targetDurationMinutes) {
      final hours = targetDurationMinutes ~/ 60;
      final minutes = targetDurationMinutes % 60;
      final minStr = minutes > 0 ? ' $minutes-minute' : '';
      return 'Your average sleep this week is below your target. Try going to bed around '
          '${formatTimeOfDay(targetBedHour, targetBedMinute)} to reach your $hours-hour$minStr target.';
    }

    if (bedtimeInconsistentDays >= 3) {
      return 'Your bedtime has been inconsistent this week. Try to align it within 30 minutes of your target.';
    }

    if (wakeInconsistentDays >= 3) {
      return 'Your wake-up time has been inconsistent this week. Try setting a regular morning alarm.';
    }

    return 'Great job! Your sleep schedule and duration have been consistent and on target this week.';
  }

  static String formatTimeOfDay(int hour, int minute) {
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMin = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMin $ampm';
  }
}
