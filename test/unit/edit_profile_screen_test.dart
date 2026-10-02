import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/features/profile/screens/edit_profile_screen.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.initialize();
  });

  testWidgets('EditProfileScreen renders avatar, inputs, and unit toggles', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    final container = ProviderContainer();
    final controller = container.read(personalizationControllerProvider.notifier);
    await controller.ensureLoaded();

    controller.updateProfile(
      PersonalizationProfile(
        name: 'Krishna Dev',
        age: 26,
        heightCm: 180,
        weightKg: 75,
        goal: PersonalizationGoal.gainMuscle,
        experienceLevel: ExperienceLevel.intermediate,
        workoutPreference: WorkoutPreference.gym,
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: EditProfileScreen(),
        ),
      ),
    );

    // Initial pump & animation frame
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Title & Initial Name
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Krishna Dev'), findsOneWidget);

    // Verify Avatar Initials "KD"
    expect(find.text('KD'), findsOneWidget);

    // Verify Unit toggles exist
    expect(find.text('cm'), findsOneWidget);
    expect(find.text('ft'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
    expect(find.text('lbs'), findsOneWidget);

    // Verify Save Button at top
    expect(find.text('Save'), findsOneWidget);

    // Toggle weight to lbs
    await tester.tap(find.text('lbs'));
    await tester.pump(const Duration(milliseconds: 200));

    // 75 kg * 2.20462 = 165.3 lbs
    expect(find.text('165.3'), findsOneWidget);

    // Toggle height to ft
    await tester.tap(find.text('ft'));
    await tester.pump(const Duration(milliseconds: 200));

    // 180 cm in feet and inches is 5'11" (5.11)
    expect(find.text('5.11'), findsOneWidget);

    // Unmount and flush to ensure all timers and frames finish cleanly
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 200));

    container.dispose();
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
