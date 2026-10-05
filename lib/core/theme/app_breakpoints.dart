/// Responsive width boundaries in dp — Material's compact / medium / expanded
/// split, matching DESIGN.md's layout targets.
abstract final class AppBreakpoints {
  /// Compact → medium boundary (phone → small tablet).
  static const double medium = 600;

  /// Medium → expanded boundary (small → large tablet / desktop).
  static const double expanded = 900;

  /// Columns in a listing-card grid at [width]: 2 on phones, 3 from [medium],
  /// 4 from [expanded].
  ///
  /// This is the single definition shared by the loaded grid (`DiscoverPage`)
  /// and its skeleton: two copies would drift, and the feed would reflow the
  /// moment the cards arrive (DESIGN.md §8 — the skeleton has the layout of
  /// the loaded view).
  static int cardGridColumns(double width) =>
      width < medium ? 2 : (width < expanded ? 3 : 4);
}
