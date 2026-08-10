import 'package:flutter_test/flutter_test.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Water Logging - Add, Delete, and Goal Progress Clamping', () async {
    final notifier = WellnessNotifier();
    await notifier.load();

    expect(notifier.state.hydrationLiters, 0.0);
    expect(notifier.state.waterLogs.isEmpty, true);

    // 1. Add 250 ml
    await notifier.addWaterLogEntry(amountMl: 250);
    expect(notifier.state.hydrationLiters, 0.25);
    expect(notifier.state.waterLogs.length, 1);
    expect(notifier.state.waterLogs.first.amountMl, 250);

    // 2. Add 500 ml
    await notifier.addWaterLogEntry(amountMl: 500);
    expect(notifier.state.hydrationLiters, 0.75);
    expect(notifier.state.waterLogs.length, 2);

    // 3. Delete the 250 ml entry
    final firstId = notifier.state.waterLogs.last.id;
    await notifier.deleteWaterLogEntry(firstId);
    expect(notifier.state.hydrationLiters, 0.5);
    expect(notifier.state.waterLogs.length, 1);

    // 4. Test exceeding goal clamping in UI logic
    await notifier.addWaterLogEntry(amountMl: 3000); // Total 3500 ml = 3.5 L
    expect(notifier.state.hydrationLiters, 3.5);

    final goal = notifier.state.hydrationGoalLiters; // default 2.5 L
    final progress = goal > 0 ? (notifier.state.hydrationLiters / goal).clamp(0.0, 1.0) : 0.0;
    expect(progress, 1.0);
  });
}
