import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitora/features/wellness/widgets/recovery_gauge_3d.dart';

void main() {
  group('RecoveryTier Unit Tests', () {
    test('80-100% maps to Peak Readiness with Green glow theme', () {
      final tier100 = RecoveryTier.fromScore(100);
      final tier80 = RecoveryTier.fromScore(80);

      expect(tier100, equals(RecoveryTier.peak));
      expect(tier80, equals(RecoveryTier.peak));
      expect(tier100.label, equals('PEAK READINESS'));
      expect(tier100.shortLabel, equals('Peak'));
      expect(tier100.primaryGlow, equals(const Color(0xFF10B981))); // Emerald green
    });

    test('50-79% maps to Moderate Recovery with Amber glow theme', () {
      final tier79 = RecoveryTier.fromScore(79);
      final tier50 = RecoveryTier.fromScore(50);

      expect(tier79, equals(RecoveryTier.moderate));
      expect(tier50, equals(RecoveryTier.moderate));
      expect(tier79.label, equals('MODERATE RECOVERY'));
      expect(tier79.shortLabel, equals('Moderate'));
      expect(tier79.primaryGlow, equals(const Color(0xFFF59E0B))); // Amber
    });

    test('0-49% maps to Rest Day with Blue glow theme', () {
      final tier49 = RecoveryTier.fromScore(49);
      final tier0 = RecoveryTier.fromScore(0);

      expect(tier49, equals(RecoveryTier.restDay));
      expect(tier0, equals(RecoveryTier.restDay));
      expect(tier49.label, equals('REST DAY'));
      expect(tier49.shortLabel, equals('Rest Day'));
      expect(tier49.primaryGlow, equals(const Color(0xFF3B82F6))); // Blue
    });
  });

  group('RecoveryGauge3D Widget Tests', () {
    testWidgets('renders score and peak badge correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RecoveryGauge3D(
                score: 85,
                animatePulse: false,
                sleepContribution: 34,
                stepContribution: 28,
                restingHrContribution: 23,
                sleepLabel: '8h 15m • 94% Quality',
                stepLabel: '10,240 steps',
                restingHrLabel: '56 bpm • Optimal',
              ),
            ),
          ),
        ),
      );

      // Fast forward animations
      await tester.pumpAndSettle();

      // Verify the score and status are present
      expect(find.text('85'), findsOneWidget);
      expect(find.text('%'), findsOneWidget);
      expect(find.text('PEAK'), findsOneWidget);
      expect(find.text('RECOVERY SCORE'), findsOneWidget);

      // Verify breakdown is collapsed initially
      expect(find.text('Readiness Factors Breakdown'), findsNothing);
    });

    testWidgets('tap expands breakdown tooltip with sleep, step, and resting HR metrics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Center(
                child: RecoveryGauge3D(
                  score: 65,
                  animatePulse: false,
                  sleepContribution: 26,
                  stepContribution: 22,
                  restingHrContribution: 17,
                  sleepLabel: '6h 40m • 78% Quality',
                  stepLabel: '7,100 steps',
                  restingHrLabel: '64 bpm',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the gauge dial to toggle the breakdown
      await tester.tap(find.byType(RecoveryGauge3D));
      await tester.pumpAndSettle();

      // Verify breakdown card is displayed
      expect(find.text('Readiness Factors Breakdown'), findsOneWidget);
      expect(find.text('Sleep Duration & Quality'), findsOneWidget);
      expect(find.text('6h 40m • 78% Quality'), findsOneWidget);
      expect(find.text('+26 pts'), findsOneWidget);

      expect(find.text('Movement & Step Target'), findsOneWidget);
      expect(find.text('7,100 steps'), findsOneWidget);
      expect(find.text('+22 pts'), findsOneWidget);

      expect(find.text('Resting HR & Stress Recovery'), findsOneWidget);
      expect(find.text('64 bpm'), findsOneWidget);
      expect(find.text('+17 pts'), findsOneWidget);

      // Tapping close icon collapses the breakdown
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Readiness Factors Breakdown'), findsNothing);
    });

    testWidgets('pan gesture applies 3D tilt interaction', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RecoveryGauge3D(
                score: 42,
                animatePulse: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Perform a pan drag to activate 3D tilt
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(RecoveryGauge3D)),
      );
      await gesture.moveBy(const Offset(30, 40));
      await tester.pump();

      // Verify 3D Tilt HUD is displayed while interacting
      expect(find.text('3D TILT ACTIVE'), findsOneWidget);

      // Conclude gesture and ensure spring-back
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('3D TILT ACTIVE'), findsNothing);
    });

    testWidgets('renders correct accessibility semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RecoveryGauge3D(
                score: 90,
                animatePulse: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp(r'Daily Recovery Score Gauge')),
        findsOneWidget,
      );
    });
  });
}
