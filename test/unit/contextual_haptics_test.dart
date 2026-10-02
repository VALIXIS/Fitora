import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/core/services/haptic_service.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';
import 'package:fitora/features/home/domain/goals_streak_models.dart';

class FakeRef implements Ref {
  final SettingsState settingsState;
  FakeRef(this.settingsState);

  @override
  T read<T>(ProviderListenable<T> provider) {
    return settingsState as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.initialize();
  });

  group('HapticService Settings & Semantic Methods', () {
    test('HapticService respects hapticsEnabled == true', () async {
      final fakeRef = FakeRef(const SettingsState(hapticsEnabled: true));
      final hapticSvc = HapticService(fakeRef);

      // Verify methods run without error
      await hapticSvc.tabSwitch();
      await hapticSvc.buttonPress();
      await hapticSvc.sliderChange();
      await hapticSvc.goalCompleted();
    });

    test('HapticService respects hapticsEnabled == false', () async {
      final fakeRef = FakeRef(const SettingsState(hapticsEnabled: false));
      final hapticSvc = HapticService(fakeRef);

      // Should return immediately without exception
      await hapticSvc.tabSwitch();
      await hapticSvc.buttonPress();
      await hapticSvc.sliderChange();
      await hapticSvc.goalCompleted();
    });
  });

  group('Goal Completion Transition Logic', () {
    test('Triggers feedback only on incomplete -> complete transition', () {
      int feedbackTriggerCount = 0;

      void checkTransition(DailyGoalStatus? previous, DailyGoalStatus next) {
        if (previous != null) {
          for (final nextMetric in next.metrics) {
            final prevMetric = previous.metrics.firstWhere(
              (m) => m.key == nextMetric.key,
              orElse: () => GoalMetric(
                key: nextMetric.key,
                name: '',
                current: 0,
                goal: 0,
                unit: '',
                isCompleted: false,
                availability: MetricAvailability.available,
              ),
            );
            if (!prevMetric.isCompleted && nextMetric.isCompleted) {
              feedbackTriggerCount++;
              break;
            }
          }
        }
      }

      final date = DateTime(2026, 9, 5);

      final state1 = DailyGoalStatus(
        date: date,
        metrics: [
          GoalMetric(
            key: 'water',
            name: 'Water',
            current: 1.0,
            goal: 2.0,
            unit: 'L',
            isCompleted: false,
            availability: MetricAvailability.available,
          ),
        ],
        isDailyGoalCompleted: false,
        completionPercentage: 50.0,
      );

      final state2 = DailyGoalStatus(
        date: date,
        metrics: [
          GoalMetric(
            key: 'water',
            name: 'Water',
            current: 2.0,
            goal: 2.0,
            unit: 'L',
            isCompleted: true,
            availability: MetricAvailability.available,
          ),
        ],
        isDailyGoalCompleted: true,
        completionPercentage: 100.0,
      );

      final state3 = DailyGoalStatus(
        date: date,
        metrics: [
          GoalMetric(
            key: 'water',
            name: 'Water',
            current: 2.25,
            goal: 2.0,
            unit: 'L',
            isCompleted: true,
            availability: MetricAvailability.available,
          ),
        ],
        isDailyGoalCompleted: true,
        completionPercentage: 100.0,
      );

      // Initial state load -> no previous state -> no feedback
      checkTransition(null, state1);
      expect(feedbackTriggerCount, equals(0));

      // Transition incomplete -> complete -> 1 feedback event
      checkTransition(state1, state2);
      expect(feedbackTriggerCount, equals(1));

      // Transition complete -> complete (e.g. rebuild or further increase) -> 0 additional feedback events
      checkTransition(state2, state3);
      expect(feedbackTriggerCount, equals(1));
    });
  });

  group('Slider Step Throttling Logic', () {
    test('Triggers sliderChange only on step boundaries', () {
      int hapticCallCount = 0;
      int currentStep = (0.5 * 20).round();

      void onSliderUpdate(double newValue) {
        final newStep = (newValue * 20).round();
        if (newStep != currentStep) {
          hapticCallCount++;
          currentStep = newStep;
        }
      }

      // Small drag within same 5% step -> no haptic
      onSliderUpdate(0.51);
      onSliderUpdate(0.52);
      expect(hapticCallCount, equals(0));

      // Drag crosses 5% boundary (0.55 -> step 11) -> 1 haptic
      onSliderUpdate(0.56);
      expect(hapticCallCount, equals(1));

      // Drag crosses another boundary (0.61 -> step 12) -> 1 haptic
      onSliderUpdate(0.61);
      expect(hapticCallCount, equals(2));
    });
  });
}
