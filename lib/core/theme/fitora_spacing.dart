import 'package:flutter/material.dart';

class FitoraSpacing {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // EdgeInsets helper presets
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: md, vertical: lg);
  
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  
  static const EdgeInsets dialogPadding = EdgeInsets.all(lg);

  // Layout spacers for quick size boxes
  static const SizedBox spaceXs = SizedBox(width: xs, height: xs);
  static const SizedBox spaceSm = SizedBox(width: sm, height: sm);
  static const SizedBox spaceMd = SizedBox(width: md, height: md);
  static const SizedBox spaceLg = SizedBox(width: lg, height: lg);
  static const SizedBox spaceXl = SizedBox(width: xl, height: xl);
  static const SizedBox spaceXxl = SizedBox(width: xxl, height: xxl);
}
