import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/providers/health_providers.dart';
import 'package:fitora/features/progress/domain/progress_models.dart';
import 'package:fitora/features/progress/providers/health_analytics_provider.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';
import 'package:fitora/features/wellness/domain/wellness_models.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

class HealthTrendChart extends ConsumerStatefulWidget {
  const HealthTrendChart({super.key});

  @override
  ConsumerState<HealthTrendChart> createState() => _HealthTrendChartState();
}

class _HealthTrendChartState extends ConsumerState<HealthTrendChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animCurve;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animCurve = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerAnimation() {
    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final timeframe = ref.watch(healthTimeframeProvider);
    final selectedMetric = ref.watch(healthSelectedMetricProvider);

    // Listen to timeframe or metric changes to trigger animation
    ref.listen(healthTimeframeProvider, (_, _) => _triggerAnimation());
    ref.listen(healthSelectedMetricProvider, (_, _) => _triggerAnimation());

    // Fetch health activity range based on timeframe days (x2 for prior comparison)
    final daysCount = timeframe.days;
    final currentActivities = ref.watch(healthActivityRangeProvider(daysCount));
    final priorActivities = ref.watch(healthActivityRangeProvider(daysCount * 2));
    final wellness = ref.watch(wellnessProvider);

    final series = _extractMetricSeries(
      timeframe: timeframe,
      metric: selectedMetric,
      activities: currentActivities,
      wellnessState: wellness,
    );

    final deltaPct = _calculateDeltaPercentage(
      timeframe: timeframe,
      metric: selectedMetric,
      currentActivities: currentActivities,
      priorActivities: priorActivities,
      wellnessState: wellness,
    );

    final hasData = series.values.any((v) => v > 0);
    final avgValue = hasData
        ? (series.values.reduce((a, b) => a + b) / series.values.length)
        : 0.0;

    final metricColor = _getMetricColor(selectedMetric);

    return RepaintBoundary(
      child: GlowContainer(
        glowColor: metricColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(FitoraSpacing.xl),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ??
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Title & Delta Information (Clean & Uncluttered)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRENDS & ANALYTICS',
                    style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        hasData
                            ? 'Avg: ${_formatMetricValue(selectedMetric, avgValue)} ${selectedMetric.unit}'
                            : 'No entries recorded',
                        style: tt.bodySmall?.copyWith(
                          color: hasData
                              ? metricColor
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildDeltaBadge(
                        context: context,
                        tt: tt,
                        deltaPct: deltaPct,
                        timeframe: timeframe,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: FitoraSpacing.lg),

              // Supported Metric Selector Chips (Steps, Sleep, Hydration, etc.)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: HealthMetricType.values.map((metric) {
                    final isSelected = metric == selectedMetric;
                    final mColor = _getMetricColor(metric);
                    return Padding(
                      padding: const EdgeInsets.only(right: FitoraSpacing.xs),
                      child: ChoiceChip(
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _touchedIndex = null);
                          ref
                              .read(healthSelectedMetricProvider.notifier)
                              .state = metric;
                        },
                        avatar: Icon(
                          _getMetricIcon(metric),
                          size: 14,
                          color: isSelected ? Colors.black : mColor,
                        ),
                        label: Text(
                          metric.displayName,
                          style: tt.labelSmall?.copyWith(
                            color: isSelected
                                ? Colors.black
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        selectedColor: mColor,
                        backgroundColor: theme.colorScheme.onSurface
                            .withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? mColor
                                : theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: FitoraSpacing.xl),

              // Animated Chart Render or Empty State
              if (!hasData)
                _buildEmptyState(context, tt, selectedMetric)
              else
                _buildInteractiveSplineChart(
                  context: context,
                  tt: tt,
                  series: series,
                  metric: selectedMetric,
                  color: metricColor,
                ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),
    );
  }

  // ── Delta Badge Implementation ───────────────────────────────────────────────
  Widget _buildDeltaBadge({
    required BuildContext context,
    required TextTheme tt,
    required double deltaPct,
    required HealthTimeframe timeframe,
  }) {
    final isPositive = deltaPct > 0;
    final isZero = deltaPct == 0;

    // Positive -> Green styling
    // Negative -> Amber/warning styling (as requested in spec section 6)
    // Zero -> Neutral surface styling
    final Color color;
    final IconData icon;

    if (isZero) {
      color = Theme.of(context).colorScheme.onSurfaceVariant;
      icon = Icons.remove_rounded;
    } else if (isPositive) {
      color = FitoraColors.mintGreen;
      icon = Icons.trending_up_rounded;
    } else {
      color = FitoraColors.warningOrange; // Amber warning treatment
      icon = Icons.trending_down_rounded;
    }

    final String timeSuffix;
    switch (timeframe) {
      case HealthTimeframe.day:
        timeSuffix = 'vs yesterday';
        break;
      case HealthTimeframe.sevenDays:
        timeSuffix = 'vs last week';
        break;
      case HealthTimeframe.thirtyDays:
        timeSuffix = 'vs last month';
        break;
    }

    final sign = isPositive ? '+' : '';
    final label = '$sign${deltaPct.toStringAsFixed(0)}% $timeSuffix';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 3),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Interactive Spline Chart Render ──────────────────────────────────────────
  Widget _buildInteractiveSplineChart({
    required BuildContext context,
    required TextTheme tt,
    required _ChartMetricSeries series,
    required HealthMetricType metric,
    required Color color,
  }) {
    final maxVal = series.values.fold<double>(
      0.0,
      (curr, next) => curr > next ? curr : next,
    );
    final maxY = maxVal == 0.0 ? 1.0 : maxVal * 1.15; // 15% headroom

    return Column(
      children: [
        // Chart Canvas Area
        SizedBox(
          height: 160,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = constraints.maxWidth;

              return GestureDetector(
                onPanStart: (details) =>
                    _updateTouchIndex(details.localPosition.dx, chartWidth, series.values.length),
                onPanUpdate: (details) =>
                    _updateTouchIndex(details.localPosition.dx, chartWidth, series.values.length),
                onTapDown: (details) =>
                    _updateTouchIndex(details.localPosition.dx, chartWidth, series.values.length),
                onPanEnd: (_) => setState(() => _touchedIndex = null),
                onTapCancel: () => setState(() => _touchedIndex = null),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Animated Spline CustomPainter
                    AnimatedBuilder(
                      animation: _animCurve,
                      builder: (context, child) {
                        return CustomPaint(
                          size: Size(constraints.maxWidth, 160),
                          painter: _SplineChartPainter(
                            values: series.values,
                            labels: series.labels,
                            animationProgress: _animCurve.value,
                            color: color,
                            selectedIndex: _touchedIndex,
                            maxY: maxY,
                            context: context,
                          ),
                        );
                      },
                    ),

                    // Touch Tooltip Overlay
                    if (_touchedIndex != null &&
                        _touchedIndex! >= 0 &&
                        _touchedIndex! < series.values.length)
                      _buildTooltipOverlay(
                        context: context,
                        tt: tt,
                        series: series,
                        index: _touchedIndex!,
                        metric: metric,
                        color: color,
                        maxY: maxY,
                        chartWidth: constraints.maxWidth,
                        chartHeight: 160,
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // X-Axis Date / Time Labels Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _buildXAxisLabels(context, tt, series),
        ),
      ],
    );
  }

  void _updateTouchIndex(double touchX, double chartWidth, int dataCount) {
    if (dataCount <= 0 || chartWidth <= 0) return;
    const paddingLeft = 12.0;
    const paddingRight = 12.0;
    final availableWidth = chartWidth - paddingLeft - paddingRight;
    final stepX = dataCount > 1 ? availableWidth / (dataCount - 1) : availableWidth;

    final relativeX = touchX - paddingLeft;
    final rawIndex = (relativeX / stepX).round();
    final clampedIndex = rawIndex.clamp(0, dataCount - 1);

    if (_touchedIndex != clampedIndex) {
      setState(() {
        _touchedIndex = clampedIndex;
      });
    }
  }

  // ── Exact-Value Tooltip Overlay ──────────────────────────────────────────────
  Widget _buildTooltipOverlay({
    required BuildContext context,
    required TextTheme tt,
    required _ChartMetricSeries series,
    required int index,
    required HealthMetricType metric,
    required Color color,
    required double maxY,
    required double chartWidth,
    required double chartHeight,
  }) {
    final val = series.values[index];
    final label = series.labels[index];
    final fullDate = series.fullDates.length > index ? series.fullDates[index] : label;

    const paddingLeft = 12.0;
    const paddingRight = 12.0;
    const paddingTop = 16.0;
    const paddingBottom = 28.0;

    final availW = chartWidth - paddingLeft - paddingRight;
    final availH = chartHeight - paddingTop - paddingBottom;
    final count = series.values.length;
    final stepX = count > 1 ? availW / (count - 1) : availW / 2;

    final pointX = paddingLeft + (count > 1 ? index * stepX : availW / 2);
    final normalizedY = (maxY > 0 ? (val / maxY) : 0.0).clamp(0.0, 1.0);
    final pointY = paddingTop + availH * (1.0 - normalizedY);

    // Exact value string formatting
    final formattedValue = _formatExactTooltipValue(metric, val);

    const tooltipWidth = 120.0;
    const tooltipHeight = 44.0;

    // Clamp horizontal position within chart bounds
    final leftPos = (pointX - tooltipWidth / 2).clamp(
      6.0,
      chartWidth - tooltipWidth - 6.0,
    );

    // Position above point unless near top edge
    final topPos = pointY - tooltipHeight - 12 < 0
        ? pointY + 14
        : pointY - tooltipHeight - 10;

    return Positioned(
      left: leftPos,
      top: topPos,
      child: IgnorePointer(
        child: Container(
          width: tooltipWidth,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                fullDate,
                style: tt.labelSmall?.copyWith(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                formattedValue,
                style: tt.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatExactTooltipValue(HealthMetricType metric, double val) {
    final formatter = NumberFormat('#,###');
    switch (metric) {
      case HealthMetricType.steps:
        return '${formatter.format(val.toInt())} steps';
      case HealthMetricType.sleep:
        return '${val.toStringAsFixed(1)} hours';
      case HealthMetricType.water:
        return '${val.toStringAsFixed(1)} L';
      case HealthMetricType.distance:
        return '${val.toStringAsFixed(1)} km';
      case HealthMetricType.calories:
        return '${formatter.format(val.toInt())} kcal';
    }
  }

  // ── X-Axis Labels Generator ──────────────────────────────────────────────────
  List<Widget> _buildXAxisLabels(
    BuildContext context,
    TextTheme tt,
    _ChartMetricSeries series,
  ) {
    final theme = Theme.of(context);
    final count = series.labels.length;
    if (count <= 0) return [];

    // Select label indices to avoid overcrowding
    final step = count <= 8
        ? 1
        : count <= 15
            ? 2
            : (count / 6).ceil();

    final labelsWidgets = <Widget>[];
    for (int i = 0; i < count; i++) {
      if (i % step == 0 || i == count - 1) {
        final isSelected = _touchedIndex == i;
        labelsWidgets.add(
          Text(
            series.labels[i],
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontSize: 9.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }
    }
    return labelsWidgets;
  }

  // ── Empty State ──────────────────────────────────────────────────────────────
  Widget _buildEmptyState(
    BuildContext context,
    TextTheme tt,
    HealthMetricType metric,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(FitoraSpacing.lg),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(
            _getMetricIcon(metric),
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            size: 36,
          ),
          const SizedBox(height: FitoraSpacing.md),
          Text(
            'No ${metric.displayName} Data Available',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Log daily activities to see trend analytics.',
            style: tt.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Metric Series Extraction Logic ───────────────────────────────────────────
  _ChartMetricSeries _extractMetricSeries({
    required HealthTimeframe timeframe,
    required HealthMetricType metric,
    required List<DailyActivitySummary> activities,
    required WellnessState wellnessState,
  }) {
    final values = <double>[];
    final labels = <String>[];
    final fullDates = <String>[];

    final dateFormatMonthDay = DateFormat('MMM d');
    final dateFormatFull = DateFormat('EEE, MMM d');

    if (timeframe == HealthTimeframe.day) {
      // 24-hour intraday focus breakdown (8 intervals: 03:00 to 24:00)
      final todaySummary = activities.isNotEmpty
          ? activities.last
          : DailyActivitySummary.empty();

      final hourSlots = ['3 AM', '6 AM', '9 AM', '12 PM', '3 PM', '6 PM', '9 PM', '12 AM'];
      final weights = [0.02, 0.08, 0.20, 0.25, 0.20, 0.15, 0.08, 0.02];

      for (int i = 0; i < hourSlots.length; i++) {
        labels.add(hourSlots[i]);
        fullDates.add('Today at ${hourSlots[i]}');

        switch (metric) {
          case HealthMetricType.steps:
            values.add((todaySummary.steps * weights[i]).roundToDouble());
            break;
          case HealthMetricType.sleep:
            final mins = wellnessState.sleepMinutes;
            final sleepHrs = mins > 0 ? mins / 60.0 : 7.5;
            // Sleep active mostly in night/morning slots (indices 0, 1, 7)
            final sleepWeight = (i == 0 || i == 1 || i == 7) ? 0.33 : 0.0;
            values.add((sleepHrs * sleepWeight).clamp(0.0, 12.0));
            break;
          case HealthMetricType.water:
            final waterLiters = wellnessState.hydrationLiters;
            final cumulativeFrac = (i + 1) / hourSlots.length;
            values.add(double.parse((waterLiters * cumulativeFrac).toStringAsFixed(2)));
            break;
          case HealthMetricType.distance:
            values.add(double.parse((todaySummary.distanceKm * weights[i]).toStringAsFixed(2)));
            break;
          case HealthMetricType.calories:
            values.add((todaySummary.caloriesBurned * weights[i]).roundToDouble());
            break;
        }
      }
    } else {
      // Week (7 days) or Month (30 days)
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      for (final act in activities) {
        final dateStr =
            "${act.date.year}-${act.date.month.toString().padLeft(2, '0')}-${act.date.day.toString().padLeft(2, '0')}";

        if (timeframe == HealthTimeframe.sevenDays) {
          labels.add(dayNames[act.date.weekday - 1]);
        } else {
          labels.add(dateFormatMonthDay.format(act.date));
        }

        fullDates.add(dateFormatFull.format(act.date));

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
            final mins = wellnessState.sleepLogHistory[dateStr] ??
                (act.date.day == DateTime.now().day
                    ? wellnessState.sleepMinutes
                    : 0);
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
                final isToday = act.date.year == DateTime.now().year &&
                    act.date.month == DateTime.now().month &&
                    act.date.day == DateTime.now().day;
                water = isToday ? wellnessState.hydrationLiters : 0.0;
              }
            }
            values.add(water);
            break;
        }
      }
    }

    return _ChartMetricSeries(
      values: values,
      labels: labels,
      fullDates: fullDates,
    );
  }

  // ── Delta Calculation Logic ──────────────────────────────────────────────────
  double _calculateDeltaPercentage({
    required HealthTimeframe timeframe,
    required HealthMetricType metric,
    required List<DailyActivitySummary> currentActivities,
    required List<DailyActivitySummary> priorActivities,
    required WellnessState wellnessState,
  }) {
    if (priorActivities.isEmpty) return 0.0;

    final count = timeframe.days;
    final currentList = currentActivities.length >= count
        ? currentActivities.sublist(currentActivities.length - count)
        : currentActivities;

    final priorList = priorActivities.length >= count * 2
        ? priorActivities.sublist(0, count)
        : <DailyActivitySummary>[];

    if (currentList.isEmpty || priorList.isEmpty) return 0.0;

    double currentSum = 0.0;
    double priorSum = 0.0;

    for (int i = 0; i < currentList.length; i++) {
      currentSum += _getMetricValueForDay(metric, currentList[i], wellnessState);
    }
    for (int i = 0; i < priorList.length; i++) {
      priorSum += _getMetricValueForDay(metric, priorList[i], wellnessState);
    }

    if (priorSum == 0.0) {
      return currentSum > 0.0 ? 100.0 : 0.0;
    }

    final delta = ((currentSum - priorSum) / priorSum) * 100.0;
    return delta.isNaN || delta.isInfinite ? 0.0 : delta;
  }

  double _getMetricValueForDay(
    HealthMetricType metric,
    DailyActivitySummary act,
    WellnessState wellness,
  ) {
    final dateStr =
        "${act.date.year}-${act.date.month.toString().padLeft(2, '0')}-${act.date.day.toString().padLeft(2, '0')}";
    switch (metric) {
      case HealthMetricType.steps:
        return act.steps.toDouble();
      case HealthMetricType.distance:
        return act.distanceKm;
      case HealthMetricType.calories:
        return act.caloriesBurned;
      case HealthMetricType.sleep:
        final mins = wellness.sleepLogHistory[dateStr] ?? 0;
        return mins / 60.0;
      case HealthMetricType.water:
        return wellness.waterLogHistory[dateStr] ?? 0.0;
    }
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

  String _formatMetricValue(HealthMetricType metric, double val) {
    if (metric == HealthMetricType.steps ||
        metric == HealthMetricType.calories) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }
}

// ── Chart Data Series Data Structure ──────────────────────────────────────────
class _ChartMetricSeries {
  final List<double> values;
  final List<String> labels;
  final List<String> fullDates;

  const _ChartMetricSeries({
    required this.values,
    required this.labels,
    required this.fullDates,
  });
}

// ── Smooth Bezier Spline CustomPainter ─────────────────────────────────────────
class _SplineChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double animationProgress;
  final Color color;
  final int? selectedIndex;
  final double maxY;
  final BuildContext context;

  _SplineChartPainter({
    required this.values,
    required this.labels,
    required this.animationProgress,
    required this.color,
    required this.selectedIndex,
    required this.maxY,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const paddingLeft = 12.0;
    const paddingRight = 12.0;
    const paddingTop = 16.0;
    const paddingBottom = 28.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    final n = values.length;
    final stepX = n > 1 ? chartWidth / (n - 1) : chartWidth / 2;

    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = paddingLeft + (n > 1 ? i * stepX : chartWidth / 2);
      final normalizedY = (maxY > 0 ? (values[i] / maxY) : 0.0).clamp(0.0, 1.0);
      final y = paddingTop + chartHeight * (1.0 - normalizedY * animationProgress);
      points.add(Offset(x, y));
    }

    // Gridlines
    final gridPaint = Paint()
      ..color = Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(paddingLeft, paddingTop + chartHeight),
      Offset(size.width - paddingRight, paddingTop + chartHeight),
      gridPaint,
    );
    canvas.drawLine(
      Offset(paddingLeft, paddingTop + chartHeight / 2),
      Offset(size.width - paddingRight, paddingTop + chartHeight / 2),
      gridPaint,
    );

    if (points.length < 2) {
      if (points.isNotEmpty) {
        final p = points.first;
        canvas.drawCircle(p, 6.0, Paint()..color = color);
        canvas.drawCircle(p, 3.0, Paint()..color = Colors.white);
      }
      return;
    }

    // Construct smooth spline path using cubic Bezier control points
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : p2;

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;

      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p0.dy) / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    // Gradient fill under spline curve
    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
    fillPath.lineTo(points.first.dx, paddingTop + chartHeight);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0.28),
        color.withValues(alpha: 0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
        Rect.fromLTWH(0, paddingTop, size.width, chartHeight),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Spline stroke
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // Data points & selected hover highlight
    final drawDotsStep = n > 15 ? 5 : 1;
    for (int i = 0; i < points.length; i++) {
      if (i % drawDotsStep == 0 || i == n - 1 || i == selectedIndex) {
        final pt = points[i];
        final isSelected = i == selectedIndex;

        if (isSelected) {
          // Vertical guide line
          final guidePaint = Paint()
            ..color = color.withValues(alpha: 0.45)
            ..strokeWidth = 1.5;
          canvas.drawLine(
            Offset(pt.dx, paddingTop),
            Offset(pt.dx, paddingTop + chartHeight),
            guidePaint,
          );

          // Glowing selected dot
          canvas.drawCircle(pt, 9.0, Paint()..color = color.withValues(alpha: 0.3));
          canvas.drawCircle(pt, 5.5, Paint()..color = color);
          canvas.drawCircle(pt, 2.5, Paint()..color = Colors.white);
        } else {
          canvas.drawCircle(pt, 3.5, Paint()..color = color);
          canvas.drawCircle(pt, 1.5, Paint()..color = Colors.white);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SplineChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.color != color ||
        oldDelegate.maxY != maxY ||
        oldDelegate.values != values;
  }
}
