import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/shared/widgets/glow_container.dart';
import 'package:fitora/core/health/providers/health_providers.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';
import 'package:fitora/features/wellness/domain/wellness_models.dart';
import 'package:fitora/features/wellness/widgets/water_logging_modal.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/shared/widgets/fitora_background.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String _selectedFilter = 'Week';

  double _calculateTrendPercentage(List<double> values) {
    if (values.length < 2) return 0.0;
    final mid = values.length ~/ 2;
    final firstHalf = values.sublist(0, mid);
    final secondHalf = values.sublist(mid);
    
    final sum1 = firstHalf.fold<double>(0.0, (a, b) => a + b);
    final sum2 = secondHalf.fold<double>(0.0, (a, b) => a + b);
    
    if (sum1 == 0.0) return sum2 > 0.0 ? 100.0 : 0.0;
    return ((sum2 - sum1) / sum1) * 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastWeek = today.subtract(const Duration(days: 6));
    final summaries = ref.watch(weeklyActivityProvider(lastWeek));

    final profile = ref.watch(personalizationControllerProvider).profile;
    final hasWeight = profile.weightKg != null && profile.weightKg! > 0;
    
    final sleepValues = summaries.map((s) {
      return ref.watch(sleepSummaryProvider(s.date)).totalSleep.inMinutes.toDouble();
    }).toList();
    final hasSleepHistory = sleepValues.any((v) => v > 0);

    return FitoraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Premium SafeArea Header ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildHeader(textTheme),
            ),
            
            // ── Scrollable Content List ────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: FitoraSpacing.xl),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: FitoraSpacing.sm),
                  
                  // Time Filter Segmented Control
                  _buildTimeFilter(textTheme),
                  const SizedBox(height: FitoraSpacing.xl),
                  
                  // Activity Summary Metrics
                  _buildSectionHeader(textTheme, 'OVERVIEW'),
                  const SizedBox(height: FitoraSpacing.md),
                  if (summaries.isEmpty || summaries.last.lastSyncTime == null) ...[
                    _buildEmptyActivityCard(context, textTheme),
                  ] else ...[
                    _buildActivitySection(textTheme, summaries),
                  ],
                  const SizedBox(height: FitoraSpacing.xl),
                  
                  // Recovery Stats Section
                  _buildSectionHeader(textTheme, 'RECOVERY'),
                  const SizedBox(height: FitoraSpacing.md),
                  _buildRecoverySection(context, textTheme),
                  const SizedBox(height: FitoraSpacing.xl),
    
                  // Trends & Analytics Charts Section
                  _buildSectionHeader(textTheme, 'TRENDS & ANALYTICS'),
                  const SizedBox(height: FitoraSpacing.md),
                  if (summaries.isEmpty || summaries.last.lastSyncTime == null) ...[
                    _buildEmptyTrendsCard(context, textTheme),
                  ] else ...[
                    _buildTrendsSection(textTheme, summaries, hasSleepHistory, sleepValues, hasWeight, profile.weightKg),
                  ],
                  const SizedBox(height: 100), // Bottom scroll padding
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FitoraSpacing.xl,
          FitoraSpacing.md,
          FitoraSpacing.xl,
          FitoraSpacing.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Analytics',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded, color: FitoraColors.mintGreen, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    'This Week',
                    style: textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilter(TextTheme textTheme) {
    final options = ['Day', 'Week', 'Month', 'Year'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = _selectedFilter == opt;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = opt;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [FitoraColors.mintGreen, FitoraColors.calmCyan],
                        )
                      : null,
                ),
                child: Text(
                  opt,
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge?.copyWith(
                    color: isSelected ? Colors.black : Colors.white54,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(TextTheme tt, String title) {
    return Text(
      title,
      style: tt.labelSmall?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: Colors.white30,
      ),
    );
  }

  Widget _buildActivitySection(TextTheme tt, List<DailyActivitySummary> summaries) {
    final summary = summaries.last;
    
    // Dynamic trend calculations
    final stepsTrend = _calculateTrendPercentage(summaries.map((s) => s.steps.toDouble()).toList());
    final caloriesTrend = _calculateTrendPercentage(summaries.map((s) => s.caloriesBurned).toList());
    final activeTrend = _calculateTrendPercentage(summaries.map((s) => s.activeMinutes.toDouble()).toList());
    final distanceTrend = _calculateTrendPercentage(summaries.map((s) => s.distanceKm).toList());

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                label: 'Steps',
                value: summary.steps.toString(),
                unit: ' / ${summary.stepsGoal}',
                trend: '${stepsTrend >= 0 ? "+" : ""}${stepsTrend.toStringAsFixed(0)}%',
                isPositiveTrend: stepsTrend >= 0,
                icon: Icons.directions_walk_rounded,
                color: FitoraColors.mintGreen,
                textTheme: tt,
              ),
            ),
            const SizedBox(width: FitoraSpacing.sm),
            Expanded(
              child: _buildOverviewCard(
                label: 'Calories',
                value: summary.caloriesBurned.toInt().toString(),
                unit: ' kcal',
                trend: '${caloriesTrend >= 0 ? "+" : ""}${caloriesTrend.toStringAsFixed(0)}%',
                isPositiveTrend: caloriesTrend >= 0,
                icon: Icons.local_fire_department_rounded,
                color: FitoraColors.softEmerald,
                textTheme: tt,
              ),
            ),
          ],
        ),
        const SizedBox(height: FitoraSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                label: 'Active',
                value: summary.activeMinutes.toString(),
                unit: ' min',
                trend: '${activeTrend >= 0 ? "+" : ""}${activeTrend.toStringAsFixed(0)}%',
                isPositiveTrend: activeTrend >= 0,
                icon: Icons.timer_rounded,
                color: FitoraColors.calmCyan,
                textTheme: tt,
              ),
            ),
            const SizedBox(width: FitoraSpacing.sm),
            Expanded(
              child: _buildOverviewCard(
                label: 'Distance',
                value: summary.distanceKm.toStringAsFixed(1),
                unit: ' km',
                trend: '${distanceTrend >= 0 ? "+" : ""}${distanceTrend.toStringAsFixed(0)}%',
                isPositiveTrend: distanceTrend >= 0,
                icon: Icons.route_rounded,
                color: Colors.purpleAccent,
                textTheme: tt,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildOverviewCard({
    required String label,
    required String value,
    required String unit,
    required String trend,
    required bool isPositiveTrend,
    required IconData icon,
    required Color color,
    required TextTheme textTheme,
  }) {
    return GlowContainer(
      glowColor: color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPositiveTrend ? FitoraColors.mintGreen : FitoraColors.errorRed).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveTrend ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: isPositiveTrend ? FitoraColors.mintGreen : FitoraColors.errorRed,
                        size: 10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend,
                        style: textTheme.labelSmall?.copyWith(
                          color: isPositiveTrend ? FitoraColors.mintGreen : FitoraColors.errorRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: FitoraSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      unit,
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: Colors.white30,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoverySection(BuildContext context, TextTheme tt) {
    return Consumer(
      builder: (context, ref, _) {
        final sleep = ref.watch(sleepSummaryProvider(DateTime.now()));
        final wellness = ref.watch(wellnessProvider);
        final now = DateTime.now();
        final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        final mood = wellness.loggedMoods[todayStr] ?? 'Not logged';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSleepCard(context, tt, sleep),
            const SizedBox(height: FitoraSpacing.md),
            _buildHydrationCard(context, ref, tt, wellness),
            const SizedBox(height: FitoraSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    label: 'Mood',
                    value: mood,
                    unit: '',
                    trend: 'Daily',
                    isPositiveTrend: true,
                    icon: Icons.sentiment_satisfied_rounded,
                    color: Colors.amber,
                    textTheme: tt,
                  ),
                ),
                const SizedBox(width: FitoraSpacing.sm),
                Expanded(
                  child: _buildOverviewCard(
                    label: 'Breathing',
                    value: '${wellness.breathingMinutes} min',
                    unit: '',
                    trend: '+${wellness.breathingMinutes}m',
                    isPositiveTrend: true,
                    icon: Icons.air_rounded,
                    color: FitoraColors.softEmerald,
                    textTheme: tt,
                  ),
                ),
              ],
            ),
          ],
        ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildHydrationCard(BuildContext context, WidgetRef ref, TextTheme tt, WellnessState wellness) {
    final liters = wellness.hydrationLiters;
    final goal = wellness.hydrationGoalLiters;
    final progress = goal > 0 ? (liters / goal).clamp(0.0, 1.0) : 0.0;
    
    const double glassSize = 0.25;
    final totalGlasses = goal > 0 ? (goal / glassSize).ceil() : 8;
    final filledGlasses = (liters / glassSize).floor();

    return GlowContainer(
      glowColor: Colors.blueAccent.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(24),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.water_drop_rounded, color: Colors.blueAccent, size: 20),
                    ),
                    const SizedBox(width: FitoraSpacing.md),
                    Text(
                      'HYDRATION',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (liters > 0)
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white30, size: 20),
                        onPressed: () => ref.read(wellnessProvider.notifier).resetHydration(),
                        tooltip: 'Reset intake',
                      ),
                    ElevatedButton.icon(
                      onPressed: () => WaterLoggingModal.show(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('+ Add Water'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                        foregroundColor: Colors.blueAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.3)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: FitoraSpacing.lg),
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: tt.labelLarge?.copyWith(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: FitoraSpacing.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${liters.toStringAsFixed(2)} L',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        goal > 0 ? 'Goal: ${goal.toStringAsFixed(1)} L (1 glass = 250ml)' : 'Set Daily Water Goal',
                        style: tt.bodySmall?.copyWith(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: FitoraSpacing.lg),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(totalGlasses, (index) {
                final isFilled = index < filledGlasses;
                return Container(
                  width: 16,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isFilled ? Colors.blueAccent.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(2),
                    ),
                    border: Border.all(
                      color: isFilled ? Colors.blueAccent : Colors.white24,
                      width: 1.5,
                    ),
                  ),
                  child: isFilled
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 2,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        )
                      : null,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard(BuildContext context, TextTheme tt, SleepSummary sleep) {
    final totalMinutes = sleep.totalSleep.inMinutes;
    final hours = sleep.totalSleep.inHours;
    final minutes = sleep.totalSleep.inMinutes.remainder(60);
    
    const double sleepGoalMinutes = 480.0;
    final progress = (totalMinutes / sleepGoalMinutes).clamp(0.0, 1.0);

    String qualityText = 'Unknown';
    Color qualityColor = Colors.white30;
    if (totalMinutes > 0) {
      if (sleep.sleepScore >= 85) {
        qualityText = 'Excellent';
        qualityColor = FitoraColors.mintGreen;
      } else if (sleep.sleepScore >= 70) {
        qualityText = 'Good';
        qualityColor = FitoraColors.calmCyan;
      } else if (sleep.sleepScore >= 50) {
        qualityText = 'Fair';
        qualityColor = FitoraColors.warningOrange;
      } else {
        qualityText = 'Poor';
        qualityColor = FitoraColors.errorRed;
      }
    }

    final hasStages = sleep.deepSleep.inMinutes > 0 || sleep.remSleep.inMinutes > 0 || sleep.lightSleep.inMinutes > 0;

    return GlowContainer(
      glowColor: FitoraColors.calmCyan.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(24),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FitoraColors.calmCyan.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bedtime_rounded, color: FitoraColors.calmCyan, size: 20),
                    ),
                    const SizedBox(width: FitoraSpacing.md),
                    Text(
                      'SLEEP ANALYSIS',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                if (totalMinutes > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: qualityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: qualityColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      qualityText.toUpperCase(),
                      style: tt.labelSmall?.copyWith(
                        color: qualityColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: FitoraSpacing.lg),
            if (totalMinutes == 0) ...[
              Text(
                'Sleep information will appear after your first night of tracking.',
                style: tt.bodySmall?.copyWith(color: Colors.white38),
              ),
            ] else ...[
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 7,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: const AlwaysStoppedAnimation<Color>(FitoraColors.calmCyan),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: tt.labelLarge?.copyWith(
                          color: FitoraColors.calmCyan,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: FitoraSpacing.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${hours}h ${minutes}m',
                          style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sleep Goal: 8 hrs',
                          style: tt.bodySmall?.copyWith(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasStages) ...[
                const SizedBox(height: FitoraSpacing.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        if (sleep.deepSleep.inMinutes > 0)
                          Expanded(
                            flex: sleep.deepSleep.inMinutes,
                            child: Container(color: Colors.indigoAccent),
                          ),
                        if (sleep.remSleep.inMinutes > 0)
                          Expanded(
                            flex: sleep.remSleep.inMinutes,
                            child: Container(color: FitoraColors.calmCyan),
                          ),
                        if (sleep.lightSleep.inMinutes > 0)
                          Expanded(
                            flex: sleep.lightSleep.inMinutes,
                            child: Container(color: FitoraColors.lavender),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: FitoraSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (sleep.deepSleep.inMinutes > 0)
                      _buildSleepStageLabel(tt, 'Deep', '${sleep.deepSleep.inHours}h ${sleep.deepSleep.inMinutes.remainder(60)}m', Colors.indigoAccent),
                    if (sleep.remSleep.inMinutes > 0)
                      _buildSleepStageLabel(tt, 'REM', '${sleep.remSleep.inHours}h ${sleep.remSleep.inMinutes.remainder(60)}m', FitoraColors.calmCyan),
                    if (sleep.lightSleep.inMinutes > 0)
                      _buildSleepStageLabel(tt, 'Light', '${sleep.lightSleep.inHours}h ${sleep.lightSleep.inMinutes.remainder(60)}m', FitoraColors.lavender),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSleepStageLabel(TextTheme tt, String label, String duration, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: tt.labelSmall?.copyWith(color: Colors.white30, fontSize: 9)),
            Text(duration, style: tt.labelSmall?.copyWith(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendsSection(
    TextTheme tt,
    List<DailyActivitySummary> summaries,
    bool hasSleepHistory,
    List<double> sleepValues,
    bool hasWeight,
    double? weight,
  ) {
    return Column(
      children: [
        // Modern Weekly Steps Gradient Bar Chart
        _buildStepsGraph(tt, summaries),
        const SizedBox(height: FitoraSpacing.lg),
        
        Row(
          children: [
            Expanded(
              child: _buildTrendCard(
                tt,
                'Calories',
                Icons.local_fire_department_rounded,
                FitoraColors.softEmerald,
                summaries.map((s) => s.caloriesBurned).toList(),
              ),
            ),
            const SizedBox(width: FitoraSpacing.md),
            Expanded(
              child: _buildTrendCard(
                tt,
                'Active',
                Icons.timer_rounded,
                FitoraColors.calmCyan,
                summaries.map((s) => s.activeMinutes.toDouble()).toList(),
              ),
            ),
          ],
        ),
        if (hasSleepHistory) ...[
          const SizedBox(height: FitoraSpacing.lg),
          _buildTrendCard(tt, 'Sleep History', Icons.bedtime_rounded, FitoraColors.mintGreen, sleepValues),
        ],
        if (hasWeight && weight != null) ...[
          const SizedBox(height: FitoraSpacing.lg),
          _buildWeightTrend(tt, weight),
        ],
        const SizedBox(height: FitoraSpacing.lg),
        _buildStreakCard(tt),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildStepsGraph(TextTheme tt, List<DailyActivitySummary> summaries) {
    final stepValues = summaries.map((s) => s.steps.toDouble()).toList();
    final maxSteps = stepValues.isEmpty ? 1.0 : stepValues.reduce((curr, next) => curr > next ? curr : next);
    final maxStepsChecked = maxSteps == 0 ? 1.0 : maxSteps;
    
    final trendPct = _calculateTrendPercentage(stepValues);
    final isPositive = trendPct >= 0;
    final trendText = '${isPositive ? "+" : ""}${trendPct.toStringAsFixed(0)}%';

    final now = DateTime.now();

    return GlowContainer(
      glowColor: FitoraColors.mintGreen.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(24),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEEKLY STEPS',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          color: isPositive ? FitoraColors.mintGreen : FitoraColors.errorRed,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$trendText vs last period',
                          style: TextStyle(
                            color: isPositive ? FitoraColors.mintGreen : FitoraColors.errorRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FitoraColors.mintGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_walk_rounded, color: FitoraColors.mintGreen, size: 20),
                ),
              ],
            ),
            const SizedBox(height: FitoraSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: summaries.map((s) {
                final isToday = s.date.day == now.day && s.date.month == now.month && s.date.year == now.year;
                return _buildBar(_getDayName(s.date), s.steps / maxStepsChecked, isToday, FitoraColors.mintGreen);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(
    TextTheme tt,
    String title,
    IconData icon,
    Color color,
    List<double> values,
  ) {
    final maxVal = values.isEmpty ? 1.0 : values.reduce((curr, next) => curr > next ? curr : next);
    final maxValChecked = maxVal == 0 ? 1.0 : maxVal;
    
    final trendPct = _calculateTrendPercentage(values);
    final isPositive = trendPct >= 0;
    final trendText = '${isPositive ? "+" : ""}${trendPct.toStringAsFixed(0)}%';

    return GlowContainer(
      glowColor: color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: FitoraSpacing.sm),
                    Text(
                      title.toUpperCase(),
                      style: tt.labelSmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  trendText,
                  style: TextStyle(
                    color: isPositive ? FitoraColors.mintGreen : FitoraColors.errorRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FitoraSpacing.xl),
            SizedBox(
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: values.map((val) {
                  final heightRatio = (val / maxValChecked).clamp(0.05, 1.0);
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 70 * heightRatio,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.3)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: FitoraSpacing.sm),
            Text(
              'Compared to last period',
              style: tt.labelSmall?.copyWith(color: Colors.white30, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightTrend(TextTheme tt, double currentWeight) {
    return GlowContainer(
      glowColor: FitoraColors.lavender.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'WEIGHT TREND',
                  style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.white54,
                  ),
                ),
                const Icon(Icons.monitor_weight_rounded, color: FitoraColors.lavender, size: 20),
              ],
            ),
            const SizedBox(height: FitoraSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentWeight.toStringAsFixed(1),
                  style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4),
                  child: Text('kg', style: tt.bodySmall?.copyWith(color: Colors.white54)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String day, double heightRatio, bool isToday, Color color) {
    final double clampedRatio = heightRatio.clamp(0.04, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 12,
          height: 120 * clampedRatio,
          decoration: BoxDecoration(
            gradient: isToday
                ? LinearGradient(
                    colors: [FitoraColors.mintGreen, FitoraColors.softEmerald],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : LinearGradient(
                    colors: [
                      FitoraColors.calmCyan.withValues(alpha: 0.4),
                      FitoraColors.calmCyan.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: isToday ? FitoraColors.mintGreen.withValues(alpha: 0.8) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isToday
                ? [
                    BoxShadow(
                      color: FitoraColors.mintGreen.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          day,
          style: TextStyle(
            color: isToday ? Colors.white : Colors.white30,
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w900 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard(TextTheme tt) {
    final wellness = ref.watch(wellnessProvider);
    if (wellness.wellnessStreak == 0) return const SizedBox.shrink();

    return GlowContainer(
      glowColor: FitoraColors.warningOrange.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FitoraColors.warningOrange.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_fire_department_rounded, color: FitoraColors.warningOrange, size: 28),
            ),
            const SizedBox(width: FitoraSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${wellness.wellnessStreak} DAY STREAK',
                    style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: FitoraColors.warningOrange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You are unstoppable!',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Keep the momentum going.',
                    style: tt.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  Widget _buildEmptyActivityCard(BuildContext context, TextTheme tt) {
    return GlowContainer(
      glowColor: FitoraColors.mintGreen.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            const Icon(Icons.sync_disabled_rounded, color: Colors.white30, size: 36),
            const SizedBox(height: FitoraSpacing.md),
            Text(
              'No activity recorded yet.',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: FitoraSpacing.xs),
            Text(
              'Start tracking today to unlock insights.',
              style: tt.bodySmall?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FitoraSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.pushNamed(AppRouteNames.healthSync),
              icon: const Icon(Icons.link_rounded),
              label: const Text('Connect Health Source'),
              style: FilledButton.styleFrom(
                backgroundColor: FitoraColors.mintGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTrendsCard(BuildContext context, TextTheme tt) {
    return GlowContainer(
      glowColor: FitoraColors.lavender.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            const Icon(Icons.bar_chart_rounded, color: FitoraColors.lavender, size: 40),
            const SizedBox(height: FitoraSpacing.md),
            Text(
              'No Trend Data Yet',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: FitoraSpacing.xs),
            Text(
              'Weekly steps, calorie trends, and sleep logs will appear here once connected.',
              style: tt.bodySmall?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FitoraSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.pushNamed(AppRouteNames.healthSync),
              icon: const Icon(Icons.link_rounded),
              label: const Text('Connect Health Source'),
              style: FilledButton.styleFrom(
                backgroundColor: FitoraColors.lavender,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
