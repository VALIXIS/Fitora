import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/shared/widgets/glow_container.dart';
import 'package:fitora/core/health/providers/health_providers.dart';
import 'package:fitora/features/home/widgets/activity_rings_widget.dart';
import 'package:fitora/features/home/widgets/activity_metric_card.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _formatSyncTime(DateTime? syncTime) {
    if (syncTime == null) return 'Never synced';
    final localTime = syncTime.toLocal();
    final hourVal = localTime.hour == 0
        ? 12
        : (localTime.hour > 12 ? localTime.hour - 12 : localTime.hour);
    final amPm = localTime.hour >= 12 ? 'PM' : 'AM';
    final minute = localTime.minute.toString().padLeft(2, '0');
    return 'Synced at $hourVal:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activity = ref.watch(dailyActivityProvider(today));
    ref.watch(healthSyncServiceProvider); // Rebuilds on sync

    return Scaffold(
      backgroundColor: const Color(0xFF0E1312),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            floating: true,
            pinned: true,
            expandedHeight: 80,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: FitoraSpacing.xl,
                vertical: FitoraSpacing.md,
              ),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [FitoraColors.mintGreen, FitoraColors.calmCyan],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: FitoraColors.mintGreen.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: FitoraSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Good morning, Alex',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatSyncTime(activity.lastSyncTime),
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: FitoraSpacing.xl),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: FitoraSpacing.sm),
                // Activity Rings Section
                RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(healthSyncServiceProvider.notifier)
                        .syncNow();
                  },
                  child: Column(
                    children: [
                      ActivityRingsWidget(summary: activity),
                      const SizedBox(height: FitoraSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: ActivityMetricCard(
                              title: 'Steps',
                              value: activity.steps.toString(),
                              unit: ' / ${activity.stepsGoal}',
                              icon: Icons.directions_walk_rounded,
                              color: FitoraColors.mintGreen,
                            ),
                          ),
                          const SizedBox(width: FitoraSpacing.sm),
                          Expanded(
                            child: ActivityMetricCard(
                              title: 'Calories',
                              value: activity.caloriesBurned.toInt().toString(),
                              unit: ' / ${activity.caloriesGoal.toInt()} kcal',
                              icon: Icons.local_fire_department_rounded,
                              color: FitoraColors.warningOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: FitoraSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: ActivityMetricCard(
                              title: 'Active',
                              value: activity.activeMinutes.toString(),
                              unit: ' / ${activity.activeMinutesGoal} min',
                              icon: Icons.timer_rounded,
                              color: FitoraColors.calmCyan,
                            ),
                          ),
                          const SizedBox(width: FitoraSpacing.sm),
                          Expanded(
                            child: ActivityMetricCard(
                              title: 'Distance',
                              value: activity.distanceKm.toStringAsFixed(1),
                              unit: ' km',
                              icon: Icons.route_rounded,
                              color: FitoraColors.lavender,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: FitoraSpacing.xl),
                // AI Insight
                _buildAiInsightCard(textTheme),
                const SizedBox(height: FitoraSpacing.lg),
                // Daily Goals Prompts
                Text(
                  'DAILY GOALS',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: FitoraSpacing.md),
                // Steps — uses live sensor data when available
                _buildGoalTile(
                  textTheme,
                  Icons.directions_walk_rounded,
                  activity.sensorStatus == SensorStatus.active
                      ? 'Step Goal  🟢'
                      : 'Step Goal',
                  '${activity.steps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} / ${activity.stepsGoal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} steps',
                  activity.stepsProgress,
                  FitoraColors.mintGreen,
                ),
                const SizedBox(height: FitoraSpacing.sm),
                Consumer(
                  builder: (context, ref, _) {
                    final wellness = ref.watch(wellnessProvider);
                    final hasHydrationGoal = wellness.hydrationGoalLiters > 0;
                    final hydrationSubtitle = hasHydrationGoal
                        ? '${wellness.hydrationLiters.toStringAsFixed(1)} / ${wellness.hydrationGoalLiters.toStringAsFixed(1)} L'
                        : 'Set Daily Water Goal';
                    final hydrationProgress = hasHydrationGoal
                        ? (wellness.hydrationLiters /
                                  wellness.hydrationGoalLiters)
                              .clamp(0.0, 1.0)
                        : 0.0;
                    return _buildGoalTile(
                      textTheme,
                      Icons.water_drop_rounded,
                      'Hydration',
                      hydrationSubtitle,
                      hydrationProgress,
                      Colors.blueAccent,
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final sleep = ref.watch(sleepSummaryProvider(today));
                    if (sleep.totalSleep.inMinutes == 0) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: FitoraSpacing.sm),
                        _buildGoalTile(
                          textTheme,
                          Icons.bedtime_rounded,
                          'Sleep',
                          '${sleep.totalSleep.inHours}h ${sleep.totalSleep.inMinutes.remainder(60)}m logged',
                          (sleep.totalSleep.inMinutes / 480.0).clamp(0.0, 1.0),
                          FitoraColors.softPink,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 100), // Bottom padding
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightCard(TextTheme tt) {
    return GestureDetector(
      onTap: () => context.goNamed(AppRouteNames.progress),
      child: GlowContainer(
        glowColor: FitoraColors.lavender.withValues(alpha: 0.15),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(FitoraSpacing.lg),
              decoration: BoxDecoration(
                color: FitoraColors.lavender.withValues(alpha: 0.05),
                border: Border.all(
                  color: FitoraColors.lavender.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FitoraColors.lavender.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: FitoraColors.lavender,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: FitoraSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Recommendation',
                          style: tt.labelMedium?.copyWith(
                            color: FitoraColors.lavender,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your readiness is peaking. It’s an ideal day for high-intensity training to maximize your activity rings.',
                          style: tt.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildGoalTile(
    TextTheme tt,
    IconData icon,
    String title,
    String subtitle,
    double progress,
    Color color,
  ) {
    return GlowContainer(
      glowColor: color.withValues(alpha: 0.1),
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: FitoraSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
