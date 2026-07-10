import 'package:flutter/material.dart';

/// Canonical spacing tokens from DESIGN.md (Airbnb 4px base scale).
///
/// Use these instead of hard-coded numeric values everywhere.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double section = 64;

  /// Page horizontal gutter (Airbnb mobile = 16).
  static const double screen = base;

  // Convenience EdgeInsets
  static const EdgeInsets edgeXxs = EdgeInsets.all(xxs);
  static const EdgeInsets edgeXs = EdgeInsets.all(xs);
  static const EdgeInsets edgeSm = EdgeInsets.all(sm);
  static const EdgeInsets edgeMd = EdgeInsets.all(md);
  static const EdgeInsets edgeBase = EdgeInsets.all(base);
  static const EdgeInsets edgeLg = EdgeInsets.all(lg);
  static const EdgeInsets edgeXl = EdgeInsets.all(xl);
  static const EdgeInsets edgeScreen = EdgeInsets.all(screen);

  static const EdgeInsets horizontalScreen = EdgeInsets.symmetric(
    horizontal: screen,
  );

  /// Property-card meta block padding (16).
  static const EdgeInsets cardPadding = EdgeInsets.all(base);

  /// Host / reservation card padding (24).
  static const EdgeInsets hostCardPadding = EdgeInsets.all(lg);

  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: base,
    vertical: md,
  );
}
