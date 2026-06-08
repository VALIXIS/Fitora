import 'package:flutter/material.dart';
import 'package:fitora/core/theme/fitora_spacing.dart' as new_spacing;
import 'package:fitora/core/theme/fitora_radius.dart' as new_radius;

class FitoraSpacing {
  static const double xs = new_spacing.FitoraSpacing.xs;
  static const double sm = new_spacing.FitoraSpacing.sm;
  static const double md = new_spacing.FitoraSpacing.md;
  static const double lg = new_spacing.FitoraSpacing.lg;
  static const double xl = new_spacing.FitoraSpacing.xl;
  static const double xxl = new_spacing.FitoraSpacing.xxl;

  static const EdgeInsets pagePadding = new_spacing.FitoraSpacing.pagePadding;
  static const EdgeInsets cardPadding = new_spacing.FitoraSpacing.cardPadding;

  static const BorderRadius cardRadius = new_radius.FitoraRadius.cardRadius;
}
