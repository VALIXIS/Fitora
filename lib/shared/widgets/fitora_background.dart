import 'dart:ui';
import 'package:flutter/material.dart';

class FitoraBackground extends StatelessWidget {
  final Widget child;

  const FitoraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // 1. Base solid adaptive background
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
            ),
          ),
        ),
        
        // 2. Cyan radial glow (top-left)
        Positioned(
          top: -200,
          left: -200,
          width: 500,
          height: 500,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.1 : 0.04),
                  const Color(0xFF06B6D4).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        
        // 3. Blue radial glow (center)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.25,
          left: MediaQuery.of(context).size.width * 0.1,
          width: 600,
          height: 600,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.08 : 0.03),
                  const Color(0xFF3B82F6).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        
        // 4. Purple radial glow (bottom-right)
        Positioned(
          bottom: -200,
          right: -200,
          width: 500,
          height: 500,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.1 : 0.04),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        
        // 5. Blur filter for smooth gradients and no banding
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: const SizedBox.shrink(),
          ),
        ),
        
        // 6. Main content child
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
