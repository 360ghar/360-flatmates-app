import 'package:flutter/widgets.dart';

/// Canonical type scale from DESIGN.md.
///
/// Font families are configured in [AppTheme]. These constants define
/// sizes, weights, line heights, and letter spacing so they can be
/// referenced without reaching into the theme text theme.
abstract final class AppTypography {
  // Font family names
  static const String fontFamilyDisplay = 'Fraunces';
  static const String fontFamilyBody = 'Inter';
  static const String fontFamilyMono = 'JetBrains Mono';
  static const String fontFamilySerif = 'Instrument Serif';

  // Display, 32sp regular serif
  static const double displaySize = 32;
  static const FontWeight displayWeight = FontWeight.w400;
  static const double displayHeight = 1.05;
  static const double displayLetterSpacing = -0.035;

  // H1, 28sp regular serif
  static const double h1Size = 28;
  static const FontWeight h1Weight = FontWeight.w400;
  static const double h1Height = 1.05;
  static const double h1LetterSpacing = -0.035;

  // H2, 24sp regular serif
  static const double h2Size = 24;
  static const FontWeight h2Weight = FontWeight.w400;
  static const double h2Height = 1.1;
  static const double h2LetterSpacing = -0.025;

  // H3, 16sp semibold sans
  static const double h3Size = 16;
  static const double h3SizeLarge = 20;
  static const FontWeight h3Weight = FontWeight.w600;
  static const double h3Height = 1.25;
  static const double h3LetterSpacing = -0.012;

  // H4-H6, 14sp semibold sans
  static const double h4Size = 14;
  static const FontWeight h4Weight = FontWeight.w600;
  static const double h4Height = 1.3;
  static const double h4LetterSpacing = -0.01;

  // Body Large — 16sp Medium
  static const double bodyLargeSize = 16;
  static const FontWeight bodyLargeWeight = FontWeight.w500;
  static const double bodyLargeHeight = 1.5;
  static const double bodyLargeLetterSpacing = 0;

  // Body Medium — 14sp Medium
  static const double bodyMediumSize = 14;
  static const FontWeight bodyMediumWeight = FontWeight.w500;
  static const double bodyMediumHeight = 1.45;
  static const double bodyMediumLetterSpacing = 0;

  // Label Large — 14sp Bold (buttons, chip labels)
  static const double labelLargeSize = 14;
  static const FontWeight labelLargeWeight = FontWeight.w700;
  static const double labelLargeHeight = 1.0;
  static const double labelLargeLetterSpacing = 0.5;

  // Label Medium — 12sp SemiBold (tags, badges)
  static const double labelMediumSize = 12;
  static const FontWeight labelMediumWeight = FontWeight.w600;
  static const double labelMediumHeight = 1.4;
  static const double labelMediumLetterSpacing = 0.2;

  // Caption — 12sp Regular
  static const double captionSize = 12;
  static const FontWeight captionWeight = FontWeight.w400;
  static const double captionHeight = 1.4;
  static const double captionLetterSpacing = 0;

  // Eyebrow, 10sp uppercase mono
  static const double eyebrowSize = 10;
  static const FontWeight eyebrowWeight = FontWeight.w600;
  static const double eyebrowHeight = 1.4;
  static const double eyebrowLetterSpacing = 1.6;

  // Fraunces variable settings, documented for renderer support.
  static const String frauncesOpszDisplay = '"opsz" 144, "SOFT" 50, "WONK" 0';
  static const String frauncesOpszH1 = '"opsz" 112, "SOFT" 40, "WONK" 0';
  static const String frauncesOpszH2 = '"opsz" 96, "SOFT" 30, "WONK" 0';

  // Specialized sizes
  static const double priceHeroSize = 26;
  static const double cardTitleSize = 16;
  static const double metadataSize = 12;
  static const double badgeSize = 12;
}
