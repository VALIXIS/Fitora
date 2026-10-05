import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/features/gamification/domain/gamification_models.dart';
import 'package:fitora/features/gamification/providers/gamification_provider.dart';
import 'package:fitora/features/gamification/widgets/badge_3d_card.dart';
import 'package:fitora/features/gamification/screens/badges_screen.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';
import 'package:fitora/core/services/haptic_service.dart';

class _FakeGamificationNotifier extends StateNotifier<GamificationState>
    implements GamificationNotifier {
  _FakeGamificationNotifier()
      : super(
          GamificationState(
            streakState: StreakState.initial(),
            badges: GamificationNotifier.defaultBadges,
          ),
        );

  @override
  void checkBadges() {}

  @override
  void checkStreaksAndBadges() {}

  @override
  void updateStreak({int? currentStepStreak, int? currentWaterStreak, int? longestStreak}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.initialize();
  });

  group('Badge3DCard Component Tests', () {
    testWidgets('renders unlocked milestone badge with 3D styling and metallic details',
        (tester) async {
      final badge = AchievementBadge(
        id: 'streak_7',
        title: '7-Day Step Warrior',
        description: 'Achieve a 7-day daily step or activity streak',
        iconType: 'streak_7',
        category: 'streak',
        isUnlocked: true,
        unlockedAt: DateTime(2026, 10, 1, 14, 30),
        tier: 'gold',
        statRequirement: '7-Day Streak',
        currentProgress: '7 / 7 days',
        progressRatio: 1.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Badge3DCard(
                badge: badge,
                animateShine: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verifies title and tier render correctly
      expect(find.text('7-Day Step Warrior'), findsOneWidget);
      expect(find.text('GOLD'), findsOneWidget);
      expect(find.text('TAP FOR STATS'), findsOneWidget);
      expect(find.byIcon(Icons.military_tech_rounded), findsOneWidget);
    });

    testWidgets('renders locked badge with padlock icon and progress stats',
        (tester) async {
      const badge = AchievementBadge(
        id: 'water_2l',
        title: '2L Water Champion',
        description: 'Reach 2.0 Liters or more of hydration in a single day',
        iconType: 'water_2l',
        category: 'water',
        isUnlocked: false,
        tier: 'emerald',
        statRequirement: '2.0L Daily Hydration',
        currentProgress: '1.2L / 2.0L',
        progressRatio: 0.6,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Badge3DCard(
                badge: badge,
                animateShine: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('2L Water Champion'), findsOneWidget);
      expect(find.text('2.0L Daily Hydration'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.text('TAP FOR STATS'), findsOneWidget);
    });

    testWidgets('responds to drag gestures with 3D tilt perspective without error',
        (tester) async {
      final badge = AchievementBadge(
        id: 'sleep_8h',
        title: '8h Sleep Champion',
        description: 'Log 8 or more hours of restful, high-quality sleep',
        iconType: 'sleep_8h',
        category: 'sleep',
        isUnlocked: true,
        unlockedAt: DateTime.now(),
        tier: 'diamond',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Badge3DCard(
                badge: badge,
                animateShine: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Pan/drag gesture on card to trigger 3D perspective matrix tilt
      final cardFinder = find.byType(Badge3DCard);
      expect(cardFinder, findsOneWidget);

      await tester.drag(cardFinder, const Offset(30, 40));
      await tester.pump(const Duration(milliseconds: 50));

      // Release drag to trigger tilt spring-back physics
      await tester.pump(const Duration(milliseconds: 400));
      expect(cardFinder, findsOneWidget);
    });

    testWidgets('tapping card flips to back view revealing milestone details and unlock date',
        (tester) async {
      final badge = AchievementBadge(
        id: 'streak_7',
        title: '7-Day Step Warrior',
        description: 'Achieve a 7-day daily step or activity streak',
        iconType: 'streak_7',
        category: 'streak',
        isUnlocked: true,
        unlockedAt: DateTime(2026, 10, 1),
        tier: 'gold',
        statRequirement: '7-Day Streak',
        currentProgress: '7 / 7 days',
        progressRatio: 1.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Badge3DCard(
                badge: badge,
                animateShine: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Tap on card to flip
      await tester.tap(find.byType(Badge3DCard));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Back side should reveal requirement, date, and share action
      expect(find.text('Milestone Stat'), findsOneWidget);
      expect(find.text('7 / 7 days'), findsOneWidget);
      expect(find.text('UNLOCKED'), findsOneWidget);
      expect(find.text('Share Trophy'), findsOneWidget);

      // Tap again to flip back to front
      await tester.tap(find.byType(Badge3DCard));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('TAP FOR STATS'), findsOneWidget);
    });
  });

  group('BadgesScreen 3D Trophy Shelf Tests', () {
    testWidgets('renders Trophy Shelf with rank banner, categories, and pedestals',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          gamificationProvider.overrideWith((ref) => _FakeGamificationNotifier()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: BadgesScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Shelf title
      expect(find.text('Trophy Shelf'), findsOneWidget);

      // Rank showcase banner
      expect(find.text('3D WELLNESS SHELF'), findsOneWidget);

      // Category filters
      expect(find.text('All Trophies'), findsOneWidget);
      expect(find.text('Streaks'), findsOneWidget);
      expect(find.text('Sleep'), findsOneWidget);
      expect(find.text('Hydration'), findsOneWidget);
      expect(find.text('Movement'), findsOneWidget);

      // Milestone badges rendered on pedestals
      expect(find.text('7-Day Step Warrior'), findsOneWidget);
      expect(find.text('8h Sleep Champion'), findsOneWidget);
    });

    testWidgets('category chip selection filters badges properly',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          gamificationProvider.overrideWith((ref) => _FakeGamificationNotifier()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: BadgesScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Select 'Streaks' category chip
      final streaksChip = find.text('Streaks');
      expect(streaksChip, findsOneWidget);
      await tester.tap(streaksChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 7-Day Step Warrior should be visible, 8h Sleep Champion should be filtered out
      expect(find.text('7-Day Step Warrior'), findsOneWidget);
      expect(find.text('8h Sleep Champion'), findsNothing);
    });

    testWidgets('celebration icon triggers celebration without exception',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          gamificationProvider.overrideWith((ref) => _FakeGamificationNotifier()),
          hapticServiceProvider.overrideWithValue(HapticService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: BadgesScreen(),
          ),
        ),
      );

      await tester.pump();

      final celebrationBtn = find.byTooltip('Celebrate Milestone Explosion');
      expect(celebrationBtn, findsOneWidget);
      await tester.tap(celebrationBtn);
      // Pump past confetti controller duration (2s)
      await tester.pump(const Duration(seconds: 3));
      // Unmount BadgesScreen so its controllers dispose cleanly
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('GamificationNotifier Milestone Badge Automation', () {
    test('unlocks 7-day step streak badge when streak reaches 7', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gamificationProvider.notifier);

      notifier.updateStreak(
        currentStepStreak: 7,
        longestStreak: 7,
      );

      final state = container.read(gamificationProvider);
      final streak7 = state.badges.firstWhere((b) => b.id == 'streak_7');
      expect(streak7.isUnlocked, isTrue);
      expect(streak7.unlockedAt, isNotNull);
      expect(streak7.currentProgress, equals('7 / 7 days'));
      expect(streak7.progressRatio, equals(1.0));
    });

    test('unlocks 8h sleep streak badge when sleep entry >= 8h (480 mins)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final wellnessNotifier = container.read(wellnessProvider.notifier);
      await wellnessNotifier.logSleep(minutes: 510, qualityScore: 90);

      final gamificationNotifier = container.read(gamificationProvider.notifier);
      gamificationNotifier.checkStreaksAndBadges();

      final state = container.read(gamificationProvider);
      final sleepBadge = state.badges.firstWhere((b) => b.id == 'sleep_8h');
      expect(sleepBadge.isUnlocked, isTrue);
      expect(sleepBadge.unlockedAt, isNotNull);
      expect(sleepBadge.progressRatio, equals(1.0));
    });

    test('unlocks 2L water badge when hydration reaches 2.0 liters', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final wellnessNotifier = container.read(wellnessProvider.notifier);
      await wellnessNotifier.addWaterLogEntry(2500);

      final gamificationNotifier = container.read(gamificationProvider.notifier);
      gamificationNotifier.checkStreaksAndBadges();

      final state = container.read(gamificationProvider);
      final waterBadge = state.badges.firstWhere((b) => b.id == 'water_2l');
      expect(waterBadge.isUnlocked, isTrue);
      expect(waterBadge.unlockedAt, isNotNull);
      expect(waterBadge.progressRatio, equals(1.0));
    });
  });
}
