import '../../../../core/theme/app_spacing.dart';

/// Height of a framed media band (floor plan, mini map) in a content column
/// [width] dp wide.
///
/// Both bands hold a document-shaped image, so the frame decides how the image
/// reads. A fixed 220 dp height stops working once the reading column widens:
/// in a 688 dp column a floor plan fits by height and floats in a 3.1:1
/// letterbox with ~190 dp of empty frame either side. Holding the phone's
/// aspect instead keeps the frame worth looking at at every width.
///
/// `width / _phoneBandAspect` is the phone band exactly — a 466 dp viewport
/// gives the 434 x 220 band it always had — capped at [_maxBandHeight] so a
/// wide band never eats a landscape viewport.
double detailsMediaBandHeight(double width) =>
    (width / _phoneBandAspect).clamp(_phoneBandHeight, _maxBandHeight);

/// 434 / 220 — the phone band: a 466 dp viewport minus the 16 dp page gutters.
const double _phoneBandAspect = (466 - 2 * AppSpacing.screen) / 220;

/// The band height the phone layout uses.
const double _phoneBandHeight = 220;

/// Ceiling for the band, so a wide column does not push the content below the
/// fold on a landscape pose.
const double _maxBandHeight = 360;
