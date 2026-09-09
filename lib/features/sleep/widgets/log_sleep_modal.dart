import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';
import 'package:fitora/features/sleep/widgets/circular_sleep_dial.dart';
import 'package:fitora/core/health/domain/sleep_calculations.dart';
import 'package:fitora/shared/widgets/scale_on_press.dart';
import 'package:fitora/core/services/haptic_service.dart';

Future<void> showSleepLogModal(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet(
    context: context,
    useRootNavigator: true,
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
  late int _bedHour;
  late int _bedMin;
  late int _wakeHour;
  late int _wakeMin;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _bedHour = settings.sleepTargetBedtimeHour;
    _bedMin = settings.sleepTargetBedtimeMinute;
    _wakeHour = settings.sleepTargetWakeHour;
    _wakeMin = settings.sleepTargetWakeMinute;
  }

  void _onDialChanged(int bedHour, int bedMin, int wakeHour, int wakeMin) {
    setState(() {
      _bedHour = bedHour;
      _bedMin = bedMin;
      _wakeHour = wakeHour;
      _wakeMin = wakeMin;
    });
  }

  Future<void> _onSave() async {
    ref.read(hapticServiceProvider).buttonPress();
    final duration = SleepCalculations.calculateTargetDuration(
      _bedHour,
      _bedMin,
      _wakeHour,
      _wakeMin,
    );

    await ref.read(wellnessProvider.notifier).logSleep(
          minutes: duration.inMinutes,
          qualityScore: 80,
        );

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final settings = ref.watch(settingsProvider);

    final duration = SleepCalculations.calculateTargetDuration(
      _bedHour,
      _bedMin,
      _wakeHour,
      _wakeMin,
    );
    final hours = duration.inHours;
    final mins = duration.inMinutes.remainder(60);
    final durationStr = mins > 0 ? '${hours}h ${mins}m' : '${hours}h 0m';

    final bedTimeStr = TimeOfDay(hour: _bedHour, minute: _bedMin).format(context);
    final wakeTimeStr = TimeOfDay(hour: _wakeHour, minute: _wakeMin).format(context);
    final targetHours = (settings.sleepTargetDurationMinutes / 60.0).toStringAsFixed(1);

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: 'Log Last Night\'s Sleep Dialog',
      child: Container(
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
                Semantics(
                  button: true,
                  label: 'Close sleep log modal',
                  child: IconButton(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    tooltip: 'Close sleep log modal',
                    icon: Icon(
                      Icons.close_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: FitoraSpacing.xs),

            Text(
              'Drag bedtime & wake-up handles on the circular meter to log your sleep.',
              style: tt.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FitoraSpacing.md),

            // Circular Dial Meter for Logging
            Center(
              child: SizedBox(
                width: 250,
                height: 250,
                child: CircularSleepDial(
                  initialBedHour: _bedHour,
                  initialBedMinute: _bedMin,
                  initialWakeHour: _wakeHour,
                  initialWakeMinute: _wakeMin,
                  onChanged: _onDialChanged,
                ),
              ),
            ),
            const SizedBox(height: FitoraSpacing.md),

            // Readout Box
            Container(
              padding: const EdgeInsets.all(FitoraSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'BEDTIME',
                        style: tt.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '🌙 $bedTimeStr',
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  Column(
                    children: [
                      Text(
                        'SLEPT DURATION',
                        style: tt.labelSmall?.copyWith(
                          color: FitoraColors.calmCyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        durationStr,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: FitoraColors.calmCyan,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  Column(
                    children: [
                      Text(
                        'WAKE UP',
                        style: tt.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '☀️ $wakeTimeStr',
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: FitoraSpacing.sm),

            Center(
              child: Text(
                'Target Goal: $targetHours hrs (Configure target in Progress ➜ Recovery)',
                style: tt.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: FitoraSpacing.lg),

            // Save Button
            Semantics(
              button: true,
              label: 'Save Sleep Log',
              child: ScaleOnPress(
                child: ElevatedButton(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
