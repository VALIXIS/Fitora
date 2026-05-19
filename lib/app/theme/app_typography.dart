import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme light = _buildTextTheme(Brightness.light);
  static TextTheme dark = _buildTextTheme(Brightness.dark);

  static TextTheme _buildTextTheme(Brightness brightness) {
    final base = GoogleFonts.manropeTextTheme();

    return base.copyWith(
      headlineLarge: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      headlineSmall: GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}
