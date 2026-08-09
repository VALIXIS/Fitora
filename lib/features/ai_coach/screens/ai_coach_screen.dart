import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/shared/widgets/app_scaffold.dart';
import 'package:fitora/shared/widgets/fitora_card.dart';
import 'package:fitora/shared/widgets/glow_container.dart';
import '../domain/ai_coach_models.dart';
import '../providers/ai_coach_provider.dart';

class AICoachScreen extends ConsumerStatefulWidget {
  const AICoachScreen({super.key});

  @override
  ConsumerState<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends ConsumerState<AICoachScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitMessage(String text) {
    if (text.trim().isEmpty) return;
    ref.read(aiCoachProvider.notifier).sendMessage(text);
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCoachProvider);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'AI Wellness Coach',
      applyPadding: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Reset Conversation',
          onPressed: () => ref.read(aiCoachProvider.notifier).clearConversation(),
        ),
      ],
      body: Column(
        children: [
          // Segmented Tab Bar for Chat vs Insights
          Container(
            padding: const EdgeInsets.symmetric(horizontal: FitoraSpacing.md, vertical: FitoraSpacing.xs),
            color: cs.surface,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: cs.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                labelStyle: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Conversational Coach'),
                  Tab(text: 'Trends & Weekly Insights'),
                ],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Tab 1: Conversational Chat Screen ─────────────────────────
                Column(
                  children: [
                    // Dynamic Coach Header & Interactive Orb
                    _CoachOrbHeader(mood: state.mood, isLoading: state.isLoading),

                    // Message Logs list
                    Expanded(
                      child: state.messages.isEmpty
                          ? const Center(child: Text('Start a session with your coach.'))
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: FitoraSpacing.md),
                              itemCount: state.messages.length,
                              itemBuilder: (context, index) {
                                final msg = state.messages[index];
                                final isCoach = msg.sender == 'coach';

                                return _ChatBubble(message: msg, isCoach: isCoach)
                                    .animate()
                                    .fadeIn(duration: 300.ms)
                                    .slideY(begin: 0.1, end: 0, duration: 300.ms);
                              },
                            ),
                    ),

                    // Quick Suggested Prompts
                    if (state.messages.isNotEmpty &&
                        state.messages.last.suggestedPrompts.isNotEmpty &&
                        !state.isLoading)
                      _SuggestedPromptsList(
                        prompts: state.messages.last.suggestedPrompts,
                        onPromptTap: _submitMessage,
                      ).animate().fadeIn(duration: 250.ms),

                    // Thinking/Typing Indicator
                    if (state.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: _ThinkingTypingIndicator(),
                      ),

                    // Input Text Bar
                    _ChatInputBar(
                      controller: _messageController,
                      onSubmit: _submitMessage,
                      isEnabled: !state.isLoading,
                    ),
                  ],
                ),

                // ── Tab 2: Trends & Weekly Insights Hub ────────────────────────
                _TrendsAndInsightsHub(
                  trends: state.trends,
                  summary: state.weeklySummary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating Animated AI Orb Widget ──────────────────────────────────────────

class _CoachOrbHeader extends StatefulWidget {
  final AICoachMood mood;
  final bool isLoading;

  const _CoachOrbHeader({required this.mood, required this.isLoading});

  @override
  State<_CoachOrbHeader> createState() => _CoachOrbHeaderState();
}

class _CoachOrbHeaderState extends State<_CoachOrbHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Color primaryColor;
    switch (widget.mood) {
      case AICoachMood.idle:
        primaryColor = FitoraColors.mintGreen;
        break;
      case AICoachMood.thinking:
        primaryColor = FitoraColors.calmCyan;
        break;
      case AICoachMood.speaking:
        primaryColor = FitoraColors.lavender;
        break;
      case AICoachMood.comforting:
        primaryColor = FitoraColors.softPink;
        break;
      case AICoachMood.encouraging:
        primaryColor = FitoraColors.warmCoral;
        break;
    }

    final secondaryColor = primaryColor.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.all(FitoraSpacing.md),
      margin: const EdgeInsets.symmetric(horizontal: FitoraSpacing.md, vertical: FitoraSpacing.xs),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.surfaceContainerHighest.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          // Animated breathing glassmorphic orb
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = _pulseAnimation.value;
              return Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [primaryColor, secondaryColor, Colors.transparent],
                    stops: const [0.2, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3 * scale),
                      blurRadius: 18 * scale,
                      spreadRadius: 2 * scale,
                    ),
                  ],
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                  child: Center(
                    child: Container(
                      width: 24 * scale,
                      height: 24 * scale,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: FitoraSpacing.md),

          // Context label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fitora Intelligence',
                  style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.isLoading
                      ? 'Synthesizing biometrics…'
                      : (widget.mood == AICoachMood.speaking
                          ? 'Sharing insights…'
                          : 'Attuned to your current readiness'),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Conversational Chat Bubble Widget ──────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final CoachMessage message;
  final bool isCoach;

  const _ChatBubble({required this.message, required this.isCoach});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: isCoach ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCoach) ...[
            Container(
              margin: const EdgeInsets.only(right: 8.0, top: 4.0),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: FitoraColors.mintGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.psychology_outlined, color: FitoraColors.mintGreen, size: 18),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isCoach
                    ? cs.surfaceContainerHighest.withValues(alpha: 0.7)
                    : cs.primary.withValues(alpha: 0.85),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isCoach ? 4 : 16),
                  bottomRight: Radius.circular(isCoach ? 16 : 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: tt.bodyMedium?.copyWith(
                      color: isCoach ? cs.onSurface : Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isCoach) ...[
            const SizedBox(width: 8.0),
            Container(
              margin: const EdgeInsets.only(top: 4.0),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.person, color: cs.primary, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Smart Contextual Suggested Prompts ─────────────────────────────────────────

class _SuggestedPromptsList extends StatelessWidget {
  final List<String> prompts;
  final ValueChanged<String> onPromptTap;

  const _SuggestedPromptsList({required this.prompts, required this.onPromptTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: FitoraSpacing.md),
        itemCount: prompts.length,
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              backgroundColor: FitoraColors.mintGreen.withValues(alpha: 0.08),
              label: Text(
                prompt,
                style: const TextStyle(
                  color: FitoraColors.mintGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              side: const BorderSide(color: FitoraColors.mintGreen, width: 0.5),
              onPressed: () => onPromptTap(prompt),
            ),
          );
        },
      ),
    );
  }
}

// ── Thinking / Typing Simulated Indicator ──────────────────────────────────────

class _ThinkingTypingIndicator extends StatelessWidget {
  const _ThinkingTypingIndicator();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FitoraSpacing.lg, vertical: FitoraSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.6), shape: BoxShape.circle),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(duration: 600.ms, curve: Curves.easeInOut),
          const SizedBox(width: 4),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.6), shape: BoxShape.circle),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeInOut),
          const SizedBox(width: 4),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.6), shape: BoxShape.circle),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(delay: 400.ms, duration: 600.ms, curve: Curves.easeInOut),
        ],
      ),
    );
  }
}

// ── Bottom Chat Input Panel ───────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final bool isEnabled;

  const _ChatInputBar({
    required this.controller,
    required this.onSubmit,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5), width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: isEnabled,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: onSubmit,
                decoration: InputDecoration(
                  hintText: 'Ask about sleep, soreness, or today’s plan…',
                  hintStyle: const TextStyle(fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton.filled(
              icon: const Icon(Icons.send_rounded, size: 20),
              onPressed: isEnabled ? () => onSubmit(controller.text) : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trends & Weekly Insights Hub Panel ─────────────────────────────────────────

class _TrendsAndInsightsHub extends StatelessWidget {
  final List<WellnessTrend> trends;
  final WeeklySummary summary;

  const _TrendsAndInsightsHub({required this.trends, required this.summary});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(FitoraSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Weekly Metrics Overview Sparklines
          Text(
            'Wellness Trend Analysis (Last 7 Days)',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: FitoraSpacing.sm),

          _WeeklyTrendChart(trends: trends),

          const SizedBox(height: FitoraSpacing.lg),

          // Weekly Metrics Averages
          Text(
            '7-Day Biometrics',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: FitoraSpacing.sm),

          Row(
            children: [
              Expanded(
                child: _MetricAverageCard(
                  label: 'Readiness Avg',
                  value: '${summary.weeklyReadinessAvg.round()}%',
                  color: FitoraColors.mintGreen,
                ),
              ),
              const SizedBox(width: FitoraSpacing.sm),
              Expanded(
                child: _MetricAverageCard(
                  label: 'Sleep Avg',
                  value: '${summary.weeklySleepHoursAvg.toStringAsFixed(1)} hrs',
                  color: FitoraColors.lavender,
                ),
              ),
            ],
          ),
          const SizedBox(height: FitoraSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _MetricAverageCard(
                  label: 'Steps Avg',
                  value: '${summary.weeklyStepsAvg.round()}',
                  color: FitoraColors.calmCyan,
                ),
              ),
              const SizedBox(width: FitoraSpacing.sm),
              Expanded(
                child: _MetricAverageCard(
                  label: 'Hydration Avg',
                  value: '${summary.weeklyWaterLitersAvg.toStringAsFixed(1)} L',
                  color: FitoraColors.softPink,
                ),
              ),
            ],
          ),

          const SizedBox(height: FitoraSpacing.lg),

          // Personalized Insights Feed
          Text(
            'Personalized AI Insights',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: FitoraSpacing.sm),

          // Insight: Sleep
          _PersonalizedInsightCard(
            category: 'SLEEP HYGIENE',
            content: summary.primaryRecoverySuggestion,
            color: FitoraColors.lavender,
            icon: Icons.nights_stay_rounded,
          ),

          const SizedBox(height: FitoraSpacing.md),

          // Insight: Workout scale
          _PersonalizedInsightCard(
            category: 'ADAPTIVE TRAINING',
            content: summary.energyWorkoutRecommendation,
            color: FitoraColors.mintGreen,
            icon: Icons.fitness_center_rounded,
          ),

          const SizedBox(height: FitoraSpacing.md),

          // Insight: Stress and Breathing
          _PersonalizedInsightCard(
            category: 'STRESS BALANCE & PARASYMPATHETIC',
            content: summary.moodWellnessCoaching,
            color: FitoraColors.softPink,
            icon: Icons.spa_rounded,
          ),

          const SizedBox(height: FitoraSpacing.xl),
        ],
      ),
    );
  }
}

// ── Custom Weekly Trend Bar Chart ──────────────────────────────────────────────

class _WeeklyTrendChart extends StatelessWidget {
  final List<WellnessTrend> trends;

  const _WeeklyTrendChart({required this.trends});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return FitoraCard(
      padding: const EdgeInsets.all(FitoraSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Readiness Scores & Fatigue Level', style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: FitoraColors.mintGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('Stable Trend', style: tt.labelSmall?.copyWith(color: FitoraColors.mintGreen, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: FitoraSpacing.lg),
          // Chart layout using custom vertical bar indicators
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trends.map((trend) {
                final barHeightFactor = trend.readinessScore / 100.0;
                final isToday = trend.label == 'Sun';

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Hover score label
                    Text(
                      '${trend.readinessScore}',
                      style: tt.labelSmall?.copyWith(
                        fontSize: 9,
                        color: isToday ? FitoraColors.mintGreen : cs.onSurfaceVariant,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Bar representation
                    Container(
                      width: 14,
                      height: 80 * barHeightFactor,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isToday
                              ? [FitoraColors.mintGreen, FitoraColors.calmCyan]
                              : [cs.primary.withValues(alpha: 0.4), cs.primary.withValues(alpha: 0.15)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      trend.label,
                      style: tt.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Metric Average Card ────────────────────────────────────────────────────────

class _MetricAverageCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricAverageCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return FitoraCard(
      padding: const EdgeInsets.all(FitoraSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label, style: tt.labelSmall?.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ── Personalized AI Insight Card ───────────────────────────────────────────────

class _PersonalizedInsightCard extends StatelessWidget {
  final String category;
  final String content;
  final Color color;
  final IconData icon;

  const _PersonalizedInsightCard({
    required this.category,
    required this.content,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GlowContainer(
      glowColor: color.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                category,
                style: tt.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: FitoraSpacing.sm),
          Text(
            content,
            style: tt.bodyMedium?.copyWith(
              height: 1.4,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
