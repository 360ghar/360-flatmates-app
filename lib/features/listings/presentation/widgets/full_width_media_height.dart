import '../../../../core/theme/app_spacing.dart';

/// Card width the full-width media bands in this feature were designed
/// against: the 466 dp folded-Duo viewport minus the 16 dp page gutter on each
/// side. Both consumers (`ManageListingCard`, `StepRoomSection`) sit inside a
/// page that pads its list by [AppSpacing.screen].
const double _compactCardWidth = 466 - AppSpacing.screen * 2;

/// Ceiling for a band that has grown with the card: four 72 dp scale steps.
///
/// On the 688 dp card inside a 720 dp reading column that holds a photo at
/// roughly 2.4:1 — still a band, but one that reads as a photo rather than as
/// a strip, and it never eats a third of the open pose's height.
const double _maxBandHeight = AppSpacing.s72 * 4;

/// Height of a full-width media band (a listing photo header, an uploaded room
/// photo, an add-photo tile) on a child [width] wide.
///
/// A fixed height on a full-width child is a phone assumption. At 434 dp — the
/// 466 dp folded-Duo viewport minus the page gutters — 200 dp is the 2.2:1 the
/// design was drawn at; the same 200 dp inside the 688 dp reading column of the
/// 951 dp open pose is a 3.4:1 letterbox strip with the photo cropped to a
/// sliver. Growing the height with the width keeps the band's proportions
/// instead of flattening them.
///
/// [compactHeight] is the height the band was designed at on the compact card.
/// It is also the floor: a narrower phone (320 dp and up) keeps that height
/// rather than shrinking the band, and the floor is what makes the 466 dp
/// rendering byte-for-byte what it was before this helper existed.
///
/// Call it with a measured child width (a `LayoutBuilder`'s
/// `constraints.maxWidth`), not the viewport width: the reading column caps a
/// page at 720 dp, so the viewport overstates the card on the open pose.
double fullWidthMediaHeight({
  required double width,
  required double compactHeight,
}) {
  final grown = compactHeight * width / _compactCardWidth;
  return grown.clamp(compactHeight, _maxBandHeight);
}
