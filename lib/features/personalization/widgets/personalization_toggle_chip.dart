import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';

class PersonalizationToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const PersonalizationToggleChip({
    super.key,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final background = isSelected
        ? accentColor.withOpacity(0.16)
        : colorScheme.surfaceVariant;
    final borderColor = isSelected ? accentColor : colorScheme.outlineVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: accentColor.withOpacity(0.2),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FitoraSpacing.md,
              vertical: FitoraSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: accentColor),
                const SizedBox(width: FitoraSpacing.sm),
                Text(label, style: textTheme.labelLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
