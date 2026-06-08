import 'package:flutter/animation.dart';

class FitoraMotion {
  // Reusable durations
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration smooth = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 600);

  // Curves
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;

  // Custom calming/wellness breathing wave curve
  // A beautiful, slow-rising wave that eases in and holds momentarily at the top
  static const Curve breathingCurve = Cubic(0.42, 0.0, 0.58, 1.0);
}
