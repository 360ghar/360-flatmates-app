import 'package:flutter/material.dart';

/// Semantic color tokens from DESIGN.md.
///
/// Use these instead of hard-coded Color() literals for status colors.
abstract final class AppSemanticColors {
  // Accent
  static const Color accent = Color(0xFFC96442);
  static const Color accentSoft = Color(0x1AC96442);
  static const Color primaryContainer = coralSoft;

  // Semantic colors
  static const Color success = Color(0xFF5B8C44);
  static const Color error = Color(0xFFB4452C);
  static const Color warning = Color(0xFFB57828);
  static const Color info = accent;

  // Context colors
  static const Color whatsapp = Color(0xFF25D366);

  // Paper scale
  static const Color paper = Color(0xFFF4F3EE);
  static const Color paper2 = Color(0xFFEDEBE3);
  static const Color paper3 = Color(0xFFE4E1D7);
  static const Color paper4 = Color(0xFFD8D4C7);
  static const Color card = Color(0xFFFFFFFF);

  // Ink scale
  static const Color ink = Color(0xFF1F1A14);
  static const Color ink2 = Color(0xFF4A463E);
  static const Color ink3 = Color(0xFF8A847A);
  static const Color ink4 = Color(0xFFB5AFA3);

  // Line scale
  static const Color line = Color(0x141F1A14);
  static const Color line2 = Color(0x0A1F1A14);
  static const Color lineLow = Color(0x0A1F1A14);

  // Semantic soft backgrounds
  static const Color successSoft = Color(0x1E5B8C44);
  static const Color errorSoft = Color(0x1AB4452C);
  static const Color warningSoft = Color(0x1AB57828);
  static const Color successBg = greenSoft;
  static const Color warningBg = yellowSoft;
  static const Color errorBg = coralSoft;
  static const Color infoBg = coralSoft;

  // Legacy palette constants (migrated from app_palette.dart)
  static const Color darkHeading = ink;
  static const Color mutedText = ink2;
  static const Color lavenderBg = paper;
  static const Color peerBubbleBg = paper3;
  static const Color successTextDark = greenInk;

  // Neutral scale (light mode)
  static const Color surface = card;
  static const Color surfaceDim = paper;
  static const Color textPrimary = ink;
  static const Color textSecondary = ink2;
  static const Color textTertiary = ink3;
  static const Color border = line;
  static const Color outlineVariant = line;

  // Categorical pastel colors
  static const Color blueSoft = Color(0xFFE1EAF4);
  static const Color blueMid = Color(0xFF5B88B5);
  static const Color blueInk = Color(0xFF2A4868);
  static const Color purpleSoft = Color(0xFFE7DDF1);
  static const Color purpleMid = Color(0xFF8B7BB8);
  static const Color purpleInk = Color(0xFF4A3E70);
  static const Color greenSoft = Color(0xFFDCEAD4);
  static const Color greenMid = Color(0xFF6A9068);
  static const Color greenInk = Color(0xFF2D4A2E);
  static const Color yellowSoft = Color(0xFFF5E8B8);
  static const Color yellowMid = Color(0xFFC49840);
  static const Color yellowInk = Color(0xFF5C4318);
  static const Color orangeSoft = Color(0xFFFCE0C8);
  static const Color orangeMid = Color(0xFFD17847);
  static const Color orangeInk = Color(0xFF5E3318);
  static const Color tealSoft = Color(0xFFCFE4DF);
  static const Color tealMid = Color(0xFF5A9DA8);
  static const Color tealInk = Color(0xFF1A4A52);
  static const Color pinkSoft = Color(0xFFF6DDE3);
  static const Color pinkMid = Color(0xFFC28098);
  static const Color pinkInk = Color(0xFF6B3548);
  static const Color coralSoft = Color(0xFFF8D5C8);
  static const Color coralMid = accent;
  static const Color coralInk = orangeInk;

  // Legacy primary aliases
  static const Color primaryLight = accentSoft;

  // Dark mode overrides
  static const Color darkScaffold = Color(0xFF1A1612);
  static const Color darkSurface = Color(0xFF2A2520);
  static const Color darkSurfaceElevated = Color(0xFF342E28);
  static const Color darkPaper2 = Color(0xFF252018);
  static const Color darkNavBar = darkSurfaceElevated;

  // Dark semantic soft variants
  static const Color successSoftDark = Color(0xFF1A3318);
  static const Color errorSoftDark = Color(0xFF3A1A14);
  static const Color warningSoftDark = Color(0xFF3A2E14);
  static const Color blueSoftDark = Color(0xFF1A2A3A);
  static const Color purpleSoftDark = Color(0xFF2A1E3A);
  static const Color greenSoftDark = Color(0xFF1A2E1A);
  static const Color yellowSoftDark = Color(0xFF3A3018);
  static const Color orangeSoftDark = Color(0xFF3A2218);
  static const Color tealSoftDark = Color(0xFF183030);
  static const Color pinkSoftDark = Color(0xFF3A1A28);
  static const Color coralSoftDark = Color(0xFF3A2018);

  // Compatibility score colors
  static const Color compatHigh = success;
  static const Color compatMedium = warning;
  static const Color compatLow = error;

  // Frost / glassmorphism tokens
  static const Color frostOverlayLight = Color(0xE0F4F3EE);
  static const Color frostOverlayDark = Color(0xE01A1612);
  static const double frostBlur = 3.0;

  static Color textPrimaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? paper : ink;

  static Color textSecondaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? paper3 : ink2;

  static Color textTertiaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? ink4 : ink3;

  static Color surfaceFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurface : card;

  static Color paperFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkScaffold : paper;

  static Color secondarySurfaceFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurfaceElevated : paper2;

  static Color disabledSurfaceFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurfaceElevated : paper3;

  static Color coralSoftFor(Brightness brightness) =>
      brightness == Brightness.dark ? coralSoftDark : coralSoft;
}
