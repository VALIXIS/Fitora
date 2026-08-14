import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/features/auth/data/auth_local_data_source.dart';
import 'package:fitora/features/onboarding/data/onboarding_local_data_source.dart';
import 'package:fitora/features/personalization/data/personalization_local_data_source.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPreferences.resetForTests();
  });

  test('persists onboarding completion across restart', () async {
    final onboarding = OnboardingLocalDataSource();

    expect(await onboarding.isCompleted(), isFalse);

    await onboarding.setCompleted(true);

    AppPreferences.resetForTests();
    final reloaded = OnboardingLocalDataSource();

    expect(await reloaded.isCompleted(), isTrue);
  });

  test('persists auth completion across restart', () async {
    final auth = AuthLocalDataSource();

    expect(await auth.isCompleted(), isFalse);

    await auth.setCompleted(true);

    AppPreferences.resetForTests();
    final reloaded = AuthLocalDataSource();

    expect(await reloaded.isCompleted(), isTrue);
  });

  test('persists personalization profile across restart', () async {
    final dataSource = PersonalizationLocalDataSource();
    final profile = PersonalizationProfile(
      goal: PersonalizationGoal.reduceStress,
      workoutPreference: WorkoutPreference.home,
      experienceLevel: ExperienceLevel.beginner,
      interests: {WellnessInterest.sleepTracking, WellnessInterest.mindfulness},
    );

    await dataSource.saveProfile(profile);
    await dataSource.setCompleted(true);

    AppPreferences.resetForTests();

    final reloadedDataSource = PersonalizationLocalDataSource();
    final reloadedProfile = await reloadedDataSource.fetchProfile();

    expect(await reloadedDataSource.isCompleted(), isTrue);
    expect(reloadedProfile?.goal, PersonalizationGoal.reduceStress);
    expect(reloadedProfile?.workoutPreference, WorkoutPreference.home);
    expect(reloadedProfile?.experienceLevel, ExperienceLevel.beginner);
    expect(
      reloadedProfile?.interests,
      containsAll(<WellnessInterest>{
        WellnessInterest.sleepTracking,
        WellnessInterest.mindfulness,
      }),
    );
  });
}
