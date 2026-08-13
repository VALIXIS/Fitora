import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/shared/widgets/glow_container.dart';
import 'package:fitora/core/health/providers/health_providers.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/auth/providers/auth_providers.dart';
import 'package:fitora/core/services/notification_service.dart';
import 'package:fitora/features/profile/screens/profile_screen.dart';
import 'package:fitora/core/utils/greeting_utils.dart';
import 'package:fitora/shared/widgets/fitora_background.dart';
import 'package:fitora/core/services/permission_manager.dart';
import 'package:fitora/features/home/providers/goals_streak_provider.dart';
import 'package:fitora/features/home/domain/goals_streak_models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PermissionManager.requestFirstLaunchPermissions(context);
      }
    });
  }

  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final tt = Theme.of(context).textTheme;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FitoraColors.mintGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: FitoraColors.mintGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Notifications & Reminders',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.water_drop_rounded, color: Colors.blueAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hydration Check-ins',
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Active every 2 hours (08:00 - 20:00)',
                            style: tt.bodySmall?.copyWith(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, color: FitoraColors.mintGreen, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_walk_rounded, color: FitoraColors.mintGreen, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Goal Summary',
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Scheduled daily at 20:00',
                            style: tt.bodySmall?.copyWith(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, color: FitoraColors.mintGreen, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  await NotificationService().showTestNotification();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification sent! Check your notifications.'),
                        backgroundColor: Color(0xFF0D1117),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Send Test Notification'),
                style: FilledButton.styleFrom(
                  backgroundColor: FitoraColors.mintGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activity = ref.watch(dailyActivityProvider(today));
    final syncStatus = ref.watch(healthSyncServiceProvider);

    final profile = ref.watch(personalizationControllerProvider).profile;
    final authSession = ref.watch(authStateProvider);
    final String greetingPrefix = getDynamicGreeting(now);

    String? name = profile.name;
    if (name == null || name.trim().isEmpty) {
      final user = authSession.user;
      if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
        name = user.displayName;
      } else if (user?.email != null && user!.email!.trim().isNotEmpty) {
        name = user.email!.split('@').first;
      }
    }

    final String greeting;
    if (name != null && name.trim().isNotEmpty) {
      final firstName = name.trim().split(' ').first;
      final capitalized = firstName.substring(0, 1).toUpperCase() + firstName.substring(1);
      greeting = '$greetingPrefix, $capitalized';
    } else {
      greeting = greetingPrefix;
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

                    // Daily Goals Cards (Steps, Hydration, Sleep, Calories)
                    _buildDailyGoals(textTheme, today),
                    const SizedBox(height: FitoraSpacing.xl),

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

  void _showStreakHistoryDialog(
    BuildContext context,
    GoalsStreakState streakState,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1117),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: FitoraColors.warningOrange,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Streak History',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Streak:',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${streakState.currentStreak} ${streakState.currentStreak == 1 ? 'day' : 'days'}',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: FitoraColors.warningOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Longest Streak:',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${streakState.longestStreak} ${streakState.longestStreak == 1 ? 'day' : 'days'}',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: FitoraColors.mintGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Keep up the great work! Smashed targets count towards your streak.',
                style: textTheme.bodySmall?.copyWith(color: Colors.white38),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: FitoraColors.mintGreen),
              ),
            ),
          ],
        );
      },
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
                    child: Text(
                      greeting,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final streakState = ref.watch(goalsStreakProvider);
                    if (streakState.currentStreak == 0)
                      return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () =>
                          _showStreakHistoryDialog(context, streakState),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: FitoraColors.warningOrange.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: FitoraColors.warningOrange.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: FitoraColors.warningOrange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${streakState.currentStreak}',
                              style: textTheme.labelLarge?.copyWith(
                                color: FitoraColors.warningOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              onPressed: () => _showNotificationsModal(context),
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

    return onTap != null ? GestureDetector(onTap: onTap, child: card) : card;
  }

  Widget _buildWeeklyActivity(
    TextTheme textTheme,
    List<DailyActivitySummary> summaries,
  ) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
                      'WEEKLY ACTIVITY',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.white30,
                      ),
                    ),
                    Text(
                      '7 Day Trend',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FitoraSpacing.lg),
                SizedBox(
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final summary = index < summaries.length
                          ? summaries[index]
                          : null;
                      final heightFactor = summary != null
                          ? summary.stepsProgress.clamp(0.1, 1.0)
                          : 0.1;
                      final isToday = index == summaries.length - 1;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 14,
                                height: 80 * heightFactor,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(99),
                                  gradient: isToday
                                      ? const LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            FitoraColors.mintGreen,
                                            FitoraColors.softEmerald,
                                          ],
                                        )
                                      : null,
                                  color: isToday
                                      ? null
                                      : Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: FitoraSpacing.xs),
                          Text(
                            days[index],
                            style: textTheme.labelSmall?.copyWith(
                              color: isToday
                                  ? FitoraColors.mintGreen
                                  : Colors.white38,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
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

  Widget _buildDailyGoals(TextTheme textTheme, DateTime today) {
    final status = ref.watch(dailyGoalStatusProvider(today));

    int completedGoalsCount = status.metrics.where((m) => m.isCompleted).length;
    int trackedGoalsCount = status.metrics
        .where((m) => m.availability == MetricAvailability.available)
        .length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlowContainer(
          glowColor: FitoraColors.mintGreen.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.all(FitoraSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        value: status.completionPercentage / 100,
                        strokeWidth: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation(
                          completedGoalsCount == trackedGoalsCount &&
                                  trackedGoalsCount > 0
                              ? FitoraColors.successGreen
                              : FitoraColors.mintGreen,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Icon(
                      completedGoalsCount == trackedGoalsCount &&
                              trackedGoalsCount > 0
                          ? Icons.emoji_events_rounded
                          : Icons.insights_rounded,
                      color:
                          completedGoalsCount == trackedGoalsCount &&
                              trackedGoalsCount > 0
                          ? FitoraColors.mintGreen
                          : Colors.white70,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(width: FitoraSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        completedGoalsCount == trackedGoalsCount &&
                                trackedGoalsCount > 0
                            ? 'All Daily Goals Smashed! 🎉'
                            : 'Daily Progress',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trackedGoalsCount > 0
                            ? '$completedGoalsCount of $trackedGoalsCount targets completed today'
                            : 'No active goals tracked today',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${status.completionPercentage.toInt()}%',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: FitoraColors.mintGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: FitoraSpacing.md),
        ...status.metrics.map((metric) {
          return Padding(
            padding: const EdgeInsets.only(bottom: FitoraSpacing.sm),
            child: _buildMetricGoalCard(textTheme, metric),
          );
        }),
      ],
    ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildMetricGoalCard(TextTheme textTheme, GoalMetric metric) {
    final color = _getMetricColor(metric.key);
    final icon = _getMetricIcon(metric.key);

    final card = GlowContainer(
      glowColor: metric.isCompleted
          ? color.withValues(alpha: 0.08)
          : color.withValues(alpha: 0.02),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: metric.isCompleted
                ? color.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.08),
          ),
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
                      Row(
                        children: [
                          Text(
                            metric.name,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (metric.isCompleted) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                'MET',
                                style: textTheme.labelSmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      _buildMetricSubtitle(textTheme, metric),
                    ],
                  ),
                ),
                _buildMetricTrailing(textTheme, metric, color),
              ],
            ),
            if (metric.availability == MetricAvailability.available) ...[
              const SizedBox(height: FitoraSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: metric.progressFraction,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ] else if (metric.availability ==
                MetricAvailability.permissionRequired) ...[
              const SizedBox(height: FitoraSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _handleRequestPermission(metric.key),
                    icon: Icon(Icons.lock_open_rounded, size: 14, color: color),
                    label: Text(
                      'Enable Access',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: FitoraSpacing.xs),
            ],
          ],
        ),
      ),
    );

    if (metric.key == 'steps' &&
        metric.availability == MetricAvailability.available) {
      return GestureDetector(
        onTap: () => showStepGoalPicker(context, ref, metric.goal.toInt()),
        child: card,
      );
    }
    return card;
  }

  Color _getMetricColor(String key) {
    switch (key) {
      case 'steps':
        return FitoraColors.mintGreen;
      case 'water':
        return Colors.blueAccent;
      case 'sleep':
        return FitoraColors.calmCyan;
      case 'calories':
        return FitoraColors.softEmerald;
      default:
        return Colors.white;
    }
  }

  IconData _getMetricIcon(String key) {
    switch (key) {
      case 'steps':
        return Icons.directions_walk_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'sleep':
        return Icons.bedtime_rounded;
      case 'calories':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Widget _buildMetricSubtitle(TextTheme textTheme, GoalMetric metric) {
    if (metric.availability == MetricAvailability.permissionRequired) {
      return Text(
        'Permission Required to track ${metric.name.toLowerCase()}',
        style: textTheme.bodySmall?.copyWith(
          color: Colors.orangeAccent.withValues(alpha: 0.8),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    if (metric.availability == MetricAvailability.unavailable) {
      return Text(
        'Data Unavailable (Sensor / Integration missing)',
        style: textTheme.bodySmall?.copyWith(
          color: Colors.white30,
          fontSize: 11,
        ),
      );
    }

    if (metric.key == 'steps') {
      final formattedCurrent = metric.current
          .toInt()
          .toString()
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
      final formattedGoal = metric.goal.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return Text(
        metric.current == 0
            ? "Start walking to begin tracking today's progress."
            : '$formattedCurrent / $formattedGoal steps',
        style: textTheme.bodySmall?.copyWith(
          color: Colors.white54,
          fontSize: 11,
        ),
      );
    }

    if (metric.key == 'water') {
      return Text(
        metric.current == 0
            ? 'Log your first glass of water today.'
            : '${metric.current.toStringAsFixed(1)} / ${metric.goal.toStringAsFixed(1)} L',
        style: textTheme.bodySmall?.copyWith(
          color: Colors.white54,
          fontSize: 11,
        ),
      );
    }

    if (metric.key == 'sleep') {
      final hours = (metric.current / 60).floor();
      final mins = (metric.current % 60).toInt();
      return Text(
        metric.current == 0
            ? 'Log your sleep or sync via Health Connect.'
            : '${hours}h ${mins}m logged of 8h goal',
        style: textTheme.bodySmall?.copyWith(
          color: Colors.white54,
          fontSize: 11,
        ),
      );
    }

    if (metric.key == 'calories') {
      return Text(
        metric.current == 0
            ? 'Active calories burned during workouts.'
            : '${metric.current.toInt()} / ${metric.goal.toInt()} kcal active burned',
        style: textTheme.bodySmall?.copyWith(
          color: Colors.white54,
          fontSize: 11,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMetricTrailing(
    TextTheme textTheme,
    GoalMetric metric,
    Color color,
  ) {
    if (metric.availability == MetricAvailability.permissionRequired) {
      return const Icon(
        Icons.lock_rounded,
        color: Colors.orangeAccent,
        size: 18,
      );
    }
    if (metric.availability == MetricAvailability.unavailable) {
      return const Icon(
        Icons.info_outline_rounded,
        color: Colors.white30,
        size: 18,
      );
    }
    return Text(
      '${metric.percentage.toInt()}%',
      style: textTheme.labelLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Future<void> _handleRequestPermission(String key) async {
    if (key == 'steps') {
      await ref.read(sensorStatusProvider.notifier).requestPermission();
    } else {
      context.pushNamed(AppRouteNames.healthSync);
    }
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
