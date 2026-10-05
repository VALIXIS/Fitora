import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/features/ai_coach/domain/ai_coach_models.dart';
import 'package:fitora/features/ai_coach/providers/ai_coach_provider.dart';
import 'package:fitora/features/ai_coach/screens/ai_coach_screen.dart';
import 'package:fitora/features/ai_coach/services/ai_coach_service.dart';
import 'package:fitora/shared/widgets/fitora_card.dart';
import 'package:fitora/core/services/haptic_service.dart';

class DailyBriefingCard extends ConsumerWidget {
  const DailyBriefingCard({super.key});

  void _openAICoach(BuildContext context, WidgetRef ref, [String? initialPrompt]) {
    ref.read(hapticServiceProvider).buttonPress();
    if (initialPrompt != null && initialPrompt.isNotEmpty) {
      ref.read(aiCoachProvider.notifier).sendMessage(initialPrompt);
    }
    
    try {
      context.push(AppRoutes.aiCoach);
    } catch (_) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AICoachScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(dailyBriefingProvider);
    final stateBriefing = ref.watch(aiCoachProvider.select((s) => s.dailyBriefing));
    final theme = Theme.of(context);
    final tt = theme.textTheme;

    return briefingAsync.when(
      data: (briefing) => _buildCard(context, ref, briefing, tt, theme),
      loading: () => stateBriefing != null
          ? _buildCard(context, ref, stateBriefing, tt, theme)
          : _buildLoadingSkeleton(context, theme),
      error: (_, __) {
        final fallback = stateBriefing ?? AICoachService().generateOfflineFallbackBriefing();
        return _buildCard(context, ref, fallback, tt, theme);
      },
    );
  }


  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    DailyBriefing briefing,
    TextTheme tt,
    ThemeData theme,
  ) {
    final tipsIcons = [
      Icons.bedtime_rounded,
      Icons.water_drop_rounded,
      Icons.fitness_center_rounded,
    ];

    final tipColors = [
      FitoraColors.calmCyan,
      Colors.blueAccent,
      FitoraColors.mintGreen,
    ];

    return FitoraCard(
      padding: const EdgeInsets.all(FitoraSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      FitoraColors.mintGreen.withValues(alpha: 0.25),
                      FitoraColors.calmCyan.withValues(alpha: 0.25),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: FitoraColors.mintGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: FitoraSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Morning Wellness Briefing',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          briefing.isOfflineFallback
                              ? Icons.offline_bolt_outlined
                              : Icons.verified_rounded,
                          size: 12,
                          color: briefing.isOfflineFallback
                              ? Colors.amber
                              : FitoraColors.mintGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          briefing.isOfflineFallback
                              ? 'Offline Cached Briefing'
                              : 'Powered by Gemini AI',
                          style: tt.bodySmall?.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh Briefing',
                onPressed: () {
                  ref.read(hapticServiceProvider).selectionClick();
                  ref.invalidate(dailyBriefingProvider);
                  ref.read(aiCoachProvider.notifier).fetchBriefing();
                },
              ),
            ],
          ),
          const SizedBox(height: FitoraSpacing.md),

          // ── Summary Section ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(FitoraSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              briefing.summary,
              style: tt.bodyMedium?.copyWith(
                height: 1.45,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          ),
          const SizedBox(height: FitoraSpacing.lg),

          // ── Actionable Tips Header ─────────────────────────────────────
          Text(
            '3 ACTIONABLE TIPS TODAY',
            style: tt.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: FitoraSpacing.sm),

          // ── 3 Actionable Tips List ─────────────────────────────────────
          ...List.generate(briefing.tips.length, (index) {
            final tipText = briefing.tips[index];
            final icon = tipsIcons[index % tipsIcons.length];
            final color = tipColors[index % tipColors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: FitoraSpacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: FitoraSpacing.md,
                  vertical: FitoraSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 16, color: color),
                    ),
                    const SizedBox(width: FitoraSpacing.md),
                    Expanded(
                      child: Text(
                        tipText,
                        style: tt.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: FitoraSpacing.md),

          // ── Ask AI Coach Button ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openAICoach(
                context,
                ref,
                'Could you elaborate on today\'s morning briefing tips?',
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text(
                'Ask AI Coach',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: FitoraColors.mintGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLoadingSkeleton(BuildContext context, ThemeData theme) {
    return FitoraCard(
      padding: const EdgeInsets.all(FitoraSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 160,
                      height: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 100,
                      height: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}
