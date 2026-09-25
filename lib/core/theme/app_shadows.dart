import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';

/// Paper elevation. See DESIGN.md §4.
///
/// Light comes from the top-left, so each layer casts a tight shadow down and
/// to the right onto the layer behind it, plus a 1 px self-coloured lip.
/// No symmetric blur, no glow.
abstract final class AppShadows {
  static Color _edge(Brightness b) => b == Brightness.dark
      ? AppSemanticColors.darkInk.withValues(alpha: 0.10)
      : AppSemanticColors.ink.withValues(alpha: 0.10);

  static Color _ink(Brightness b, double light, double dark) =>
      b == Brightness.dark
      ? Colors.black.withValues(alpha: dark)
      : AppSemanticColors.ink.withValues(alpha: light);

  /// e1: inputs, chips, list rows.
  static List<BoxShadow> e1(Brightness b) => [
    BoxShadow(color: _edge(b), offset: const Offset(0, 1)),
    BoxShadow(
      color: _ink(b, 0.08, 0.40),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// e2: cards, buttons.
  static List<BoxShadow> e2(Brightness b) => [
    BoxShadow(color: _edge(b), offset: const Offset(0, 1)),
    BoxShadow(
      color: _ink(b, 0.14, 0.50),
      offset: const Offset(1, 3),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];

  /// e3: sheets, popovers, lifted cards.
  static List<BoxShadow> e3(Brightness b) => [
    BoxShadow(color: _edge(b), offset: const Offset(0, 1)),
    BoxShadow(
      color: _ink(b, 0.18, 0.60),
      offset: const Offset(2, 6),
      blurRadius: 8,
      spreadRadius: -4,
    ),
  ];

  /// Flat on its layer.
  static const List<BoxShadow> none = <BoxShadow>[];

  // ── Aliases for existing call sites ────────────────────────────────────
  static final List<BoxShadow> elevation = e2(Brightness.light);
  static final List<BoxShadow> elevationDark = e2(Brightness.dark);
  static List<BoxShadow> elevationFor(Brightness b) => e2(b);
  static BoxShadow cardFor(Brightness b) => e2(b).last;
  static BoxShadow floatingFor(Brightness b) => e3(b).last;
  static BoxShadow subtleGlowFor(Brightness b) => e1(b).last;
  static final BoxShadow card = cardFor(Brightness.light);
  static final BoxShadow floating = floatingFor(Brightness.light);
  static final BoxShadow subtleGlow = subtleGlowFor(Brightness.light);
  static final BoxShadow cardDark = cardFor(Brightness.dark);
  static final BoxShadow floatingDark = floatingFor(Brightness.dark);
  static final BoxShadow subtleGlowDark = subtleGlowFor(Brightness.dark);
}
