import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../wellness/providers/wellness_provider.dart';
import '../../wellness/domain/wellness_models.dart';
import '../../wellness_engine/providers/wellness_engine_provider.dart';
import '../../wellness_engine/domain/wellness_engine_models.dart';
import '../../health_sync/providers/health_sync_provider.dart';
import '../../health_sync/domain/health_sync_models.dart';
import '../domain/ai_coach_models.dart';
import '../services/ai_coach_service.dart';

class AICoachState {
  final List<CoachMessage> messages;
  final AICoachMood mood;
  final WeeklySummary weeklySummary;
  final List<WellnessTrend> trends;
  final bool isLoading;

  const AICoachState({
    required this.messages,
    required this.mood,
    required this.weeklySummary,
    required this.trends,
    this.isLoading = false,
  });

  AICoachState copyWith({
    List<CoachMessage>? messages,
    AICoachMood? mood,
    WeeklySummary? weeklySummary,
    List<WellnessTrend>? trends,
    bool? isLoading,
  }) {
    return AICoachState(
      messages: messages ?? this.messages,
      mood: mood ?? this.mood,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      trends: trends ?? this.trends,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final aiCoachProvider = StateNotifierProvider<AICoachNotifier, AICoachState>((ref) {
  final wellness = ref.watch(wellnessProvider);
  final engine = ref.watch(wellnessEngineProvider);
  final health = ref.watch(healthSyncProvider);
  return AICoachNotifier(wellness, engine, health)..init();
});

class AICoachNotifier extends StateNotifier<AICoachState> {
  final WellnessState _wellness;
  final WellnessEngineState _engine;
  final HealthSyncState _health;
  final AICoachService _service = AICoachService();

  AICoachNotifier(this._wellness, this._engine, this._health)
      : super(AICoachState(
          messages: [],
          mood: AICoachMood.idle,
          weeklySummary: WeeklySummary.defaults(),
          trends: const [],
        ));

  void init() {
    if (state.messages.isNotEmpty) return;

    // Load trends
    final trends = _service.generateWeeklyTrends();

    // Set initial welcoming message
    final welcome = CoachMessage(
      id: 'welcome_msg',
      sender: 'coach',
      content: 'Hello, I am your Fitora Coach. I synthesize your sleep cycles, hydration levels, activity trends, and readiness index to offer mindful recovery paths. \n\nToday, your Readiness is at **${_engine.readiness.score}%**. How can I support your breathing, workout, or recovery journey today?',
      timestamp: DateTime.now(),
      suggestedPrompts: const [
        'Analyze my sleep quality',
        'Suggest a recovery flow',
        'Check my weekly wellness trends',
      ],
    );

    state = state.copyWith(
      messages: [welcome],
      trends: trends,
      mood: AICoachMood.idle,
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = CoachMessage(
      id: 'user_msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      mood: AICoachMood.thinking,
      isLoading: true,
    );

    try {
      final response = await _service.generateCoachResponse(
        state.messages,
        text,
        readinessScore: _engine.readiness.score,
        sleepHours: _wellness.sleepMinutes > 0 ? _wellness.sleepMinutes / 60 : 7.0,
        hydrationLiters: _wellness.hydrationLiters,
        currentMood: _wellness.loggedMoods.values.lastOrNull ?? 'Calm',
        sorenessLevel: _wellness.muscleFatigue,
        stepsCount: _health.cachedData.steps,
      );

      state = state.copyWith(
        messages: [...state.messages, response],
        mood: AICoachMood.speaking,
        isLoading: false,
      );

      // Return to idle mood after speaking is set
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (mounted && state.mood == AICoachMood.speaking) {
          state = state.copyWith(mood: AICoachMood.idle);
        }
      });
    } catch (e) {
      final errorMsg = CoachMessage(
        id: 'error_msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'coach',
        content: 'I had trouble connecting with your biometric data core. Please try asking again.',
        timestamp: DateTime.now(),
        suggestedPrompts: const ['Retry last question'],
      );

      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        mood: AICoachMood.idle,
        isLoading: false,
      );
    }
  }

  void clearConversation() {
    state = state.copyWith(messages: []);
    init();
  }
}
