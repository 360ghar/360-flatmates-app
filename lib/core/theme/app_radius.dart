import 'package:flutter/material.dart';

/// Cut-paper radius tokens. See DESIGN.md §3.
abstract final class AppRadius {
  static const double cutSm = 6;
  static const double cutMd = 12;
  static const double cutLg = 18;
  static const double cutXl = 28;
  static const double full = 9999;

  // ── Aliases for existing call sites ────────────────────────────────────
  static const double xs = 4;
  static const double sm = cutSm;
  static const double md = cutMd;
  static const double lg = cutLg;
  static const double xl = cutXl;
  static const double card = cutMd;
  static const double sheet = cutXl;
  static const double pill = full;

  static const BorderRadius xsBorder = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smBorder = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBorder = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgBorder = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlBorder = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius sheetBorder = BorderRadius.all(
    Radius.circular(sheet),
  );
  static const BorderRadius pillBorder = BorderRadius.all(
    Radius.circular(pill),
  );

  /// Hand-cut uneven card corners: 12 / 14 / 11 / 13 (TL, TR, BR, BL).
  static const BorderRadius cardBorder = BorderRadius.only(
    topLeft: Radius.circular(12),
    topRight: Radius.circular(14),
    bottomRight: Radius.circular(11),
    bottomLeft: Radius.circular(13),
  );

  static const BorderRadius sheetTopBorder = BorderRadius.only(
    topLeft: Radius.circular(sheet),
    topRight: Radius.circular(sheet),
  );
}
