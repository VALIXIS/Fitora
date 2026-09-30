import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/providers/health_providers.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';
import 'package:fitora/features/auth/providers/auth_providers.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';
import 'package:fitora/shared/widgets/glow_container.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';
import 'package:fitora/shared/widgets/fitora_background.dart';
import 'package:fitora/features/profile/widgets/achievements_grid.dart';
import 'package:fitora/features/cloud_backup/widgets/cloud_backup_modal.dart';
import 'package:fitora/core/ads/ad_service.dart';
import 'package:fitora/core/services/haptic_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final personalizationState = ref.watch(personalizationControllerProvider);
    final profile = personalizationState.profile;
    final authSession = ref.watch(authStateProvider);
    final wellness = ref.watch(wellnessProvider);
    final today = ref.watch(todayProvider);
    final activity = ref.watch(dailyActivityProvider(today));

    String displayName = authSession.user?.displayName ?? '';
    if (displayName.isEmpty) displayName = profile.name ?? '';
    if (displayName.isEmpty) displayName = 'Guest User';

    return FitoraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Profile',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FitoraSpacing.xl,
                  vertical: FitoraSpacing.md,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildProfileHeader(
                      context,
                      textTheme,
                      profile,
                      displayName,
                      profile.goal?.label ?? 'General Fitness',
                    ),
                    const SizedBox(height: FitoraSpacing.xl),

                    _buildSectionTitle(context, textTheme, 'HEALTH OVERVIEW'),
                    _buildHealthOverview(context, textTheme, profile),
                    const SizedBox(height: FitoraSpacing.xl),

                    _buildSectionTitle(context, textTheme, 'PERSONALIZATION'),
                    _buildPersonalizationDetails(context, textTheme, profile),
                    const SizedBox(height: FitoraSpacing.xl),

                    _buildSectionTitle(context, textTheme, 'GOALS'),
                    _buildGoalsSection(
                      context,
                      textTheme,
                      ref,
                      activity,
                      wellness,
                    ),
                    const SizedBox(height: FitoraSpacing.xl),

                    _buildSectionTitle(context, textTheme, 'QUICK ACTIONS'),
                    _buildQuickActions(context, textTheme, ref),
                    const SizedBox(height: FitoraSpacing.xl),

                    const AchievementsGrid(),
                    const SizedBox(height: FitoraSpacing.xl),

                    Consumer(
                      builder: (context, ref, _) {
                        final packageInfoAsync = ref.watch(packageInfoProvider);
                        final versionText = packageInfoAsync.when(
                          data: (info) =>
                              'Version ${info.version} (Build ${info.buildNumber})',
                          loading: () => 'Loading...',
                          error: (_, _) => 'Version 1.0.0',
                        );
                        return Center(
                          child: Text(
                            versionText,
                            style: textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: FitoraSpacing.md),
                    const Center(child: FitoraBannerAd()),
                    const SizedBox(height: 160),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    TextTheme textTheme,
    String title,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    List<Widget> children, {
    Color? highlightColor,
  }) {
    final theme = Theme.of(context);
    final glowColor = highlightColor ?? FitoraColors.calmCyan;
    return GlowContainer(
      glowColor: glowColor.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color:
              theme.cardTheme.color ??
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                highlightColor?.withValues(alpha: 0.2) ??
                theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    TextTheme tt,
    PersonalizationProfile profile,
    String name,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    return _buildCard(context, highlightColor: FitoraColors.mintGreen, [
      Padding(
        padding: const EdgeInsets.all(FitoraSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [FitoraColors.mintGreen, FitoraColors.calmCyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 36),
            ),
            const SizedBox(width: FitoraSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: FitoraColors.lavender.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: FitoraColors.lavender.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      profile.experienceLevel?.label ?? 'Beginner Level',
                      style: tt.labelSmall?.copyWith(
                        color: FitoraColors.lavender,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'Edit Profile',
              child: IconButton(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.edit_rounded, color: Colors.white54),
                onPressed: () => context.pushNamed(AppRouteNames.editProfile),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildHealthOverview(
    BuildContext context,
    TextTheme tt,
    PersonalizationProfile profile,
  ) {
    double bmi = 0.0;
    if (profile.weightKg != null &&
        profile.heightCm != null &&
        profile.heightCm! > 0) {
      final heightM = profile.heightCm! / 100;
      bmi = profile.weightKg! / (heightM * heightM);
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildHealthMetric(
                context,
                tt,
                'Age',
                '${profile.age ?? 25}',
              ),
            ),
            const SizedBox(width: FitoraSpacing.sm),
            Expanded(
              child: _buildHealthMetric(
                context,
                tt,
                'Height',
                '${profile.heightCm?.round() ?? 170} cm',
              ),
            ),
            const SizedBox(width: FitoraSpacing.sm),
            Expanded(
              child: _buildHealthMetric(
                context,
                tt,
                'Weight',
                '${profile.weightKg?.toStringAsFixed(1) ?? 65.0} kg',
              ),
            ),
          ],
        ),
        if (bmi > 0) ...[
          const SizedBox(height: FitoraSpacing.sm),
          _buildCard(context, [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: AnimatedBMIGauge(bmi: bmi),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _buildHealthMetric(
    BuildContext context,
    TextTheme tt,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return GlowContainer(
      glowColor: FitoraColors.calmCyan.withValues(alpha: 0.02),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: FitoraSpacing.lg),
        decoration: BoxDecoration(
          color:
              theme.cardTheme.color ??
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: tt.labelSmall?.copyWith(
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

  Widget _buildPersonalizationDetails(
    BuildContext context,
    TextTheme tt,
    PersonalizationProfile profile,
  ) {
    return _buildCard(context, [
      _buildTile(
        context,
        tt,
        Icons.track_changes_rounded,
        'Primary Goal',
        profile.goal?.label ?? 'General Fitness',
        iconColor: FitoraColors.mintGreen,
      ),
      _buildDivider(context),
      _buildTile(
        context,
        tt,
        Icons.spa_rounded,
        'Wellness Focus',
        profile.interests.isNotEmpty ? profile.interests.first.label : 'Energy',
        iconColor: FitoraColors.lavender,
      ),
    ]);
  }

  Widget _buildGoalsSection(
    BuildContext context,
    TextTheme tt,
    WidgetRef ref,
    DailyActivitySummary activity,
    wellness,
  ) {
    final stepsGoalStr = activity.stepsGoal.toString().replaceAllMapped(
      RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
      (m) => "${m[1]},",
    );
    final waterGoalStr = wellness.hydrationGoalLiters > 0
        ? '${wellness.hydrationGoalLiters.toStringAsFixed(1)}L'
        : '2.5L';
    return _buildCard(context, [
      _buildTile(
        context,
        tt,
        Icons.directions_walk_rounded,
        'Daily Steps',
        stepsGoalStr,
        iconColor: FitoraColors.calmCyan,
        onTap: () => showStepGoalPicker(context, ref, activity.stepsGoal),
      ),
      _buildDivider(context),
      _buildTile(
        context,
        tt,
        Icons.water_drop_rounded,
        'Water Goal',
        waterGoalStr,
        iconColor: Colors.blueAccent,
      ),
    ]);
  }

  Widget _buildQuickActions(BuildContext context, TextTheme tt, WidgetRef ref) {
    return _buildCard(context, [
      _buildActionTile(
        context,
        tt,
        Icons.cloud_sync_rounded,
        'Cloud Backup & Restore',
        onTap: () => showCloudBackupModal(context, ref),
      ),
      _buildDivider(context),
      _buildActionTile(
        context,
        tt,
        Icons.settings_rounded,
        'Settings',
        onTap: () => context.pushNamed(AppRouteNames.settings),
      ),
      _buildDivider(context),
      _buildActionTile(
        context,
        tt,
        Icons.info_outline_rounded,
        'About Fitora',
        onTap: () => context.pushNamed(AppRouteNames.about),
      ),
      _buildDivider(context),
      _buildActionTile(
        context,
        tt,
        Icons.lock_outline_rounded,
        'Privacy Policy',
        onTap: () => context.pushNamed(AppRouteNames.privacyPolicy),
      ),
      _buildDivider(context),
      _buildActionTile(
        context,
        tt,
        Icons.help_outline_rounded,
        'Help & Support',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Support email: official.valixis@gmail.com'),
            ),
          );
        },
      ),
    ]);
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.3),
      height: 1,
      indent: 56,
    );
  }

  Widget _buildTile(
    BuildContext context,
    TextTheme tt,
    IconData icon,
    String title,
    String value, {
    Color? iconColor,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? theme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: tt.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: tt.bodyMedium?.copyWith(
              color: valueColor ?? theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Semantics(
        button: true,
        label: '$title, current target $value',
        hint: 'Double tap to change target',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: tile,
          ),
        ),
      );
    }
    return tile;
  }

  Widget _buildActionTile(
    BuildContext context,
    TextTheme tt,
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: tt.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showStepGoalPicker(BuildContext context, WidgetRef ref, int currentGoal) {
  final theme = Theme.of(context);
  final textTheme = theme.textTheme;
  final presets = [5000, 8000, 10000, 12000, 15000, 20000];
  int tempGoal = currentGoal;

  showModalBottomSheet(
    context: context,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Semantics(
            scopesRoute: true,
            namesRoute: true,
            label: 'Daily Step Target Picker',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Daily Step Target',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${tempGoal.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")} steps / day',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: FitoraColors.mintGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: tempGoal.toDouble().clamp(3000.0, 30000.0),
                    min: 3000,
                    max: 30000,
                    divisions: 54,
                    activeColor: FitoraColors.mintGreen,
                    inactiveColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.12,
                    ),
                    onChanged: (val) {
                      final newGoal = (val / 500).round() * 500;
                      if (newGoal != tempGoal) {
                        ref.read(hapticServiceProvider).sliderChange();
                      }
                      setState(() {
                        tempGoal = newGoal;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((p) {
                      final isSelected = tempGoal == p;
                      final kStr = '${p ~/ 1000}k steps target';
                      return Semantics(
                        button: true,
                        selected: isSelected,
                        label: kStr,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 48,
                            minWidth: 48,
                          ),
                          child: ChoiceChip(
                            label: Text('${p ~/ 1000}k'),
                            selected: isSelected,
                            selectedColor: FitoraColors.mintGreen,
                            backgroundColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.05),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.black
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (_) {
                              setState(() {
                                tempGoal = p;
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    button: true,
                    label: 'Save Step Target',
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(customStepGoalProvider.notifier)
                            .setGoal(tempGoal);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FitoraColors.mintGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Save Step Target',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class AnimatedBMIGauge extends StatelessWidget {
  final double bmi;
  const AnimatedBMIGauge({super.key, required this.bmi});

  @override
  Widget build(BuildContext context) {
    String category = 'Normal';
    Color categoryColor = FitoraColors.mintGreen;

    if (bmi < 18.5) {
      category = 'Underweight';
      categoryColor = Colors.blueAccent;
    } else if (bmi < 25) {
      category = 'Normal';
      categoryColor = FitoraColors.mintGreen;
    } else if (bmi < 30) {
      category = 'Overweight';
      categoryColor = FitoraColors.warningOrange;
    } else {
      category = 'Obese';
      categoryColor = FitoraColors.errorRed;
    }

    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 15.0, end: bmi),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final displayBmi = value.clamp(15.0, 40.0);
        final percent = (displayBmi - 15) / (40 - 15);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BMI Score',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  value.toStringAsFixed(1),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 24,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Track background
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.blueAccent,
                          FitoraColors.mintGreen,
                          FitoraColors.warningOrange,
                          FitoraColors.errorRed,
                        ],
                        stops: [0.1, 0.4, 0.7, 0.9],
                      ),
                    ),
                  ),
                  // Thumb
                  Positioned(
                    left:
                        percent *
                        (MediaQuery.of(context).size.width -
                            64 -
                            24), // approx available width
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: categoryColor, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '15',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '25',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '40+',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
