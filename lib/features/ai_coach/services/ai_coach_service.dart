import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/ai_coach_models.dart';

class AICoachService {
  /// Generate a personalized morning wellness briefing analyzing yesterday's metrics using Gemini API,
  /// with an intelligent offline fallback pipeline.
  Future<DailyBriefing> generateDailyBriefing({
    required double sleepHours,
    required int stepsCount,
    required int restingHeartRate,
    required int recoveryScore,
    String? apiKey,
  }) async {
    final effectiveApiKey = apiKey ??
        const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

    if (effectiveApiKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$effectiveApiKey',
        );

        final prompt = '''
You are the Fitora AI Wellness Coach.
Analyze the user's health metrics from yesterday and current recovery state:
- Sleep Duration: ${sleepHours.toStringAsFixed(1)} hours
- Daily Steps: $stepsCount steps
- Resting Heart Rate: $restingHeartRate bpm
- Recovery / Readiness Score: $recoveryScore%

Generate a personalized morning wellness briefing for today with exactly 3 actionable tips.
Your response MUST be valid raw JSON with NO markdown code fences, using exact schema:
{
  "summary": "A warm 2-3 sentence summary analyzing sleep debt, cardiovascular strain, and recovery capability.",
  "tips": [
    "First actionable tip with specific advice",
    "Second actionable tip with specific advice",
    "Third actionable tip with specific advice"
  ]
}
''';

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt}
                    ]
                  }
                ],
                'generationConfig': {
                  'temperature': 0.7,
                  'responseMimeType': 'application/json',
                }
              }),
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

          if (text != null && text.trim().isNotEmpty) {
            String cleanJsonStr = text.trim();
            if (cleanJsonStr.startsWith('```json')) {
              cleanJsonStr = cleanJsonStr.replaceFirst('```json', '');
            }
            if (cleanJsonStr.startsWith('```')) {
              cleanJsonStr = cleanJsonStr.replaceFirst('```', '');
            }
            if (cleanJsonStr.endsWith('```')) {
              cleanJsonStr = cleanJsonStr.substring(0, cleanJsonStr.length - 3);
            }
            cleanJsonStr = cleanJsonStr.trim();

            final parsed = jsonDecode(cleanJsonStr);
            final summary = parsed['summary'] as String? ?? '';
            final tipsRaw = parsed['tips'] as List?;
            final tips = tipsRaw?.map((e) => e.toString()).toList() ?? [];

            if (summary.isNotEmpty && tips.length >= 3) {
              return DailyBriefing(
                summary: summary,
                tips: tips.take(3).toList(),
                generatedAt: DateTime.now(),
                isOfflineFallback: false,
              );
            }
          }
        }
      } catch (_) {
        // Fallback to offline briefing pipeline if API call fails
      }
    }

    return _generateOfflineDailyBriefing(
      sleepHours: sleepHours,
      stepsCount: stepsCount,
      restingHeartRate: restingHeartRate,
      recoveryScore: recoveryScore,
    );
  }

  DailyBriefing generateOfflineFallbackBriefing({
    double sleepHours = 7.2,
    int stepsCount = 8400,
    int restingHeartRate = 64,
    int recoveryScore = 82,
  }) {
    return _generateOfflineDailyBriefing(
      sleepHours: sleepHours,
      stepsCount: stepsCount,
      restingHeartRate: restingHeartRate,
      recoveryScore: recoveryScore,
    );
  }

  DailyBriefing _generateOfflineDailyBriefing({

    required double sleepHours,
    required int stepsCount,
    required int restingHeartRate,
    required int recoveryScore,
  }) {
    final String summary;
    if (recoveryScore >= 80) {
      summary =
          'Good morning! Yesterday you logged ${sleepHours.toStringAsFixed(1)} hours of sleep and $stepsCount steps with a steady resting HR of ${restingHeartRate > 0 ? restingHeartRate : 62} bpm. Your recovery score is a strong $recoveryScore%. You are in prime shape for peak energy today.';
    } else if (recoveryScore >= 60) {
      summary =
          'Good morning! Yesterday’s rest reached ${sleepHours.toStringAsFixed(1)} hours and $stepsCount steps. Resting HR registered at ${restingHeartRate > 0 ? restingHeartRate : 68} bpm, putting your recovery at a balanced $recoveryScore%. Focus on steady momentum without overexertion.';
    } else {
      summary =
          'Good morning! Sleep logged at ${sleepHours.toStringAsFixed(1)} hours alongside $stepsCount steps. Resting HR reached ${restingHeartRate > 0 ? restingHeartRate : 74} bpm, bringing your recovery score to $recoveryScore%. Today is an active recovery day — listen to your body and rest.';
    }

    final List<String> tips = [];

    // Tip 1: Sleep / Wind-down
    if (sleepHours < 7.0) {
      tips.add(
        'Pay back sleep debt: Aim for a 20-minute power nap or begin your screen-free wind-down routine 45 minutes earlier tonight.',
      );
    } else {
      tips.add(
        'Maintain circadian alignment: Keep tonight’s bedtime consistent to lock in your solid ${sleepHours.toStringAsFixed(1)}h sleep quality.',
      );
    }

    // Tip 2: Heart rate & stress / hydration
    if (restingHeartRate > 72) {
      tips.add(
        'Lower cardiovascular strain: Sip 500ml of electrolyte water now and try 5 minutes of 4-7-8 box breathing mid-afternoon.',
      );
    } else {
      tips.add(
        'Optimize cellular hydration: Drink 500ml of cold water upon waking to support metabolic readiness and blood flow.',
      );
    }

    // Tip 3: Movement / Training
    if (recoveryScore >= 80) {
      tips.add(
        'Capitalize on high readiness: Schedule your intense full-body strength or HIIT workout earlier in the day when cortisol is peak.',
      );
    } else if (recoveryScore >= 60) {
      tips.add(
        'Moderate movement: Keep workouts at zone 2 (moderate cardio or light yoga flow) to build stamina without fatigue.',
      );
    } else {
      tips.add(
        'Active recovery focus: Replace heavy lifts with a gentle 15-minute walk and full-body hamstring & mobility stretches.',
      );
    }

    return DailyBriefing(
      summary: summary,
      tips: tips,
      generatedAt: DateTime.now(),
      isOfflineFallback: true,
    );
  }

  // Generate a customized coaching response based on wellness context

  Future<CoachMessage> generateCoachResponse(
    List<CoachMessage> history,
    String userMessage, {
    required int readinessScore,
    required double sleepHours,
    required double hydrationLiters,
    required String currentMood,
    required String sorenessLevel,
    required int stepsCount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1400)); // Calming human thinking delay

    final normalizedQuery = userMessage.toLowerCase();
    String reply = '';
    List<String> suggestions = [];

    if (normalizedQuery.contains('sleep') || normalizedQuery.contains('tired') || normalizedQuery.contains('night')) {
      reply = _generateSleepAdvice(sleepHours, readinessScore);
      suggestions = [
        'How can I get deep sleep?',
        'Analyze my weekly sleep trends',
        'Should I work out if I am tired?',
      ];
    } else if (normalizedQuery.contains('workout') || normalizedQuery.contains('exercise') || normalizedQuery.contains('train') || normalizedQuery.contains('run')) {
      reply = _generateWorkoutAdvice(readinessScore, sorenessLevel);
      suggestions = [
        'Recommend a yoga flow',
        'Check my active calories',
        'How does soreness affect my body?',
      ];
    } else if (normalizedQuery.contains('water') || normalizedQuery.contains('hydrate') || normalizedQuery.contains('hydration')) {
      reply = _generateHydrationAdvice(hydrationLiters);
      suggestions = [
        'Set daily water targets',
        'How does water improve recovery?',
        'Review trend analysis',
      ];
    } else if (normalizedQuery.contains('mood') || normalizedQuery.contains('stressed') || normalizedQuery.contains('anxious') || normalizedQuery.contains('sad') || normalizedQuery.contains('happy')) {
      reply = _generateMoodAdvice(currentMood);
      suggestions = [
        'Guide me in breathing',
        'Why does box breathing help stress?',
        'Check my readiness index',
      ];
    } else if (normalizedQuery.contains('readiness') || normalizedQuery.contains('score') || normalizedQuery.contains('how am i')) {
      reply = _generateReadinessAdvice(readinessScore, sleepHours, hydrationLiters, sorenessLevel);
      suggestions = [
        'Show weekly wellness trends',
        'Give me a rest routine',
        'Explain my hydration target',
      ];
    } else if (normalizedQuery.contains('trend') || normalizedQuery.contains('weekly') || normalizedQuery.contains('summary') || normalizedQuery.contains('progress')) {
      reply = 'Looking at your weekly summary, your average Readiness is **76.5%** with a consistent workout streak. Your sleep has been slightly compressed (average 7.2 hours), and steps hit **8,900** daily. \n\nYour primary recovery suggestion is to boost slow-wave sleep by reducing blue light 45 minutes before sleep. How would you like me to analyze these metrics today?';
      suggestions = [
        'Explain slow-wave sleep',
        'Compare to yesterday',
        'How do I maintain my streak?',
      ];
    } else {
      reply = _generateGeneralCoachGreeting(readinessScore, currentMood);
      suggestions = [
        'Check my readiness today',
        'Help me wind down tonight',
        'Is it a good day to push hard?',
      ];
    }

    return CoachMessage(
      id: 'coach_msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'coach',
      content: reply,
      timestamp: DateTime.now(),
      suggestedPrompts: suggestions,
    );
  }

  String _generateSleepAdvice(double sleepHours, int readiness) {
    if (sleepHours < 6.5) {
      return 'I notice you logged only **${sleepHours.toStringAsFixed(1)} hours** of sleep. When sleep drops, your brain struggles to complete deep REM cycles. \n\nToday, let’s focus on light, restorative activity. Keep workouts gentle, and let’s schedule a 5-minute deep breathing session before bed to settle your nervous system. Remember: recovery is where strength is built.';
    } else {
      return 'Fantastic sleep quality logged at **${sleepHours.toStringAsFixed(1)} hours**. This robust rest has powered your Readiness score to a solid **$readiness%**. \n\nYour heart rate variability is likely at a healthy baseline. Today is an excellent opportunity to engage in a challenging workout. How are you planning to move your body?';
    }
  }

  String _generateWorkoutAdvice(int readiness, String soreness) {
    final sore = soreness.toLowerCase();
    if (readiness < 65 || sore == 'high' || sore == 'severe') {
      return 'With your Readiness at **$readiness%** and **$soreness soreness** levels, pushing into heavy lifting or intense cardio today might increase stress markers. \n\nI suggest a restorative 15-minute mobility session or a calming breathing exercise. Let’s focus on moving gently to increase blood flow and accelerate muscle healing.';
    } else {
      return 'Your body shows high readiness (**$readiness%**) with minimal muscle fatigue. This makes it a perfect day to engage in a moderate-to-high intensity workout! \n\nI recommend a **Full Body Strength Circuit** or an active **Cardio HIIT session**. How does that sound to you?';
    }
  }

  String _generateHydrationAdvice(double hydration) {
    if (hydration < 1.5) {
      return 'You have recorded **${hydration.toStringAsFixed(1)}L** of water today. Proper cellular hydration is vital for nutrient transport and core body temperature regulation. \n\nLet’s sip a glass of water right now. I highly recommend aiming for at least another 1.0L before the day ends to keep your muscles flexible and prevent fatigue.';
    } else {
      return 'Excellent hydration tracking! At **${hydration.toStringAsFixed(1)}L**, you are supporting optimal blood plasma volume and muscle recovery. \n\nKeep maintaining this steady intake. It directly translates to lower resting heart rates during your sessions!';
    }
  }

  String _generateMoodAdvice(String mood) {
    final m = mood.toLowerCase();
    if (m.contains('stress') || m.contains('anxious') || m.contains('tired')) {
      return 'I hear you. When feeling $mood, your sympathetic nervous system is highly active, raising cortisol levels. \n\nLet’s take a breath together. I encourage trying a 4-7-8 box breathing exercise right now. It is a powerful physiological lever to activate your vagal nerve and restore calm.';
    } else {
      return 'It is wonderful to hear that your energy feels $mood today! When you are in a positive state, your neuroplasticity is elevated, and workouts feel lighter. \n\nLet’s capture this momentum! Would you like to set an active intention or plan a rewarding workout for later?';
    }
  }

  String _generateReadinessAdvice(int readiness, double sleep, double hydration, String soreness) {
    if (readiness < 70) {
      return 'Your Readiness index is at **$readiness%** today. This is primarily influenced by **${sleep.toStringAsFixed(1)}h** of sleep and **$soreness soreness**. \n\nYour body is requesting active recovery. Think of today as a "rebuilding day" rather than a resting day. Gentle walk, light hydration, and intentional breathwork will be your best allies.';
    } else {
      return 'Your Readiness index is strong at **$readiness%**! Sleep is balanced, soreness is light, and your recovery indices are in the green zone. \n\nYou are in a prime state to perform. If you are up for it, push your limits slightly during your workout today. What are we tracking next?';
    }
  }

  String _generateGeneralCoachGreeting(int readiness, String mood) {
    return 'Hello, I am your Fitora AI Coach. I synthesize your biometrics, sleep patterns, and daily habits to guide you gently toward balanced wellness. \n\nToday, your Readiness is at **$readiness%**, and your mood is recorded as **$mood**. How can I support your breathing, workout, or recovery journey today?';
  }

  // Generate simulated weekly trends
  List<WellnessTrend> generateWeeklyTrends() {
    return const [
      WellnessTrend(label: 'Mon', steps: 8400, sleepHours: 6.8, waterLiters: 1.8, readinessScore: 72, moodValue: 3),
      WellnessTrend(label: 'Tue', steps: 9100, sleepHours: 7.2, waterLiters: 2.3, readinessScore: 81, moodValue: 4),
      WellnessTrend(label: 'Wed', steps: 7800, sleepHours: 6.5, waterLiters: 1.5, readinessScore: 68, moodValue: 3),
      WellnessTrend(label: 'Thu', steps: 10500, sleepHours: 7.8, waterLiters: 2.6, readinessScore: 88, moodValue: 5),
      WellnessTrend(label: 'Fri', steps: 8900, sleepHours: 7.1, waterLiters: 2.1, readinessScore: 78, moodValue: 4),
      WellnessTrend(label: 'Sat', steps: 11200, sleepHours: 8.0, waterLiters: 2.8, readinessScore: 92, moodValue: 5),
      WellnessTrend(label: 'Sun', steps: 6500, sleepHours: 7.0, waterLiters: 1.9, readinessScore: 74, moodValue: 4),
    ];
  }
}
