import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final bool center;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(FitoraSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorScheme.onSecondaryContainer, size: 28),
        ),
        const SizedBox(height: FitoraSpacing.md),
        Text(
          title,
          style: textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: FitoraSpacing.sm),
        Text(
          message,
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[
          const SizedBox(height: FitoraSpacing.lg),
          action!,
        ],
      ],
    );

    if (center) {
      return Center(child: content);
    }

    return content;
  }
}
