import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/shared/widgets/glow_container.dart';
import 'package:fitora/core/health/providers/health_providers.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/features/progress/domain/progress_models.dart';
import 'package:fitora/features/progress/providers/health_analytics_provider.dart';
import 'package:fitora/features/progress/providers/progress_controller.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';
import 'package:fitora/features/wellness/domain/wellness_models.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/progress/widgets/weekly_summary_card.dart';
import 'package:fitora/features/progress/widgets/health_trend_chart.dart';
import 'package:fitora/shared/widgets/fitora_background.dart';
import 'package:fitora/features/workouts/widgets/log_workout_modal.dart';
import 'package:fitora/features/sleep/widgets/sleep_analysis_modal.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';
import 'package:fitora/core/ads/ad_service.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/features/cycle/providers/cycle_provider.dart';
import 'package:fitora/core/services/haptic_service.dart';
import 'package:fitora/shared/widgets/scale_on_press.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String _historyFilter = 'All'; // 'All', 'Workouts', 'Sleep', 'Hydration', 'Mood'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _calculateDeltaPercentage(double currentVal, double priorVal) {
    if (priorVal == 0.0) {
      return currentVal > 0.0 ? 100.0 : 0.0;
    }
    final res = ((currentVal - priorVal) / priorVal) * 100.0;
    return res.isNaN || res.isInfinite ? 0.0 : res;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final timeframe = ref.watch(healthTimeframeProvider);
    final periodDays = timeframe.days;

    final allSummaries = ref.watch(healthActivityRangeProvider(periodDays * 2));
    final currentSummaries = allSummaries.length >= periodDays
        ? allSummaries.sublist(allSummaries.length - periodDays)
        : allSummaries;
    final priorSummaries = allSummaries.length >= periodDays * 2
        ? allSummaries.sublist(0, periodDays)
        : <DailyActivitySummary>[];

    final weightKg = ref.watch(
      personalizationControllerProvider.select((s) => s.profile.weightKg),
    );
    final hasWeight = weightKg != null && weightKg > 0;

    return DefaultTabController(
      length: 2,
      child: FitoraBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: Semantics(
            button: true,
            label: 'Log Workout',
            child: ScaleOnPress(
              child: FloatingActionButton.extended(
                onPressed: () {
                  ref.read(hapticServiceProvider).buttonPress();
                  LogWorkoutModal.show(context);
                },
                label: const Text(
                  'Log Workout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.add_rounded),
                backgroundColor: FitoraColors.mintGreen,
                foregroundColor: Colors.black,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Top Header with Title and Material TabBar
                _buildHeaderWithTabBar(context, textTheme, theme),

                // TabBarView containing Trends tab and History Logs tab
                Expanded(
                  child: TabBarView(
                    children: [
                      // ── TAB 1: TRENDS EXPERIENCE ─────────────────────────
                      _buildTrendsTabContent(
                        context: context,
                        textTheme: textTheme,
                        timeframe: timeframe,
                        currentSummaries: currentSummaries,
                        priorSummaries: priorSummaries,
                        hasWeight: hasWeight,
                        weightKg: weightKg ?? 0.0,
                      ),

                      // ── TAB 2: HISTORY LOGS ───────────────────────────────
                      _buildHistoryLogsTabContent(
                        context: context,
                        textTheme: textTheme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header & TabBar ────────────────────────────────────────────────────────
  Widget _buildHeaderWithTabBar(
    BuildContext context,
    TextTheme textTheme,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FitoraSpacing.xl,
        FitoraSpacing.md,
        FitoraSpacing.xl,
        FitoraSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analytics & Progress',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: FitoraColors.mintGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: FitoraColors.mintGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      color: FitoraColors.mintGreen,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'FITORA ANALYTICS',
                      style: textTheme.labelSmall?.copyWith(
                        color: FitoraColors.mintGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 9.5,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: FitoraSpacing.md),

          // Clean Material TabBar
          Container(
            height: 44,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: FitoraColors.mintGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
              unselectedLabelStyle: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Trends'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('History Logs'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Trends Content ───────────────────────────────────────────────────
  Widget _buildTrendsTabContent({
    required BuildContext context,
    required TextTheme textTheme,
    required HealthTimeframe timeframe,
    required List<DailyActivitySummary> currentSummaries,
    required List<DailyActivitySummary> priorSummaries,
    required bool hasWeight,
    required double weightKg,
  }) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: FitoraSpacing.xl,
        vertical: FitoraSpacing.md,
      ),
      children: [
        // Period Filter Segmented Toggle (Day / Week / Month)
        _buildPeriodFilterSegmentedControl(textTheme),
        const SizedBox(height: FitoraSpacing.xl),

        // Section 1: Interactive Health Trend Chart (Steps, Sleep, Hydration)
        _buildSectionHeader(textTheme, 'INTERACTIVE HEALTH TRENDS'),
        const SizedBox(height: FitoraSpacing.md),
        const HealthTrendChart(),
        const SizedBox(height: FitoraSpacing.xl),

        // Section 2: Overview Activity Metric Cards
        _buildSectionHeader(textTheme, 'OVERVIEW'),
        const SizedBox(height: FitoraSpacing.md),
        if (currentSummaries.isEmpty) ...[
          _buildEmptyActivityCard(context, textTheme),
        ] else ...[
          _buildActivitySection(
            textTheme,
            currentSummaries,
            priorSummaries,
          ),
        ],
        const SizedBox(height: FitoraSpacing.xl),

        // Section 3: Weekly Performance & WoW Deltas
        _buildSectionHeader(textTheme, 'WEEKLY PERFORMANCE'),
        const SizedBox(height: FitoraSpacing.md),
        const WeeklySummaryCard(),
        const SizedBox(height: FitoraSpacing.xl),

        // Section 4: Recovery (Sleep, Hydration, Cycle, Mood, Breathing)
        _buildSectionHeader(textTheme, 'RECOVERY & WELLNESS'),
        const SizedBox(height: FitoraSpacing.md),
        _buildRecoverySection(context, textTheme),
        const SizedBox(height: FitoraSpacing.xl),

        if (hasWeight) ...[
          _buildWeightTrend(textTheme, weightKg),
          const SizedBox(height: FitoraSpacing.lg),
        ],
        _buildStreakCard(textTheme),
        const SizedBox(height: FitoraSpacing.lg),
        const FitoraNativeAdCard(),
        const SizedBox(height: 120),
      ],
    );
  }

  // ── Tab 2: History Logs Content ─────────────────────────────────────────────
  Widget _buildHistoryLogsTabContent({
    required BuildContext context,
    required TextTheme textTheme,
  }) {
    final theme = Theme.of(context);
    final progressState = ref.watch(progressControllerProvider);
    final wellness = ref.watch(wellnessProvider);

    final historyList = progressState.history;
    final sleepLogs = wellness.sleepLogHistory;
    final waterLogs = wellness.waterLogs;
    final waterHistory = wellness.waterLogHistory;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FitoraSpacing.xl,
            vertical: FitoraSpacing.sm,
          ),
          child: Column(
            children: [
              // Search Input Field
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search logs (workout, sleep, water)...',
                  hintStyle: textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: FitoraColors.mintGreen,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: FitoraSpacing.sm),

              // Filter Category Chips (All, Workouts, Sleep, Hydration)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: ['All', 'Workouts', 'Sleep', 'Hydration'].map((cat) {
                    final isSelected = _historyFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(cat),
                        labelStyle: textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? Colors.black
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                        selectedColor: FitoraColors.mintGreen,
                        backgroundColor: theme.colorScheme.onSurface
                            .withValues(alpha: 0.05),
                        onSelected: (_) {
                          setState(() => _historyFilter = cat);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? FitoraColors.mintGreen
                                : theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Scrollable History Items List
        Expanded(
          child: _buildFilteredHistoryList(
            context: context,
            tt: textTheme,
            historyList: historyList,
            sleepLogs: sleepLogs,
            waterLogs: waterLogs,
            waterHistory: waterHistory,
          ),
        ),
      ],
    );
  }

  Widget _buildFilteredHistoryList({
    required BuildContext context,
    required TextTheme tt,
    required List<WorkoutHistoryEntry> historyList,
    required Map<String, int> sleepLogs,
    required List<WaterLogEntry> waterLogs,
    required Map<String, double> waterHistory,
  }) {
    final theme = Theme.of(context);
    final items = <_HistoryLogItem>[];

    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final dateOnlyFormat = DateFormat('EEE, MMM d, yyyy');

    // 1. Workouts
    if (_historyFilter == 'All' || _historyFilter == 'Workouts') {
      for (final w in historyList) {
        if (_searchQuery.isNotEmpty &&
            !w.title.toLowerCase().contains(_searchQuery) &&
            !'workout'.contains(_searchQuery)) {
          continue;
        }
        items.add(
          _HistoryLogItem(
            dateTime: w.completedAt,
            title: w.title,
            subtitle: '${w.durationLabel} • ${w.calories} kcal • ${w.exercisesCompleted} exercises',
            dateLabel: dateFormat.format(w.completedAt),
            type: _LogType.workout,
            icon: Icons.fitness_center_rounded,
            color: FitoraColors.mintGreen,
          ),
        );
      }
    }

    // 2. Sleep Logs
    if (_historyFilter == 'All' || _historyFilter == 'Sleep') {
      sleepLogs.forEach((dateStr, mins) {
        if (mins > 0) {
          final dt = DateTime.tryParse(dateStr) ?? DateTime.now();
          final hours = (mins / 60.0).toStringAsFixed(1);
          final title = 'Sleep Log ($hours hrs)';
          if (_searchQuery.isNotEmpty &&
              !title.toLowerCase().contains(_searchQuery) &&
              !dateStr.contains(_searchQuery)) {
            return;
          }
          items.add(
            _HistoryLogItem(
              dateTime: dt,
              title: title,
              subtitle: 'Duration: $mins minutes of tracked rest',
              dateLabel: dateOnlyFormat.format(dt),
              type: _LogType.sleep,
              icon: Icons.bedtime_rounded,
              color: FitoraColors.calmCyan,
            ),
          );
        }
      });
    }

    // 3. Hydration Logs
    if (_historyFilter == 'All' || _historyFilter == 'Hydration') {
      for (final wl in waterLogs) {
        final liters = (wl.amountMl / 1000.0).toStringAsFixed(2);
        final title = 'Hydration Intakes: ${wl.amountMl} ml ($liters L)';
        if (_searchQuery.isNotEmpty &&
            !title.toLowerCase().contains(_searchQuery)) {
          continue;
        }
        items.add(
          _HistoryLogItem(
            dateTime: wl.timestamp,
            title: title,
            subtitle: 'Logged via water tracker',
            dateLabel: dateFormat.format(wl.timestamp),
            type: _LogType.water,
            icon: Icons.water_drop_rounded,
            color: Colors.blueAccent,
          ),
        );
      }
    }

    // Sort items by date descending (newest first)
    items.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(FitoraSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_toggle_off_rounded,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: 48,
              ),
              const SizedBox(height: FitoraSpacing.md),
              Text(
                'No History Logs Found',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Log your workouts, sleep, and water intake to view your historical logs here.',
                style: tt.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        FitoraSpacing.xl,
        FitoraSpacing.sm,
        FitoraSpacing.xl,
        120,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: FitoraSpacing.sm),
          child: Container(
            padding: const EdgeInsets.all(FitoraSpacing.md),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ??
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(width: FitoraSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            item.dateLabel,
                            style: tt.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        style: tt.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Period Filter Control for Trends ───────────────────────────────────────
  Widget _buildPeriodFilterSegmentedControl(TextTheme textTheme) {
    final theme = Theme.of(context);
    final currentTimeframe = ref.watch(healthTimeframeProvider);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: HealthTimeframe.values.map((tf) {
          final isSelected = currentTimeframe == tf;
          return Expanded(
            child: Semantics(
              button: true,
              selected: isSelected,
              label: '${tf.label} filter',
              child: GestureDetector(
                onTap: () {
                  ref.read(healthTimeframeProvider.notifier).state = tf;
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [
                                FitoraColors.mintGreen,
                                FitoraColors.calmCyan,
                              ],
                            )
                          : null,
                    ),
                    child: Text(
                      tf.label,
                      textAlign: TextAlign.center,
                      style: textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? Colors.black
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ).animate().fadeIn(duration: 400.ms).slideX(
            begin: 0.1,
            end: 0,
            curve: Curves.easeOutCubic,
          ),
    );
  }

  Widget _buildSectionHeader(TextTheme tt, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: tt.labelSmall?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  // ── Overview Activity Section Cards ─────────────────────────────────────────
  Widget _buildActivitySection(
    TextTheme tt,
    List<DailyActivitySummary> currentSummaries,
    List<DailyActivitySummary> priorSummaries,
  ) {
    final timeframe = ref.watch(healthTimeframeProvider);
    int totalSteps = 0;
    double totalCalories = 0.0;
    int totalActiveMinutes = 0;
    double totalDistanceKm = 0.0;

    for (final s in currentSummaries) {
      totalSteps += s.steps;
      totalCalories += s.caloriesBurned;
      totalActiveMinutes += s.activeMinutes;
      totalDistanceKm += s.distanceKm;
    }

    int priorSteps = 0;
    double priorCalories = 0.0;
    int priorActiveMinutes = 0;
    double priorDistanceKm = 0.0;

    for (final s in priorSummaries) {
      priorSteps += s.steps;
      priorCalories += s.caloriesBurned;
      priorActiveMinutes += s.activeMinutes;
      priorDistanceKm += s.distanceKm;
    }

    final stepsTrend = _calculateDeltaPercentage(
      totalSteps.toDouble(),
      priorSteps.toDouble(),
    );
    final caloriesTrend = _calculateDeltaPercentage(
      totalCalories,
      priorCalories,
    );
    final activeTrend = _calculateDeltaPercentage(
      totalActiveMinutes.toDouble(),
      priorActiveMinutes.toDouble(),
    );
    final distanceTrend = _calculateDeltaPercentage(
      totalDistanceKm,
      priorDistanceKm,
    );

    final isSingleDay = timeframe == HealthTimeframe.day;
    final latestGoal = currentSummaries.isNotEmpty
        ? currentSummaries.last.stepsGoal
        : 10000;

    final stepsValueStr = isSingleDay
        ? totalSteps.toString()
        : (totalSteps >= 10000
            ? '${(totalSteps / 1000).toStringAsFixed(1)}k'
            : totalSteps.toString());
    final stepsUnitStr = isSingleDay ? ' / $latestGoal' : ' steps';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                context,
                label: 'Steps',
                value: stepsValueStr,
                unit: stepsUnitStr,
                trend:
                    '${stepsTrend >= 0 ? "+" : ""}${stepsTrend.toStringAsFixed(0)}%',
                isPositiveTrend: stepsTrend >= 0,
                icon: Icons.directions_walk_rounded,
                color: FitoraColors.mintGreen,
                textTheme: tt,
              ),
            ),
            const SizedBox(width: FitoraSpacing.sm),
            Expanded(
              child: _buildOverviewCard(
                context,
                label: 'Calories',
                value: totalCalories.toInt().toString(),
                unit: ' kcal',
                trend:
                    '${caloriesTrend >= 0 ? "+" : ""}${caloriesTrend.toStringAsFixed(0)}%',
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
                context,
                label: 'Active',
                value: totalActiveMinutes.toString(),
                unit: ' min',
                trend:
                    '${activeTrend >= 0 ? "+" : ""}${activeTrend.toStringAsFixed(0)}%',
                isPositiveTrend: activeTrend >= 0,
                icon: Icons.timer_rounded,
                color: FitoraColors.calmCyan,
                textTheme: tt,
              ),
            ),
            const SizedBox(width: FitoraSpacing.sm),
            Expanded(
              child: _buildOverviewCard(
                context,
                label: 'Distance',
                value: totalDistanceKm.toStringAsFixed(1),
                unit: ' km',
                trend:
                    '${distanceTrend >= 0 ? "+" : ""}${distanceTrend.toStringAsFixed(0)}%',
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

  Widget _buildOverviewCard(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required String trend,
    required bool isPositiveTrend,
    required IconData icon,
    required Color color,
    required TextTheme textTheme,
  }) {
    final theme = Theme.of(context);
    final trendColor = isPositiveTrend
        ? FitoraColors.mintGreen
        : FitoraColors.warningOrange;

    return GlowContainer(
      glowColor: color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.md),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ??
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveTrend
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: trendColor,
                        size: 10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend,
                        style: textTheme.labelSmall?.copyWith(
                          color: trendColor,
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
                      color: theme.colorScheme.onSurface,
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
                        color: theme.colorScheme.onSurfaceVariant,
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
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recovery & Wellness Section ────────────────────────────────────────────
  Widget _buildRecoverySection(BuildContext context, TextTheme tt) {
    return Consumer(
      builder: (context, ref, _) {
        final today = ref.watch(todayProvider);
        final sleep = ref.watch(sleepSummaryProvider(today));
        final wellness = ref.watch(wellnessProvider);
        final todayStr =
            "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
        final mood = wellness.loggedMoods[todayStr] ?? 'Not logged';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSleepCard(context, tt, sleep),
            const SizedBox(height: FitoraSpacing.md),
            _buildHydrationCard(context, ref, tt, wellness),
            if (ref.watch(cycleProvider).cycleTrackingEnabled) ...[
              const SizedBox(height: FitoraSpacing.md),
              _buildCycleCard(context, ref, tt),
            ],
            const SizedBox(height: FitoraSpacing.md),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showMoodDialog(context, ref, mood),
                    child: _buildOverviewCard(
                      context,
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
                ),
                const SizedBox(width: FitoraSpacing.sm),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showBreathingDialog(context, ref),
                    child: _buildOverviewCard(
                      context,
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
                ),
              ],
            ),
          ],
        )
            .animate()
            .fadeIn(delay: 150.ms, duration: 400.ms)
            .slideY(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildHydrationCard(
    BuildContext context,
    WidgetRef ref,
    TextTheme tt,
    WellnessState wellness,
  ) {
    final theme = Theme.of(context);
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
          color: theme.cardTheme.color ??
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
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
                      child: const Icon(
                        Icons.water_drop_rounded,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: FitoraSpacing.md),
                    Text(
                      'HYDRATION',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (liters > 0)
                      IconButton(
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () => ref
                            .read(wellnessProvider.notifier)
                            .resetHydration(),
                        tooltip: 'Reset intake',
                      ),
                    ElevatedButton.icon(
                      onPressed: () => ref
                          .read(wellnessProvider.notifier)
                          .addHydration(0.25),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('+ 250ml'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent.withValues(
                          alpha: 0.2,
                        ),
                        foregroundColor: Colors.blueAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.blueAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
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
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.blueAccent,
                        ),
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
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        goal > 0
                            ? 'Goal: ${goal.toStringAsFixed(1)} L (1 glass = 250ml)'
                            : 'Set Daily Water Goal',
                        style: tt.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
                    color: isFilled
                        ? Colors.blueAccent.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.05),
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

  Widget _buildSleepCard(
    BuildContext context,
    TextTheme tt,
    SleepSummary sleep,
  ) {
    final theme = Theme.of(context);
    final totalMinutes = sleep.totalSleep.inMinutes;
    final hours = sleep.totalSleep.inHours;
    final minutes = sleep.totalSleep.inMinutes.remainder(60);

    final sleepGoalMinutes =
        ref.watch(settingsProvider).sleepTargetDurationMinutes.toDouble();
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

    final hasStages =
        sleep.deepSleep.inMinutes > 0 ||
        sleep.remSleep.inMinutes > 0 ||
        sleep.lightSleep.inMinutes > 0;

    final goalHours = (sleepGoalMinutes / 60).toInt();
    final goalMins = (sleepGoalMinutes % 60).toInt();
    final goalStr =
        goalMins > 0 ? '${goalHours}h ${goalMins}m' : '$goalHours hrs';

    return GestureDetector(
      onTap: () => showSleepAnalysisModal(context, ref),
      child: GlowContainer(
        glowColor: FitoraColors.calmCyan.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(FitoraSpacing.xl),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
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
                        child: const Icon(
                          Icons.bedtime_rounded,
                          color: FitoraColors.calmCyan,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: FitoraSpacing.md),
                      Text(
                        'SLEEP ANALYSIS',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (totalMinutes > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: qualityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: qualityColor.withValues(alpha: 0.3),
                        ),
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
                  'Log your last night\'s sleep or set your target sleep schedule dial.',
                  style: tt.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: FitoraSpacing.md),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => showSleepAnalysisModal(context, ref),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Log Sleep'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FitoraColors.calmCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ],
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
                            backgroundColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.08),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              FitoraColors.calmCyan,
                            ),
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
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sleep Goal: $goalStr',
                            style: tt.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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
                        _buildSleepStageLabel(
                          tt,
                          'Deep',
                          '${sleep.deepSleep.inHours}h ${sleep.deepSleep.inMinutes.remainder(60)}m',
                          Colors.indigoAccent,
                        ),
                      if (sleep.remSleep.inMinutes > 0)
                        _buildSleepStageLabel(
                          tt,
                          'REM',
                          '${sleep.remSleep.inHours}h ${sleep.remSleep.inMinutes.remainder(60)}m',
                          FitoraColors.calmCyan,
                        ),
                      if (sleep.lightSleep.inMinutes > 0)
                        _buildSleepStageLabel(
                          tt,
                          'Light',
                          '${sleep.lightSleep.inHours}h ${sleep.lightSleep.inMinutes.remainder(60)}m',
                          FitoraColors.lavender,
                        ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSleepStageLabel(
    TextTheme tt,
    String label,
    String duration,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                color: Colors.white30,
                fontSize: 9,
              ),
            ),
            Text(
              duration,
              style: tt.labelSmall?.copyWith(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightTrend(TextTheme tt, double currentWeight) {
    final theme = Theme.of(context);
    return GlowContainer(
      glowColor: FitoraColors.lavender.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
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
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Icon(
                  Icons.monitor_weight_rounded,
                  color: FitoraColors.lavender,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: FitoraSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentWeight.toStringAsFixed(1),
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4),
                  child: Text(
                    'kg',
                    style: tt.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(TextTheme tt) {
    final wellness = ref.watch(wellnessProvider);
    if (wellness.wellnessStreak == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return GlowContainer(
      glowColor: FitoraColors.warningOrange.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FitoraColors.warningOrange.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: FitoraColors.warningOrange,
                size: 28,
              ),
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
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Keep the momentum going.',
                    style: tt.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildEmptyActivityCard(BuildContext context, TextTheme tt) {
    final theme = Theme.of(context);
    return GlowContainer(
      glowColor: FitoraColors.mintGreen.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.xl),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.sync_disabled_rounded,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              size: 36,
            ),
            const SizedBox(height: FitoraSpacing.md),
            Text(
              'No activity recorded yet.',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: FitoraSpacing.xs),
            Text(
              'Start tracking today to unlock insights.',
              style: tt.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showMoodDialog(
    BuildContext context,
    WidgetRef ref,
    String currentMood,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final tt = Theme.of(context).textTheme;
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1117),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          title: Text(
            'How are you feeling?',
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Great', 'Good', 'Okay', 'Poor', 'Terrible'].map((mood) {
              final isSelected = mood == currentMood;
              return ListTile(
                title: Text(
                  mood,
                  style: tt.bodyLarge?.copyWith(
                    color: isSelected ? Colors.amber : Colors.white70,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.amber)
                    : null,
                onTap: () {
                  ref.read(wellnessProvider.notifier).logMood(mood);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showBreathingDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        final tt = Theme.of(context).textTheme;
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1117),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          title: Text(
            'Log Breathing',
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Log 5 minutes of mindful breathing?',
                style: tt.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ref.read(wellnessProvider.notifier).addBreathingMinutes(5);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FitoraColors.softEmerald.withValues(
                    alpha: 0.2,
                  ),
                  foregroundColor: FitoraColors.softEmerald,
                ),
                child: const Text('Log 5 mins'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCycleCard(BuildContext context, WidgetRef ref, TextTheme tt) {
    final theme = Theme.of(context);
    final state = ref.watch(cycleProvider);
    if (!state.cycleTrackingEnabled) {
      return const SizedBox.shrink();
    }

    final cycleNotifier = ref.read(cycleProvider.notifier);
    final now = DateTime.now();
    final localToday = DateTime(now.year, now.month, now.day);
    final currentDay = cycleNotifier.getCycleDay(localToday);

    final nextPeriod = cycleNotifier.getEstimatedNextPeriod();
    final stats = cycleNotifier.getStatistics();
    final hasPrediction =
        nextPeriod != null && stats.completedIntervalsCount >= 2;

    String headline = 'Cycle Tracker';
    String sub = 'Keep logging to build your history';
    if (currentDay > 0) {
      headline = 'Cycle Day $currentDay';
    }
    if (hasPrediction) {
      final diff = nextPeriod.difference(localToday).inDays;
      if (diff == 0) {
        sub = 'Next period expected today (Estimated)';
      } else if (diff > 0) {
        sub = 'Next period estimated in $diff days';
      } else {
        sub = 'Next period was expected ${diff.abs()} days ago (Estimated)';
      }
    }

    return GestureDetector(
      onTap: () {
        ref.read(hapticServiceProvider).lightImpact();
        context.push('/progress/cycle');
      },
      child: GlowContainer(
        glowColor: FitoraColors.softPink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(FitoraSpacing.xl),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FitoraColors.softPink.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: FitoraColors.softPink,
                  size: 20,
                ),
              ),
              const SizedBox(width: FitoraSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CYCLE TRACKING',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      headline,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: tt.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Internal Helper Data Model for History Logs List ─────────────────────────
enum _LogType { workout, sleep, water }

class _HistoryLogItem {
  final DateTime dateTime;
  final String title;
  final String subtitle;
  final String dateLabel;
  final _LogType type;
  final IconData icon;
  final Color color;

  const _HistoryLogItem({
    required this.dateTime,
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.type,
    required this.icon,
    required this.color,
  });
}
