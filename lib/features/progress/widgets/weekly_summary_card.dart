import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/features/progress/providers/health_analytics_provider.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

class WeeklySummaryCard extends ConsumerWidget {
  const WeeklySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final summary = ref.watch(weeklyHealthSummaryProvider);

    final sleepHours = summary.avgSleepMinutes / 60.0;
    final sleepH = sleepHours.floor();
    final sleepM = ((sleepHours - sleepH) * 60).round();

    return GlowContainer(
      glowColor: FitoraColors.mintGreen.withValues(alpha: 0.06),
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
            // Card Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FitoraColors.mintGreen.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        color: FitoraColors.mintGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: FitoraSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WEEKLY HEALTH SUMMARY',
                          style: tt.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Last 7 Days vs Prior Week',
                          style: tt.bodySmall?.copyWith(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    '7-Day WoW',
                    style: tt.labelSmall?.copyWith(
                      color: FitoraColors.mintGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: FitoraSpacing.xl),

            // 2x2 Grid of Weekly Totals & Deltas
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    tt: tt,
                    label: 'Total Steps',
                    value: _formatNumber(summary.totalSteps),
                    unit: 'steps',
                    deltaText: _formatPctDelta(summary.stepsDeltaPct),
                    isPositive: summary.stepsDeltaPct >= 0,
                    icon: Icons.directions_walk_rounded,
                    color: FitoraColors.mintGreen,
                  ),
                ),
                const SizedBox(width: FitoraSpacing.md),
                Expanded(
                  child: _buildMetricTile(
                    tt: tt,
                    label: 'Total Water',
                    value: summary.totalWaterLiters.toStringAsFixed(1),
                    unit: 'L',
                    deltaText: _formatValueDelta(summary.waterDeltaLiters, 'L'),
                    isPositive: summary.waterDeltaLiters >= 0,
                    icon: Icons.water_drop_rounded,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: FitoraSpacing.md),

            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    tt: tt,
                    label: 'Avg Sleep',
                    value: '${sleepH}h ${sleepM}m',
                    unit: '/ night',
                    deltaText: _formatValueDelta(summary.sleepDeltaHours, 'h'),
                    isPositive: summary.sleepDeltaHours >= 0,
                    icon: Icons.bedtime_rounded,
                    color: FitoraColors.calmCyan,
                  ),
                ),
                const SizedBox(width: FitoraSpacing.md),
                Expanded(
                  child: _buildMetricTile(
                    tt: tt,
                    label: 'Active Calories',
                    value: summary.totalActiveCalories.toInt().toString(),
                    unit: 'kcal',
                    deltaText: _formatPctDelta(summary.caloriesDeltaPct),
                    isPositive: summary.caloriesDeltaPct >= 0,
                    icon: Icons.local_fire_department_rounded,
                    color: FitoraColors.softEmerald,
                  ),
                ),
              ],
            ),

            const SizedBox(height: FitoraSpacing.xl),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: FitoraSpacing.md),

            // Best Day Highlights Section
            Text(
              'WEEKLY HIGHLIGHTS',
              style: tt.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: Colors.white30,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: FitoraSpacing.sm),

            Row(
              children: [
                Expanded(
                  child: _buildBestDayBadge(
                    tt: tt,
                    title: 'Best Step Count',
                    day: summary.bestStepDay,
                    value: summary.bestStepValue > 0
                        ? '${_formatNumber(summary.bestStepValue)} steps'
                        : 'No logs',
                    icon: Icons.emoji_events_rounded,
                    accentColor: FitoraColors.mintGreen,
                  ),
                ),
                const SizedBox(width: FitoraSpacing.sm),
                Expanded(
                  child: _buildBestDayBadge(
                    tt: tt,
                    title: 'Best Hydration',
                    day: summary.bestHydrationDay,
                    value: summary.bestHydrationValue > 0
                        ? '${summary.bestHydrationValue.toStringAsFixed(1)}L'
                        : 'No logs',
                    icon: Icons.water_drop_rounded,
                    accentColor: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildMetricTile({
    required TextTheme tt,
    required String label,
    required String value,
    required String unit,
    required String deltaText,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    final deltaColor = isPositive
        ? FitoraColors.mintGreen
        : FitoraColors.errorRed;

    return Container(
      padding: const EdgeInsets.all(FitoraSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: deltaColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: deltaColor,
                      size: 10,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      deltaText,
                      style: tt.labelSmall?.copyWith(
                        color: deltaColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FitoraSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: tt.labelSmall?.copyWith(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: tt.labelSmall?.copyWith(color: Colors.white30, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBestDayBadge({
    required TextTheme tt,
    required String title,
    required String day,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FitoraSpacing.md,
        vertical: FitoraSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 16),
          const SizedBox(width: FitoraSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                    color: Colors.white30,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$day — $value',
                  style: tt.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int val) {
    if (val >= 10000) {
      return '${(val / 1000).toStringAsFixed(1)}k';
    }
    return val.toString();
  }

  String _formatPctDelta(double pct) {
    final prefix = pct >= 0 ? '+' : '';
    return '$prefix${pct.toStringAsFixed(0)}%';
  }

  String _formatValueDelta(double delta, String unit) {
    final prefix = delta >= 0 ? '+' : '';
    return '$prefix${delta.toStringAsFixed(1)}$unit';
  }
}
