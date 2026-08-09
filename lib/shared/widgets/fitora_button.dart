import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/shared/widgets/scale_on_press.dart';

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

    Widget button;
    switch (variant) {
      case FitoraButtonVariant.primary:
        button = FilledButton(onPressed: onPressed, child: child);
        break;
      case FitoraButtonVariant.secondary:
        button = OutlinedButton(onPressed: onPressed, child: child);
        break;
      case FitoraButtonVariant.ghost:
        button = TextButton(onPressed: onPressed, child: child);
        break;
    }

    final wrappedButton = onPressed != null
        ? ScaleOnPress(scaleDownTo: 0.96, child: button)
        : button;

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: wrappedButton);
    }

    return wrappedButton;
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
