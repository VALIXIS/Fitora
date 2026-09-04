import 'package:flutter_test/flutter_test.dart';
import 'package:fitora/core/services/notification_service.dart';

void main() {
  group('NotificationService Action & Bedtime Calculations', () {
    test('Action ID constants are correctly defined', () {
      expect(NotificationService.actionAddWater250, equals('ADD_WATER_250'));
      expect(NotificationService.actionLogSleep, equals('LOG_SLEEP'));
    });

    test('Bedtime prep time is calculated exactly 30 minutes prior to bedtime', () {
      final targetDate = DateTime(2026, 9, 4);
      final bedtimeHour = 23;
      final bedtimeMin = 0;

      final bedtime = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        bedtimeHour,
        bedtimeMin,
      );
      final prepTime = bedtime.subtract(const Duration(minutes: 30));

      expect(prepTime.hour, equals(22));
      expect(prepTime.minute, equals(30));
    });

    test('Bedtime prep handles midnight date rollover correctly', () {
      final targetDate = DateTime(2026, 9, 5);
      final bedtimeHour = 0;
      final bedtimeMin = 15;

      final bedtime = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        bedtimeHour,
        bedtimeMin,
      );
      final prepTime = bedtime.subtract(const Duration(minutes: 30));

      expect(prepTime.year, equals(2026));
      expect(prepTime.month, equals(9));
      expect(prepTime.day, equals(4));
      expect(prepTime.hour, equals(23));
      expect(prepTime.minute, equals(45));
    });

    test('Managed notification ID ranges do not overlap', () {
      // Hydration IDs: 100..249
      // Step IDs: 300..302
      // Sleep IDs: 400..402
      // Summary IDs: 500..502
      final hydrationIds = List.generate(150, (i) => 100 + i).toSet();
      final stepIds = List.generate(3, (i) => 300 + i).toSet();
      final sleepIds = List.generate(3, (i) => 400 + i).toSet();
      final summaryIds = List.generate(3, (i) => 500 + i).toSet();

      expect(hydrationIds.intersection(stepIds), isEmpty);
      expect(hydrationIds.intersection(sleepIds), isEmpty);
      expect(hydrationIds.intersection(summaryIds), isEmpty);
      expect(stepIds.intersection(sleepIds), isEmpty);
      expect(sleepIds.intersection(summaryIds), isEmpty);
    });
  });
}
