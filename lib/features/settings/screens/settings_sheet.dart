import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/app/providers/theme_mode_provider.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Enable notifications'),
              value: settings.notificationsEnabled,
              onChanged: (v) => ref.read(settingsProvider.notifier).setNotifications(v),
            ),
            SwitchListTile(
              title: const Text('Hydration reminders'),
              value: settings.hydrationReminders,
              onChanged: (v) => ref.read(settingsProvider.notifier).setHydrationReminders(v),
            ),
            SwitchListTile(
              title: const Text('Sound & haptics'),
              value: settings.soundEnabled,
              onChanged: (v) => ref.read(settingsProvider.notifier).setSoundEnabled(v),
            ),
            SwitchListTile(
              title: const Text('Autoplay rest timers'),
              value: settings.autoplayRest,
              onChanged: (v) => ref.read(settingsProvider.notifier).setAutoplayRest(v),
            ),
            ListTile(
              title: const Text('Units'),
              subtitle: Text(settings.units == 'metric' ? 'Metric (kg, cm)' : 'Imperial (lbs, in)'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) => ref.read(settingsProvider.notifier).setUnits(v),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'metric', child: Text('Metric')),
                  const PopupMenuItem(value: 'imperial', child: Text('Imperial')),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Appearance'),
              subtitle: const Text('Select app theme'),
              trailing: PopupMenuButton<ThemeMode>(
                onSelected: (mode) => ref.read(themeModeProvider.notifier).setThemeMode(mode),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: ThemeMode.light, child: Text('Light')),
                  const PopupMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                  const PopupMenuItem(value: ThemeMode.system, child: Text('System')),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
