import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/progress/domain/progress_models.dart';
import 'package:fitora/features/progress/providers/progress_controller.dart';
import 'package:fitora/features/settings/screens/settings_sheet.dart';
import 'package:fitora/shared/widgets/app_scaffold.dart';
import 'package:fitora/shared/widgets/fitora_card.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Profile',
      applyPadding: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const SettingsSheet(),
          ),
        ),
      ],
      body: const _ProfileBody(),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(
      personalizationControllerProvider.select((s) => s.profile),
    );
    final progressState = ref.watch(progressControllerProvider);
    final summary = progressState.summary;
    final streak = progressState.streak;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        FitoraSpacing.md,
        FitoraSpacing.md,
        FitoraSpacing.md,
        FitoraSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero card
          _HeroCard(profile: profile, streak: streak)
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: -0.05, end: 0, duration: 350.ms),

          const SizedBox(height: FitoraSpacing.md),

          // Stats row
          _StatsRow(summary: summary, streak: streak)
              .animate()
              .fadeIn(delay: 80.ms, duration: 350.ms),

          const SizedBox(height: FitoraSpacing.md),

          // Body metrics (only if entered)
          if (profile.hasMetrics)
            _BodyMetricsCard(profile: profile)
                .animate()
                .fadeIn(delay: 160.ms, duration: 350.ms),

          if (profile.hasMetrics) const SizedBox(height: FitoraSpacing.md),

          // Training profile
          _TrainingCard(profile: profile)
              .animate()
              .fadeIn(delay: 220.ms, duration: 350.ms),

          const SizedBox(height: FitoraSpacing.md),

          // Wellness interests
          if (profile.interests.isNotEmpty)
            _WellnessCard(profile: profile)
                .animate()
                .fadeIn(delay: 280.ms, duration: 350.ms),

          if (profile.interests.isNotEmpty) const SizedBox(height: FitoraSpacing.md),

          // Settings link
          _SettingsLink()
              .animate()
              .fadeIn(delay: 340.ms, duration: 350.ms),
        ],
      ),
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final PersonalizationProfile profile;
  final StreakInfo streak;

  const _HeroCard({required this.profile, required this.streak});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GlowContainer(
      glowColor: cs.primary.withValues(alpha: 0.16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primaryContainer, cs.secondaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline_rounded,
                size: 34, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: FitoraSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your profile',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (profile.goal != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.goal!.label,
                    style: tt.bodyMedium?.copyWith(color: cs.primary),
                  ),
                ],
                if (profile.experienceLevel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.experienceLevel!.label,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),

          // Streak badge
          if (streak.currentStreak > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FitoraSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 18)),
                  Text(
                    '${streak.currentStreak}d',
                    style: tt.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final ProgressSummary summary;
  final StreakInfo streak;

  const _StatsRow({required this.summary, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.fitness_center_outlined,
            label: 'Workouts',
            value: '${summary.totalWorkouts}',
          ),
        ),
        const SizedBox(width: FitoraSpacing.sm),
        Expanded(
          child: _StatTile(
            icon: Icons.local_fire_department_outlined,
            label: 'Streak',
            value: '${streak.currentStreak}d',
          ),
        ),
        const SizedBox(width: FitoraSpacing.sm),
        Expanded(
          child: _StatTile(
            icon: Icons.schedule_outlined,
            label: 'Minutes',
            value: '${summary.totalMinutes}',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return FitoraCard(
      child: Column(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(height: 6),
          Text(value,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(label,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Body metrics ──────────────────────────────────────────────────────────────

class _BodyMetricsCard extends StatelessWidget {
  final PersonalizationProfile profile;

  const _BodyMetricsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    double? bmi;
    String? bmiCategory;
    if (profile.heightCm != null && profile.weightKg != null) {
      final hM = profile.heightCm! / 100;
      bmi = profile.weightKg! / (hM * hM);
      bmiCategory = bmi < 18.5
          ? 'Underweight'
          : bmi < 25
              ? 'Normal'
              : bmi < 30
                  ? 'Overweight'
                  : 'Obese';
    }

    return FitoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: 'Body metrics', icon: Icons.monitor_weight_outlined),
          const SizedBox(height: FitoraSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (profile.heightCm != null)
                _BodyMetricItem(
                  label: 'Height',
                  value: '${profile.heightCm!.round()}',
                  unit: 'cm',
                ),
              if (profile.weightKg != null)
                _BodyMetricItem(
                  label: 'Weight',
                  value: profile.weightKg!.toStringAsFixed(1),
                  unit: 'kg',
                ),
              if (profile.age != null)
                _BodyMetricItem(
                  label: 'Age',
                  value: '${profile.age}',
                  unit: 'yr',
                ),
              if (bmi != null)
                _BodyMetricItem(
                  label: 'BMI',
                  value: bmi.toStringAsFixed(1),
                  unit: bmiCategory ?? '',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyMetricItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _BodyMetricItem({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(unit, style: tt.labelSmall?.copyWith(color: cs.primary)),
        Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

// ── Training profile ──────────────────────────────────────────────────────────

class _TrainingCard extends StatelessWidget {
  final PersonalizationProfile profile;

  const _TrainingCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return FitoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: 'Training profile', icon: Icons.sports_gymnastics_outlined),
          const SizedBox(height: FitoraSpacing.md),
          _InfoRow(
            icon: Icons.flag_outlined,
            label: 'Goal',
            value: profile.goal?.label ?? '—',
          ),
          const Divider(height: FitoraSpacing.md),
          _InfoRow(
            icon: Icons.home_work_outlined,
            label: 'Workout style',
            value: profile.workoutPreference?.label ?? '—',
          ),
          const Divider(height: FitoraSpacing.md),
          _InfoRow(
            icon: Icons.trending_up_outlined,
            label: 'Experience',
            value: profile.experienceLevel?.label ?? '—',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: FitoraSpacing.sm),
        Text(label,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const Spacer(),
        Text(value,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Wellness interests ────────────────────────────────────────────────────────

class _WellnessCard extends StatelessWidget {
  final PersonalizationProfile profile;

  const _WellnessCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return FitoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: 'Wellness interests', icon: Icons.spa_outlined),
          const SizedBox(height: FitoraSpacing.md),
          Wrap(
            spacing: FitoraSpacing.sm,
            runSpacing: FitoraSpacing.sm,
            children: profile.interests.map((i) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: FitoraSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  i.label,
                  style: tt.labelMedium?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Settings link ─────────────────────────────────────────────────────────────

class _SettingsLink extends StatelessWidget {
  const _SettingsLink();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return FitoraCard(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const SettingsSheet(),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.settings_outlined, size: 20, color: cs.primary),
          ),
          const SizedBox(width: FitoraSpacing.md),
          Expanded(
            child: Text('App Settings',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _CardHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: FitoraSpacing.xs),
        Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
