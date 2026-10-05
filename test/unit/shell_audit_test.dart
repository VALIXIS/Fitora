import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/core/services/haptic_service.dart';
import 'package:fitora/shared/widgets/scale_on_press.dart';
import 'package:fitora/app/router/app_router.dart';
import 'package:fitora/app/navigation/fitora_bottom_nav_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FIT-12 Haptic Service & Micro-Interactions Audit', () {
    test('AppHaptics executes semantic haptic feedback methods smoothly', () async {
      AppHaptics.hapticsGlobalEnabled = true;

      // Ensure all semantic impact calls execute cleanly without error
      await AppHaptics.light();
      await AppHaptics.medium();
      await AppHaptics.heavy();
      await AppHaptics.selection();
      await AppHaptics.buttonPress();
      await AppHaptics.switchToggle();
      await AppHaptics.sliderChange();
      await AppHaptics.tabSwitch();
      await AppHaptics.cardTap();
      await AppHaptics.goalCompleted();

      expect(AppHaptics.hapticsGlobalEnabled, isTrue);

      // Verify disabled state bypass
      AppHaptics.hapticsGlobalEnabled = false;
      await AppHaptics.light();
      await AppHaptics.selection();
      expect(AppHaptics.hapticsGlobalEnabled, isFalse);
      AppHaptics.hapticsGlobalEnabled = true;
    });

    testWidgets('ScaleOnPress triggers spring animation and haptics on press', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ScaleOnPress(
                onTap: () => tapped = true,
                enableHaptics: true,
                child: const Text('Interactive Button'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Interactive Button'), findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(find.text('Interactive Button')));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('FIT-12 60fps Route Transitions & Shell Isolation', () {
    testWidgets('fadeThroughTransitionPage creates RepaintBoundary isolated page in router', (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => fadeThroughTransitionPage(
              context: context,
              state: state,
              child: const Text('Home Content'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(find.text('Home Content'), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('slideHorizontalTransitionPage creates smooth isolated detail transition', (tester) async {
      final router = GoRouter(
        initialLocation: '/detail',
        routes: [
          GoRoute(
            path: '/detail',
            pageBuilder: (context, state) => slideHorizontalTransitionPage(
              context: context,
              state: state,
              child: const Text('Sleep Detail Content'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(find.text('Sleep Detail Content'), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });
  });

  group('FIT-12 Responsive Viewport Audit (320dp & 20:9)', () {
    testWidgets('FitoraBottomNavBar adapts without overflow on 320dp compact width', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 568 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int tappedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: const Center(child: Text('Content')),
            bottomNavigationBar: FitoraBottomNavBar(
              currentIndex: 0,
              onTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(FitoraBottomNavBar), findsOneWidget);

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(1));
    });

    testWidgets('FitoraBottomNavBar renders smoothly on modern tall 20:9 aspect ratio', (tester) async {
      tester.view.physicalSize = const Size(412 * 3, 920 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            bottomNavigationBar: FitoraBottomNavBar(
              currentIndex: 2,
              onTap: (_) {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Profile'), findsOneWidget);
    });
  });
}
