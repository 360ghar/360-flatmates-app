import 'package:flutter/material.dart';

/// Canonical spacing tokens from DESIGN.md.
///
/// Use these instead of hard-coded numeric values everywhere.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double screen = 24;
  static const double section = 28;

  // Convenience EdgeInsets
  static const EdgeInsets edgeXs = EdgeInsets.all(xs);
  static const EdgeInsets edgeSm = EdgeInsets.all(sm);
  static const EdgeInsets edgeMd = EdgeInsets.all(md);
  static const EdgeInsets edgeLg = EdgeInsets.all(lg);
  static const EdgeInsets edgeXl = EdgeInsets.all(xl);
  static const EdgeInsets edgeScreen = EdgeInsets.all(screen);

  static const EdgeInsets horizontalScreen = EdgeInsets.symmetric(
    horizontal: screen,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: md,
  );
}
