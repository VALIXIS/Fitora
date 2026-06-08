import 'package:flutter/material.dart';

class FitoraRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 20;
  static const double pill = 99;
  static const double full = 999;

  // BorderRadius helper presets
  static const BorderRadius smallBorderRadius = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumBorderRadius = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius largeBorderRadius = BorderRadius.all(Radius.circular(large));
  static const BorderRadius pillBorderRadius = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius fullBorderRadius = BorderRadius.all(Radius.circular(full));

  // Legacy compatibility: cardRadius matches largeBorderRadius
  static const BorderRadius cardRadius = largeBorderRadius;
}
