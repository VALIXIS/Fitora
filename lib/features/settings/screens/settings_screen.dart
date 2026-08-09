import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:share_plus/share_plus.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/services/audio_service.dart';
import 'package:fitora/core/services/haptic_service.dart';
import 'package:fitora/core/services/notification_service.dart';
import 'package:fitora/core/health/providers/health_providers.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';
import 'package:fitora/shared/widgets/fitora_background.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final syncStatus = ref.watch(healthSyncServiceProvider);

    return FitoraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                      // ── GENERAL ───────────────────────────────────────────────
                      _buildSectionTitle(textTheme, 'GENERAL'),
                      _buildSettingsCard([
                        _buildSwitchTile(textTheme, Icons.dark_mode_rounded, 'Dark Mode', settings.isDarkMode, (v) => settingsNotifier.updateSetting('isDarkMode', v)),
                        _buildDivider(),
                        _buildSwitchTile(
                          textTheme,
                          Icons.notifications_active_rounded,
                          'Notifications',
                          settings.notificationsEnabled,
                          (v) async {
                            await settingsNotifier.updateSetting('notificationsEnabled', v);
                            // If they enabled but permission was denied, show guidance
                            if (v && context.mounted) {
                              final hasPermission = await settingsNotifier.checkNotificationPermission();
                              if (!hasPermission && context.mounted) {
                                _showNotificationDeniedSnackbar(context);
                              }
                            }
                          },
                        ),
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

                      // ── HEALTH SYNC ───────────────────────────────────────────
                      _buildSectionTitle(textTheme, 'HEALTH SYNC'),
                      _buildSettingsCard([
                        _buildTile(
                          textTheme,
                          Icons.monitor_heart_rounded,
                          'Health Integration',
                          _syncStatusLabel(syncStatus),
                          onTap: () => context.pushNamed(AppRouteNames.healthSync),
                          trailingIcon: Icons.arrow_forward_ios_rounded,
                        ),
                        _buildDivider(),
                        _buildTile(
                          textTheme,
                          Icons.access_time_rounded,
                          'Last Sync',
                          _lastSyncLabel(ref),
                        ),
                        _buildDivider(),
                        _buildTile(
                          textTheme,
                          Icons.sync_rounded,
                          'Sync Now',
                          null,
                          onTap: syncStatus == SyncStatus.syncing
                              ? null
                              : () => ref.read(healthSyncServiceProvider.notifier).syncNow(),
                          trailingWidget: syncStatus == SyncStatus.syncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                                )
                              : null,
                        ),
                      ]),
                      const SizedBox(height: FitoraSpacing.xl),

                      // ── REMINDERS ─────────────────────────────────────────────
                      _buildSectionTitle(textTheme, 'REMINDERS'),
                      _buildSettingsCard([
                        _buildSwitchTile(
                          textTheme,
                          Icons.water_drop_rounded,
                          'Hydration Reminders',
                          settings.hydrationReminderEnabled,
                          (v) async {
                            if (v) {
                              // Check notification permission first
                              final hasPermission = await settingsNotifier.checkNotificationPermission();
                              if (!hasPermission && context.mounted) {
                                final granted = await ref.read(notificationServiceProvider).requestPermissions();
                                if (!granted && context.mounted) {
                                  _showNotificationDeniedSnackbar(context);
                                  return;
                                }
                              }
                            }
                            await settingsNotifier.updateSetting('hydrationReminderEnabled', v);
                          },
                          iconColor: Colors.blueAccent,
                        ),
                        if (settings.hydrationReminderEnabled) ...[
                          _buildDivider(),
                          _buildTile(
                            textTheme,
                            Icons.timer_rounded,
                            'Reminder Interval',
                            _intervalLabel(settings.hydrationReminderIntervalHours),
                            onTap: () => _showIntervalPicker(context, ref, settings.hydrationReminderIntervalHours),
                            trailingIcon: Icons.expand_more_rounded,
                          ),
                          _buildDivider(),
                          _buildTile(
                            textTheme,
                            Icons.wb_sunny_rounded,
                            'Start Time',
                            _hourLabel(settings.hydrationReminderStartHour),
                            onTap: () => _showTimePicker(context, ref, 'hydrationReminderStartHour', settings.hydrationReminderStartHour),
                            trailingIcon: Icons.expand_more_rounded,
                          ),
                          _buildDivider(),
                          _buildTile(
                            textTheme,
                            Icons.nights_stay_rounded,
                            'End Time',
                            _hourLabel(settings.hydrationReminderEndHour),
                            onTap: () => _showTimePicker(context, ref, 'hydrationReminderEndHour', settings.hydrationReminderEndHour),
                            trailingIcon: Icons.expand_more_rounded,
                          ),
                          _buildDivider(),
                          _buildTile(
                            textTheme,
                            Icons.notifications_active_rounded,
                            'Test Notification',
                            null,
                            onTap: () async {
                              await ref.read(notificationServiceProvider).showTestNotification();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Test notification sent! Check your notification tray.'),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            trailingIcon: Icons.send_rounded,
                            trailingIconColor: FitoraColors.calmCyan,
                          ),
                        ],
                      ]),
                      const SizedBox(height: FitoraSpacing.xl),

                      // ── UNITS ─────────────────────────────────────────────────
                      _buildSectionTitle(textTheme, 'UNITS'),
                      _buildSettingsCard([
                        _buildTile(textTheme, Icons.straighten_rounded, 'System', settings.isMetric ? 'Metric' : 'Imperial', onTap: () {
                          settingsNotifier.updateSetting('isMetric', !settings.isMetric);
                        }),
                      ]),
                      const SizedBox(height: FitoraSpacing.xl),

                      // ── DATA ──────────────────────────────────────────────────
                      _buildSectionTitle(textTheme, 'DATA'),
                      _buildSettingsCard([
                        _buildTile(textTheme, Icons.download_rounded, 'Export Data', null, onTap: () => _exportData(context, ref)),
                        _buildDivider(),
                        _buildTile(textTheme, Icons.delete_forever_rounded, 'Reset Progress', null, isDestructive: true, onTap: () => _confirmReset(context, ref)),
                      ]),
                      const SizedBox(height: FitoraSpacing.xl),

                      // ── ABOUT ─────────────────────────────────────────────────
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
      ),
    );
  }

  // ── Sync helpers ─────────────────────────────────────────────────────────

  String _syncStatusLabel(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.synced:
        return 'Connected';
      case SyncStatus.error:
        return 'Sync Failed';
      default:
        return 'Not Connected';
    }
  }

  String _lastSyncLabel(WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activity = ref.watch(dailyActivityProvider(today));
    final lastSync = activity.lastSyncTime;
    if (lastSync == null) return 'Never';
    final diff = now.difference(lastSync);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    final hourVal = lastSync.toLocal().hour == 0 ? 12 : (lastSync.toLocal().hour > 12 ? lastSync.toLocal().hour - 12 : lastSync.toLocal().hour);
    final amPm = lastSync.toLocal().hour >= 12 ? 'PM' : 'AM';
    final minute = lastSync.toLocal().minute.toString().padLeft(2, '0');
    return '$hourVal:$minute $amPm';
  }

  // ── Reminder helpers ──────────────────────────────────────────────────────

  String _intervalLabel(int hours) => 'Every $hours hour${hours > 1 ? 's' : ''}';

  String _hourLabel(int hour) {
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final amPm = hour >= 12 ? 'PM' : 'AM';
    return '$h:00 $amPm';
  }

  void _showIntervalPicker(BuildContext context, WidgetRef ref, int current) {
    final tt = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Reminder Interval', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            for (final h in [1, 2, 3, 4])
              ListTile(
                title: Text('Every $h hour${h > 1 ? 's' : ''}', style: TextStyle(color: h == current ? FitoraColors.calmCyan : Colors.white)),
                trailing: h == current ? Icon(Icons.check_rounded, color: FitoraColors.calmCyan) : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).updateSetting('hydrationReminderIntervalHours', h);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker(BuildContext context, WidgetRef ref, String key, int currentHour) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
      helpText: key == 'hydrationReminderStartHour' ? 'Select start time' : 'Select end time',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: FitoraColors.calmCyan,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(settingsProvider.notifier).updateSetting(key, picked.hour);
    }
  }

  void _showNotificationDeniedSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notifications are disabled. Open App Settings to enable them.'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Open Settings',
          onPressed: () => ph.openAppSettings(),
        ),
      ),
    );
  }

  // ── Confirm reset ─────────────────────────────────────────────────────────

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
          'hydrationReminderEnabled': settings.hydrationReminderEnabled,
          'hydrationReminderIntervalHours': settings.hydrationReminderIntervalHours,
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

  // ── Shared UI Helpers ─────────────────────────────────────────────────────

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

  Widget _buildSwitchTile(
    TextTheme tt,
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    Color iconColor = Colors.white70,
  }) {
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

  Widget _buildTile(
    TextTheme tt,
    IconData icon,
    String title,
    String? trailingText, {
    bool isDestructive = false,
    VoidCallback? onTap,
    IconData? trailingIcon,
    Color? trailingIconColor,
    Widget? trailingWidget,
  }) {
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
          ?trailingWidget,
          if (trailingText != null) ...[
            Text(trailingText, style: tt.bodySmall?.copyWith(color: Colors.white54)),
            const SizedBox(width: 8),
          ],
          if (trailingIcon != null)
            Icon(trailingIcon, color: trailingIconColor ?? Colors.white30, size: 14),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
  }
}
