import 'package:flutter/material.dart';
import 'fitora_colors.dart';

class FitoraGradients {
  // Primary gradient: Mint Green to Soft Emerald
  static const LinearGradient primary = LinearGradient(
    colors: [FitoraColors.mintGreen, FitoraColors.softEmerald],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Wellness/Mindfulness gradient: Soft Pink to Lavender
  static const LinearGradient wellness = LinearGradient(
    colors: [FitoraColors.softPink, FitoraColors.lavender],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Calm Energy: Cyan to Mint
  static const LinearGradient calm = LinearGradient(
    colors: [FitoraColors.calmCyan, FitoraColors.mintGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Warm Recovery: Warm Coral to Soft Pink
  static const LinearGradient recovery = LinearGradient(
    colors: [FitoraColors.warmCoral, FitoraColors.softPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Elegant Background Radial Gradient for subtle ambient glows
  static RadialGradient ambientGlow(Color color) {
    return RadialGradient(
      colors: [
        color.withValues(alpha: 0.15),
        color.withValues(alpha: 0.0),
      ],
      radius: 0.8,
    );
  }
}
