import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

class AuthSectionCard extends StatelessWidget {
  final Widget child;

  const AuthSectionCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlowContainer(
      glowColor: colorScheme.primary.withOpacity(0.12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: FitoraSpacing.cardPadding,
          child: child,
        ),
      ),
    );
  }
}
