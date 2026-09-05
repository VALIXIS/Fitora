import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/app/providers/theme_mode_provider.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/features/cloud_backup/domain/cloud_backup_models.dart';
import 'package:fitora/features/cloud_backup/providers/cloud_backup_providers.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final cloudBackupState = ref.watch(cloudBackupSyncProvider);
    final cloudBackupNotifier = ref.read(cloudBackupSyncProvider.notifier);

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: 'Settings Sheet',
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Semantics(
                    button: true,
                    label: 'Close settings',
                    child: IconButton(
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Cloud Backup & Sync Section ────────────────────────────
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.cloud_sync_rounded,
                  color: FitoraColors.mintGreen,
                ),
                title: const Text(
                  'Cloud Backup & Restore',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  cloudBackupState.status.displayName,
                  style: TextStyle(
                    color: cloudBackupState.status == CloudBackupSyncStatus.failed
                        ? Colors.redAccent
                        : null,
                  ),
                ),
                trailing: Switch(
                  value: cloudBackupState.enabled,
                  onChanged: (v) => cloudBackupNotifier.toggleBackup(v),
                ),
              ),
              if (cloudBackupState.enabled) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
                  child: Row(
                    children: [
                      if (cloudBackupState.lastSyncTime != null)
                        Text(
                          'Last backup: ${_formatTime(cloudBackupState.lastSyncTime!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        )
                      else
                        Text(
                          'No cloud backup yet',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(88, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: cloudBackupState.status == CloudBackupSyncStatus.syncing
                            ? null
                            : () => cloudBackupNotifier.syncNow(),
                        icon: cloudBackupState.status == CloudBackupSyncStatus.syncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync_rounded, size: 16),
                        label: const Text('Sync Now'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(88, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: cloudBackupState.status == CloudBackupSyncStatus.syncing
                            ? null
                            : () => cloudBackupNotifier.restoreData(),
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Restore'),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(),

              SwitchListTile(
                title: const Text('Enable notifications'),
                value: settings.notificationsEnabled,
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .updateSetting('notificationsEnabled', v),
              ),
              SwitchListTile(
                title: const Text('Hydration reminders'),
                value: settings.hydrationReminderEnabled,
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .updateSetting('hydrationReminderEnabled', v),
              ),
              SwitchListTile(
                title: const Text('Sound & haptics'),
                value: settings.soundEffectsEnabled,
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .updateSetting('soundEffectsEnabled', v),
              ),
              SwitchListTile(
                title: const Text('Autoplay rest timers'),
                value: settings.autoplayRest,
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .updateSetting('autoplayRest', v),
              ),
              ListTile(
                title: const Text('Units'),
                subtitle: Text(
                  settings.isMetric ? 'Metric (kg, cm)' : 'Imperial (lbs, in)',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => ref
                      .read(settingsProvider.notifier)
                      .updateSetting('isMetric', v == 'metric'),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'metric', child: Text('Metric')),
                    const PopupMenuItem(
                      value: 'imperial',
                      child: Text('Imperial'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.sync_rounded,
                  color: FitoraColors.mintGreen,
                ),
                title: const Text('Health Integration'),
                subtitle: const Text('Google Fit, Health Connect, Apple Health…'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/profile/health-sync');
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Appearance'),
                subtitle: const Text('Select app theme'),
                trailing: PopupMenuButton<ThemeMode>(
                  onSelected: (mode) =>
                      ref.read(themeModeProvider.notifier).setThemeMode(mode),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    const PopupMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                    const PopupMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
