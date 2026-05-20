import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/responsive/responsive_builder.dart';
import 'package:fitora/features/progress/domain/progress_models.dart';
import 'package:fitora/features/progress/providers/progress_controller.dart';
import 'package:fitora/shared/widgets/app_scaffold.dart';
import 'package:fitora/shared/widgets/fitora_card.dart';
import 'package:fitora/shared/widgets/glow_container.dart';
import 'package:fitora/shared/widgets/loading_widget.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading =
        ref.watch(progressControllerProvider.select((s) => s.isLoading));

    if (isLoading) {
      return const AppScaffold(
        title: 'Progress',
        body: LoadingWidget(message: 'Loading progress…'),
      );
    }

    return AppScaffold(
      title: 'Progress',
      applyPadding: false,
      body: ResponsiveBuilder(
        mobile: (_) => const _ProgressLayout(maxWidth: 560, isWide: false),
        tablet: (_) => const _ProgressLayout(maxWidth: 900, isWide: true),
        desktop: (_) => const _ProgressLayout(maxWidth: 1100, isWide: true),
      ),
    );
  }
}

// ── Layout ────────────────────────────────────────────────────────────────────

class _ProgressLayout extends StatelessWidget {
  final double maxWidth;
  final bool isWide;

  const _ProgressLayout({required this.maxWidth, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            FitoraSpacing.md,
            FitoraSpacing.md,
            FitoraSpacing.md,
            FitoraSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero header
              Consumer(builder: (context, ref, _) {
                final summary = ref.watch(
                  progressControllerProvider.select((s) => s.summary),
                );
                final streak = ref.watch(
                  progressControllerProvider.select((s) => s.streak),
                );
                return _HeroSection(summary: summary, streak: streak);
              })
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: -0.06, end: 0, duration: 350.ms),

              const SizedBox(height: FitoraSpacing.md),

              // Weekly rings (3 metrics)
              Consumer(builder: (context, ref, _) {
                final summary = ref.watch(
                  progressControllerProvider.select((s) => s.summary),
                );
                return _WeeklyGoalsRow(summary: summary);
              })
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 350.ms)
                  .slideY(begin: 0.05, end: 0, duration: 350.ms),

              const SizedBox(height: FitoraSpacing.md),

              // Streak + Weekly chart side-by-side on tablet
              Consumer(builder: (context, ref, _) {
                final streak = ref.watch(
                  progressControllerProvider.select((s) => s.streak),
                );
                final days = ref.watch(
                  progressControllerProvider.select((s) => s.weeklyActivity),
                );
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _StreakCard(streak: streak)),
                      const SizedBox(width: FitoraSpacing.md),
                      Expanded(child: _WeeklyBarChart(days: days)),
                    ],
                  );
                }
                return Column(children: [
                  _StreakCard(streak: streak),
                  const SizedBox(height: FitoraSpacing.md),
                  _WeeklyBarChart(days: days),
                ]);
              })
                  .animate()
                  .fadeIn(delay: 160.ms, duration: 350.ms),

              const SizedBox(height: FitoraSpacing.md),

              // Trends
              Consumer(builder: (context, ref, _) {
                final trends = ref.watch(
                  progressControllerProvider.select((s) => s.weeklyTrends),
                );
                return _TrendsSection(trends: trends);
              })
                  .animate()
                  .fadeIn(delay: 220.ms, duration: 350.ms),

              const SizedBox(height: FitoraSpacing.md),

              // All-time totals grid
              Consumer(builder: (context, ref, _) {
                final summary = ref.watch(
                  progressControllerProvider.select((s) => s.summary),
                );
                return _TotalsGrid(summary: summary, isWide: isWide);
              })
                  .animate()
                  .fadeIn(delay: 280.ms, duration: 350.ms),

              const SizedBox(height: FitoraSpacing.md),

              // Recent workouts
              Consumer(builder: (context, ref, _) {
                final recent = ref.watch(
                  progressControllerProvider.select((s) => s.recentWorkouts),
                );
                return _RecentSection(recent: recent);
              })
                  .animate()
                  .fadeIn(delay: 330.ms, duration: 350.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final ProgressSummary summary;
  final StreakInfo streak;

  const _HeroSection({required this.summary, required this.streak});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GlowContainer(
      glowColor: colorScheme.primary.withValues(alpha: 0.18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This week', style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                )),
                const SizedBox(height: 4),
                Text(
                  '${summary.weeklyWorkouts} workout${summary.weeklyWorkouts == 1 ? '' : 's'}',
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: FitoraSpacing.sm),
                Wrap(
                  spacing: FitoraSpacing.sm,
                  runSpacing: FitoraSpacing.xs,
                  children: [
                    _MiniChip(value: '${summary.weeklyMinutes}', label: 'min'),
                    _MiniChip(value: '${summary.weeklyCalories}', label: 'kcal'),
                  ],
                ),
              ],
            ),
          ),
          if (streak.currentStreak > 0)
            _StreakBadge(days: streak.currentStreak),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String value;
  final String label;

  const _MiniChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FitoraSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 3),
          Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int days;

  const _StreakBadge({required this.days});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FitoraSpacing.md,
        vertical: FitoraSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            '$days',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onTertiaryContainer,
            ),
          ),
          Text('day streak', style: tt.labelSmall?.copyWith(color: cs.onTertiaryContainer)),
        ],
      ),
    );
  }
}

// ── Weekly goals rings ────────────────────────────────────────────────────────

class _WeeklyGoalsRow extends StatelessWidget {
  final ProgressSummary summary;

  const _WeeklyGoalsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Weekly goals',
      child: Row(
        children: [
          Expanded(
            child: _RingTile(
              label: 'Workouts',
              value: summary.weeklyWorkouts,
              goal: 5,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: _RingTile(
              label: 'Minutes',
              value: summary.weeklyMinutes,
              goal: 150,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          Expanded(
            child: _RingTile(
              label: 'Calories',
              value: summary.weeklyCalories,
              goal: 2000,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingTile extends StatelessWidget {
  final String label;
  final int value;
  final int goal;
  final Color color;

  const _RingTile({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final progress = goal == 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: v,
                  strokeWidth: 6,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: FitoraSpacing.xs),
        Text(label, style: textTheme.labelSmall),
        Text(
          '$value/$goal',
          style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ── Streak card ───────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final StreakInfo streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final lastLabel = streak.lastCompletedDate == null
        ? 'No sessions yet'
        : _fmtDate(streak.lastCompletedDate!);

    return FitoraCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_fire_department,
                color: cs.onTertiaryContainer, size: 22),
          ),
          const SizedBox(width: FitoraSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current streak', style: textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(
                  '${streak.currentStreak} day${streak.currentStreak == 1 ? '' : 's'}',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Longest: ${streak.longestStreak}d',
                  style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Last done', style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(lastLabel, style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Weekly bar chart ──────────────────────────────────────────────────────────

class _WeeklyBarChart extends StatelessWidget {
  final List<DailyActivity> days;

  const _WeeklyBarChart({required this.days});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Activity this week',
      child: SizedBox(
        height: 100,
        child: days.isEmpty
            ? Center(
                child: Text(
                  'No activity yet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            : _BarChart(days: days),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<DailyActivity> days;

  const _BarChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxW = days.fold<int>(1, (m, d) => d.workouts > m ? d.workouts : m);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: days.map((day) {
        final ratio = day.workouts / maxW;
        final isToday = _isToday(day.date);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (day.workouts > 0)
                  Text('${day.workouts}',
                      style: textTheme.labelSmall?.copyWith(fontSize: 9)),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  height: 8 + (60 * ratio),
                  decoration: BoxDecoration(
                    color: isToday
                        ? cs.primary
                        : cs.primary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _weekday(day.date),
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Trends section ────────────────────────────────────────────────────────────

class _TrendsSection extends StatelessWidget {
  final List<WeeklyTrend> trends;

  const _TrendsSection({required this.trends});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxW = trends.fold<int>(1, (m, t) => t.workouts > m ? t.workouts : m);

    return _SectionCard(
      title: '4-week trend',
      child: SizedBox(
        height: 80,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: trends.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            final ratio = t.workouts / maxW;
            final isCurrent = i == trends.length - 1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${t.workouts}',
                      style: textTheme.labelSmall?.copyWith(
                        color: isCurrent ? cs.secondary : cs.onSurfaceVariant,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      height: 8 + (46 * ratio),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? cs.secondary
                            : cs.secondary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCurrent ? 'Now' : 'W${i + 1}',
                      style: textTheme.labelSmall?.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── All-time totals ───────────────────────────────────────────────────────────

class _TotalsGrid extends StatelessWidget {
  final ProgressSummary summary;
  final bool isWide;

  const _TotalsGrid({required this.summary, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _TotalTile(
        icon: Icons.fitness_center_outlined,
        label: 'Workouts',
        value: '${summary.totalWorkouts}',
      ),
      _TotalTile(
        icon: Icons.schedule_outlined,
        label: 'Minutes',
        value: '${summary.totalMinutes}',
      ),
      _TotalTile(
        icon: Icons.local_fire_department_outlined,
        label: 'Calories',
        value: '${summary.totalCalories}',
      ),
      _TotalTile(
        icon: Icons.repeat_outlined,
        label: 'Exercises',
        value: '${summary.totalExercises}',
      ),
    ];

    return _SectionCard(
      title: 'All-time stats',
      child: isWide
          ? Row(
              children: tiles
                  .expand((t) => [Expanded(child: t), const SizedBox(width: FitoraSpacing.sm)])
                  .toList()
                ..removeLast(),
            )
          : Column(children: [
              Row(children: [
                Expanded(child: tiles[0]),
                const SizedBox(width: FitoraSpacing.sm),
                Expanded(child: tiles[1]),
              ]),
              const SizedBox(height: FitoraSpacing.sm),
              Row(children: [
                Expanded(child: tiles[2]),
                const SizedBox(width: FitoraSpacing.sm),
                Expanded(child: tiles[3]),
              ]),
            ]),
    );
  }
}

class _TotalTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TotalTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(FitoraSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(height: FitoraSpacing.xs),
          Text(value,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(label,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Recent workouts ───────────────────────────────────────────────────────────

class _RecentSection extends StatelessWidget {
  final List<WorkoutHistoryEntry> recent;

  const _RecentSection({required this.recent});

  @override
  Widget build(BuildContext context) {
    if (recent.isEmpty) {
      return _SectionCard(
        title: 'Recent workouts',
        child: _EmptyState(
          icon: Icons.fitness_center_outlined,
          message: 'Complete your first workout to see it here.',
        ),
      );
    }

    return _SectionCard(
      title: 'Recent workouts',
      child: Column(
        children: recent.asMap().entries.map((e) {
          final entry = e.value;
          final isLast = e.key == recent.length - 1;
          return Column(
            children: [
              _RecentWorkoutRow(entry: entry),
              if (!isLast) const Divider(height: FitoraSpacing.md),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _RecentWorkoutRow extends StatelessWidget {
  final WorkoutHistoryEntry entry;

  const _RecentWorkoutRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.fitness_center_outlined,
              size: 16, color: cs.onPrimaryContainer),
        ),
        const SizedBox(width: FitoraSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.title,
                  style: tt.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(
                '${_fmtDate(entry.completedAt)} · ${entry.durationLabel}',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${entry.calories} kcal', style: tt.labelMedium),
            Text('${entry.exercisesCompleted} ex',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FitoraSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: FitoraSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card wrapper ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 2,
            bottom: FitoraSpacing.xs,
          ),
          child: Text(title,
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        ),
        FitoraCard(child: child),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

bool _isToday(DateTime d) {
  final n = DateTime.now();
  return d.year == n.year && d.month == n.month && d.day == n.day;
}

String _weekday(DateTime d) {
  const l = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  return l[(d.weekday - 1).clamp(0, 6)];
}

String _fmtDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[(d.month - 1).clamp(0, 11)]} ${d.day}';
}
