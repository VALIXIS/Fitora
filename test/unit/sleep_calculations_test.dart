import 'package:flutter_test/flutter_test.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/domain/sleep_calculations.dart';

void main() {
  group('Sleep Duration Calculations', () {
    test('Overnight sleep: 22:30 -> 06:10 = 7h 40m', () {
      final start = DateTime(2026, 8, 28, 22, 30);
      final end = DateTime(2026, 8, 29, 6, 10);
      final duration = SleepCalculations.calculateDuration(start, end);
      expect(duration.inMinutes, equals(460)); // 7 hours * 60 + 40 = 460
    });

    test('Overnight sleep: 23:00 -> 07:00 = 8h', () {
      final start = DateTime(2026, 8, 28, 23, 0);
      final end = DateTime(2026, 8, 29, 7, 0);
      final duration = SleepCalculations.calculateDuration(start, end);
      expect(duration.inHours, equals(8));
    });

    test('Overnight sleep: 23:30 -> 00:30 = 1h', () {
      final start = DateTime(2026, 8, 28, 23, 30);
      final end = DateTime(2026, 8, 29, 0, 30);
      final duration = SleepCalculations.calculateDuration(start, end);
      expect(duration.inHours, equals(1));
    });

    test('Same-day sleep session: 08:00 -> 10:00 = 2h', () {
      final start = DateTime(2026, 8, 28, 8, 0);
      final end = DateTime(2026, 8, 28, 10, 0);
      final duration = SleepCalculations.calculateDuration(start, end);
      expect(duration.inHours, equals(2));
    });

    test('Invalid/Empty interval: end before start', () {
      final start = DateTime(2026, 8, 28, 10, 0);
      final end = DateTime(2026, 8, 28, 8, 0);
      final duration = SleepCalculations.calculateDuration(start, end);
      expect(duration, equals(Duration.zero));
    });
  });

  group('Sleep Day Assignment Rules', () {
    test('23:00 Aug 28 -> 07:00 Aug 29 belongs to Aug 28', () {
      final start = DateTime(2026, 8, 28, 23, 0);
      final day = SleepCalculations.assignDateForSession(start);
      expect(day, equals(DateTime(2026, 8, 28)));
    });

    test('01:00 Aug 29 -> 07:00 Aug 29 belongs to Aug 28', () {
      final start = DateTime(2026, 8, 29, 1, 0);
      final day = SleepCalculations.assignDateForSession(start);
      expect(day, equals(DateTime(2026, 8, 28)));
    });

    test('Session starting after noon (12:05 PM) belongs to same day', () {
      final start = DateTime(2026, 8, 28, 12, 5);
      final day = SleepCalculations.assignDateForSession(start);
      expect(day, equals(DateTime(2026, 8, 28)));
    });

    test('Session starting before noon (11:55 AM) belongs to previous day', () {
      final start = DateTime(2026, 8, 28, 11, 55);
      final day = SleepCalculations.assignDateForSession(start);
      expect(day, equals(DateTime(2026, 8, 27)));
    });
  });

  group('7-Day History & Average Calculations', () {
    test('Calculate average only from valid recorded days', () {
      final baseDate = DateTime(2026, 8, 29);
      final history = [
        SleepSummary(
          totalSleep: const Duration(hours: 8),
          remSleep: Duration.zero,
          deepSleep: Duration.zero,
          lightSleep: const Duration(hours: 8),
          sleepScore: 80,
          date: baseDate.subtract(const Duration(days: 6)),
        ),
        SleepSummary(
          totalSleep: Duration.zero, // missing data
          remSleep: Duration.zero,
          deepSleep: Duration.zero,
          lightSleep: Duration.zero,
          sleepScore: 0,
          date: baseDate.subtract(const Duration(days: 5)),
        ),
        SleepSummary(
          totalSleep: const Duration(hours: 6),
          remSleep: Duration.zero,
          deepSleep: Duration.zero,
          lightSleep: const Duration(hours: 6),
          sleepScore: 60,
          date: baseDate.subtract(const Duration(days: 4)),
        ),
      ];

      final average = SleepCalculations.calculate7DayAverage(history);
      // Valid days are 8h and 6h. Average = 7h. Missing day (0) is ignored!
      expect(average.inHours, equals(7));
    });

    test('Fewer than 7 days of available data (all missing) returns zero', () {
      final baseDate = DateTime(2026, 8, 29);
      final history = [
        SleepSummary(
          totalSleep: Duration.zero,
          remSleep: Duration.zero,
          deepSleep: Duration.zero,
          lightSleep: Duration.zero,
          sleepScore: 0,
          date: baseDate,
        ),
      ];
      final average = SleepCalculations.calculate7DayAverage(history);
      expect(average, equals(Duration.zero));
    });
  });

  group('Sleep Target Schedule Calculations', () {
    test('Overnight target: 23:00 -> 07:00 = 8h', () {
      final target = SleepCalculations.calculateTargetDuration(23, 0, 7, 0);
      expect(target.inHours, equals(8));
    });

    test('Same-day target: 14:00 -> 18:00 = 4h', () {
      final target = SleepCalculations.calculateTargetDuration(14, 0, 18, 0);
      expect(target.inHours, equals(4));
    });

    test('Target crossing midnight: 22:30 -> 06:30 = 8h', () {
      final target = SleepCalculations.calculateTargetDuration(22, 30, 6, 30);
      expect(target.inHours, equals(8));
    });
  });

  group('Sleep Consistency Evaluations', () {
    test('Bedtime within ±30 minutes is consistent', () {
      final targetBedHour = 23;
      final targetBedMinute = 0;

      final act1 = DateTime(2026, 8, 28, 23, 15);
      final act2 = DateTime(2026, 8, 28, 22, 45);
      final act3 = DateTime(2026, 8, 28, 23, 40);

      expect(SleepCalculations.isBedtimeConsistent(act1, targetBedHour, targetBedMinute), isTrue);
      expect(SleepCalculations.isBedtimeConsistent(act2, targetBedHour, targetBedMinute), isTrue);
      expect(SleepCalculations.isBedtimeConsistent(act3, targetBedHour, targetBedMinute), isFalse);
    });

    test('Bedtime consistency handles midnight boundaries correctly', () {
      final targetBedHour = 23;
      final targetBedMinute = 50;

      // 00:10 is 20 minutes after 23:50
      final act1 = DateTime(2026, 8, 29, 0, 10);
      // 00:30 is 40 minutes after 23:50
      final act2 = DateTime(2026, 8, 29, 0, 30);

      expect(SleepCalculations.isBedtimeConsistent(act1, targetBedHour, targetBedMinute), isTrue);
      expect(SleepCalculations.isBedtimeConsistent(act2, targetBedHour, targetBedMinute), isFalse);
    });

    test('Wake time within ±30 minutes is consistent', () {
      final targetWakeHour = 7;
      final targetWakeMinute = 0;

      final act1 = DateTime(2026, 8, 29, 7, 10);
      final act2 = DateTime(2026, 8, 29, 6, 45);
      final act3 = DateTime(2026, 8, 29, 8, 0);

      expect(SleepCalculations.isWakeTimeConsistent(act1, targetWakeHour, targetWakeMinute), isTrue);
      expect(SleepCalculations.isWakeTimeConsistent(act2, targetWakeHour, targetWakeMinute), isTrue);
      expect(SleepCalculations.isWakeTimeConsistent(act3, targetWakeHour, targetWakeMinute), isFalse);
    });

    test('Schedule achieved requires BOTH consistent bedtime and wake time', () {
      final targetBedHour = 23;
      final targetBedMinute = 0;
      final targetWakeHour = 7;
      final targetWakeMinute = 0;

      final bedtimeOk = DateTime(2026, 8, 28, 23, 10);
      final bedtimeBad = DateTime(2026, 8, 28, 22, 10);
      final wakeOk = DateTime(2026, 8, 29, 6, 50);
      final wakeBad = DateTime(2026, 8, 29, 8, 0);

      expect(
        SleepCalculations.isScheduleAchieved(bedtimeOk, wakeOk, targetBedHour, targetBedMinute, targetWakeHour, targetWakeMinute),
        isTrue,
      );
      expect(
        SleepCalculations.isScheduleAchieved(bedtimeBad, wakeOk, targetBedHour, targetBedMinute, targetWakeHour, targetWakeMinute),
        isFalse,
      );
      expect(
        SleepCalculations.isScheduleAchieved(bedtimeOk, wakeBad, targetBedHour, targetBedMinute, targetWakeHour, targetWakeMinute),
        isFalse,
      );
    });
  });

  group('SleepSummary Serialization', () {
    test('startTime/endTime survive toJson/fromJson', () {
      final original = SleepSummary(
        totalSleep: const Duration(hours: 7),
        remSleep: Duration.zero,
        deepSleep: Duration.zero,
        lightSleep: const Duration(hours: 7),
        sleepScore: 70,
        date: DateTime(2026, 8, 28),
        startTime: DateTime(2026, 8, 28, 23, 0),
        endTime: DateTime(2026, 8, 29, 6, 0),
      );

      final json = original.toJson();
      final reconstructed = SleepSummary.fromJson(json);

      expect(reconstructed.totalSleep, equals(original.totalSleep));
      expect(reconstructed.startTime, equals(original.startTime));
      expect(reconstructed.endTime, equals(original.endTime));
    });
  });
}
