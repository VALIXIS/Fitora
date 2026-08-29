import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';
import 'package:fitora/features/sleep/widgets/circular_sleep_dial.dart';
import 'package:fitora/core/health/domain/sleep_calculations.dart';

class SleepScheduleScreen extends ConsumerStatefulWidget {
  const SleepScheduleScreen({super.key});

  @override
  ConsumerState<SleepScheduleScreen> createState() => _SleepScheduleScreenState();
}

class _SleepScheduleScreenState extends ConsumerState<SleepScheduleScreen> {
  late int _tempBedHour;
  late int _tempBedMin;
  late int _tempWakeHour;
  late int _tempWakeMin;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _tempBedHour = settings.sleepTargetBedtimeHour;
    _tempBedMin = settings.sleepTargetBedtimeMinute;
    _tempWakeHour = settings.sleepTargetWakeHour;
    _tempWakeMin = settings.sleepTargetWakeMinute;
  }

  void _onDialChanged(int bedHour, int bedMin, int wakeHour, int wakeMin) {
    setState(() {
      _tempBedHour = bedHour;
      _tempBedMin = bedMin;
      _tempWakeHour = wakeHour;
      _tempWakeMin = wakeMin;
    });
  }

  Future<void> _onSave() async {
    final notifier = ref.read(settingsProvider.notifier);
    final targetDuration = SleepCalculations.calculateTargetDuration(
      _tempBedHour,
      _tempBedMin,
      _tempWakeHour,
      _tempWakeMin,
    ).inMinutes;

    await notifier.updateSetting('sleepTargetBedtimeHour', _tempBedHour);
    await notifier.updateSetting('sleepTargetBedtimeMinute', _tempBedMin);
    await notifier.updateSetting('sleepTargetWakeHour', _tempWakeHour);
    await notifier.updateSetting('sleepTargetWakeMinute', _tempWakeMin);
    await notifier.updateSetting('sleepTargetDurationMinutes', targetDuration);

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(), // Cancel action - Discards temporary changes
        ),
        title: Text(
          'Target Sleep Schedule',
          style: tt.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _onSave, // Save action - Persists changes
            child: Text(
              'Save',
              style: tt.titleMedium?.copyWith(
                color: FitoraColors.calmCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(FitoraSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Set your daily target schedule. We\'ll use this to track sleep consistency and offer bedtime guidance.',
                style: tt.bodyMedium?.copyWith(color: Colors.white38),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Circular timeline slider
              Center(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: CircularSleepDial(
                    initialBedHour: _tempBedHour,
                    initialBedMinute: _tempBedMin,
                    initialWakeHour: _tempWakeHour,
                    initialWakeMinute: _tempWakeMin,
                    onChanged: _onDialChanged,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
