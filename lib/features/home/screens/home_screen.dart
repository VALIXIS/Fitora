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
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/profile/screens/profile_screen.dart';
import 'package:fitora/shared/widgets/fitora_background.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _buildSyncLabel(SyncStatus syncStatus, DateTime? lastSyncTime) {
    if (syncStatus == SyncStatus.syncing) return 'Syncing...';
    if (syncStatus == SyncStatus.error) return 'Sync failed';
    if (lastSyncTime == null) return 'Never synced';
    final diff = DateTime.now().difference(lastSyncTime);
    if (diff.inSeconds < 60) return 'Last synced just now';
    if (diff.inMinutes < 60) return 'Last synced ${diff.inMinutes} min ago';
    final localTime = lastSyncTime.toLocal();
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
    final syncStatus = ref.watch(healthSyncServiceProvider); // Rebuilds on sync

    final profile = ref.watch(personalizationControllerProvider).profile;
    final String greeting;
    if (profile.name != null && profile.name!.trim().isNotEmpty) {
      final firstName = profile.name!.trim().split(' ').first;
      greeting = 'Good morning, $firstName';
    } else {
      greeting = 'Welcome';
    }

    final lastWeek = today.subtract(const Duration(days: 6));
    final weeklySummaries = ref.watch(weeklyActivityProvider(lastWeek));

    return FitoraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: () =>
              ref.read(healthSyncServiceProvider.notifier).syncNow(),
          color: const Color(0xFF06B6D4),
          backgroundColor: const Color(0xFF0D1117),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Premium SafeArea Header ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildHeader(textTheme, activity, greeting, syncStatus),
              ),

              // ── Scrollable Dashboard Grid ──────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FitoraSpacing.xl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: FitoraSpacing.sm),

                    // Hero Steps Card (Visual Centerpiece)
                    _buildHeroStepsCard(textTheme, activity),
                    const SizedBox(height: FitoraSpacing.xl),

                    // Quick Stats Section Header
                    Text(
                      'QUICK STATS',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.white30,
                      ),
                    ),
                    const SizedBox(height: FitoraSpacing.md),

                    // Quick Stats Grid (Calories, Active Time, Distance, Hydration)
                    Consumer(
                      builder: (context, ref, _) {
                        final wellness = ref.watch(wellnessProvider);
                        return _buildQuickStats(textTheme, activity, wellness);
                      },
                    ),
                    const SizedBox(height: FitoraSpacing.xl),

                    // Weekly Activity Section
                    _buildWeeklyActivity(textTheme, weeklySummaries),
                    const SizedBox(height: FitoraSpacing.xl),

                    // Daily Goals Section Header
                    Text(
                      'DAILY GOALS',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.white30,
                      ),
                    ),
                    const SizedBox(height: FitoraSpacing.md),

                    // Daily Goals Cards (Steps, Hydration, Sleep)
                    Consumer(
                      builder: (context, ref, _) {
                        final wellness = ref.watch(wellnessProvider);
                        return _buildDailyGoals(
                          textTheme,
                          activity,
                          wellness,
                          today,
                        );
                      },
                    ),
                    const SizedBox(height: FitoraSpacing.xl),

                    // Connection Prompt (if never synced before)
                    _buildSyncPrompt(context, textTheme, activity),

                    const SizedBox(height: 100), // Bottom scroll padding
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    TextTheme textTheme,
    DailyActivitySummary activity,
    String greeting,
    SyncStatus syncStatus,
  ) {
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
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Image.asset(
                      'assets/icon_foreground.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: FitoraSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          greeting,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.sync_rounded,
                              color: Colors.white38,
                              size: 10,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _buildSyncLabel(
                                  syncStatus,
                                  activity.lastSyncTime,
                                ),
                                style: textTheme.labelSmall?.copyWith(
                                  color: syncStatus == SyncStatus.syncing
                                      ? const Color(0xFF06B6D4)
                                      : syncStatus == SyncStatus.error
                                      ? Colors.redAccent
                                      : Colors.white38,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Badge(
                backgroundColor: FitoraColors.mintGreen,
                smallSize: 8,
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStepsCard(
    TextTheme textTheme,
    DailyActivitySummary activity,
  ) {
    final stepsValue = activity.steps;
    final stepsGoal = activity.stepsGoal;
    final progress = activity.stepsProgress;

    final formattedSteps = stepsValue.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

    final goalFormatted = stepsGoal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    final stepsGoalText = stepsValue == 0
        ? "Start walking to begin tracking today's progress."
        : 'Goal: $goalFormatted';

    return GestureDetector(
      onTap: () => showStepGoalPicker(context, ref, activity.stepsGoal),
      child: GlowContainer(
        glowColor: FitoraColors.mintGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(FitoraSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: FitoraColors.mintGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: FitoraColors.mintGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${(progress * 100).toInt()}% OF GOAL',
                        style: textTheme.labelSmall?.copyWith(
                          color: FitoraColors.mintGreen,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: FitoraSpacing.md),
                    Text(
                      'Today\'s Steps',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stepsValue == 0 ? '0' : formattedSteps,
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stepsGoalText,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FitoraSpacing.md),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 9,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        FitoraColors.mintGreen,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FitoraColors.mintGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_walk_rounded,
                      color: FitoraColors.mintGreen,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
    );
  }

  Widget _buildQuickStats(
    TextTheme textTheme,
    DailyActivitySummary activity,
    wellness,
  ) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'Active',
                    value: activity.activeMinutes.toString(),
                    unit: ' min',
                    icon: Icons.timer_rounded,
                    color: FitoraColors.mintGreen,
                    textTheme: textTheme,
                  ),
                ),
                const SizedBox(width: FitoraSpacing.sm),
                Expanded(
                  child: _buildStatCard(
                    label: 'Calories',
                    value: activity.caloriesBurned.toInt().toString(),
                    unit: ' kcal',
                    icon: Icons.local_fire_department_rounded,
                    color: FitoraColors.softEmerald,
                    textTheme: textTheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FitoraSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'Distance',
                    value: activity.distanceKm.toStringAsFixed(1),
                    unit: ' km',
                    icon: Icons.route_rounded,
                    color: FitoraColors.calmCyan,
                    textTheme: textTheme,
                  ),
                ),
                const SizedBox(width: FitoraSpacing.sm),
                Expanded(
                  child: _buildStatCard(
                    label: 'Hydration',
                    value: wellness.hydrationLiters.toStringAsFixed(1),
                    unit: ' L',
                    icon: Icons.water_drop_rounded,
                    color: Colors.blueAccent,
                    textTheme: textTheme,
                  ),
                ),
              ],
            ),
          ],
        )
        .animate()
        .fadeIn(delay: 150.ms, duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String unit,
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: FitoraSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
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

  Widget _buildWeeklyActivity(
    TextTheme textTheme,
    List<DailyActivitySummary> summaries,
  ) {
    final maxSteps = summaries.isEmpty
        ? 1
        : summaries
              .map((s) => s.steps)
              .reduce((curr, next) => curr > next ? curr : next);
    final maxVal = maxSteps == 0 ? 1 : maxSteps;

    final now = DateTime.now();
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Overview',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.progress),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Details',
                            style: textTheme.labelLarge?.copyWith(
                              color: FitoraColors.mintGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: FitoraColors.mintGreen,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FitoraSpacing.xl),
                SizedBox(
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(summaries.length, (index) {
                      final summary = summaries[index];
                      final steps = summary.steps;
                      final date = summary.date;

                      final isToday =
                          date.day == now.day &&
                          date.month == now.month &&
                          date.year == now.year;
                      final double ratio = (steps / maxVal).clamp(0.02, 1.0);

                      final labelIndex = (date.weekday - 1) % 7;
                      final dayLabel = weekdays[labelIndex];

                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (steps > 0)
                              Text(
                                steps >= 1000
                                    ? '${(steps / 1000).toStringAsFixed(1)}k'
                                    : '$steps',
                                style: textTheme.labelSmall?.copyWith(
                                  color: isToday
                                      ? FitoraColors.mintGreen
                                      : Colors.white30,
                                  fontSize: 9,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              )
                            else
                              const Text(
                                '-',
                                style: TextStyle(
                                  color: Colors.white12,
                                  fontSize: 9,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final barHeight =
                                      constraints.maxHeight * ratio;
                                  return Container(
                                    width: 12,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isToday
                                            ? [
                                                FitoraColors.mintGreen,
                                                FitoraColors.softEmerald,
                                              ]
                                            : [
                                                FitoraColors.calmCyan
                                                    .withValues(alpha: 0.4),
                                                FitoraColors.calmCyan
                                                    .withValues(alpha: 0.1),
                                              ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                        color: isToday
                                            ? FitoraColors.mintGreen.withValues(
                                                alpha: 0.8,
                                              )
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                      boxShadow: isToday
                                          ? [
                                              BoxShadow(
                                                color: FitoraColors.mintGreen
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dayLabel,
                              style: textTheme.labelSmall?.copyWith(
                                color: isToday ? Colors.white : Colors.white30,
                                fontWeight: isToday
                                    ? FontWeight.w900
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildDailyGoals(
    TextTheme textTheme,
    DailyActivitySummary activity,
    wellness,
    DateTime today,
  ) {
    final sleep = ref.watch(sleepSummaryProvider(today));
    final hasSleep = sleep.totalSleep.inMinutes > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGoalCard(
          title: activity.sensorStatus == SensorStatus.active
              ? 'Step Goal  🟢'
              : 'Step Goal',
          subtitle: activity.steps == 0
              ? "Start walking to begin tracking today's progress."
              : '${activity.steps.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")} / ${activity.stepsGoal.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")} steps',
          progress: activity.stepsProgress,
          icon: Icons.directions_walk_rounded,
          color: FitoraColors.mintGreen,
          textTheme: textTheme,
          onTap: () => showStepGoalPicker(context, ref, activity.stepsGoal),
        ),
        const SizedBox(height: FitoraSpacing.sm),
        _buildGoalCard(
          title: 'Hydration',
          subtitle: wellness.hydrationGoalLiters == 0
              ? 'Set Daily Water Goal'
              : (wellness.hydrationLiters == 0
                    ? 'Log your first glass of water today.'
                    : '${wellness.hydrationLiters.toStringAsFixed(1)} / ${wellness.hydrationGoalLiters.toStringAsFixed(1)} L'),
          progress: wellness.hydrationGoalLiters == 0
              ? 0.0
              : (wellness.hydrationLiters / wellness.hydrationGoalLiters).clamp(
                  0.0,
                  1.0,
                ),
          icon: Icons.water_drop_rounded,
          color: Colors.blueAccent,
          textTheme: textTheme,
        ),
        if (hasSleep) ...[
          const SizedBox(height: FitoraSpacing.sm),
          _buildGoalCard(
            title: 'Sleep',
            subtitle:
                '${sleep.totalSleep.inHours}h ${sleep.totalSleep.inMinutes.remainder(60)}m logged',
            progress: (sleep.totalSleep.inMinutes / 480.0).clamp(0.0, 1.0),
            icon: Icons.bedtime_rounded,
            color: FitoraColors.calmCyan,
            textTheme: textTheme,
          ),
        ],
      ],
    ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildGoalCard({
    required String title,
    required String subtitle,
    required double progress,
    required IconData icon,
    required Color color,
    required TextTheme textTheme,
    VoidCallback? onTap,
  }) {
    final card = GlowContainer(
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: FitoraSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FitoraSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }

  Widget _buildSyncPrompt(
    BuildContext context,
    TextTheme textTheme,
    DailyActivitySummary activity,
  ) {
    if (activity.lastSyncTime != null) return const SizedBox.shrink();

    final hasSensorIssue =
        activity.sensorStatus == SensorStatus.unknown ||
        activity.sensorStatus == SensorStatus.permissionRequired;

    return GlowContainer(
      glowColor: FitoraColors.mintGreen.withValues(alpha: 0.08),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FitoraColors.mintGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.link_rounded,
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
                        'Connect Health Data',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasSensorIssue
                            ? 'Enable sensors or connect health integration to sync your activity.'
                            : 'Sync steps and metrics automatically with your health source.',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: FitoraSpacing.md),
            Row(
              children: [
                if (hasSensorIssue) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await ref
                            .read(healthSyncServiceProvider.notifier)
                            .syncNow();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        'Permissions',
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: FitoraSpacing.sm),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        context.pushNamed(AppRouteNames.healthSync),
                    style: FilledButton.styleFrom(
                      backgroundColor: FitoraColors.mintGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'Connect Now',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}
