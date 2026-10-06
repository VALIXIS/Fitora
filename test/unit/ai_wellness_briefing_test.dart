import 'package:flutter_test/flutter_test.dart';
import 'package:fitora/features/ai_coach/domain/ai_coach_models.dart';
import 'package:fitora/features/ai_coach/services/ai_coach_service.dart';

void main() {
  group('FIT-09 AI Wellness Briefing Verification Tests', () {
    late AICoachService service;

    setUp(() {
      service = AICoachService();
    });

    test('TEST 1: Valid high-recovery health metrics pipeline', () async {
      final briefing = await service.generateDailyBriefing(
        sleepHours: 7.5,
        stepsCount: 8200,
        restingHeartRate: 62,
        recoveryScore: 88,
      );

      expect(briefing.summary, contains('88%'));
      expect(briefing.tips.length, equals(3));
      expect(briefing.tips[2], contains('Capitalize on high readiness'));
    });

    test('TEST 2: Low recovery scenario changes briefing and tips dynamically', () async {
      final briefing = await service.generateDailyBriefing(
        sleepHours: 5.5,
        stepsCount: 3500,
        restingHeartRate: 78,
        recoveryScore: 45,
      );

      expect(briefing.summary, contains('45%'));
      expect(briefing.tips.length, equals(3));
      expect(briefing.tips[0], contains('Pay back sleep debt'));
      expect(briefing.tips[1], contains('Lower cardiovascular strain'));
      expect(briefing.tips[2], contains('Active recovery focus'));
    });

    test('TEST 3: Fallback briefing generator produces valid 3-tip object', () {
      final briefing = service.generateOfflineFallbackBriefing(
        sleepHours: 6.8,
        stepsCount: 9100,
        restingHeartRate: 68,
        recoveryScore: 75,
      );

      expect(briefing.isOfflineFallback, isTrue);
      expect(briefing.tips.length, equals(3));
      expect(briefing.summary, isNotEmpty);
    });

    test('TEST 4: DailyBriefing model serialization (toJson / fromJson)', () {
      final briefing = DailyBriefing(
        summary: 'Test summary briefing',
        tips: const ['Tip 1', 'Tip 2', 'Tip 3'],
        generatedAt: DateTime(2026, 10, 5, 8, 0),
        isOfflineFallback: true,
      );

      final json = briefing.toJson();
      final restored = DailyBriefing.fromJson(json);

      expect(restored.summary, equals('Test summary briefing'));
      expect(restored.tips, equals(['Tip 1', 'Tip 2', 'Tip 3']));
      expect(restored.isOfflineFallback, isTrue);
    });
  });
}
