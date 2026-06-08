import 'package:flutter/material.dart';
import 'package:fitora/app/theme/app_colors.dart';
import 'package:fitora/app/theme/app_typography.dart';
import 'package:fitora/core/theme/fitora_colors.dart' as core_colors;
import 'package:fitora/core/theme/fitora_spacing.dart';
import 'package:fitora/core/theme/fitora_radius.dart';
import 'package:fitora/core/theme/fitora_motion.dart';

class AppTheme {
  static ThemeData light = _buildTheme(
    colorScheme: FitoraColorSchemes.light,
    textTheme: AppTypography.light,
    brightness: Brightness.light,
  );

  static ThemeData dark = _buildTheme(
    colorScheme: FitoraColorSchemes.dark,
    textTheme: AppTypography.dark,
    brightness: Brightness.dark,
  );

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required Brightness brightness,
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
        const RoundedRectangleBorder(
          borderRadius: FitoraRadius.largeBorderRadius,
        ),
      ),
      elevation: WidgetStateProperty.all(0),
      animationDuration: FitoraMotion.quick,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: baseButtonStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withValues(alpha: 0.12);
            }
            return colorScheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withValues(alpha: 0.38);
            }
            return colorScheme.onPrimary;
          }),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: baseButtonStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(colorScheme.surface),
          foregroundColor: WidgetStateProperty.all(colorScheme.primary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: baseButtonStyle.copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.disabled)
                ? colorScheme.onSurface.withValues(alpha: 0.12)
                : colorScheme.outline;
            return BorderSide(color: color);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withValues(alpha: 0.38);
            }
            return colorScheme.primary;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: baseButtonStyle.copyWith(
          minimumSize: WidgetStateProperty.all(const Size.fromHeight(40)),
          foregroundColor: WidgetStateProperty.all(colorScheme.primary),
        ),
      ),
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: brightness == Brightness.dark
            ? core_colors.FitoraColors.darkSurface
            : core_colors.FitoraColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: FitoraRadius.largeBorderRadius,
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.8),
            width: 0.8,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 10,
        shape: const RoundedRectangleBorder(
          borderRadius: FitoraRadius.largeBorderRadius,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(FitoraRadius.large)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary,
        disabledColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary),
        shape: const RoundedRectangleBorder(
          borderRadius: FitoraRadius.pillBorderRadius,
        ),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 0.8,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
        elevation: 4,
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FitoraSpacing.md,
          vertical: FitoraSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: FitoraRadius.mediumBorderRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: FitoraRadius.mediumBorderRadius,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: FitoraRadius.mediumBorderRadius,
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: FitoraRadius.mediumBorderRadius,
          borderSide: BorderSide(
            color: core_colors.FitoraColors.errorRed,
          ),
        ),
      ),
    );
  }
}
