import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/services/audio_service.dart';
import 'package:fitora/core/services/haptic_service.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0E1312),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Settings', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: FitoraSpacing.xl, vertical: FitoraSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _buildSectionTitle(textTheme, 'GENERAL'),
                    _buildSettingsCard([
                      _buildSwitchTile(textTheme, Icons.dark_mode_rounded, 'Dark Mode', settings.isDarkMode, (v) => settingsNotifier.updateSetting('isDarkMode', v)),
                      _buildDivider(),
                      _buildSwitchTile(textTheme, Icons.notifications_active_rounded, 'Notifications', settings.notificationsEnabled, (v) => settingsNotifier.updateSetting('notificationsEnabled', v)),
                      _buildDivider(),
                      _buildSwitchTile(textTheme, Icons.volume_up_rounded, 'Sound Effects', settings.soundEffectsEnabled, (v) {
                        settingsNotifier.updateSetting('soundEffectsEnabled', v);
                        if (v) ref.read(audioServiceProvider).playNotificationSound();
                      }),
                      _buildDivider(),
                      _buildSwitchTile(textTheme, Icons.vibration_rounded, 'Haptics', settings.hapticsEnabled, (v) {
                        settingsNotifier.updateSetting('hapticsEnabled', v);
                        if (v) ref.read(hapticServiceProvider).lightImpact();
                      }),
                    ]),
                    const SizedBox(height: FitoraSpacing.xl),

                    _buildSectionTitle(textTheme, 'HEALTH'),
                    _buildSettingsCard([
                      _buildSwitchTile(textTheme, Icons.water_drop_rounded, 'Water Reminder', settings.waterReminder, (v) => settingsNotifier.updateSetting('waterReminder', v), iconColor: Colors.blueAccent),
                      _buildDivider(),
                      _buildSwitchTile(textTheme, Icons.fitness_center_rounded, 'Workout Reminder', settings.workoutReminder, (v) => settingsNotifier.updateSetting('workoutReminder', v), iconColor: FitoraColors.calmCyan),
                      _buildDivider(),
                      _buildSwitchTile(textTheme, Icons.flag_rounded, 'Daily Goal Reminder', settings.dailyGoalReminder, (v) => settingsNotifier.updateSetting('dailyGoalReminder', v), iconColor: FitoraColors.mintGreen),
                    ]),
                    const SizedBox(height: FitoraSpacing.xl),

                    _buildSectionTitle(textTheme, 'UNITS'),
                    _buildSettingsCard([
                      _buildTile(textTheme, Icons.straighten_rounded, 'System', settings.isMetric ? 'Metric' : 'Imperial', onTap: () {
                        settingsNotifier.updateSetting('isMetric', !settings.isMetric);
                      }),
                    ]),
                    const SizedBox(height: FitoraSpacing.xl),

                    _buildSectionTitle(textTheme, 'DATA'),
                    _buildSettingsCard([
                      _buildTile(textTheme, Icons.download_rounded, 'Export Data', null, onTap: () => _exportData(context, ref)),
                      _buildDivider(),
                      _buildTile(textTheme, Icons.delete_forever_rounded, 'Reset Progress', null, isDestructive: true, onTap: () => _confirmReset(context, ref)),
                    ]),
                    const SizedBox(height: FitoraSpacing.xl),

                    _buildSectionTitle(textTheme, 'ABOUT'),
                    _buildSettingsCard([
                      Consumer(
                        builder: (context, ref, _) {
                          final packageInfoAsync = ref.watch(packageInfoProvider);
                          final versionText = packageInfoAsync.when(
                            data: (info) => 'v${info.version} (Build ${info.buildNumber})',
                            loading: () => 'Loading...',
                            error: (_, _) => 'v1.0.0',
                          );
                          return _buildTile(textTheme, Icons.info_outline_rounded, 'App Version', versionText);
                        },
                      ),
                      _buildDivider(),
                      _buildTile(textTheme, Icons.sports_gymnastics_rounded, 'About Fitora', null, onTap: () => context.pushNamed(AppRouteNames.about)),
                      _buildDivider(),
                      _buildTile(textTheme, Icons.privacy_tip_rounded, 'Privacy Policy', null, onTap: () => context.pushNamed(AppRouteNames.privacyPolicy)),
                      _buildDivider(),
                      _buildTile(textTheme, Icons.gavel_rounded, 'Terms of Service', null, onTap: () => context.pushNamed(AppRouteNames.termsOfService)),
                    ]),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2626),
        title: const Text('Reset Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to reset all your progress and personalization settings? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              final nav = GoRouter.of(context);
              // Reset Logic
              await ref.read(settingsProvider.notifier).resetToDefaults();
              await ref.read(personalizationControllerProvider.notifier).reset();
              nav.go(AppRoutes.onboarding);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final profile = ref.read(personalizationControllerProvider).profile;
      final settings = ref.read(settingsProvider);
      
      final data = {
        'profile': profile.toJson(),
        'settings': {
          'isDarkMode': settings.isDarkMode,
          'notificationsEnabled': settings.notificationsEnabled,
          'soundEffectsEnabled': settings.soundEffectsEnabled,
          'hapticsEnabled': settings.hapticsEnabled,
          'waterReminder': settings.waterReminder,
          'workoutReminder': settings.workoutReminder,
          'dailyGoalReminder': settings.dailyGoalReminder,
          'isMetric': settings.isMetric,
          'autoplayRest': settings.autoplayRest,
        }
      };
      
      final jsonStr = jsonEncode(data);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/fitora_data.json');
      await file.writeAsString(jsonStr);
      
      if (!context.mounted) return;
      
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Fitora Data Export',
          sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export data: $e')),
      );
    }
  }

  Widget _buildSectionTitle(TextTheme textTheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.white.withValues(alpha: 0.05), height: 1, indent: 56);
  }

  Widget _buildSwitchTile(TextTheme tt, IconData icon, String title, bool value, ValueChanged<bool> onChanged, {Color iconColor = Colors.white70}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: tt.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: FitoraColors.mintGreen,
            activeTrackColor: FitoraColors.mintGreen.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(TextTheme tt, IconData icon, String title, String? trailingText, {bool isDestructive = false, VoidCallback? onTap}) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: isDestructive ? Colors.redAccent : Colors.white70, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title, 
              style: tt.bodyMedium?.copyWith(
                color: isDestructive ? Colors.redAccent : Colors.white, 
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailingText != null) ...[
            Text(trailingText, style: tt.bodySmall?.copyWith(color: Colors.white54)),
            const SizedBox(width: 8),
          ],
          if (onTap != null)
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}
