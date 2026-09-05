import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitora/features/progress/domain/shareable_milestone_models.dart';
import 'package:fitora/features/progress/widgets/shareable_milestone_card.dart';
import 'package:fitora/core/services/shareable_image_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShareableMilestoneData Domain Tests', () {
    test('streak7Day factory initializes fields correctly', () {
      final data = ShareableMilestoneData.streak7Day(
        streakDays: 7,
        totalSteps: 59500,
        userName: 'Aditya',
      );

      expect(data.type, equals(ShareableMilestoneType.sevenDayStreak));
      expect(data.title, equals('7-DAY STEP STREAK'));
      expect(data.metricValue, equals('59.5k'));
      expect(data.metricUnit, equals('TOTAL STEPS LOGGED'));
      expect(data.userName, equals('Aditya'));
      expect(data.accentColor, equals(const Color(0xFFFF9500)));
    });

    test('achievement factory initializes fields correctly', () {
      final data = ShareableMilestoneData.achievement(
        title: 'Step Master',
        description: 'Walked 10,000 steps in a single day',
        icon: Icons.directions_walk_rounded,
        accentColor: const Color(0xFF00E5A3),
        userName: 'Aditya',
      );

      expect(data.type, equals(ShareableMilestoneType.achievementBadge));
      expect(data.title, equals('STEP MASTER'));
      expect(data.subtitle, equals('Walked 10,000 steps in a single day'));
      expect(data.metricValue, equals('UNLOCKED'));
      expect(data.metricUnit, equals('ACHIEVEMENT BADGE'));
    });
  });

  group('ShareableMilestoneCardWidget Widget Tests', () {
    testWidgets('renders 9:16 aspect ratio milestone card', (tester) async {
      final milestoneData = ShareableMilestoneData.streak7Day(
        streakDays: 7,
        totalSteps: 60000,
        userName: 'Warrior',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ShareableMilestoneCardWidget(
                data: milestoneData,
                width: 360.0,
              ),
            ),
          ),
        ),
      );

      // Verify widget elements rendered
      expect(find.text('FITORA'), findsOneWidget);
      expect(find.text('7-DAY STEP STREAK'), findsOneWidget);
      expect(find.text('60.0k'), findsOneWidget);
      expect(find.text('POWERED BY FITORA AI  •  ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'), findsOneWidget);

      // Verify 9:16 aspect ratio height (360 * 16 / 9 = 640)
      final size = tester.getSize(find.byType(ShareableMilestoneCardWidget));
      expect(size.width, equals(360.0));
      expect(size.height, equals(640.0));
    });

    testWidgets('RepaintBoundary wraps milestone card in share modal', (tester) async {
      final milestoneData = ShareableMilestoneData.achievement(
        title: 'Hydration Hero',
        description: 'Met hydration goal for 7 consecutive days',
        icon: Icons.water_drop_rounded,
        accentColor: const Color(0xFF00E5A3),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => ShareableImageService.showMilestoneShareModal(
                    context,
                    milestoneData,
                  ),
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      // Tap button to open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Verify share modal UI components
      expect(find.text('SHARE MILESTONE'), findsOneWidget);
      expect(find.text('SHARE TO STORY / STATUS'), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });
  });
}
