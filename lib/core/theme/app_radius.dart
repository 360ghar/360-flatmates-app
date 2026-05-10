import 'package:flutter/material.dart';

/// Canonical border-radius tokens from DESIGN.md.
abstract final class AppRadius {
  static const double sm = 9;
  static const double md = 10;
  static const double card = 16;
  static const double sheet = 8;
  static const double pill = 999;

  // Convenience BorderRadius
  static const BorderRadius smBorder = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBorder = BorderRadius.all(Radius.circular(md));
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
