import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/shared/widgets/fitora_card.dart';
import 'package:fitora/shared/widgets/glow_container.dart';
import 'package:fitora/core/health/providers/health_providers.dart';
import 'package:fitora/core/health/domain/health_models.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastWeek = today.subtract(const Duration(days: 6));
    final summaries = ref.watch(weeklyActivityProvider(lastWeek));

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
            title: Text('Analytics', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
            centerTitle: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: FitoraSpacing.xl),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: FitoraSpacing.sm),
                RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(healthSyncServiceProvider.notifier).syncNow();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionHeader(textTheme, 'ACTIVITY'),
                      const SizedBox(height: FitoraSpacing.md),
                      _buildActivitySection(textTheme, summaries.last),
                      const SizedBox(height: FitoraSpacing.xl),
                      
                      _buildSectionHeader(textTheme, 'RECOVERY'),
                      const SizedBox(height: FitoraSpacing.md),
                      _buildRecoverySection(context, textTheme),
                      const SizedBox(height: FitoraSpacing.xl),

                      _buildSectionHeader(textTheme, 'TRENDS'),
                      const SizedBox(height: FitoraSpacing.md),
                      _buildTrendsSection(textTheme, summaries),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(TextTheme tt, String title) {
    return Text(title, style: tt.labelSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white70));
  }

  Widget _buildActivitySection(TextTheme tt, DailyActivitySummary summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricCard(tt, 'Steps', summary.steps.toString(), ' / ${summary.stepsGoal}', Icons.directions_walk_rounded, FitoraColors.mintGreen)),
            const SizedBox(width: FitoraSpacing.sm),
            Expanded(child: _buildMetricCard(tt, 'Calories', summary.caloriesBurned.toInt().toString(), ' kcal', Icons.local_fire_department_rounded, FitoraColors.warningOrange)),
          ],
        ),
        const SizedBox(height: FitoraSpacing.sm),
        Row(
          children: [
            Expanded(child: _buildMetricCard(tt, 'Active', summary.activeMinutes.toString(), ' min', Icons.timer_rounded, FitoraColors.calmCyan)),
            const SizedBox(width: FitoraSpacing.sm),
            Expanded(child: _buildMetricCard(tt, 'Distance', summary.distanceKm.toStringAsFixed(1), ' km', Icons.route_rounded, FitoraColors.lavender)),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildRecoverySection(BuildContext context, TextTheme tt) {
    return Consumer(
      builder: (context, ref, _) {
        final sleep = ref.watch(sleepSummaryProvider(DateTime.now()));
        
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Builder(builder: (context) {
                    if (sleep.totalSleep.inMinutes == 0) {
                      return _buildMetricCard(tt, 'Sleep', '--', '', Icons.bedtime_rounded, Colors.white38);
                    }
                    final hours = sleep.totalSleep.inHours;
                    final minutes = sleep.totalSleep.inMinutes.remainder(60);
                    return _buildMetricCard(tt, 'Sleep', '${hours}h ${minutes}m', '', Icons.bedtime_rounded, FitoraColors.softPink);
                  }),
                ),
                const SizedBox(width: FitoraSpacing.sm),
                Expanded(child: _buildMetricCard(tt, 'Hydration', '0.0', ' L', Icons.water_drop_rounded, Colors.blueAccent)),
              ],
            ),
            const SizedBox(height: FitoraSpacing.sm),
            Row(
              children: [
                Expanded(child: _buildMetricCard(tt, 'Mood', 'Unknown', '', Icons.sentiment_satisfied_rounded, Colors.amber)),
                const SizedBox(width: FitoraSpacing.sm),
                Expanded(child: _buildMetricCard(tt, 'Breathing', '0 min', '', Icons.air_rounded, FitoraColors.calmCyan)),
              ],
            ),
          ],
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildMetricCard(TextTheme tt, String title, String value, String unit, IconData icon, Color color) {
    return GlowContainer(
      glowColor: color.withValues(alpha: 0.1),
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: FitoraSpacing.sm),
            Text(title.toUpperCase(), style: tt.labelSmall?.copyWith(color: Colors.white70, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(child: Text(value, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white), overflow: TextOverflow.ellipsis)),
                if (unit.isNotEmpty) Text(unit, style: tt.labelSmall?.copyWith(color: Colors.white54)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsSection(TextTheme tt, List<DailyActivitySummary> summaries) {
    return Column(
      children: [
        _buildStepsGraph(tt, summaries),
        const SizedBox(height: FitoraSpacing.lg),
        Row(
          children: [
            Expanded(child: _buildTrendCard(tt, 'Calories', Icons.local_fire_department_rounded, FitoraColors.warningOrange, summaries.map((s) => s.caloriesBurned).toList())),
            const SizedBox(width: FitoraSpacing.md),
            Expanded(child: _buildTrendCard(tt, 'Active', Icons.timer_rounded, FitoraColors.calmCyan, summaries.map((s) => s.activeMinutes.toDouble()).toList())),
          ],
        ),
        const SizedBox(height: FitoraSpacing.lg),
        _buildWeightTrend(tt),
        const SizedBox(height: FitoraSpacing.lg),
        _buildStreakCard(tt),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStepsGraph(TextTheme tt, List<DailyActivitySummary> summaries) {
    return FitoraCard(
      padding: const EdgeInsets.all(FitoraSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WEEKLY STEPS', style: tt.labelSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white54)),
              const Icon(Icons.directions_walk_rounded, color: FitoraColors.mintGreen, size: 20),
            ],
          ),
          const SizedBox(height: FitoraSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: summaries.map((s) {
              final isToday = s.date.day == DateTime.now().day;
              return _buildBar(_getDayName(s.date), s.stepsProgress, isToday, FitoraColors.mintGreen);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(TextTheme tt, String title, IconData icon, Color color, List<double> values) {
    final maxVal = values.reduce((curr, next) => curr > next ? curr : next);
    
    return GlowContainer(
      glowColor: color.withValues(alpha: 0.15),
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: FitoraSpacing.sm),
                Expanded(
                  child: Text(title.toUpperCase(), style: tt.labelSmall?.copyWith(color: Colors.white70, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: FitoraSpacing.md),
            SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: values.map((val) {
                  final heightRatio = (val / maxVal).clamp(0.0, 1.0);
                  return Container(
                    width: 8,
                    height: 60 * heightRatio,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightTrend(TextTheme tt) {
    return FitoraCard(
      padding: const EdgeInsets.all(FitoraSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WEIGHT TREND', style: tt.labelSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white54)),
              const Icon(Icons.monitor_weight_rounded, color: FitoraColors.lavender, size: 20),
            ],
          ),
          const SizedBox(height: FitoraSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('68.2', style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text('kg', style: tt.bodySmall?.copyWith(color: Colors.white54)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FitoraColors.mintGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_downward_rounded, color: FitoraColors.mintGreen, size: 14),
                    const SizedBox(width: 4),
                    Text('1.2 kg', style: tt.labelSmall?.copyWith(color: FitoraColors.mintGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double heightRatio, bool isToday, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 12,
          height: 120 * heightRatio.clamp(0.0, 1.0),
          decoration: BoxDecoration(
            gradient: isToday ? LinearGradient(colors: [color, color.withValues(alpha: 0.5)], begin: Alignment.bottomCenter, end: Alignment.topCenter) : null,
            color: isToday ? null : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            boxShadow: isToday ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)] : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(day, style: TextStyle(color: isToday ? Colors.white : Colors.white54, fontSize: 12, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildStreakCard(TextTheme tt) {
    return GlowContainer(
      glowColor: FitoraColors.warningOrange.withValues(alpha: 0.15),
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.lg),
        decoration: BoxDecoration(
          color: FitoraColors.warningOrange.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: FitoraColors.warningOrange.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: FitoraColors.warningOrange.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.local_fire_department_rounded, color: FitoraColors.warningOrange, size: 28),
            ),
            const SizedBox(width: FitoraSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('12 DAY STREAK', style: tt.labelSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: FitoraColors.warningOrange)),
                  const SizedBox(height: 4),
                  Text('You are unstoppable!', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Keep the momentum going.', style: tt.bodySmall?.copyWith(color: Colors.white70)),
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
}
