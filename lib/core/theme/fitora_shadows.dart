import 'package:flutter/material.dart';
import 'fitora_colors.dart';

class FitoraShadows {
  // Reusable subtle card shadow
  static List<BoxShadow> subtleCardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : const Color(0xFF0F1B16).withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // Soft glow based on a custom color
  static List<BoxShadow> softGlow(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.16),
        blurRadius: 20,
        spreadRadius: -2,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // Emerald Glow (Mint/Emerald theme)
  static final List<BoxShadow> emeraldGlow = softGlow(FitoraColors.mintGreen);

  // Pink Glow (Wellness/Pink theme)
  static final List<BoxShadow> pinkGlow = softGlow(FitoraColors.softPink);

  // Deep Premium Shadow for elevated headers/modals
  static List<BoxShadow> deepElevation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : const Color(0xFF0F1B16).withValues(alpha: 0.08),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];
  }
}
