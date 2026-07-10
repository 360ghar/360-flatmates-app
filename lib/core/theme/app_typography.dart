import 'package:flutter/widgets.dart';

/// Canonical type scale from DESIGN.md (Airbnb / Inter substitute for Cereal).
///
/// Single family for display, body, nav, captions. Modest display weights —
/// photography carries visual hierarchy.
abstract final class AppTypography {
  // Font family — Inter is the open-source Cereal substitute.
  static const String fontFamily = 'Inter';

  // ── Airbnb scale ───────────────────────────────────────────────────────

  // rating-display — 64 / 700 (listing detail only)
  static const double ratingDisplaySize = 64;
  static const FontWeight ratingDisplayWeight = FontWeight.w700;
  static const double ratingDisplayHeight = 1.1;
  static const double ratingDisplayLetterSpacing = -1;

  // display-xl — 28 / 700
  static const double displayXlSize = 28;
  static const FontWeight displayXlWeight = FontWeight.w700;
  static const double displayXlHeight = 1.43;
  static const double displayXlLetterSpacing = 0;

  // display-lg — 22 / 500
  static const double displayLgSize = 22;
  static const FontWeight displayLgWeight = FontWeight.w500;
  static const double displayLgHeight = 1.18;
  static const double displayLgLetterSpacing = -0.44;

  // display-md — 21 / 700
  static const double displayMdSize = 21;
  static const FontWeight displayMdWeight = FontWeight.w700;
  static const double displayMdHeight = 1.43;
  static const double displayMdLetterSpacing = 0;

  // display-sm — 20 / 600
  static const double displaySmSize = 20;
  static const FontWeight displaySmWeight = FontWeight.w600;
  static const double displaySmHeight = 1.20;
  static const double displaySmLetterSpacing = -0.18;

  // title-md — 16 / 600
  static const double titleMdSize = 16;
  static const FontWeight titleMdWeight = FontWeight.w600;
  static const double titleMdHeight = 1.25;
  static const double titleMdLetterSpacing = 0;

  // title-sm — 16 / 500
  static const double titleSmSize = 16;
  static const FontWeight titleSmWeight = FontWeight.w500;
  static const double titleSmHeight = 1.25;
  static const double titleSmLetterSpacing = 0;

  // body-md — 16 / 400
  static const double bodyMdSize = 16;
  static const FontWeight bodyMdWeight = FontWeight.w400;
  static const double bodyMdHeight = 1.5;
  static const double bodyMdLetterSpacing = 0;

  // body-sm — 14 / 400
  static const double bodySmSize = 14;
  static const FontWeight bodySmWeight = FontWeight.w400;
  static const double bodySmHeight = 1.43;
  static const double bodySmLetterSpacing = 0;

  // caption — 14 / 500
  static const double captionSize = 14;
  static const FontWeight captionWeight = FontWeight.w500;
  static const double captionHeight = 1.29;
  static const double captionLetterSpacing = 0;

  // caption-sm — 13 / 400
  static const double captionSmSize = 13;
  static const FontWeight captionSmWeight = FontWeight.w400;
  static const double captionSmHeight = 1.23;
  static const double captionSmLetterSpacing = 0;

  // badge — 11 / 600
  static const double badgeSize = 11;
  static const FontWeight badgeWeight = FontWeight.w600;
  static const double badgeHeight = 1.18;
  static const double badgeLetterSpacing = 0;

  // micro-label — 12 / 700
  static const double microLabelSize = 12;
  static const FontWeight microLabelWeight = FontWeight.w700;
  static const double microLabelHeight = 1.33;
  static const double microLabelLetterSpacing = 0;

  // uppercase-tag — 8 / 700
  static const double uppercaseTagSize = 8;
  static const FontWeight uppercaseTagWeight = FontWeight.w700;
  static const double uppercaseTagHeight = 1.25;
  static const double uppercaseTagLetterSpacing = 0.32;

  // button-md — 16 / 500
  static const double buttonMdSize = 16;
  static const FontWeight buttonMdWeight = FontWeight.w500;
  static const double buttonMdHeight = 1.25;
  static const double buttonMdLetterSpacing = 0;

  // button-sm — 14 / 500
  static const double buttonSmSize = 14;
  static const FontWeight buttonSmWeight = FontWeight.w500;
  static const double buttonSmHeight = 1.29;
  static const double buttonSmLetterSpacing = 0;

  // nav-link — 16 / 600
  static const double navLinkSize = 16;
  static const FontWeight navLinkWeight = FontWeight.w600;
  static const double navLinkHeight = 1.25;
  static const double navLinkLetterSpacing = 0;
}
