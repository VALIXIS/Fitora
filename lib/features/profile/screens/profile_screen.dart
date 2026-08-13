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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final personalizationState = ref.watch(personalizationControllerProvider);
    final profile = personalizationState.profile;
    final authSession = ref.watch(authStateProvider);
    final wellness = ref.watch(wellnessProvider);
    final activity = ref.watch(dailyActivityProvider(DateTime.now()));

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
              color: Colors.white,
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

                    _buildSectionTitle(textTheme, 'HEALTH OVERVIEW'),
                    _buildHealthOverview(textTheme, profile),
                    const SizedBox(height: FitoraSpacing.xl),

                    _buildSectionTitle(textTheme, 'PERSONALIZATION'),
                    _buildPersonalizationDetails(textTheme, profile),
                    const SizedBox(height: FitoraSpacing.xl),

                    _buildSectionTitle(textTheme, 'GOALS'),
                    _buildGoalsSection(
                      context,
                      textTheme,
                      ref,
                      activity,
                      wellness,
                    ),
                    const SizedBox(height: FitoraSpacing.xl),

                    _buildSectionTitle(textTheme, 'QUICK ACTIONS'),
                    _buildQuickActions(context, textTheme),
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
                              color: Colors.white38,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(TextTheme textTheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Colors.white30,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children, {Color? highlightColor}) {
    final glowColor = highlightColor ?? FitoraColors.calmCyan;
    return GlowContainer(
      glowColor: glowColor.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                highlightColor?.withValues(alpha: 0.2) ??
                Colors.white.withValues(alpha: 0.08),
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
    return _buildCard(highlightColor: FitoraColors.mintGreen, [
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(color: Colors.white70),
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
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white54),
              onPressed: () => context.pushNamed(AppRouteNames.editProfile),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildHealthOverview(TextTheme tt, PersonalizationProfile profile) {
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
              child: _buildHealthMetric(tt, 'Age', '${profile.age ?? 25}'),
            ),
            const SizedBox(width: FitoraSpacing.sm),
            Expanded(
              child: _buildHealthMetric(
                tt,
                'Height',
                '${profile.heightCm?.round() ?? 170} cm',
              ),
            ),
            const SizedBox(width: FitoraSpacing.sm),
            Expanded(
              child: _buildHealthMetric(
                tt,
                'Weight',
                '${profile.weightKg?.toStringAsFixed(1) ?? 65.0} kg',
              ),
            ),
          ],
        ),
        if (bmi > 0) ...[
          const SizedBox(height: FitoraSpacing.sm),
          _buildCard([
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.monitor_weight_outlined,
                    color: FitoraColors.mintGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BMI (Body Mass Index)',
                          style: tt.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getBmiCategory(bmi),
                          style: tt.labelSmall?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    bmi.toStringAsFixed(1),
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: FitoraColors.mintGreen,
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ],
    );
  }

  String _getBmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal Weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Widget _buildHealthMetric(TextTheme tt, String label, String value) {
    return GlowContainer(
      glowColor: FitoraColors.calmCyan.withValues(alpha: 0.02),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: FitoraSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: tt.labelSmall?.copyWith(
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

  Widget _buildPersonalizationDetails(
    TextTheme tt,
    PersonalizationProfile profile,
  ) {
    return _buildCard([
      _buildTile(
        tt,
        Icons.track_changes_rounded,
        'Primary Goal',
        profile.goal?.label ?? 'General Fitness',
        iconColor: FitoraColors.mintGreen,
      ),
      _buildDivider(),
      _buildTile(
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
    return _buildCard([
      _buildTile(
        tt,
        Icons.directions_walk_rounded,
        'Daily Steps',
        stepsGoalStr,
        iconColor: FitoraColors.calmCyan,
        onTap: () => showStepGoalPicker(context, ref, activity.stepsGoal),
      ),
      _buildDivider(),
      _buildTile(
        tt,
        Icons.water_drop_rounded,
        'Water Goal',
        waterGoalStr,
        iconColor: Colors.blueAccent,
      ),
    ]);
  }

  Widget _buildQuickActions(BuildContext context, TextTheme tt) {
    return _buildCard([
      _buildActionTile(
        tt,
        Icons.settings_rounded,
        'Settings',
        onTap: () => context.pushNamed(AppRouteNames.settings),
      ),
      _buildDivider(),
      _buildActionTile(
        tt,
        Icons.info_outline_rounded,
        'About Fitora',
        onTap: () => context.pushNamed(AppRouteNames.about),
      ),
      _buildDivider(),
      _buildActionTile(
        tt,
        Icons.lock_outline_rounded,
        'Privacy Policy',
        onTap: () => context.pushNamed(AppRouteNames.privacyPolicy),
      ),
      _buildDivider(),
      _buildActionTile(
        tt,
        Icons.help_outline_rounded,
        'Help & Support',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Support email: support@fitora.app')),
          );
        },
      ),
    ]);
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.05),
      height: 1,
      indent: 56,
    );
  }

  Widget _buildTile(
    TextTheme tt,
    IconData icon,
    String title,
    String value, {
    Color? iconColor,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? Colors.white70, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: tt.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: tt.bodyMedium?.copyWith(
              color: valueColor ?? Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: tile,
      );
    }
    return tile;
  }

  Widget _buildActionTile(
    TextTheme tt,
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: tt.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white30,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

void showStepGoalPicker(BuildContext context, WidgetRef ref, int currentGoal) {
  final textTheme = Theme.of(context).textTheme;
  final presets = [5000, 8000, 10000, 12000, 15000, 20000];
  int tempGoal = currentGoal;

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF0D1117),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
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
                    color: Colors.white,
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
                  inactiveColor: Colors.white10,
                  onChanged: (val) {
                    setState(() {
                      tempGoal = (val / 500).round() * 500;
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
                    return ChoiceChip(
                      label: Text('${p ~/ 1000}k'),
                      selected: isSelected,
                      selectedColor: FitoraColors.mintGreen,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setState(() {
                          tempGoal = p;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.read(customStepGoalProvider.notifier).setGoal(tempGoal);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FitoraColors.mintGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Step Target',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
