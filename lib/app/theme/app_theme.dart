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
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(
          horizontal: FitoraSpacing.lg,
          vertical: FitoraSpacing.sm,
        ),
      ),
      minimumSize: WidgetStateProperty.all(const Size.fromHeight(48)),
      shape: WidgetStateProperty.all(
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
      elevatedButtonTheme: ElevatedButtonThemeData(style: baseButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: baseButtonStyle.copyWith(
          side: WidgetStateProperty.all(
            BorderSide(color: colorScheme.outline),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: baseButtonStyle),
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: FitoraSpacing.cardRadius,
          side: BorderSide(color: colorScheme.outlineVariant, width: 0.8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) {
            final color = states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant;
            return IconThemeData(color: color);
          },
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
        thickness: 0.8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
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
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
