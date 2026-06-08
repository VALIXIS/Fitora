import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitora/core/constants/spacing.dart';

class PersonalizationWheelPicker extends StatefulWidget {
  final List<String> items;
  final int initialIndex;
  final ValueChanged<int> onSelectedItemChanged;
  final String label;
  final Color accentColor;

  const PersonalizationWheelPicker({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.onSelectedItemChanged,
    required this.label,
    required this.accentColor,
  });

  @override
  State<PersonalizationWheelPicker> createState() => _PersonalizationWheelPickerState();
}

class _PersonalizationWheelPickerState extends State<PersonalizationWheelPicker> {
  late final FixedExtentScrollController _controller;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _controller = FixedExtentScrollController(initialItem: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: widget.accentColor.withValues(alpha: 0.8),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: FitoraSpacing.md),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.accentColor.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.05),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Selection highlight
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.symmetric(
                    horizontal: BorderSide(color: widget.accentColor.withValues(alpha: 0.3)),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: 50,
                physics: const FixedExtentScrollPhysics(),
                perspective: 0.003,
                diameterRatio: 1.2,
                squeeze: 1.1,
                onSelectedItemChanged: (index) {
                  setState(() => _selectedIndex = index);
                  widget.onSelectedItemChanged(index);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.items.length,
                  builder: (context, index) {
                    final isSelected = index == _selectedIndex;
                    return Center(
                      child: Text(
                        widget.items[index],
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
                          fontSize: isSelected ? 32 : 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).scale(curve: Curves.easeOutBack),
      ],
    );
  }
}
