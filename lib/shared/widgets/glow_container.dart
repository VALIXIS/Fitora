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
    final background = color ?? colorScheme.surfaceVariant;
    final glow = glowColor ?? colorScheme.primary.withOpacity(0.18);

    return Container(
      padding: padding ?? FitoraSpacing.cardPadding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: borderRadius ?? FitoraSpacing.cardRadius,
        boxShadow: [
          BoxShadow(
            color: glow,
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
