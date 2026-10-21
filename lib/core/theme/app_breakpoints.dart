import 'dart:math' as math;

/// Responsive width boundaries in dp — Material's compact / medium / expanded
/// split, matching DESIGN.md's layout targets.
///
/// The foldable iPhone Duo (Apple "iPhone Duo") measures 466 × 678 folded and
/// 669 × 951 open; 669 lands in [medium] and 951 in [expanded], so the three
/// existing boundaries already classify every pose correctly. What changes at
/// those boundaries is the *layout*: a reading column, a grid's column count,
/// a rail instead of a bottom bar.
abstract final class AppBreakpoints {
  /// Compact → medium boundary (phone → small tablet).
  static const double medium = 600;

  /// Medium → expanded boundary (small → large tablet / desktop).
  static const double expanded = 900;

  /// Wide boundary — open iPhone Duo in landscape, large tablets, desktop.
  ///
  /// Above this a single-pane reading column stops growing, so text keeps a
  /// comfortable measure instead of running the full 951 dp.
  static const double wide = 1024;

  /// Cap on a modal bottom sheet's width, so it floats centred instead of
  /// stretching across a 951 dp viewport.
  static const double sheetMaxWidth = 640;

  /// Cap on a dialog's width for the same reason as [sheetMaxWidth].
  static const double dialogMaxWidth = 560;

  /// Max width of a single-pane reading column below [wide]. Above [wide] the
  /// column is bounded by this same value, because [contentMaxWidth] returns
  /// infinity only for *layout* purposes — the cap itself is this constant.
  static const double readingColumn = 720;

  /// Hard cap on a chat message bubble, whatever the viewport width.
  static const double bubbleMaxWidth = 560;

  /// Width of the wide-viewport `NavigationRail` column in the app shell.
  ///
  /// The rail is laid out at a fixed width (rather than its intrinsic one) so
  /// the reading column beside it is deterministic and does not shift when a
  /// localized label changes length. 96 leaves the rail's 12 dp destination
  /// padding plus ~72 dp for a label, which fits the longest shell label
  /// ("Explore") at the 1.3 text-scale cap. A locale that needs more wraps to a
  /// second line — the rail absorbs the extra height rather than clipping.
  static const double railWidth = 96;

  /// True when [width] is at or above [medium].
  static bool isMedium(double width) => width >= medium;

  /// True when [width] is at or above [expanded].
  static bool isExpanded(double width) => width >= expanded;

  /// Columns in a listing-card grid at [width]: 2 on phones, 3 from [medium],
  /// 4 from [expanded].
  ///
  /// This is the single definition shared by the loaded grid (`DiscoverPage`)
  /// and its skeleton: two copies would drift, and the feed would reflow the
  /// moment the cards arrive (DESIGN.md §8 — the skeleton has the layout of
  /// the loaded view).
  static int cardGridColumns(double width) =>
      width < medium ? 2 : (width < expanded ? 3 : 4);

  /// Columns in the Likes / profile grid at [width]: 2 on phones, 3 from
  /// [medium], 4 from [expanded].
  ///
  /// Deliberately not delegating to [cardGridColumns]: the two grids share a
  /// shape today, but the listing feed and the profile grid are free to
  /// diverge (the profile grid has no skeleton to match).
  static int profileGridColumns(double width) =>
      width < medium ? 2 : (width < expanded ? 3 : 4);

  /// Columns in the lifestyle grid at [width]: 2 on phones, 4 from [medium].
  ///
  /// Four is the ceiling: the cells are a bare icon plus two short lines, and
  /// beyond four they stop reading as a pair of label/value.
  static int lifestyleColumns(double width) => width < medium ? 2 : 4;

  /// Max width of a single-pane reading column at [width].
  /// 720 below [wide]; unbounded (double.infinity) from [wide] up.
  static double contentMaxWidth(double width) =>
      width < wide ? readingColumn : double.infinity;

  /// Max width of a chat message bubble at [width]: width * 0.75, capped at
  /// 560.
  static double chatBubbleMaxWidth(double width) =>
      math.min(width * 0.75, bubbleMaxWidth);

  /// Thumbnail edge for the browse-listing row at [width]: 110 on a phone,
  /// 140 from [medium], 160 from [expanded].
  ///
  /// The row is photo-left / text-right, so a fixed 110 dp thumb left ~570 dp
  /// of single-line text beside it once the reading column capped the page.
  /// Growing the photo with the column keeps its share of the row (~25 % on a
  /// phone, ~23 % at 951) and leaves the meta chips a block worth reading.
  ///
  /// Lives here rather than beside the card so `BrowseListingsSkeleton` — a
  /// shared component — can reserve the same row the loaded card draws
  /// (DESIGN.md §8: the skeleton has the layout of the loaded view) without
  /// `lib/features/shared/` importing a feature.
  static double browseThumbSize(double width) => width >= expanded
      ? _browseThumbWide
      : (width >= medium ? _browseThumbMedium : _browseThumbPhone);

  static const double _browseThumbPhone = 110;
  static const double _browseThumbMedium = 140;
  static const double _browseThumbWide = 160;
}
