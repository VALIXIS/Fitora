import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/shared/widgets/scale_on_press.dart';

class FitoraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const FitoraCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: margin ?? EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: FitoraSpacing.cardRadius,
        child: Padding(
          padding: padding ?? FitoraSpacing.cardPadding,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return ScaleOnPress(
        onTap: onTap,
        scaleDownTo: 0.97,
        child: card,
      );
    }

    return card;
  }
}
