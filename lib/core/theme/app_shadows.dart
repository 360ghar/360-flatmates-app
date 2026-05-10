import 'package:flutter/material.dart';

/// Canonical shadow tokens from DESIGN.md.
///
/// All shadows are defined for light mode. Dark mode should reduce shadow
/// intensity via [AppShadows.dark] overrides.
abstract final class AppShadows {
  // Light mode
  static const BoxShadow card = BoxShadow(
    color: Color(0x0F1F1A14),
    blurRadius: 6,
    offset: Offset(0, 2),
  );

  static const BoxShadow button = BoxShadow(
    color: Color(0x2EC96442),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow floating = BoxShadow(
    color: Color(0x1A1F1A14),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  static const BoxShadow modal = BoxShadow(
    color: Color(0x1F1F1A14),
    blurRadius: 60,
    offset: Offset(0, 18),
  );

  static const BoxShadow shadowXs = BoxShadow(
    color: Color(0x0A1F1A14),
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  static const BoxShadow shadowMd = BoxShadow(
    color: Color(0x141F1A14),
    blurRadius: 18,
    offset: Offset(0, 6),
  );

  static const BoxShadow shadowLg = BoxShadow(
    color: Color(0x1F1F1A14),
    blurRadius: 60,
    offset: Offset(0, 18),
  );

  /// Primary-tinted ambient glow for cards on hover/focus.
  static const BoxShadow subtleGlow = BoxShadow(
    color: Color(0x14C96442),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  /// Elevated card shadow for interactive/pressed states.
  static const BoxShadow cardHover = BoxShadow(
    color: Color(0x1A1F1A14),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  /// Top-edge shadow for bottom navigation bar.
  static const BoxShadow bottomBar = BoxShadow(
    color: Color(0x0A1F1A14),
    blurRadius: 2,
    offset: Offset(0, -1),
  );

  /// Primary-tinted glow for focused input fields.
  static BoxShadow inputFocusGlow(Color accent) => BoxShadow(
    color: accent.withValues(alpha: 0.12),
    blurRadius: 12,
    offset: Offset(0, 2),
  );

  // Dark mode — reduced intensity
  static const BoxShadow cardDark = BoxShadow(
    color: Color(0x061F1A14),
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  static const BoxShadow floatingDark = BoxShadow(
    color: Color(0x0A1F1A14),
    blurRadius: 6,
    offset: Offset(0, 2),
  );

  /// Dark mode — reduced subtle glow.
  static const BoxShadow subtleGlowDark = BoxShadow(
    color: Color(0x0AC96442),
    blurRadius: 6,
    offset: Offset(0, 2),
  );

  /// Dark mode — reduced card hover.
  static const BoxShadow cardHoverDark = BoxShadow(
    color: Color(0x0A1F1A14),
    blurRadius: 6,
    offset: Offset(0, 2),
  );

  /// Dark mode — reduced bottom bar shadow.
  static const BoxShadow bottomBarDark = BoxShadow(
    color: Color(0x041F1A14),
    blurRadius: 2,
    offset: Offset(0, -1),
  );

  /// Returns the appropriate card shadow for the given brightness.
  static BoxShadow cardFor(Brightness brightness) =>
      brightness == Brightness.dark ? cardDark : card;

  /// Returns the appropriate floating shadow for the given brightness.
  static BoxShadow floatingFor(Brightness brightness) =>
      brightness == Brightness.dark ? floatingDark : floating;

  /// Returns the appropriate subtle glow for the given brightness.
  static BoxShadow subtleGlowFor(Brightness brightness) =>
      brightness == Brightness.dark ? subtleGlowDark : subtleGlow;

  /// Returns the appropriate card hover shadow for the given brightness.
  static BoxShadow cardHoverFor(Brightness brightness) =>
      brightness == Brightness.dark ? cardHoverDark : cardHover;

  /// Returns the appropriate bottom bar shadow for the given brightness.
  static BoxShadow bottomBarFor(Brightness brightness) =>
      brightness == Brightness.dark ? bottomBarDark : bottomBar;

  /// Converts a [BoxShadow] to a list (convenient for `decoration.boxShadow`).
  static List<BoxShadow> asList(BoxShadow shadow) => [shadow];

  /// Merges multiple shadows into a list.
  static List<BoxShadow> merge(List<BoxShadow> shadows) => shadows;
}
