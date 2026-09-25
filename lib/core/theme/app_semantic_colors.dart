import 'package:flutter/material.dart';

/// Colour tokens for the Paper Diorama design system. See DESIGN.md §1.
///
/// Paper-diorama names (`sky`, `paper1`–`paper3`, `ink`, `clay`, `pine`,
/// `marigold`, `danger`) are the source of truth. Older names (`primary`,
/// `canvas`, `body`, `muted`, `hairline`, …) remain as aliases so existing
/// call sites pick up the new palette without edits.
///
/// Every text/background pair passes WCAG AA; see
/// `test/core/theme/contrast_test.dart`.
abstract final class AppSemanticColors {
  // ── Paper layers and ink (light) ───────────────────────────────────────
  static const Color sky = Color(0xFFE4EBE3);
  static const Color paper1 = Color(0xFFEDF1EA);
  static const Color paper2 = Color(0xFFFDFCFA);
  static const Color paper3 = Color(0xFFFFFFFF);

  /// One step deeper than [paper1]: pressed rows, disabled fills, tracks.
  static const Color paperDeep = Color(0xFFDFE6DC);
  static const Color ink = Color(0xFF23201C);
  static const Color body = Color(0xFF4A443D);
  static const Color muted = Color(0xFF6B6359);

  /// Decorative or disabled text only; not AA for body copy.
  static const Color mutedSoft = Color(0xFF948C81);

  // ── Brand (light) ──────────────────────────────────────────────────────
  static const Color clay = Color(0xFFA94A2B);
  static const Color clayPress = Color(0xFF8C3B20);
  static const Color claySoft = Color(0xFFF2DACF);
  static const Color onClay = Color(0xFFFFFFFF);
  static const Color pine = Color(0xFF2E5B48);
  static const Color pineSoft = Color(0xFFD3E2D8);
  static const Color onPine = Color(0xFFFFFFFF);
  static const Color marigold = Color(0xFFE0A034);
  static const Color danger = Color(0xFFB3261E);
  static const Color dangerSoft = Color(0xFFF6DAD7);
  static const Color warningInk = Color(0xFF7E5208);
  static const Color warningSoftBg = Color(0xFFF7E8C8);

  // ── Borders ────────────────────────────────────────────────────────────
  static const Color hairline = Color(0xFFD5DBD1);
  static const Color hairlineSoft = Color(0xFFE3E8E0);
  static const Color borderStrong = Color(0xFFB9C1B5);

  // ── Dark (night diorama on pine-black) ─────────────────────────────────
  static const Color darkSky = Color(0xFF121814);
  static const Color darkPaper1 = Color(0xFF19211C);
  static const Color darkPaper2Surface = Color(0xFF222A24);
  static const Color darkPaper3 = Color(0xFF2A332C);
  static const Color darkPaperDeep = Color(0xFF2F3931);
  static const Color darkInk = Color(0xFFF1EDE6);
  static const Color darkBody = Color(0xFFCBC4B9);
  static const Color darkMuted = Color(0xFFA39C91);
  static const Color darkHairline = Color(0xFF3A4539);
  static const Color darkClay = Color(0xFFE27E5A);
  static const Color darkClayPress = Color(0xFFC9694A);
  static const Color darkClaySoft = Color(0xFF3A2A23);
  static const Color darkOnClay = Color(0xFF1A120E);
  static const Color darkPine = Color(0xFF86B9A0);
  static const Color darkPineSoft = Color(0xFF22352C);
  static const Color darkMarigold = Color(0xFFE8B458);
  static const Color darkDanger = Color(0xFFF2A097);
  static const Color darkDangerSoft = Color(0xFF3B2220);
  static const Color darkWarningInk = Color(0xFFE8B458);
  static const Color darkWarningSoftBg = Color(0xFF352B19);

  // ── Aliases: brand ─────────────────────────────────────────────────────
  static const Color primary = clay;
  static const Color primaryActive = clayPress;
  static const Color primaryDisabled = claySoft;
  static const Color onPrimary = onClay;
  static const Color accent = clay;
  static const Color accentSoft = claySoft;
  static const Color primarySoft = claySoft;
  static const Color primaryContainer = claySoft;
  static const Color primaryLight = claySoft;
  static const Color coralSoft = claySoft;
  static const Color coralMid = clay;
  static const Color coralInk = danger;

  // ── Aliases: surfaces ──────────────────────────────────────────────────
  static const Color canvas = paper2;
  static const Color surfaceSoft = paper1;
  static const Color surfaceStrong = paperDeep;
  static const Color surfaceCard = paper2;
  static const Color card = paper2;
  static const Color paper = paper1;
  static const Color paper4 = hairlineSoft;
  static const Color surface = paper2;
  static const Color surfaceDim = paper1;
  static const Color lavenderBg = paper1;
  static const Color peerBubbleBg = paperDeep;
  static const Color darkScaffold = darkSky;
  static const Color darkSurface = darkPaper2Surface;
  static const Color darkSurfaceElevated = darkPaper3;
  static const Color darkPaper2 = darkPaper1;
  static const Color darkNavBar = darkPaper1;

  // ── Aliases: text and lines ────────────────────────────────────────────
  static const Color starRating = marigold;
  static const Color onDark = darkInk;
  static const Color ink2 = body;
  static const Color ink3 = muted;
  static const Color ink4 = mutedSoft;
  static const Color darkHeading = ink;
  static const Color mutedText = body;
  static const Color textPrimary = ink;
  static const Color textSecondary = body;
  static const Color textTertiary = muted;
  static const Color line = hairline;
  static const Color line2 = hairlineSoft;
  static const Color lineLow = hairlineSoft;
  static const Color border = hairline;
  static const Color outlineVariant = hairlineSoft;

  // ── Aliases: status ────────────────────────────────────────────────────
  static const Color error = danger;
  static const Color errorHover = Color(0xFF93201A);
  static const Color success = pine;
  static const Color successTextDark = pine;
  static const Color warning = warningInk;
  static const Color info = pine;
  static const Color successSoft = pineSoft;
  static const Color errorSoft = dangerSoft;
  static const Color warningSoft = warningSoftBg;
  static const Color successBg = pineSoft;
  static const Color warningBg = warningSoftBg;
  static const Color errorBg = dangerSoft;
  static const Color infoBg = pineSoft;
  static const Color successSoftDark = darkPineSoft;
  static const Color errorSoftDark = darkDangerSoft;
  static const Color warningSoftDark = darkWarningSoftBg;
  static const Color coralSoftDark = darkClaySoft;

  // ── Scrim ──────────────────────────────────────────────────────────────
  static const Color scrim = Color(0xFF0D100E);
  static Color get scrim50 => scrim.withValues(alpha: 0.5);

  // ── Categorical (earth tones that sit with clay, pine and marigold) ────
  static const Color blueSoft = Color(0xFFDCE6EA);
  static const Color blueMid = Color(0xFF4F7A8C);
  static const Color blueInk = Color(0xFF2A4B59);
  static const Color purpleSoft = Color(0xFFEADDE3);
  static const Color purpleMid = Color(0xFF7D4E63);
  static const Color purpleInk = Color(0xFF512D3D);
  static const Color greenSoft = pineSoft;
  static const Color greenMid = pine;
  static const Color greenInk = Color(0xFF1F4636);
  static const Color yellowSoft = warningSoftBg;
  static const Color yellowMid = Color(0xFFB07A16);
  static const Color yellowInk = Color(0xFF6B4A0B);
  static const Color orangeSoft = Color(0xFFF5DDCC);
  static const Color orangeMid = Color(0xFFC0612E);
  static const Color orangeInk = Color(0xFF7A3A18);
  static const Color tealSoft = Color(0xFFD6E6E1);
  static const Color tealMid = Color(0xFF3C7D6E);
  static const Color tealInk = Color(0xFF24544A);
  static const Color pinkSoft = Color(0xFFF4DCD8);
  static const Color pinkMid = Color(0xFFB8545A);
  static const Color pinkInk = Color(0xFF7A2F35);
  static const Color blueSoftDark = Color(0xFF1C2A30);
  static const Color purpleSoftDark = Color(0xFF2C1F26);
  static const Color greenSoftDark = darkPineSoft;
  static const Color yellowSoftDark = darkWarningSoftBg;
  static const Color orangeSoftDark = Color(0xFF36241A);
  static const Color tealSoftDark = Color(0xFF1D302B);
  static const Color pinkSoftDark = Color(0xFF35201F);

  // ── Feature colours ────────────────────────────────────────────────────
  static const Color compatHigh = pine;
  static const Color compatMedium = yellowMid;
  static const Color compatLow = danger;
  static const Color mapMarkerRoom = clay;
  static const Color mapMarkerProperty = pine;
  static const Color mapMarkerCluster = ink;

  /// Placeholder behind a card with no photo: near hill to deep pine.
  static const Color swipeCardFallbackStart = Color(0xFF93B39F);
  static const Color swipeCardFallbackMid = pine;
  static const Color swipeCardFallbackEnd = greenInk;

  /// Solid paper overlays for map chrome (no blur).
  static const Color frostOverlayLight = Color(0xF0FDFCFA);
  static const Color frostOverlayDark = Color(0xF0121814);

  // ── Brightness helpers ─────────────────────────────────────────────────
  static bool _dark(Brightness b) => b == Brightness.dark;

  static Color skyFor(Brightness b) => _dark(b) ? darkSky : sky;
  static Color paper1For(Brightness b) => _dark(b) ? darkPaper1 : paper1;
  static Color paper2For(Brightness b) => _dark(b) ? darkPaper2Surface : paper2;
  static Color paper3For(Brightness b) => _dark(b) ? darkPaper3 : paper3;
  static Color paperDeepFor(Brightness b) =>
      _dark(b) ? darkPaperDeep : paperDeep;
  static Color clayFor(Brightness b) => _dark(b) ? darkClay : clay;
  static Color clayPressFor(Brightness b) =>
      _dark(b) ? darkClayPress : clayPress;
  static Color onClayFor(Brightness b) => _dark(b) ? darkOnClay : onClay;
  static Color pineFor(Brightness b) => _dark(b) ? darkPine : pine;
  static Color pineSoftFor(Brightness b) => _dark(b) ? darkPineSoft : pineSoft;
  static Color marigoldFor(Brightness b) => _dark(b) ? darkMarigold : marigold;
  static Color dangerFor(Brightness b) => _dark(b) ? darkDanger : danger;
  static Color warningInkFor(Brightness b) =>
      _dark(b) ? darkWarningInk : warningInk;

  static Color textPrimaryFor(Brightness b) => _dark(b) ? darkInk : ink;
  static Color textSecondaryFor(Brightness b) => _dark(b) ? darkBody : body;
  static Color textTertiaryFor(Brightness b) => _dark(b) ? darkMuted : muted;

  /// Card and sheet surface (layer 2).
  static Color surfaceFor(Brightness b) => paper2For(b);

  /// Page background (layer 0, the sky).
  static Color paperFor(Brightness b) => skyFor(b);
  static Color scaffoldFor(Brightness b) => skyFor(b);

  /// Section and band surface (layer 1).
  static Color secondarySurfaceFor(Brightness b) => paper1For(b);
  static Color disabledSurfaceFor(Brightness b) => paperDeepFor(b);
  static Color coralSoftFor(Brightness b) => _dark(b) ? darkClaySoft : claySoft;
  static Color successSoftFor(Brightness b) =>
      _dark(b) ? darkPineSoft : pineSoft;
  static Color warningSoftFor(Brightness b) =>
      _dark(b) ? darkWarningSoftBg : warningSoftBg;
  static Color errorSoftFor(Brightness b) =>
      _dark(b) ? darkDangerSoft : dangerSoft;
  static Color blueSoftFor(Brightness b) => _dark(b) ? blueSoftDark : blueSoft;
  static Color purpleSoftFor(Brightness b) =>
      _dark(b) ? purpleSoftDark : purpleSoft;
  static Color greenSoftFor(Brightness b) =>
      _dark(b) ? greenSoftDark : greenSoft;
  static Color yellowSoftFor(Brightness b) =>
      _dark(b) ? yellowSoftDark : yellowSoft;
  static Color orangeSoftFor(Brightness b) =>
      _dark(b) ? orangeSoftDark : orangeSoft;
  static Color tealSoftFor(Brightness b) => _dark(b) ? tealSoftDark : tealSoft;
  static Color pinkSoftFor(Brightness b) => _dark(b) ? pinkSoftDark : pinkSoft;

  /// Ink on soft green chips (match chips, meta tags).
  static Color greenInkFor(Brightness b) => _dark(b) ? darkPine : greenInk;
  static Color hairlineFor(Brightness b) => _dark(b) ? darkHairline : hairline;
}
