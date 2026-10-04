import 'package:flutter/material.dart';

/// Spacing tokens. DESIGN.md §3 scale: 4 8 12 16 20 24 32 40 56 72.
///
/// Use these instead of hard-coded numeric values everywhere. `s20`, `s40`,
/// `s56` and `s72` are the scale steps that have no t-shirt name.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double s20 = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double s40 = 40;
  static const double s56 = 56;
  static const double s72 = 72;
  static const double xxl = 48;
  static const double section = 64;

  /// Page horizontal gutter on phones (DESIGN.md §3).
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

  /// [base] scaled by the user's text size, for fixed-height boxes that hold
  /// text, such as horizontal lists. Keeps text from clipping at large text
  /// sizes.
  ///
  /// The factor is clamped to 1x..2x: above 2x text would clip, and below 1x a
  /// scaled box would shrink past the 48 dp minimum tap target it wraps (e.g.
  /// the 52 dp parent around the filter chips). Scale 1.0 is unchanged.
  static double scaled(BuildContext context, double base) =>
      MediaQuery.textScalerOf(
        context,
      ).clamp(minScaleFactor: 1, maxScaleFactor: 2).scale(base);
}
