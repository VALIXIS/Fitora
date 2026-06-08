import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FitoraTypography {
  // Centralized Text Styles
  static TextStyle displayLarge = GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
  );

  static TextStyle headline = GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle sectionTitle = GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static TextStyle body = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static TextStyle caption = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static TextStyle metricLarge = GoogleFonts.manrope(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
  );

  static TextStyle buttonText = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );

  // Return standard TextTheme for dark / light modes
  static TextTheme buildTextTheme(Brightness brightness) {
    return TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayLarge.copyWith(fontSize: 28),
      headlineMedium: headline,
      headlineSmall: headline.copyWith(fontSize: 20),
      titleLarge: sectionTitle,
      titleMedium: sectionTitle.copyWith(fontSize: 16),
      bodyLarge: body.copyWith(fontSize: 16),
      bodyMedium: body,
      bodySmall: body.copyWith(fontSize: 12),
      labelLarge: buttonText,
      labelMedium: buttonText.copyWith(fontSize: 13),
      labelSmall: caption,
    );
  }
}
