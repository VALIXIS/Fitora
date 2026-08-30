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
  late int _bedHour;
  late int _bedMin;
  late int _wakeHour;
  late int _wakeMin;

  double _hoursSlept = 8.0;
  int _qualityScore = 80;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _bedHour = settings.sleepTargetBedtimeHour;
    _bedMin = settings.sleepTargetBedtimeMinute;
    _wakeHour = settings.sleepTargetWakeHour;
    _wakeMin = settings.sleepTargetWakeMinute;

    final wellness = ref.read(wellnessProvider);
    if (wellness.sleepMinutes > 0) {
      _hoursSlept = (wellness.sleepMinutes / 60.0).clamp(1.0, 14.0);
      _qualityScore = wellness.sleepQualityScore > 0 ? wellness.sleepQualityScore : 80;
    }
  }

  void _onDialChanged(int bedHour, int bedMin, int wakeHour, int wakeMin) {
    setState(() {
      _bedHour = bedHour;
      _bedMin = bedMin;
      _wakeHour = wakeHour;
      _wakeMin = wakeMin;
    });
  }

  Future<void> _saveTargetSchedule() async {
    final targetDuration = SleepCalculations.calculateTargetDuration(
      _bedHour,
      _bedMin,
      _wakeHour,
      _wakeMin,
    ).inMinutes;

    final notifier = ref.read(settingsProvider.notifier);
    await notifier.updateSetting('sleepTargetBedtimeHour', _bedHour);
    await notifier.updateSetting('sleepTargetBedtimeMinute', _bedMin);
    await notifier.updateSetting('sleepTargetWakeHour', _wakeHour);
    await notifier.updateSetting('sleepTargetWakeMinute', _wakeMin);
    await notifier.updateSetting('sleepTargetDurationMinutes', targetDuration);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Target Sleep Schedule Saved!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveSleepLog() async {
    final minutes = (_hoursSlept * 60).round();
    await ref.read(wellnessProvider.notifier).logSleep(
          minutes: minutes,
          qualityScore: _qualityScore,
        );

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;

    final targetDuration = SleepCalculations.calculateTargetDuration(
      _bedHour,
      _bedMin,
      _wakeHour,
      _wakeMin,
    );
    final targetHours = targetDuration.inHours;
    final targetMins = targetDuration.inMinutes.remainder(60);
    final targetDurationStr =
        targetMins > 0 ? '${targetHours}h ${targetMins}m' : '${targetHours}h 0m';

    final bedTimeStr = TimeOfDay(hour: _bedHour, minute: _bedMin).format(context);
    final wakeTimeStr = TimeOfDay(hour: _wakeHour, minute: _wakeMin).format(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
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
              // Sheet Drag Handle
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
              // SECTION 1: SET TARGET SLEEP SCHEDULE
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
                          'SECTION 1: TARGET SLEEP SCHEDULE',
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
                      'Select your target sleep hours or drag the handles on the circular dial meter to set bedtime & wake-up time.',
                      style: tt.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: FitoraSpacing.md),

                    // Quick Target Selection Options / Chips
                    Text(
                      'Target Sleep Goal Options:',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [7.0, 7.5, 8.0, 8.5, 9.0].map((tHours) {
                        final currentTargetH = targetDuration.inMinutes / 60.0;
                        final isSelected = (currentTargetH - tHours).abs() < 0.25;
                        return ChoiceChip(
                          label: Text('${tHours % 1 == 0 ? tHours.toInt() : tHours} hrs Target'),
                          selected: isSelected,
                          selectedColor: FitoraColors.calmCyan,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.black
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (_) {
                            final newWakeH = (_bedHour + tHours.toInt()) % 24;
                            final newWakeM = _bedMin;
                            _onDialChanged(_bedHour, _bedMin, newWakeH, newWakeM);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: FitoraSpacing.lg),

                    // Circular Sleep Dial Meter for Target
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

                    // Target Schedule Readout Box
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
                          'Target: $targetDurationStr',
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: FitoraColors.calmCyan,
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
                    const SizedBox(height: FitoraSpacing.md),

                    OutlinedButton.icon(
                      onPressed: _saveTargetSchedule,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text('Update Target Schedule'),
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
              // SECTION 2: LOG SLEEP DURATION (LOGGING METER)
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
                      'Use the slider or quick options to log your actual sleep duration for last night.',
                      style: tt.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: FitoraSpacing.md),

                    // Log Value Meter Display
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '${_hoursSlept.toStringAsFixed(1)} hrs',
                            style: tt.displayMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: FitoraColors.mintGreen,
                            ),
                          ),
                          Text(
                            'Actual Sleep Duration Logged',
                            style: tt.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: FitoraSpacing.md),

                    // Logging Slider Meter
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: FitoraColors.mintGreen,
                        inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
                        thumbColor: FitoraColors.mintGreen,
                        overlayColor: FitoraColors.mintGreen.withValues(alpha: 0.2),
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

                    // Quick Log Options Chips
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0].map((h) {
                        final isSelected = (_hoursSlept - h).abs() < 0.2;
                        return ChoiceChip(
                          label: Text('${h % 1 == 0 ? h.toInt() : h}h'),
                          selected: isSelected,
                          selectedColor: FitoraColors.mintGreen,
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
