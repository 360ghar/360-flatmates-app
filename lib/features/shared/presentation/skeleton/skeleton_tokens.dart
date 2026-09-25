import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';

/// Colors for skeleton bones and the shimmer highlight sweep.
abstract final class SkeletonTokens {
  /// Solid bone fill (the placeholder shape). Paper-deep, not DESIGN's
  /// paper-1: most skeletons sit on the sky layer, where paper-1 is almost
  /// invisible.
  static Color bone(Brightness brightness) =>
      AppSemanticColors.paperDeepFor(brightness);

  /// Softer nested bone (e.g. text lines on a card surface).
  static Color boneSoft(Brightness brightness) =>
      AppSemanticColors.paper1For(brightness);

  /// Shimmer base (matches typical bone).
  static Color shimmerBase(Brightness brightness) => bone(brightness);

  /// Shimmer highlight — higher contrast than bone for a visible sweep.
  static Color shimmerHighlight(Brightness brightness) =>
      AppSemanticColors.paper1For(brightness);

  /// Subtle container behind a group of bones.
  static Color surface(Brightness brightness) =>
      AppSemanticColors.paper2For(brightness);

  /// Unread / emphasized row tint (no side stripe).
  static Color unreadTint(Brightness brightness) =>
      AppSemanticColors.coralSoftFor(brightness);
}
