import 'package:flutter/material.dart';

class FitoraSpacing {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: md, vertical: lg);
    static const EdgeInsets cardPadding = EdgeInsets.all(md);

  static const BorderRadius cardRadius =
      BorderRadius.all(Radius.circular(20));
}
