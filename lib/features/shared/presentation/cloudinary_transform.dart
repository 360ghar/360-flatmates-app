/// Injects Cloudinary delivery transformations into a Cloudinary asset URL so
/// the CDN returns an appropriately-sized, optimally-encoded image instead of
/// the original full-resolution upload.
///
/// The Flutter app receives URLs like
/// `https://res.cloudinary.com/<cloud>/image/upload/v<version>/<path>.jpg`
/// from the backend. Without transformations, Cloudinary ships the original
/// bytes (often several MB for property photos) regardless of how small the
/// target widget is. This helper inserts a transformation segment that
/// requests format auto-negotiation (WebP/AVIF where supported), automatic
/// quality, and a width/height cap matched to the receiving widget.
///
/// Non-Cloudinary URLs are returned unchanged so the helper is safe to run
/// over every image URL in the app unconditionally.
String applyCloudinaryTransform(
  String url, {
  double? width,
  double? height,
}) {
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    return url;
  }

  // Only rewrite URLs on the Cloudinary image delivery path. The video upload
  // path, raw upload, and private CDN variants with different hostnames are
  // left alone.
  const marker = '/image/upload/';
  final markerIndex = url.indexOf(marker);
  if (markerIndex == -1) return url;

  final prefix = url.substring(0, markerIndex + marker.length);
  final tail = url.substring(markerIndex + marker.length);

  final desired = _buildTransformSegment(width: width, height: height);
  if (desired.isEmpty) return url;

  // Cloudinary URL grammar:
  //   /image/upload/[<existing-transforms>/][v<digits>/]<public_id>.<ext>
  //
  // The version marker `v<digits>/` is the unambiguous boundary between the
  // (possibly empty) transformations segment and the immutable asset path.
  // We anchor on it whenever it's present so we never confuse a folder name
  // like `360ghar/` for a transformation directive.
  final versionMatch = RegExp(r'v\d+/').firstMatch(tail);

  if (versionMatch == null) {
    // No version marker — treat the entire tail as the public ID and prepend
    // our transforms as a new segment. This is safe even if the tail happens
    // to look like a transform segment, because Cloudinary's URL grammar
    // disambiguates by trying transforms-then-public-ID resolution.
    return '$prefix$desired/$tail';
  }

  final existingTransforms = tail.substring(0, versionMatch.start);
  final versionAndPath = tail.substring(versionMatch.start);

  // Append our transform segment AFTER any existing transforms so that, per
  // Cloudinary's "last directive wins" semantics, our width/height/quality
  // take precedence over whatever the backend specified. We do NOT merge into
  // the existing segment with a comma because that would make ordering
  // ambiguous for chained transforms (Cloudinary applies segments in order).
  return '$prefix$existingTransforms$desired/$versionAndPath';
}

String _buildTransformSegment({double? width, double? height}) {
  // Match the existing memCacheWidth/memCacheHeight math used in
  // flatmates_network_image.dart — request 2× the widget dimensions so high-DPR
  // screens still get a crisp image, clamped to Cloudinary's sensible bounds.
  final tokens = <String>['f_auto', 'q_auto'];

  final w = _normalizeDim(width);
  if (w != null) tokens.add('w_$w');

  final h = _normalizeDim(height);
  if (h != null) tokens.add('h_$h');

  // `c_limit` resizes only if the original is larger than the requested box —
  // small originals are returned untouched, which is what we want for
  // thumbnails and avatars alike.
  if (w != null || h != null) tokens.add('c_limit');

  return tokens.join(',');
}

int? _normalizeDim(double? raw) {
  if (raw == null) return null;
  if (!raw.isFinite || raw <= 0) return null;
  final scaled = (raw * 2).round();
  if (scaled < 50) return 50;
  if (scaled > 2000) return 2000;
  return scaled;
}
