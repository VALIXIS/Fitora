import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';

enum FitoraButtonVariant { primary, secondary, ghost }

class FitoraButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final FitoraButtonVariant variant;
  final Widget? leading;
  final bool isFullWidth;

  const FitoraButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = FitoraButtonVariant.primary,
    this.leading,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = _buildChild(context);

    final button = switch (variant) {
      FitoraButtonVariant.primary =>
        FilledButton(onPressed: onPressed, child: child),
      FitoraButtonVariant.secondary =>
        OutlinedButton(onPressed: onPressed, child: child),
      FitoraButtonVariant.ghost =>
        TextButton(onPressed: onPressed, child: child),
    };

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Widget _buildChild(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textTheme.labelLarge,
    );

    if (leading == null) {
      return labelWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconTheme.merge(
          data: const IconThemeData(size: 18),
          child: leading!,
        ),
        const SizedBox(width: FitoraSpacing.sm),
        Flexible(child: labelWidget),
      ],
    );
  }
}
