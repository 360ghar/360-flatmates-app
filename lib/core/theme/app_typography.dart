import 'package:flutter/widgets.dart';

/// Type scale for the Paper Diorama design system. See DESIGN.md §2.
///
/// Display roles use Gambarino (bundled asset, one weight). Body and UI roles
/// use the platform font (SF Pro on iOS, Roboto on Android), so body styles
/// set no family.
///
/// `pubspec.yaml` registers the single Gambarino file under weights 400–800,
/// so a `copyWith(fontWeight: …)` on a display style never synthesises a
/// fake bold.
abstract final class AppTypography {
  static const String displayFamily = 'Gambarino';

  /// Kept for call sites that read a family name; display text is Gambarino.
  static const String fontFamily = displayFamily;

  // ── Display (Gambarino 400) ────────────────────────────────────────────
  static const double displaySize = 40;
  static const double displayHeight = 1.1;
  static const double h1Size = 32;
  static const double h1Height = 1.19;
  static const double h2Size = 26;
  static const double h2Height = 1.23;
  static const double h3Size = 21;
  static const double h3Height = 1.24;
  static const FontWeight displayWeight = FontWeight.w400;

  // ── Body (platform font) ───────────────────────────────────────────────
  static const double titleSize = 17;
  static const double titleHeight = 1.29;
  static const FontWeight titleWeight = FontWeight.w600;
  static const double bodySize = 16;
  static const double bodyHeight = 1.5;
  static const double bodySmallSize = 14;
  static const double bodySmallHeight = 1.43;
  static const double labelSize = 14;
  static const double labelHeight = 1.29;
  static const FontWeight labelWeight = FontWeight.w600;
  static const double captionSize = 13;
  static const double captionHeight = 1.38;

  // ── Aliases for existing call sites ────────────────────────────────────
  static const double ratingDisplaySize = displaySize;
  static const FontWeight ratingDisplayWeight = displayWeight;
  static const double ratingDisplayHeight = displayHeight;
  static const double ratingDisplayLetterSpacing = 0;
  static const double displayXlSize = h2Size;
  static const FontWeight displayXlWeight = displayWeight;
  static const double displayXlHeight = h2Height;
  static const double displayXlLetterSpacing = 0;
  static const double displayLgSize = h3Size;
  static const FontWeight displayLgWeight = displayWeight;
  static const double displayLgHeight = h3Height;
  static const double displayLgLetterSpacing = 0;
  static const double displayMdSize = h3Size;
  static const FontWeight displayMdWeight = displayWeight;
  static const double displayMdHeight = h3Height;
  static const double displayMdLetterSpacing = 0;
  static const double displaySmSize = 20;
  static const FontWeight displaySmWeight = displayWeight;
  static const double displaySmHeight = 1.25;
  static const double displaySmLetterSpacing = 0;
  static const double titleMdSize = titleSize;
  static const FontWeight titleMdWeight = titleWeight;
  static const double titleMdHeight = titleHeight;
  static const double titleMdLetterSpacing = 0;
  static const double titleSmSize = 16;
  static const FontWeight titleSmWeight = FontWeight.w500;
  static const double titleSmHeight = 1.25;
  static const double titleSmLetterSpacing = 0;
  static const double bodyMdSize = bodySize;
  static const FontWeight bodyMdWeight = FontWeight.w400;
  static const double bodyMdHeight = bodyHeight;
  static const double bodyMdLetterSpacing = 0;
  static const double bodySmSize = bodySmallSize;
  static const FontWeight bodySmWeight = FontWeight.w400;
  static const double bodySmHeight = bodySmallHeight;
  static const double bodySmLetterSpacing = 0;
  static const FontWeight captionWeight = FontWeight.w500;
  static const double captionLetterSpacing = 0;
  static const double captionSmSize = captionSize;
  static const FontWeight captionSmWeight = FontWeight.w400;
  static const double captionSmHeight = captionHeight;
  static const double captionSmLetterSpacing = 0;
  static const double badgeSize = 12;
  static const FontWeight badgeWeight = FontWeight.w600;
  static const double badgeHeight = 1.25;
  static const double badgeLetterSpacing = 0;
  static const double microLabelSize = 12;
  static const FontWeight microLabelWeight = FontWeight.w600;
  static const double microLabelHeight = 1.33;
  static const double microLabelLetterSpacing = 0;
  static const double uppercaseTagSize = 11;
  static const FontWeight uppercaseTagWeight = FontWeight.w600;
  static const double uppercaseTagHeight = 1.25;
  static const double uppercaseTagLetterSpacing = 0;
  static const double buttonMdSize = 16;
  static const FontWeight buttonMdWeight = FontWeight.w600;
  static const double buttonMdHeight = 1.25;
  static const double buttonMdLetterSpacing = 0;
  static const double buttonSmSize = 14;
  static const FontWeight buttonSmWeight = FontWeight.w600;
  static const double buttonSmHeight = 1.29;
  static const double buttonSmLetterSpacing = 0;
  static const double navLinkSize = 16;
  static const FontWeight navLinkWeight = FontWeight.w600;
  static const double navLinkHeight = 1.25;
  static const double navLinkLetterSpacing = 0;
}
