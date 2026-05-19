import 'package:flutter/material.dart';
import 'package:fitora/app/theme/app_colors.dart';
import 'package:fitora/app/theme/app_typography.dart';
import 'package:fitora/core/constants/spacing.dart';

class AppTheme {
  static ThemeData light = _buildTheme(
    colorScheme: FitoraColorSchemes.light,
    textTheme: AppTypography.light,
  );

  static ThemeData dark = _buildTheme(
    colorScheme: FitoraColorSchemes.dark,
    textTheme: AppTypography.dark,
  );

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final baseButtonStyle = ButtonStyle(
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(
          horizontal: FitoraSpacing.lg,
          vertical: FitoraSpacing.sm,
        ),
      ),
      minimumSize: MaterialStateProperty.all(const Size.fromHeight(48)),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: FitoraSpacing.cardRadius),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(style: baseButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: baseButtonStyle.copyWith(
          side: MaterialStateProperty.all(
            BorderSide(color: colorScheme.outline),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: baseButtonStyle),
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onBackground,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: FitoraSpacing.cardRadius,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: MaterialStateProperty.all(
          textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith(
          (states) {
            final color = states.contains(MaterialState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant;
            return IconThemeData(color: color);
          },
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: FitoraSpacing.cardRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: FitoraSpacing.cardRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: FitoraSpacing.cardRadius,
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
