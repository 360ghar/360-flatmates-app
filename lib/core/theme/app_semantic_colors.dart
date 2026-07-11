import 'package:flutter/material.dart';

/// Semantic color tokens from DESIGN.md (Airbnb system).
///
/// Light mode is the design-system source of truth. Dark mode uses derived
/// neutrals while keeping Rausch as the single brand primary.
///
/// Prefer Airbnb names (`primary`, `canvas`, `body`, `muted`, `hairline`).
/// Legacy aliases (`accent`, `paper`, `ink2`, `line`, …) remain for gradual
/// migration of call sites.
abstract final class AppSemanticColors {
  // ── Brand & accent (Airbnb Rausch) ─────────────────────────────────────
  static const Color primary = Color(0xFFFF385C);
  static const Color primaryActive = Color(0xFFE00B41);
  static const Color primaryDisabled = Color(0xFFFFD1DA);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Sub-brand tokens (documented only — not used in mainline UI).
  static const Color luxe = Color(0xFF460479);
  static const Color plus = Color(0xFF92174D);

  // ── Surfaces ───────────────────────────────────────────────────────────
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF7F7F7);
  static const Color surfaceStrong = Color(0xFFF2F2F2);
  static const Color surfaceCard = canvas;

  // ── Text ───────────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF222222);
  static const Color body = Color(0xFF3F3F3F);
  static const Color muted = Color(0xFF6A6A6A);
  static const Color mutedSoft = Color(0xFF929292);
  static const Color starRating = ink;
  static const Color onDark = Color(0xFFFFFFFF);

  // ── Borders ────────────────────────────────────────────────────────────
  static const Color hairline = Color(0xFFDDDDDD);
  static const Color hairlineSoft = Color(0xFFEBEBEB);
  static const Color borderStrong = Color(0xFFC1C1C1);

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color error = Color(0xFFC13515);
  static const Color errorHover = Color(0xFFB32505);
  static const Color legalLink = Color(0xFF428BFF);
  static const Color success = Color(0xFF008A05);
  static const Color warning = Color(0xFFC13515);
  static const Color info = primary;

  // ── Scrim ──────────────────────────────────────────────────────────────
  static const Color scrim = Color(0xFF000000);
  static Color get scrim50 => scrim.withValues(alpha: 0.5);

  // ── Context ────────────────────────────────────────────────────────────
  static const Color whatsapp = Color(0xFF25D366);

  // ── Soft semantic backgrounds ──────────────────────────────────────────
  static const Color primarySoft = Color(0x1AFF385C);
  static const Color successSoft = Color(0x1A008A05);
  static const Color errorSoft = Color(0x1AC13515);
  static const Color warningSoft = Color(0x1AC13515);
  static const Color successBg = Color(0xFFE6F4E8);
  static const Color warningBg = Color(0xFFF7F7F7);
  static const Color errorBg = Color(0xFFFFD1DA);
  static const Color infoBg = Color(0xFFFFD1DA);

  // ── Legacy brand aliases (map to Airbnb tokens) ────────────────────────
  static const Color accent = primary;
  static const Color accentSoft = primarySoft;
  static const Color primaryContainer = primarySoft;
  static const Color primaryLight = primarySoft;

  // Paper scale → surface tokens
  static const Color paper = surfaceSoft;
  static const Color paper2 = surfaceSoft;
  static const Color paper3 = surfaceStrong;
  static const Color paper4 = hairlineSoft;
  static const Color card = canvas;

  // Ink scale → text tokens
  static const Color ink2 = body;
  static const Color ink3 = muted;
  static const Color ink4 = mutedSoft;

  // Line scale → hairline tokens
  static const Color line = hairline;
  static const Color line2 = hairlineSoft;
  static const Color lineLow = hairlineSoft;

  // Legacy palette constants
  static const Color darkHeading = ink;
  static const Color mutedText = body;
  static const Color lavenderBg = surfaceSoft;
  static const Color peerBubbleBg = surfaceStrong;
  static const Color successTextDark = success;
  static const Color coralSoft = primarySoft;
  static const Color coralMid = primary;
  static const Color coralInk = error;

  // Neutral scale (light mode)
  static const Color surface = canvas;
  static const Color surfaceDim = surfaceSoft;
  static const Color textPrimary = ink;
  static const Color textSecondary = body;
  static const Color textTertiary = muted;
  static const Color border = hairline;
  static const Color outlineVariant = hairlineSoft;

  // Categorical pastels (product-only; not Airbnb mainline)
  static const Color blueSoft = Color(0xFFE8F0FE);
  static const Color blueMid = Color(0xFF428BFF);
  static const Color blueInk = Color(0xFF1A4A8A);
  static const Color purpleSoft = Color(0xFFF0E8F8);
  static const Color purpleMid = Color(0xFF7B5EA7);
  static const Color purpleInk = Color(0xFF460479);
  static const Color greenSoft = Color(0xFFE6F4E8);
  static const Color greenMid = Color(0xFF008A05);
  static const Color greenInk = Color(0xFF0B5C10);
  static const Color yellowSoft = Color(0xFFFFF6E0);
  static const Color yellowMid = Color(0xFFC13515);
  static const Color yellowInk = Color(0xFF6B4E00);
  static const Color orangeSoft = Color(0xFFFFF0E8);
  static const Color orangeMid = Color(0xFFE07912);
  static const Color orangeInk = Color(0xFF8A4500);
  static const Color tealSoft = Color(0xFFE0F4F2);
  static const Color tealMid = Color(0xFF008489);
  static const Color tealInk = Color(0xFF004F52);
  static const Color pinkSoft = Color(0xFFFFE8EE);
  static const Color pinkMid = Color(0xFFFF385C);
  static const Color pinkInk = Color(0xFF92174D);

  // ── Dark mode (derived) ────────────────────────────────────────────────
  static const Color darkScaffold = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1C1C1C);
  static const Color darkSurfaceElevated = Color(0xFF2A2A2A);
  static const Color darkPaper2 = Color(0xFF1A1A1A);
  static const Color darkNavBar = darkSurfaceElevated;
  static const Color darkInk = Color(0xFFF7F7F7);
  static const Color darkBody = Color(0xFFB0B0B0);
  static const Color darkMuted = Color(0xFF8A8A8A);
  static const Color darkHairline = Color(0xFF3A3A3A);

  static const Color successSoftDark = Color(0xFF0D2A10);
  static const Color errorSoftDark = Color(0xFF3A1510);
  static const Color warningSoftDark = Color(0xFF3A2010);
  static const Color blueSoftDark = Color(0xFF152030);
  static const Color purpleSoftDark = Color(0xFF221530);
  static const Color greenSoftDark = Color(0xFF0D2A10);
  static const Color yellowSoftDark = Color(0xFF2A2210);
  static const Color orangeSoftDark = Color(0xFF2A1A10);
  static const Color tealSoftDark = Color(0xFF0D2222);
  static const Color pinkSoftDark = Color(0xFF2A1018);
  static const Color coralSoftDark = Color(0xFF2A1018);

  // Compatibility score colors
  static const Color compatHigh = success;
  static const Color compatMedium = Color(0xFFE07912);
  static const Color compatLow = error;

  // Map marker palette
  static const Color mapMarkerRoom = Color(0xFFFF385C);
  static const Color mapMarkerProperty = Color(0xFF428BFF);
  static const Color mapMarkerCluster = Color(0xFF222222);

  // Swipe card fallback gradient (neutral ink, not terracotta)
  static const Color swipeCardFallbackStart = Color(0xFF6A6A6A);
  static const Color swipeCardFallbackMid = Color(0xFF3F3F3F);
  static const Color swipeCardFallbackEnd = Color(0xFF222222);

  // Flat overlay tints for map/sheet surfaces (solid canvas, no blur).
  static const Color frostOverlayLight = Color(0xE6FFFFFF);
  static const Color frostOverlayDark = Color(0xE6121212);

  static Color textPrimaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkInk : ink;

  static Color textSecondaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkBody : body;

  static Color textTertiaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkMuted : muted;

  static Color surfaceFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurface : canvas;

  static Color paperFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkScaffold : canvas;

  static Color secondarySurfaceFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurfaceElevated : surfaceSoft;

  static Color disabledSurfaceFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurfaceElevated : surfaceStrong;

  static Color coralSoftFor(Brightness brightness) =>
      brightness == Brightness.dark ? coralSoftDark : primarySoft;

  // Soft pastel helpers — dark mode maps to *SoftDark tokens.
  // Used by notification wells, meta chips, swipe match chips, peer actions.
  static Color successSoftFor(Brightness brightness) =>
      brightness == Brightness.dark ? successSoftDark : successSoft;

  static Color warningSoftFor(Brightness brightness) =>
      brightness == Brightness.dark ? warningSoftDark : warningSoft;

  static Color errorSoftFor(Brightness brightness) =>
      brightness == Brightness.dark ? errorSoftDark : errorSoft;

  static Color blueSoftFor(Brightness brightness) =>
      brightness == Brightness.dark ? blueSoftDark : blueSoft;

  static Color purpleSoftFor(Brightness brightness) =>
      brightness == Brightness.dark ? purpleSoftDark : purpleSoft;

  static Color greenSoftFor(Brightness brightness) =>
      brightness == Brightness.dark ? greenSoftDark : greenSoft;

  static Color yellowSoftFor(Brightness brightness) =>
      brightness == Brightness.dark ? yellowSoftDark : yellowSoft;

  static Color orangeSoftFor(Brightness brightness) =>
      brightness == Brightness.dark ? orangeSoftDark : orangeSoft;

  static Color tealSoftFor(Brightness brightness) =>
      brightness == Brightness.dark ? tealSoftDark : tealSoft;

  static Color pinkSoftFor(Brightness brightness) =>
      brightness == Brightness.dark ? pinkSoftDark : pinkSoft;

  /// Ink on soft green chips (match chips, meta tags).
  static Color greenInkFor(Brightness brightness) =>
      brightness == Brightness.dark ? greenMid : greenInk;

  static Color hairlineFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkHairline : hairline;

  static Color scaffoldFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkScaffold : canvas;
}
