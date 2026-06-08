import 'package:flutter/material.dart';
import 'package:fitora/core/theme/fitora_typography.dart';

class AppTypography {
  static TextTheme light = FitoraTypography.buildTextTheme(Brightness.light);
  static TextTheme dark = FitoraTypography.buildTextTheme(Brightness.dark);
}
