import 'package:flutter/material.dart';
import 'package:fitora/core/theme/fitora_colors.dart' as core;

class FitoraColors {
  static const Color accentGreen = core.FitoraColors.mintGreen;
  static const Color accentPink = core.FitoraColors.softPink;
  static const Color accentRed = core.FitoraColors.warmCoral;
  static const Color accentMintGlow = core.FitoraColors.calmCyanGlow;
  static const Color accentRoseGlow = Color(0xFFFFB5D8);

  static const Color lightBackground = core.FitoraColors.lightBg;
  static const Color lightSurface = core.FitoraColors.lightSurface;
  static const Color lightSurfaceVariant = core.FitoraColors.lightSurfaceVariant;
  static const Color lightOutline = core.FitoraColors.lightBorder;
  static const Color lightTextPrimary = core.FitoraColors.lightTextPrimary;
  static const Color lightTextSecondary = core.FitoraColors.lightTextSecondary;
  static const Color lightOnPrimary = Colors.white;

  static const Color darkBackground = core.FitoraColors.darkBg;
  static const Color darkSurface = core.FitoraColors.darkSurface;
  static const Color darkSurfaceVariant = core.FitoraColors.darkSurfaceVariant;
  static const Color darkOutline = core.FitoraColors.darkBorder;
  static const Color darkTextPrimary = core.FitoraColors.darkTextPrimary;
  static const Color darkTextSecondary = core.FitoraColors.darkTextSecondary;
  static const Color darkOnPrimary = Color(0xFF0E1312);

  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowDark = Color(0x33000000);
}

class FitoraColorSchemes {
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: core.FitoraColors.mintGreen,
    onPrimary: Colors.white,
    primaryContainer: core.FitoraColors.calmCyanGlow,
    onPrimaryContainer: core.FitoraColors.lightTextPrimary,
    secondary: core.FitoraColors.softPink,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFFFB5D8),
    onSecondaryContainer: core.FitoraColors.lightTextPrimary,
    tertiary: core.FitoraColors.warmCoral,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFFDAD6),
    onTertiaryContainer: core.FitoraColors.lightTextPrimary,
    error: core.FitoraColors.errorRed,
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: core.FitoraColors.lightBg,
    onSurface: core.FitoraColors.lightTextPrimary,
    surfaceContainerHighest: core.FitoraColors.lightSurfaceVariant,
    onSurfaceVariant: core.FitoraColors.lightTextSecondary,
    outline: core.FitoraColors.lightBorder,
    outlineVariant: Color(0xFFD5DDD9),
    shadow: FitoraColors.shadowLight,
    scrim: Color(0x66000000),
    inverseSurface: core.FitoraColors.darkSurface,
    onInverseSurface: core.FitoraColors.darkTextPrimary,
    inversePrimary: core.FitoraColors.mintGreen,
    surfaceTint: Colors.transparent,
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: core.FitoraColors.mintGreen,
    onPrimary: FitoraColors.darkOnPrimary,
    primaryContainer: Color(0xFF143F2E),
    onPrimaryContainer: core.FitoraColors.calmCyanGlow,
    secondary: core.FitoraColors.softPink,
    onSecondary: FitoraColors.darkOnPrimary,
    secondaryContainer: Color(0xFF451931),
    onSecondaryContainer: Color(0xFFFFB5D8),
    tertiary: core.FitoraColors.warmCoral,
    onTertiary: FitoraColors.darkOnPrimary,
    tertiaryContainer: Color(0xFF6E232F),
    onTertiaryContainer: core.FitoraColors.darkTextPrimary,
    error: core.FitoraColors.errorRed,
    onError: FitoraColors.darkOnPrimary,
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: core.FitoraColors.darkTextPrimary,
    surface: core.FitoraColors.darkBg,
    onSurface: core.FitoraColors.darkTextPrimary,
    surfaceContainerHighest: core.FitoraColors.darkSurfaceVariant,
    onSurfaceVariant: core.FitoraColors.darkTextSecondary,
    outline: core.FitoraColors.darkBorder,
    outlineVariant: Color(0xFF232F2C),
    shadow: FitoraColors.shadowDark,
    scrim: Color(0x99000000),
    inverseSurface: core.FitoraColors.lightSurface,
    onInverseSurface: core.FitoraColors.lightTextPrimary,
    inversePrimary: core.FitoraColors.mintGreen,
    surfaceTint: Colors.transparent,
  );
}
