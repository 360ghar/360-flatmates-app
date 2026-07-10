import 'package:flutter/material.dart';

/// Canonical border-radius tokens from DESIGN.md (Airbnb soft geometry).
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 32;
  static const double full = 9999;

  /// Alias for property cards / host cards.
  static const double card = md;

  /// Alias for bottom sheets (soft top corners).
  static const double sheet = xl;

  /// Pill / full round.
  static const double pill = full;

  // Convenience BorderRadius
  static const BorderRadius xsBorder = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smBorder = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBorder = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgBorder = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlBorder = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius cardBorder = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius sheetBorder = BorderRadius.all(
    Radius.circular(sheet),
  );
  static const BorderRadius pillBorder = BorderRadius.all(
    Radius.circular(pill),
  );

  // Bottom sheet top corners only
  static const BorderRadius sheetTopBorder = BorderRadius.only(
    topLeft: Radius.circular(sheet),
    topRight: Radius.circular(sheet),
  );
}
