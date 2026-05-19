import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';

class AuthErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const AuthErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: FitoraSpacing.cardPadding,
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: FitoraSpacing.cardRadius,
        border: Border.all(color: colorScheme.error.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: FitoraSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close, color: colorScheme.onErrorContainer),
              tooltip: 'Dismiss',
            ),
        ],
      ),
    );
  }
}
