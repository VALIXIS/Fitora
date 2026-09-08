import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final hasExactPermission = ref.watch(exactAlarmPermissionProvider).value ?? true;
    final isBatteryOptimized = ref.watch(batteryOptimizationExemptProvider).value ?? false;

    return FitoraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: theme.colorScheme.onSurface,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Settings',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
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
                    // ── GENERAL ───────────────────────────────────────────────
                    _buildSectionTitle(context, 'GENERAL'),
                    _buildSettingsCard(context, [
                      _buildSwitchTile(
                        context,
                        textTheme,
                        Icons.dark_mode_rounded,
                        'Dark Mode',
                        settings.isDarkMode,
                        (v) => settingsNotifier.updateSetting('isDarkMode', v),
                      ),
                      _buildDivider(context),
                      _buildSwitchTile(
                        context,
                        textTheme,
                        Icons.notifications_active_rounded,
                        'Notifications',
                        settings.notificationsEnabled,
                        (v) async {
                          await settingsNotifier.updateSetting(
                            'notificationsEnabled',
                            v,
                          );
                          // If they enabled but permission was denied, show guidance
                          if (v && context.mounted) {
                            final hasPermission = await settingsNotifier
                                .checkNotificationPermission();
                            if (!hasPermission && context.mounted) {
                              _showNotificationDeniedSnackbar(context);
                            }
                          }
                        },
                      ),
                      _buildDivider(context),
                      _buildSwitchTile(
                        context,
                        textTheme,
                        Icons.volume_up_rounded,
                        'Sound Effects',
                        settings.soundEffectsEnabled,
                        (v) {
                          settingsNotifier.updateSetting(
                            'soundEffectsEnabled',
                            v,
                          );
                          if (v) {
                            ref
                                .read(audioServiceProvider)
                                .playNotificationSound();
                          }
                        },
                      ),
                      _buildDivider(context),
                      _buildSwitchTile(
                        context,
                        textTheme,
                        Icons.vibration_rounded,
                        'Haptics',
                        settings.hapticsEnabled,
                        (v) {
                          settingsNotifier.updateSetting('hapticsEnabled', v);
                          if (v) ref.read(hapticServiceProvider).lightImpact();
                        },
                      ),
                    ]),
                    const SizedBox(height: FitoraSpacing.xl),

                    // ── STEP COUNTER & SENSORS ─────────────────────────────────
                    _buildSectionTitle(context, 'STEP COUNTER & SENSORS'),
                    _buildSensorSettingsSection(context, textTheme, ref, isBatteryOptimized),
                    const SizedBox(height: FitoraSpacing.xl),

                    // ── REMINDERS ─────────────────────────────────────────────
                    _buildSectionTitle(context, 'REMINDERS'),
                    _buildSettingsCard(context, [
                      _buildSwitchTile(
                        context,
                        textTheme,
                        Icons.water_drop_rounded,
                        'Hydration Reminders',
                        settings.hydrationReminderEnabled,
                        (v) async {
                          if (v) {
                            final hasPermission = await settingsNotifier
                                .checkNotificationPermission();
                            if (!hasPermission && context.mounted) {
                              final granted = await ref
                                  .read(notificationServiceProvider)
                                  .requestPermissions();
                              if (!granted && context.mounted) {
                                _showNotificationDeniedSnackbar(context);
                                return;
                              }
                            }
                          }
                          await settingsNotifier.updateSetting(
                            'hydrationReminderEnabled',
                            v,
                          );
                        },
                        iconColor: Colors.blueAccent,
                      ),
                      if (settings.hydrationReminderEnabled) ...[
                        _buildDivider(context),
                        _buildTile(
                          context,
                          textTheme,
                          Icons.timer_rounded,
                          'Reminder Interval',
                          _intervalLabel(
                            settings.hydrationReminderIntervalMinutes,
                          ),
                          onTap: () => _showIntervalPicker(
                            context,
                            ref,
                            settings.hydrationReminderIntervalMinutes,
                          ),
                          trailingIcon: Icons.expand_more_rounded,
                        ),
                      ],
                      _buildDivider(context),
                      _buildSwitchTile(
                        context,
                        textTheme,
                        Icons.directions_walk_rounded,
                        'Step Goal Encouragement',
                        settings.stepReminderEnabled,
                        (v) async => await settingsNotifier.updateSetting(
                          'stepReminderEnabled',
                          v,
                        ),
                        iconColor: Colors.greenAccent,
                      ),
                      _buildDivider(context),
                      _buildSwitchTile(
                        context,
                        textTheme,
                        Icons.bedtime_rounded,
                        'Sleep Schedule Reminders',
                        settings.sleepReminderEnabled,
                        (v) async => await settingsNotifier.updateSetting(
                          'sleepReminderEnabled',
                          v,
                        ),
                        iconColor: Colors.deepPurpleAccent,
                      ),
                      _buildDivider(context),
                      _buildSwitchTile(
                        context,
                        textTheme,
                        Icons.summarize_rounded,
                        'Daily Health Summary',
                        settings.dailySummaryEnabled,
                        (v) async => await settingsNotifier.updateSetting(
                          'dailySummaryEnabled',
                          v,
                        ),
                        iconColor: Colors.orangeAccent,
                      ),
                      _buildDivider(context),
                      _buildSwitchTile(
                        context,
                        textTheme,
                        Icons.do_not_disturb_on_rounded,
                        'Quiet Hours',
                        settings.quietHoursEnabled,
                        (v) async => await settingsNotifier.updateSetting(
                          'quietHoursEnabled',
                          v,
                        ),
                        iconColor: Colors.grey,
                      ),
                      if (settings.quietHoursEnabled) ...[
                        _buildDivider(context),
                        _buildTile(
                          context,
                          textTheme,
                          Icons.nights_stay_rounded,
                          'Quiet Hours Start',
                          _hourLabel(settings.quietHoursStartHour),
                          onTap: () => _showTimePicker(
                            context,
                            ref,
                            'quietHoursStartHour',
                            settings.quietHoursStartHour,
                          ),
                          trailingIcon: Icons.expand_more_rounded,
                        ),
                        _buildDivider(context),
                        _buildTile(
                          context,
                          textTheme,
                          Icons.wb_sunny_rounded,
                          'Quiet Hours End',
                          _hourLabel(settings.quietHoursEndHour),
                          onTap: () => _showTimePicker(
                            context,
                            ref,
                            'quietHoursEndHour',
                            settings.quietHoursEndHour,
                          ),
                          trailingIcon: Icons.expand_more_rounded,
                        ),
                      ],
                      _buildDivider(context),
                      _buildTile(
                        context,
                        textTheme,
                        Icons.notifications_active_rounded,
                        'Test Notification',
                        null,
                        onTap: () async {
                          final svc = ref.read(notificationServiceProvider);
                          final hasPerm = await svc.hasPermission();
                          if (!hasPerm) {
                            final granted = await svc.requestPermissions();
                            if (!granted && context.mounted) {
                              _showNotificationDeniedSnackbar(context);
                              return;
                            }
                          }
                          await svc.showTestNotification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Test notification sent! Check your notification tray.',
                                ),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        trailingIcon: Icons.send_rounded,
                        trailingIconColor: FitoraColors.calmCyan,
                      ),
                      if (settings.hydrationReminderEnabled ||
                          settings.stepReminderEnabled ||
                          settings.sleepReminderEnabled ||
                          settings.dailySummaryEnabled) ...[
                        if (!hasExactPermission) ...[
                          _buildDivider(context),
                          _buildTile(
                            context,
                            textTheme,
                            Icons.warning_amber_rounded,
                            'Exact Alarms Disabled',
                            'Tap to allow exact timing',
                            onTap: () async {
                              await settingsNotifier.requestExactAlarmPermission();
                              ref.invalidate(exactAlarmPermissionProvider);
                            },
                            trailingIcon: Icons.arrow_forward_ios_rounded,
                            trailingIconColor: Colors.amber,
                          ),
                        ]
                      ]
                    ]),
                    const SizedBox(height: FitoraSpacing.xl),

                    // ── UNITS ─────────────────────────────────────────────────
                    _buildSectionTitle(context, 'UNITS'),
                    _buildSettingsCard(context, [
                      _buildTile(
                        context,
                        textTheme,
                        Icons.straighten_rounded,
                        'System',
                        settings.isMetric ? 'Metric' : 'Imperial',
                        onTap: () {
                          settingsNotifier.updateSetting(
                            'isMetric',
                            !settings.isMetric,
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: FitoraSpacing.xl),

                    // ── DATA ──────────────────────────────────────────────────
                    _buildSectionTitle(context, 'DATA'),
                    _buildSettingsCard(context, [
                      _buildTile(
                        context,
                        textTheme,
                        Icons.download_rounded,
                        'Export Data',
                        null,
                        onTap: () => _exportData(context, ref),
                      ),
                      _buildDivider(context),
                      _buildTile(
                        context,
                        textTheme,
                        Icons.delete_forever_rounded,
                        'Reset Progress',
                        null,
                        isDestructive: true,
                        onTap: () => _confirmReset(context, ref),
                      ),
                    ]),
                    const SizedBox(height: FitoraSpacing.xl),

                    // ── ABOUT ─────────────────────────────────────────────────
                    _buildSectionTitle(context, 'ABOUT'),
                    _buildSettingsCard(context, [
                      Consumer(
                        builder: (context, ref, _) {
                          final packageInfoAsync = ref.watch(
                            packageInfoProvider,
                          );
                          final versionText = packageInfoAsync.when(
                            data: (info) =>
                                'v${info.version} (Build ${info.buildNumber})',
                            loading: () => 'Loading...',
                            error: (_, _) => 'v1.0.0',
                          );
                          return _buildTile(
                            context,
                            textTheme,
                            Icons.info_outline_rounded,
                            'App Version',
                            versionText,
                          );
                        },
                      ),
                      _buildDivider(context),
                      _buildTile(
                        context,
                        textTheme,
                        Icons.sports_gymnastics_rounded,
                        'About Fitora',
                        null,
                        onTap: () => context.pushNamed(AppRouteNames.about),
                      ),
                      _buildDivider(context),
                      _buildTile(
                        context,
                        textTheme,
                        Icons.privacy_tip_rounded,
                        'Privacy Policy',
                        null,
                        onTap: () =>
                            context.pushNamed(AppRouteNames.privacyPolicy),
                      ),
                      _buildDivider(context),
                      _buildTile(
                        context,
                        textTheme,
                        Icons.gavel_rounded,
                        'Terms of Service',
                        null,
                        onTap: () =>
                            context.pushNamed(AppRouteNames.termsOfService),
                      ),
                    ]),
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

  // ── Sync helpers ─────────────────────────────────────────────────────────

  Widget _buildSensorSettingsSection(
    BuildContext context,
    TextTheme tt,
    WidgetRef ref,
    bool isBatteryOptimized,
  ) {
    final sensorStatus = ref.watch(sensorStatusProvider);
    final theme = Theme.of(context);

    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (sensorStatus) {
      case SensorStatus.active:
        statusText = 'Active 🟢';
        statusColor = FitoraColors.mintGreen;
        statusIcon = Icons.sensors_rounded;
        break;
      case SensorStatus.permissionRequired:
        statusText = 'Permission Disabled ⚠️';
        statusColor = FitoraColors.warningOrange;
        statusIcon = Icons.sensors_off_rounded;
        break;
      case SensorStatus.unavailable:
        statusText = 'Sensor Unavailable';
        statusColor = theme.colorScheme.onSurface.withValues(alpha: 0.38);
        statusIcon = Icons.do_not_disturb_rounded;
        break;
      case SensorStatus.unknown:
        statusText = 'Checking...';
        statusColor = theme.colorScheme.onSurface.withValues(alpha: 0.54);
        statusIcon = Icons.sensors_rounded;
        break;
    }

    return _buildSettingsCard(context, [
      _buildTile(
        context,
        tt,
        statusIcon,
        'Step Sensor Status',
        null,
        trailingWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(0.7,0.7), end: const Offset(1.3,1.3), duration: 800.ms),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: tt.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      _buildDivider(context),
      _buildTile(
        context,
        tt,
        Icons.fact_check_rounded,
        'Verify Sensor Permission',
        'Check Now',
        onTap: () async {
          final notifier = ref.read(sensorStatusProvider.notifier);
          await notifier.checkPermission();
          final updated = ref.read(sensorStatusProvider);
          if (context.mounted) {
            final isOK = updated == SensorStatus.active;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isOK
                      ? 'Step counter sensor is active and tracking your steps!'
                      : 'Step tracking permission is disabled. Tap Open Settings to enable it.',
                  style: TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                  ),
                ),
                backgroundColor: theme.colorScheme.inverseSurface,
                duration: const Duration(seconds: 4),
                action: isOK
                    ? null
                    : SnackBarAction(
                        label: 'Open Settings',
                        textColor: FitoraColors.warningOrange,
                        onPressed: () => ph.openAppSettings(),
                      ),
              ),
            );
          }
        },
        trailingIcon: Icons.refresh_rounded,
      ),
      _buildDivider(context),
      _buildTile(
        context,
        tt,
        Icons.battery_saver_rounded,
        'Battery Optimization',
        isBatteryOptimized ? 'Optimized' : 'Request Unrestricted',
        onTap: () async {
          if (isBatteryOptimized) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitora is already unrestricted and optimized!')),
            );
          } else {
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Background Activity'),
                content: const Text(
                  'Allowing Fitora to run in the background prevents Android from pausing the step counters and health sync operations when the phone is idle.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await ph.Permission.ignoreBatteryOptimizations.request();
                      ref.invalidate(batteryOptimizationExemptProvider);
                    },
                    child: const Text('Optimize'),
                  ),
                ],
              ),
            );
          }
        },
        trailingIcon: Icons.bolt_rounded,
        trailingIconColor: isBatteryOptimized ? FitoraColors.mintGreen : Colors.amber,
      ),
      if (sensorStatus == SensorStatus.permissionRequired) ...[
        _buildDivider(context),
        Padding(
          padding: const EdgeInsets.all(FitoraSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(FitoraSpacing.md),
            decoration: BoxDecoration(
              color: FitoraColors.warningOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: FitoraColors.warningOrange.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: FitoraColors.warningOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Step Tracking Disabled',
                        style: tt.titleSmall?.copyWith(
                          color: FitoraColors.warningOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'If you accidentally tapped "Don\'t allow" for physical activity or motion permissions, tap below to grant permission or open system App Settings to re-enable step recording.',
                  style: tt.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final notifier = ref.read(sensorStatusProvider.notifier);
                      await notifier.requestPermission();
                      final currentStatus = ref.read(sensorStatusProvider);
                      if (currentStatus == SensorStatus.permissionRequired) {
                        await ph.openAppSettings();
                      }
                    },
                    icon: const Icon(Icons.security_rounded, size: 16),
                    label: const Text('Grant / Open System Settings'),
                    style: FilledButton.styleFrom(
                      backgroundColor: FitoraColors.warningOrange,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ]);
  }

  // ── Reminder helpers ──────────────────────────────────────────────────────

  String _intervalLabel(int minutes) => 'Every $minutes mins';

  String _hourLabel(int hour) {
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final amPm = hour >= 12 ? 'PM' : 'AM';
    return '$h:00 $amPm';
  }

  void _showIntervalPicker(
    BuildContext context,
    WidgetRef ref,
    int currentMins,
  ) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Reminder Interval',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            for (final m in [60, 90, 120, 180])
              ListTile(
                title: Text(
                  'Every $m mins',
                  style: TextStyle(
                    color: m == currentMins
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                trailing: m == currentMins
                    ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .updateSetting('hydrationReminderIntervalMinutes', m);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker(
    BuildContext context,
    WidgetRef ref,
    String key,
    int currentHour,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
      helpText: 'Select time',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: FitoraColors.calmCyan),
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
        content: const Text(
          'Notifications are disabled. Open App Settings to enable them.',
        ),
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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Reset Progress',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to reset all your progress and personalization settings? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              final nav = GoRouter.of(context);
              await ref.read(settingsProvider.notifier).resetToDefaults();
              await ref
                  .read(personalizationControllerProvider.notifier)
                  .reset();
              nav.go(AppRoutes.onboarding);
            },
            child: const Text(
              'Reset',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
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
          'isMetric': settings.isMetric,
          'autoplayRest': settings.autoplayRest,
          'hydrationReminderEnabled': settings.hydrationReminderEnabled,
          'hydrationReminderIntervalMinutes': settings.hydrationReminderIntervalMinutes,
          'stepReminderEnabled': settings.stepReminderEnabled,
          'sleepReminderEnabled': settings.sleepReminderEnabled,
          'dailySummaryEnabled': settings.dailySummaryEnabled,
          'quietHoursEnabled': settings.quietHoursEnabled,
          'quietHoursStartHour': settings.quietHoursStartHour,
          'quietHoursEndHour': settings.quietHoursEndHour,
        },
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
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : null,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export data: $e')));
    }
  }

  // ── Shared UI Helpers ─────────────────────────────────────────────────────

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 24,
            decoration: BoxDecoration(
              color: FitoraColors.mintGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.5, end: 0, curve: Curves.easeOut),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
      height: 1,
      indent: 56,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    TextTheme tt,
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? theme.colorScheme.onSurfaceVariant, size: 24),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.colorScheme.primary,
            activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.3),
            inactiveThumbColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            inactiveTrackColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
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
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDestructive ? Colors.redAccent : theme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: tt.bodyMedium?.copyWith(
                color: isDestructive ? Colors.redAccent : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // ignore: use_null_aware_elements
          if (trailingWidget != null) trailingWidget,
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: tt.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
          ],
          if (trailingIcon != null)
            Icon(
              trailingIcon,
              color: trailingIconColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 14,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
  }
}
