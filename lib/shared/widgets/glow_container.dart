import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';

class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? glowColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;

  const GlowContainer({
    super.key,
    required this.child,
    this.color,
    this.glowColor,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = color ?? colorScheme.surfaceContainerHighest;
    final glow = glowColor ?? colorScheme.primary.withValues(alpha: 0.18);

    return Container(
      padding: padding ?? FitoraSpacing.cardPadding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: borderRadius ?? FitoraSpacing.cardRadius,
        boxShadow: [
          BoxShadow(
            color: glow,
            blurRadius: 20.0,
            spreadRadius: 1.5,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
