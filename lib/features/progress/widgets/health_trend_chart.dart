import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/providers/health_providers.dart';
import 'package:fitora/features/progress/domain/progress_models.dart';
import 'package:fitora/features/progress/providers/health_analytics_provider.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';
import 'package:fitora/features/wellness/domain/wellness_models.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

class HealthTrendChart extends ConsumerWidget {
  const HealthTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final timeframe = ref.watch(healthTimeframeProvider);
    final selectedMetric = ref.watch(healthSelectedMetricProvider);

    final activities = ref.watch(healthActivityRangeProvider(timeframe.days));
    final wellness = ref.watch(wellnessProvider);

    final chartData = _extractMetricData(
      metric: selectedMetric,
      activities: activities,
      wellnessState: wellness,
    );

    final hasData = chartData.values.any((v) => v > 0);
    final avgValue = hasData
        ? (chartData.values.reduce((a, b) => a + b) / chartData.values.length)
        : 0.0;

    return GlowContainer(
      glowColor: _getMetricColor(selectedMetric).withValues(alpha: 0.06),
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
            // Time Horizon & Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HEALTH TRENDS',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasData
                          ? 'Daily Avg: ${_formatMetricValue(selectedMetric, avgValue)} ${selectedMetric.unit}'
                          : 'No entries for selected timeframe',
                      style: tt.bodySmall?.copyWith(
                        color: hasData
                            ? FitoraColors.mintGreen
                            : Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                // Time Horizon Toggle Pill (7-Day vs 30-Day)
                _buildTimeframeToggle(ref, timeframe, tt),
              ],
            ),

            const SizedBox(height: FitoraSpacing.lg),

            // Supported Metric Tabs Row (Steps, Distance, Calories, Sleep, Water)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: HealthMetricType.values.map((metric) {
                  final isSelected = metric == selectedMetric;
                  final metricColor = _getMetricColor(metric);
                  return Padding(
                    padding: const EdgeInsets.only(right: FitoraSpacing.xs),
                    child: ChoiceChip(
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(healthSelectedMetricProvider.notifier).state =
                            metric;
                      },
                      avatar: Icon(
                        _getMetricIcon(metric),
                        size: 14,
                        color: isSelected ? Colors.black : metricColor,
                      ),
                      label: Text(
                        metric.displayName,
                        style: tt.labelSmall?.copyWith(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      selectedColor: metricColor,
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? metricColor
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: FitoraSpacing.xl),

            // Chart Render or Empty State
            if (!hasData) ...[
              _buildEmptyState(context, tt, selectedMetric),
            ] else ...[
              _buildVisualChart(
                tt: tt,
                chartData: chartData,
                timeframe: timeframe,
                metric: selectedMetric,
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildTimeframeToggle(
    WidgetRef ref,
    HealthTimeframe current,
    TextTheme tt,
  ) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: HealthTimeframe.values.map((tf) {
          final isSelected = tf == current;
          return GestureDetector(
            onTap: () {
              ref.read(healthTimeframeProvider.notifier).state = tf;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [FitoraColors.mintGreen, FitoraColors.calmCyan],
                      )
                    : null,
              ),
              child: Text(
                tf.label,
                style: tt.labelSmall?.copyWith(
                  color: isSelected ? Colors.black : Colors.white54,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVisualChart({
    required TextTheme tt,
    required _ChartMetricSeries chartData,
    required HealthTimeframe timeframe,
    required HealthMetricType metric,
  }) {
    final maxVal = chartData.values.fold<double>(
      0.0,
      (curr, next) => curr > next ? curr : next,
    );
    final maxValChecked = maxVal == 0.0 ? 1.0 : maxVal;
    final color = _getMetricColor(metric);
    final now = DateTime.now();

    final is7Days = timeframe == HealthTimeframe.sevenDays;

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(chartData.dates.length, (index) {
              final val = chartData.values[index];
              final date = chartData.dates[index];
              final heightRatio = (val / maxValChecked).clamp(0.04, 1.0);
              final isToday =
                  date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: is7Days ? 4.0 : 1.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (is7Days && val > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _formatShortVal(metric, val),
                            style: tt.labelSmall?.copyWith(
                              color: Colors.white54,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      Container(
                        height: 100 * heightRatio,
                        decoration: BoxDecoration(
                          gradient: isToday
                              ? LinearGradient(
                                  colors: [color, color.withValues(alpha: 0.6)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                )
                              : LinearGradient(
                                  colors: [
                                    color.withValues(alpha: 0.5),
                                    color.withValues(alpha: 0.15),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: isToday ? color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (is7Days) ...[
                        Text(
                          _getDayLabel(date),
                          style: TextStyle(
                            color: isToday ? Colors.white : Colors.white38,
                            fontSize: 10,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ] else if (index % 5 == 0 ||
                          index == chartData.dates.length - 1) ...[
                        Text(
                          '${date.month}/${date.day}',
                          style: TextStyle(
                            color: isToday ? Colors.white : Colors.white38,
                            fontSize: 8,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    TextTheme tt,
    HealthMetricType metric,
  ) {
    return Container(
      padding: const EdgeInsets.all(FitoraSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(_getMetricIcon(metric), color: Colors.white24, size: 36),
          const SizedBox(height: FitoraSpacing.md),
          Text(
            'No ${metric.displayName} Data Available',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Log daily activities to see trend analytics.',
            style: tt.bodySmall?.copyWith(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  _ChartMetricSeries _extractMetricData({
    required HealthMetricType metric,
    required List<DailyActivitySummary> activities,
    required WellnessState wellnessState,
  }) {
    final dates = <DateTime>[];
    final values = <double>[];

    final now = DateTime.now();

    for (final act in activities) {
      dates.add(act.date);
      final dateStr =
          "${act.date.year}-${act.date.month.toString().padLeft(2, '0')}-${act.date.day.toString().padLeft(2, '0')}";
      final isToday =
          act.date.year == now.year &&
          act.date.month == now.month &&
          act.date.day == now.day;

      switch (metric) {
        case HealthMetricType.steps:
          values.add(act.steps.toDouble());
          break;
        case HealthMetricType.distance:
          values.add(act.distanceKm);
          break;
        case HealthMetricType.calories:
          values.add(act.caloriesBurned);
          break;
        case HealthMetricType.sleep:
          final mins = wellnessState.sleepLogHistory[dateStr] ?? 0;
          values.add(mins / 60.0);
          break;
        case HealthMetricType.water:
          double water = wellnessState.waterLogHistory[dateStr] ?? -1.0;
          if (water < 0) {
            final dayLogs = wellnessState.waterLogs.where(
              (e) =>
                  e.timestamp.year == act.date.year &&
                  e.timestamp.month == act.date.month &&
                  e.timestamp.day == act.date.day,
            );
            if (dayLogs.isNotEmpty) {
              water =
                  dayLogs.fold<int>(0, (sum, e) => sum + e.amountMl) / 1000.0;
            } else {
              water = isToday ? wellnessState.hydrationLiters : 0.0;
            }
          }
          values.add(water);
          break;
      }
    }

    return _ChartMetricSeries(dates: dates, values: values);
  }

  Color _getMetricColor(HealthMetricType metric) {
    switch (metric) {
      case HealthMetricType.steps:
        return FitoraColors.mintGreen;
      case HealthMetricType.distance:
        return Colors.purpleAccent;
      case HealthMetricType.calories:
        return FitoraColors.softEmerald;
      case HealthMetricType.sleep:
        return FitoraColors.calmCyan;
      case HealthMetricType.water:
        return Colors.blueAccent;
    }
  }

  IconData _getMetricIcon(HealthMetricType metric) {
    switch (metric) {
      case HealthMetricType.steps:
        return Icons.directions_walk_rounded;
      case HealthMetricType.distance:
        return Icons.route_rounded;
      case HealthMetricType.calories:
        return Icons.local_fire_department_rounded;
      case HealthMetricType.sleep:
        return Icons.bedtime_rounded;
      case HealthMetricType.water:
        return Icons.water_drop_rounded;
    }
  }

  String _getDayLabel(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _formatMetricValue(HealthMetricType metric, double val) {
    if (metric == HealthMetricType.steps ||
        metric == HealthMetricType.calories) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }

  String _formatShortVal(HealthMetricType metric, double val) {
    if (metric == HealthMetricType.steps) {
      return val >= 1000
          ? '${(val / 1000).toStringAsFixed(1)}k'
          : val.toInt().toString();
    }
    if (metric == HealthMetricType.calories) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }
}

class _ChartMetricSeries {
  final List<DateTime> dates;
  final List<double> values;

  const _ChartMetricSeries({required this.dates, required this.values});
}
