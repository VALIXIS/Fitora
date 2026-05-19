import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';

class PersonalizationOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const PersonalizationOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
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
        ? colorScheme.primary.withOpacity(0.12)
        : colorScheme.surface;
    final borderColor = isSelected ? accentColor : colorScheme.outlineVariant;
    final glow = isSelected ? accentColor.withOpacity(0.22) : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: background,
        borderRadius: FitoraSpacing.cardRadius,
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: glow,
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: FitoraSpacing.cardRadius,
          child: Padding(
            padding: FitoraSpacing.cardPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(FitoraSpacing.sm),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: FitoraSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleMedium),
                      const SizedBox(height: FitoraSpacing.xs),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
