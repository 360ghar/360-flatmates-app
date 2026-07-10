import 'package:flutter/material.dart';

/// Canonical shadow tokens from DESIGN.md (Airbnb single elevation tier).
///
/// The system has one float recipe or none. Depth comes from photography,
/// white-on-white separation, and rounded clipping — not layered shadows.
abstract final class AppShadows {
  // Airbnb float: hairline ring + soft mid + deeper low
  static const BoxShadow _ring = BoxShadow(
    color: Color(0x05000000), // rgba(0,0,0,0.02)
    spreadRadius: 1,
  );

  static const BoxShadow _mid = BoxShadow(
    color: Color(0x0A000000), // rgba(0,0,0,0.04)
    blurRadius: 6,
    offset: Offset(0, 2),
  );

  static const BoxShadow _low = BoxShadow(
    color: Color(0x1A000000), // rgba(0,0,0,0.10)
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow _ringDark = BoxShadow(
    color: Color(0x0AFFFFFF),
    spreadRadius: 1,
  );

  static const BoxShadow _midDark = BoxShadow(
    color: Color(0x33000000),
    blurRadius: 6,
    offset: Offset(0, 2),
  );

  static const BoxShadow _lowDark = BoxShadow(
    color: Color(0x40000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  /// The single elevation tier used for search bar, floated cards, menus.
  static const List<BoxShadow> elevation = [_ring, _mid, _low];

  static const List<BoxShadow> elevationDark = [_ringDark, _midDark, _lowDark];

  /// Flat baseline — 95% of surfaces.
  static const List<BoxShadow> none = <BoxShadow>[];

  // Per-brightness helpers for the few surfaces that read a single BoxShadow.
  static const BoxShadow card = _mid;
  static const BoxShadow floating = _low;
  static const BoxShadow subtleGlow = _mid;

  static const BoxShadow cardDark = _midDark;
  static const BoxShadow floatingDark = _lowDark;
  static const BoxShadow subtleGlowDark = _midDark;

  static BoxShadow cardFor(Brightness brightness) =>
      brightness == Brightness.dark ? cardDark : card;

  static BoxShadow floatingFor(Brightness brightness) =>
      brightness == Brightness.dark ? floatingDark : floating;

  static BoxShadow subtleGlowFor(Brightness brightness) =>
      brightness == Brightness.dark ? subtleGlowDark : subtleGlow;

  static List<BoxShadow> elevationFor(Brightness brightness) =>
      brightness == Brightness.dark ? elevationDark : elevation;
}
