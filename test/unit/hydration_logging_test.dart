import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/features/wellness/domain/wellness_models.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.initialize();
  });

  group('WaterLogEntry & WellnessState Serialization', () {
    test('WaterLogEntry toJson and fromJson', () {
      final now = DateTime(2026, 8, 12, 14, 30);
      final entry = WaterLogEntry(id: '123_456', amountMl: 250, timestamp: now);

      final json = entry.toJson();
      expect(json['id'], equals('123_456'));
      expect(json['amountMl'], equals(250));

      final restored = WaterLogEntry.fromJson(json);
      expect(restored.id, equals('123_456'));
      expect(restored.amountMl, equals(250));
      expect(restored.timestamp, equals(now));
    });

    test('WellnessState waterLogs serialization', () {
      final now = DateTime(2026, 8, 12, 14, 30);
      final entry = WaterLogEntry(id: 'log_1', amountMl: 500, timestamp: now);
      final state = WellnessState.initial().copyWith(waterLogs: [entry]);

      final json = state.toJson();
      final restored = WellnessState.fromJson(json);

      expect(restored.waterLogs.length, equals(1));
      expect(restored.waterLogs.first.amountMl, equals(500));
    });
  });

  group('WellnessNotifier Hydration & Analytics (Tasks 3 & 4)', () {
    test(
      'addWaterLogEntry updates total liters, logs list and recovery score',
      () async {
        final notifier = WellnessNotifier();

        await notifier.addWaterLogEntry(250);
        expect(notifier.state.waterLogs.length, equals(1));
        expect(notifier.state.hydrationLiters, equals(0.25));

        await notifier.addWaterLogEntry(500);
        expect(notifier.state.waterLogs.length, equals(2));
        expect(notifier.state.hydrationLiters, equals(0.75));
      },
    );

    test('deleteWaterLogEntry recalculates total intake correctly', () async {
      final notifier = WellnessNotifier();

      await notifier.addWaterLogEntry(250);
      await notifier.addWaterLogEntry(500);
      expect(notifier.state.hydrationLiters, equals(0.75));

      final firstId = notifier.state.waterLogs.first.id;
      await notifier.deleteWaterLogEntry(firstId);

      expect(notifier.state.waterLogs.length, equals(1));
      expect(notifier.state.hydrationLiters, equals(0.5));
    });

    test('7-Day statistics calculations', () async {
      final notifier = WellnessNotifier();
      final now = DateTime.now();

      await notifier.addWaterLogEntry(1000); // 1.0 L today
      expect(notifier.get7DayTotalLiters(now), equals(1.0));
      expect(notifier.get7DayAverageLiters(now), closeTo(1.0 / 7.0, 0.001));

      final bestDay = notifier.get7DayBestDay(now);
      expect(bestDay.value, equals(1.0));

      // Goal is 2.5 L default
      expect(notifier.get7DayGoalMetCount(now), equals(0));

      // Meet goal today
      await notifier.addWaterLogEntry(1500); // Now 2.5 L total today
      expect(notifier.get7DayGoalMetCount(now), equals(1));
      expect(
        notifier.get7DayWeeklyCompletionPercentage(now),
        closeTo((2.5 / (2.5 * 7)) * 100, 0.01),
      );
    });
  });
}
