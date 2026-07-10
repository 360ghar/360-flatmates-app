import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';

/// Colors for skeleton bones and the shimmer highlight sweep.
abstract final class SkeletonTokens {
  /// Solid bone fill (the placeholder shape).
  static Color bone(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.surfaceStrong;
  }

  /// Softer nested bone (e.g. text lines on a card surface).
  static Color boneSoft(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppSemanticColors.darkHairline
        : AppSemanticColors.hairlineSoft;
  }

  /// Shimmer base (matches typical bone).
  static Color shimmerBase(Brightness brightness) => bone(brightness);

  /// Shimmer highlight — higher contrast than bone for a visible sweep.
  static Color shimmerHighlight(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF3A3A3A)
        : AppSemanticColors.canvas;
  }

  /// Subtle container behind a group of bones.
  static Color surface(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppSemanticColors.darkSurface.withValues(alpha: 0.6)
        : AppSemanticColors.surfaceSoft;
  }

  /// Unread / emphasized row tint (no side stripe).
  static Color unreadTint(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppSemanticColors.primary.withValues(alpha: 0.12)
        : AppSemanticColors.primarySoft;
  }
}
