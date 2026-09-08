import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/services/haptic_service.dart';

class PersonalizationSlider extends ConsumerStatefulWidget {
  final double? value;
  final ValueChanged<double> onChanged;
  final String label;
  final String leftLabel;
  final String rightLabel;
  final Color accentColor;

  const PersonalizationSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    required this.leftLabel,
    required this.rightLabel,
    required this.accentColor,
  });

  @override
  ConsumerState<PersonalizationSlider> createState() => _PersonalizationSliderState();
}

class _PersonalizationSliderState extends ConsumerState<PersonalizationSlider> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value ?? 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: widget.accentColor.withValues(alpha: 0.8),
              ),
            ),
            Text(
              '${(_currentValue * 100).toInt()}%',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(height: FitoraSpacing.sm),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 8,
            activeTrackColor: widget.accentColor,
            inactiveTrackColor: widget.accentColor.withValues(alpha: 0.1),
            thumbColor: Colors.white,
            overlayColor: widget.accentColor.withValues(alpha: 0.2),
            valueIndicatorColor: widget.accentColor,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 4),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: _currentValue,
            min: 0.0,
            max: 1.0,
            onChanged: (val) {
              final oldStep = (_currentValue * 20).round();
              final newStep = (val * 20).round();
              if (oldStep != newStep) {
                ref.read(hapticServiceProvider).sliderChange();
              }
              setState(() => _currentValue = val);
              widget.onChanged(val);
            },
          ),
        ).animate().fadeIn(duration: 600.ms).scaleX(begin: 0.8, end: 1.0, curve: Curves.easeOutCubic),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.leftLabel, style: textTheme.labelSmall?.copyWith(color: Colors.white54)),
            Text(widget.rightLabel, style: textTheme.labelSmall?.copyWith(color: Colors.white54)),
          ],
        ).animate().fadeIn(duration: 800.ms),
      ],
    );
  }
}
