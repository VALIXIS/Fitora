import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';
import 'package:fitora/features/sleep/widgets/circular_sleep_dial.dart';
import 'package:fitora/core/health/domain/sleep_calculations.dart';

Future<void> showSleepAnalysisModal(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _SleepAnalysisModal(),
  );
}

class _SleepAnalysisModal extends ConsumerStatefulWidget {
  const _SleepAnalysisModal();

  @override
  ConsumerState<_SleepAnalysisModal> createState() => _SleepAnalysisModalState();
}

class _SleepAnalysisModalState extends ConsumerState<_SleepAnalysisModal> {
  // Section 1: Target Sleep Goal (Bar / Quick Select Options)
  double _targetHours = 8.0;

  // Section 2: Logging Last Night's Sleep (Circular Sleep Dial Meter)
  late int _logBedHour;
  late int _logBedMin;
  late int _logWakeHour;
  late int _logWakeMin;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _targetHours = (settings.sleepTargetDurationMinutes / 60.0).clamp(5.0, 12.0);
    _logBedHour = settings.sleepTargetBedtimeHour;
    _logBedMin = settings.sleepTargetBedtimeMinute;
    _logWakeHour = settings.sleepTargetWakeHour;
    _logWakeMin = settings.sleepTargetWakeMinute;
  }

  void _onDialChanged(int bedHour, int bedMin, int wakeHour, int wakeMin) {
    setState(() {
      _logBedHour = bedHour;
      _logBedMin = bedMin;
      _logWakeHour = wakeHour;
      _logWakeMin = wakeMin;
    });
  }

  Future<void> _saveTargetGoal() async {
    final targetMinutes = (_targetHours * 60).round();
    final notifier = ref.read(settingsProvider.notifier);
    await notifier.updateSetting('sleepTargetDurationMinutes', targetMinutes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Target Sleep Goal updated to ${_targetHours.toStringAsFixed(1)} hrs!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveSleepLog() async {
    final duration = SleepCalculations.calculateTargetDuration(
      _logBedHour,
      _logBedMin,
      _logWakeHour,
      _logWakeMin,
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

    final logDuration = SleepCalculations.calculateTargetDuration(
      _logBedHour,
      _logBedMin,
      _logWakeHour,
      _logWakeMin,
    );
    final logHours = logDuration.inHours;
    final logMins = logDuration.inMinutes.remainder(60);
    final logDurationStr =
        logMins > 0 ? '${logHours}h ${logMins}m' : '${logHours}h 0m';

    final bedTimeStr = TimeOfDay(hour: _logBedHour, minute: _logBedMin).format(context);
    final wakeTimeStr = TimeOfDay(hour: _logWakeHour, minute: _logWakeMin).format(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(FitoraSpacing.xl),
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: FitoraSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
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
                        'Sleep Analysis & Target',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
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

              // =================================================================
              // SECTION 1: SET TARGET SLEEP GOAL (BAR / QUICK SELECT OPTIONS)
              // =================================================================
              Container(
                padding: const EdgeInsets.all(FitoraSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.track_changes_rounded,
                          color: FitoraColors.calmCyan,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SECTION 1: TARGET SLEEP GOAL',
                          style: tt.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: FitoraColors.calmCyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: FitoraSpacing.sm),
                    Text(
                      'Set your target sleep duration goal using the quick select options or bar slider below.',
                      style: tt.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: FitoraSpacing.md),

                    // Display Target Value
                    Center(
                      child: Text(
                        '${_targetHours.toStringAsFixed(1)} hrs / day',
                        style: tt.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: FitoraColors.calmCyan,
                        ),
                      ),
                    ),
                    const SizedBox(height: FitoraSpacing.sm),

                    // Target Duration Bar Slider
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: FitoraColors.calmCyan,
                        inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
                        thumbColor: FitoraColors.calmCyan,
                        overlayColor: FitoraColors.calmCyan.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: _targetHours,
                        min: 5.0,
                        max: 12.0,
                        divisions: 14,
                        label: '${_targetHours.toStringAsFixed(1)}h Target',
                        onChanged: (val) => setState(() => _targetHours = val),
                      ),
                    ),

                    // Quick Select Option Chips for Target Goal
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [6.5, 7.0, 7.5, 8.0, 8.5, 9.0].map((tVal) {
                        final isSelected = (_targetHours - tVal).abs() < 0.2;
                        return ChoiceChip(
                          label: Text('${tVal % 1 == 0 ? tVal.toInt() : tVal} hrs Goal'),
                          selected: isSelected,
                          selectedColor: FitoraColors.calmCyan,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.black
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _targetHours = tVal),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: FitoraSpacing.lg),

                    OutlinedButton.icon(
                      onPressed: _saveTargetGoal,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text('Save Target Goal'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FitoraColors.calmCyan,
                        side: const BorderSide(color: FitoraColors.calmCyan),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: FitoraSpacing.xl),

              // =================================================================
              // SECTION 2: LOG LAST NIGHT'S SLEEP (CIRCULAR DIAL METER)
              // =================================================================
              Container(
                padding: const EdgeInsets.all(FitoraSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          color: FitoraColors.mintGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SECTION 2: LOG LAST NIGHT\'S SLEEP',
                          style: tt.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: FitoraColors.mintGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: FitoraSpacing.sm),
                    Text(
                      'Drag bedtime & wake-up handles on the circular dial meter to log your sleep.',
                      style: tt.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: FitoraSpacing.md),

                    // Circular Sleep Dial Meter for Logging
                    Center(
                      child: SizedBox(
                        width: 250,
                        height: 250,
                        child: CircularSleepDial(
                          initialBedHour: _logBedHour,
                          initialBedMinute: _logBedMin,
                          initialWakeHour: _logWakeHour,
                          initialWakeMinute: _logWakeMin,
                          onChanged: _onDialChanged,
                        ),
                      ),
                    ),
                    const SizedBox(height: FitoraSpacing.md),

                    // Log Summary Box
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          '🌙 $bedTimeStr',
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Slept: $logDurationStr',
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: FitoraColors.mintGreen,
                          ),
                        ),
                        Text(
                          '☀️ $wakeTimeStr',
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: FitoraSpacing.lg),

                    // Save Sleep Log Button
                    ElevatedButton(
                      onPressed: _saveSleepLog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FitoraColors.mintGreen,
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
              ),
              const SizedBox(height: FitoraSpacing.xxl),
            ],
          ),
        );
      },
    );
  }
}
