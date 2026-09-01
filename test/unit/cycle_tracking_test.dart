import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/features/cycle/domain/cycle_models.dart';
import 'package:fitora/features/cycle/providers/cycle_provider.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AppPreferences.resetForTests();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await AppPreferences.initialize();
  });

  group('Cycle Models Serialization', () {
    test('PeriodRange toJson/fromJson matches', () {
      final range = PeriodRange(
        id: '123',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 5),
        notes: 'Normal flow',
      );

      final json = range.toJson();
      expect(json['startDate'], equals('2026-08-01'));
      expect(json['endDate'], equals('2026-08-05'));

      final parsed = PeriodRange.fromJson(json);
      expect(parsed.id, equals('123'));
      expect(parsed.startDate, equals(DateTime(2026, 8, 1)));
      expect(parsed.endDate, equals(DateTime(2026, 8, 5)));
      expect(parsed.notes, equals('Normal flow'));
    });

    test('PeriodDayData toJson/fromJson matches', () {
      final dayData = PeriodDayData(
        date: DateTime(2026, 8, 3),
        flow: FlowLevel.medium,
        symptoms: const [CycleSymptom.cramps, CycleSymptom.bloating],
        notes: 'Evening cramps',
      );

      final json = dayData.toJson();
      expect(json['date'], equals('2026-08-03'));
      expect(json['flow'], equals('medium'));
      expect((json['symptoms'] as List).contains('cramps'), isTrue);

      final parsed = PeriodDayData.fromJson(json);
      expect(parsed.date, equals(DateTime(2026, 8, 3)));
      expect(parsed.flow, equals(FlowLevel.medium));
      expect(parsed.symptoms, contains(CycleSymptom.cramps));
      expect(parsed.symptoms, contains(CycleSymptom.bloating));
      expect(parsed.notes, equals('Evening cramps'));
    });
  });

  group('Date Boundary & Local Parsing Rules', () {
    test('parseLocalDate and formatLocalDate are timezone independent', () {
      final dateStr = '2028-02-29'; // leap year date
      final date = parseLocalDate(dateStr);
      expect(date.year, equals(2028));
      expect(date.month, equals(2));
      expect(date.day, equals(29));

      final formatted = formatLocalDate(date);
      expect(formatted, equals(dateStr));
    });

    test('Leap year transitions and month/year boundaries', () {
      // 2028 is a leap year. Feb 28 to March 1 should span 2 days in a leap year
      final feb28 = DateTime(2028, 2, 28);
      final mar1 = DateTime(2028, 3, 1);
      expect(mar1.difference(feb28).inDays, equals(2));

      // Dec 31 to Jan 1 transition
      final dec31 = DateTime(2027, 12, 31);
      final jan1 = DateTime(2028, 1, 1);
      expect(jan1.difference(dec31).inDays, equals(1));
    });
  });

  group('Cycle Calculations and Predictions', () {
    test('Insufficient intervals (0 or 1) does not provide estimates', () async {
      final container = ProviderContainer();
      final notifier = container.read(cycleProvider.notifier);
      await notifier.loadFuture;

      // 0 completed intervals
      expect(notifier.getEstimatedNextPeriod(), isNull);
      expect(notifier.getStatistics().completedIntervalsCount, equals(0));

      // 1 completed interval (2 period start dates logged)
      await notifier.startPeriod(DateTime(2026, 6, 1));
      // End ongoing period first to allow clean logging
      await notifier.endPeriod(DateTime(2026, 6, 5));
      await notifier.startPeriod(DateTime(2026, 6, 29));
      
      expect(notifier.getEstimatedNextPeriod(), isNull);
      expect(notifier.getStatistics().completedIntervalsCount, equals(1));
    });

    test('At least 2 completed cycle intervals provides deterministic prediction', () async {
      final container = ProviderContainer();
      final notifier = container.read(cycleProvider.notifier);
      await notifier.loadFuture;

      // Period 1
      final r1 = await notifier.startPeriod(DateTime(2026, 6, 1));
      final r2 = await notifier.endPeriod(DateTime(2026, 6, 5));

      // Period 2 (Interval 1: 28 days)
      final r3 = await notifier.startPeriod(DateTime(2026, 6, 29));
      final r4 = await notifier.endPeriod(DateTime(2026, 7, 3));

      // Period 3 (Interval 2: 29 days)
      await notifier.startPeriod(DateTime(2026, 7, 28));

      final stats = notifier.getStatistics();
      expect(stats.completedIntervalsCount, equals(2));
      expect(stats.averageCycleLength, equals(28.5)); // (28 + 29) / 2
      expect(stats.averagePeriodDuration, equals(5.0)); // Completed ranges are 5 days

      // Next estimate is latest (July 28) + rounded average (29) = August 26
      final estimate = notifier.getEstimatedNextPeriod();
      expect(estimate, equals(DateTime(2026, 8, 26)));
    });

    test('Rolling calculations uses up to the most recent 3 completed intervals only', () async {
      final container = ProviderContainer();
      final notifier = container.read(cycleProvider.notifier);
      await notifier.loadFuture;

      // Log 5 periods -> 4 completed cycle intervals: 28d, 29d, 30d, 31d
      final r1 = await notifier.startPeriod(DateTime(2026, 1, 1));
      final r2 = await notifier.endPeriod(DateTime(2026, 1, 5));

      final r3 = await notifier.startPeriod(DateTime(2026, 1, 29)); // diff = 28d
      final r4 = await notifier.endPeriod(DateTime(2026, 2, 2));

      final r5 = await notifier.startPeriod(DateTime(2026, 2, 27)); // diff = 29d
      final r6 = await notifier.endPeriod(DateTime(2026, 3, 3));

      final r7 = await notifier.startPeriod(DateTime(2026, 3, 29)); // diff = 30d
      final r8 = await notifier.endPeriod(DateTime(2026, 4, 2));

      await notifier.startPeriod(DateTime(2026, 4, 29)); // diff = 31d
      
      final stats = notifier.getStatistics();
      // Total completed intervals = 4
      expect(stats.completedIntervalsCount, equals(4));
      // Rolling average should use last 3: 29d, 30d, 31d -> mean = 30.0
      expect(stats.averageCycleLength, equals(30.0));
      
      final estimate = notifier.getEstimatedNextPeriod();
      // Latest start (April 29) + 30 days = May 29
      expect(estimate, equals(DateTime(2026, 5, 29)));
    });
  });

  group('Cycle Day Tracker and Status Rules', () {
    test('Cycle Day 1 starts on period start date and increments', () async {
      final container = ProviderContainer();
      final notifier = container.read(cycleProvider.notifier);
      await notifier.loadFuture;

      await notifier.startPeriod(DateTime(2026, 8, 1));
      expect(notifier.getCycleDay(DateTime(2026, 8, 1)), equals(1));
      expect(notifier.getCycleDay(DateTime(2026, 8, 2)), equals(2));
      expect(notifier.getCycleDay(DateTime(2026, 8, 10)), equals(10));
    });

    test('Cycle Day resets to 1 upon new period start', () async {
      final container = ProviderContainer();
      final notifier = container.read(cycleProvider.notifier);
      await notifier.loadFuture;

      await notifier.startPeriod(DateTime(2026, 8, 1));
      await notifier.endPeriod(DateTime(2026, 8, 5));
      await notifier.startPeriod(DateTime(2026, 8, 29));

      expect(notifier.getCycleDay(DateTime(2026, 8, 28)), equals(28));
      expect(notifier.getCycleDay(DateTime(2026, 8, 29)), equals(1));
      expect(notifier.getCycleDay(DateTime(2026, 8, 30)), equals(2));
    });
  });

  group('Non-Silent Conflict Resolution', () {
    test('Attempting to start a period when another is ongoing returns false (conflict)', () async {
      final container = ProviderContainer();
      final notifier = container.read(cycleProvider.notifier);
      await notifier.loadFuture;

      await notifier.startPeriod(DateTime(2026, 8, 1));
      
      // Attempt another start without resolving conflict
      final success = await notifier.startPeriod(DateTime(2026, 8, 25));
      expect(success, isFalse);
      expect(notifier.getOngoingPeriod()!.startDate, equals(DateTime(2026, 8, 1)));
    });

    test('Resolving conflict explicitly closes previous period yesterday and starts new one', () async {
      final container = ProviderContainer();
      final notifier = container.read(cycleProvider.notifier);
      await notifier.loadFuture;

      await notifier.startPeriod(DateTime(2026, 8, 1));
      
      // Resolve conflict explicitly
      await notifier.resolveConflictAndStartPeriod(DateTime(2026, 8, 25));

      final ranges = container.read(cycleProvider).periodRanges;
      expect(ranges.length, equals(2));
      
      // Previous period ended on Aug 24
      expect(ranges[0].startDate, equals(DateTime(2026, 8, 1)));
      expect(ranges[0].endDate, equals(DateTime(2026, 8, 24)));
      
      // New period started on Aug 25 (ongoing)
      expect(ranges[1].startDate, equals(DateTime(2026, 8, 25)));
      expect(ranges[1].endDate, isNull);
    });

    test('Overlapping closed periods is rejected by validation', () async {
      final container = ProviderContainer();
      final notifier = container.read(cycleProvider.notifier);
      await notifier.loadFuture;

      await notifier.startPeriod(DateTime(2026, 8, 1));
      await notifier.endPeriod(DateTime(2026, 8, 5));

      // Attempt overlap: starts inside Aug 1-5 range
      final success = await notifier.startPeriod(DateTime(2026, 8, 3));
      expect(success, isFalse);
    });
  });

  group('Daily Symptom Logs', () {
    test('Saving and clearing logs updates notifier state', () async {
      final container = ProviderContainer();
      final notifier = container.read(cycleProvider.notifier);
      await notifier.loadFuture;

      final date = DateTime(2026, 8, 10);
      await notifier.logDay(
        date,
        flow: FlowLevel.heavy,
        symptoms: [CycleSymptom.cramps, CycleSymptom.backPain],
        notes: 'Very tired',
      );

      final log = container.read(cycleProvider).dayLogs[formatLocalDate(date)]!;
      expect(log.flow, equals(FlowLevel.heavy));
      expect(log.symptoms, contains(CycleSymptom.cramps));
      expect(log.symptoms, contains(CycleSymptom.backPain));
      expect(log.notes, equals('Very tired'));

      // Clear the log
      await notifier.logDay(date, flow: null, symptoms: [], notes: '');
      expect(container.read(cycleProvider).dayLogs.containsKey(formatLocalDate(date)), isFalse);
    });
  });

  group('Onboarding Opt-In and Upgrades', () {
    test('Onboarding opting in enables cycle tracking and reminders', () async {
      final container = ProviderContainer();
      final personalController = container.read(personalizationControllerProvider.notifier);
      await personalController.ensureLoaded();

      // Set interest
      personalController.toggleInterest(WellnessInterest.cycleTracking);
      
      // Complete personalization
      await personalController.completePersonalization();

      // Verify Cycle tracking is enabled
      final cycleState = container.read(cycleProvider);
      expect(cycleState.cycleTrackingEnabled, isTrue);
      expect(cycleState.remindersEnabled, isTrue);
    });

    test('Onboarding opting out disables cycle tracking and reminders', () async {
      final container = ProviderContainer();
      final personalController = container.read(personalizationControllerProvider.notifier);
      await personalController.ensureLoaded();

      // Do NOT set cycle tracking interest
      await personalController.completePersonalization();

      // Verify Cycle tracking is disabled
      final cycleState = container.read(cycleProvider);
      expect(cycleState.cycleTrackingEnabled, isFalse);
      expect(cycleState.remindersEnabled, isFalse);
    });

    test('Cycle disabled later preserves history but cancels reminders', () async {
      final container = ProviderContainer();
      final cycleNotifier = container.read(cycleProvider.notifier);
      await cycleNotifier.loadFuture;

      // Add a period start
      await cycleNotifier.startPeriod(DateTime(2026, 8, 1));
      
      // Disable cycle tracking
      await cycleNotifier.toggleCycleTracking(false);
      await cycleNotifier.toggleReminders(false);

      final state = container.read(cycleProvider);
      expect(state.cycleTrackingEnabled, isFalse);
      expect(state.remindersEnabled, isFalse);
      // History is preserved
      expect(state.periodRanges, isNotEmpty);
    });

    test('Cycle re-enabled later restores card and reminders', () async {
      final container = ProviderContainer();
      final cycleNotifier = container.read(cycleProvider.notifier);
      await cycleNotifier.loadFuture;

      // Setup and disable
      await cycleNotifier.startPeriod(DateTime(2026, 8, 1));
      await cycleNotifier.toggleCycleTracking(false);

      // Re-enable
      await cycleNotifier.toggleCycleTracking(true);

      final state = container.read(cycleProvider);
      expect(state.cycleTrackingEnabled, isTrue);
      expect(state.periodRanges, isNotEmpty);
    });

    test('Existing upgraded user defaults to false without opt-in', () async {
      final container = ProviderContainer();
      final cycleNotifier = container.read(cycleProvider.notifier);
      await cycleNotifier.loadFuture;

      // No settings stored and no cycle tracking interest selected
      final state = container.read(cycleProvider);
      expect(state.cycleTrackingEnabled, isFalse);
      expect(state.remindersEnabled, isFalse);
    });
  });
}
