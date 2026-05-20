import 'package:flutter/material.dart';

class FitoraColors {
  static const Color accentGreen = Color(0xFF2FD08B);
  static const Color accentPink = Color(0xFFFF7DBA);
  static const Color accentRed = Color(0xFFFF6B6B);
  static const Color accentMintGlow = Color(0xFF7CFFD2);
  static const Color accentRoseGlow = Color(0xFFFFB5D8);

  static const Color lightBackground = Color(0xFFF9FBFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F4F3);
  static const Color lightOutline = Color(0xFFE2E8E6);
  static const Color lightTextPrimary = Color(0xFF0F1B16);
  static const Color lightTextSecondary = Color(0xFF4A5C56);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);

  static const Color darkBackground = Color(0xFF0A0F0E);
  static const Color darkSurface = Color(0xFF121917);
  static const Color darkSurfaceVariant = Color(0xFF19211F);
  static const Color darkOutline = Color(0xFF2B3431);
  static const Color darkTextPrimary = Color(0xFFE7F0ED);
  static const Color darkTextSecondary = Color(0xFFB8C6C1);
  static const Color darkOnPrimary = Color(0xFF081310);

  static const Color shadowLight = Color(0x12000000);
  static const Color shadowDark = Color(0x66000000);
}

class FitoraColorSchemes {
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: FitoraColors.accentGreen,
    onPrimary: FitoraColors.lightOnPrimary,
    primaryContainer: FitoraColors.accentMintGlow,
    onPrimaryContainer: FitoraColors.lightTextPrimary,
    secondary: FitoraColors.accentPink,
    onSecondary: FitoraColors.lightOnPrimary,
    secondaryContainer: FitoraColors.accentRoseGlow,
    onSecondaryContainer: FitoraColors.lightTextPrimary,
    tertiary: FitoraColors.accentRed,
    onTertiary: FitoraColors.lightOnPrimary,
    tertiaryContainer: Color(0xFFFFB9B9),
    onTertiaryContainer: FitoraColors.lightTextPrimary,
    error: FitoraColors.accentRed,
    onError: FitoraColors.lightOnPrimary,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: FitoraColors.lightBackground,
    onSurface: FitoraColors.lightTextPrimary,
    surfaceContainerHighest: FitoraColors.lightSurfaceVariant,
    onSurfaceVariant: FitoraColors.lightTextSecondary,
    outline: FitoraColors.lightOutline,
    outlineVariant: Color(0xFFD5DDD9),
    shadow: FitoraColors.shadowLight,
    scrim: Color(0x66000000),
    inverseSurface: FitoraColors.darkSurface,
    onInverseSurface: FitoraColors.darkTextPrimary,
    inversePrimary: FitoraColors.accentGreen,
    surfaceTint: Colors.transparent,
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: FitoraColors.accentGreen,
    onPrimary: FitoraColors.darkOnPrimary,
    primaryContainer: Color(0xFF1A4A38),
    onPrimaryContainer: FitoraColors.accentMintGlow,
    secondary: FitoraColors.accentPink,
    onSecondary: FitoraColors.darkOnPrimary,
    secondaryContainer: Color(0xFF4A1A30),
    onSecondaryContainer: FitoraColors.accentRoseGlow,
    tertiary: FitoraColors.accentRed,
    onTertiary: FitoraColors.darkOnPrimary,
    tertiaryContainer: Color(0xFF7F2F2F),
    onTertiaryContainer: FitoraColors.darkTextPrimary,
    error: FitoraColors.accentRed,
    onError: FitoraColors.darkOnPrimary,
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: FitoraColors.darkTextPrimary,
    surface: FitoraColors.darkBackground,
    onSurface: FitoraColors.darkTextPrimary,
    surfaceContainerHighest: FitoraColors.darkSurfaceVariant,
    onSurfaceVariant: FitoraColors.darkTextSecondary,
    outline: FitoraColors.darkOutline,
    outlineVariant: Color(0xFF3C4743),
    shadow: FitoraColors.shadowDark,
    scrim: Color(0x99000000),
    inverseSurface: FitoraColors.lightSurface,
    onInverseSurface: FitoraColors.lightTextPrimary,
    inversePrimary: FitoraColors.accentGreen,
    surfaceTint: Colors.transparent,
  );
}
