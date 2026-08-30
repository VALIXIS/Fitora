import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';

Future<void> showSleepLogModal(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _LogSleepModal(),
  );
}

class _LogSleepModal extends ConsumerStatefulWidget {
  const _LogSleepModal();

  @override
  ConsumerState<_LogSleepModal> createState() => _LogSleepModalState();
}

class _LogSleepModalState extends ConsumerState<_LogSleepModal> {
  double _hoursSlept = 8.0;
  int _qualityScore = 80;

  @override
  void initState() {
    super.initState();
    final wellness = ref.read(wellnessProvider);
    if (wellness.sleepMinutes > 0) {
      _hoursSlept = (wellness.sleepMinutes / 60.0).clamp(1.0, 14.0);
      _qualityScore = wellness.sleepQualityScore > 0 ? wellness.sleepQualityScore : 80;
    }
  }

  void _onSave() {
    final minutes = (_hoursSlept * 60).round();
    ref.read(wellnessProvider.notifier).logSleep(
          minutes: minutes,
          qualityScore: _qualityScore,
        );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final settings = ref.watch(settingsProvider);
    final targetHours = (settings.sleepTargetDurationMinutes / 60.0).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(FitoraSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: FitoraColors.calmCyan.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bedtime_rounded,
                      color: FitoraColors.calmCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Log Last Night\'s Sleep',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () => context.pop(),
              ),
            ],
          ),
          const SizedBox(height: FitoraSpacing.lg),

          // Sleep Duration Selector Display
          Center(
            child: Column(
              children: [
                Text(
                  '${_hoursSlept.toStringAsFixed(1)} hrs',
                  style: tt.displayLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: FitoraColors.calmCyan,
                  ),
                ),
                Text(
                  'Hours Slept Last Night',
                  style: tt.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FitoraSpacing.md),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: FitoraColors.calmCyan,
              inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
              thumbColor: FitoraColors.calmCyan,
              overlayColor: FitoraColors.calmCyan.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _hoursSlept,
              min: 1.0,
              max: 14.0,
              divisions: 26,
              label: '${_hoursSlept.toStringAsFixed(1)}h',
              onChanged: (val) => setState(() => _hoursSlept = val),
            ),
          ),

          // Preset Chips
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0].map((h) {
              final isSelected = (_hoursSlept - h).abs() < 0.2;
              return ChoiceChip(
                label: Text('${h % 1 == 0 ? h.toInt() : h}h'),
                selected: isSelected,
                selectedColor: FitoraColors.calmCyan,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.black
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (_) => setState(() => _hoursSlept = h),
              );
            }).toList(),
          ),

          const SizedBox(height: FitoraSpacing.lg),

          // Target Goal Info Hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Daily Target: $targetHours hrs (Configure target in Progress ➜ Recovery)',
                    style: tt.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: FitoraSpacing.xl),

          // Save Button
          ElevatedButton(
            onPressed: _onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: FitoraColors.calmCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Save Sleep Log',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
