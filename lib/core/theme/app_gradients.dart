import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';

/// Canonical gradient tokens for premium visual effects.
///
/// Gradients are subtle — they add depth without being distracting.
abstract final class AppGradients {
  /// Primary gradient: subtle top-to-bottom lightening for CTA depth.
  static LinearGradient primaryGradient(Color primary) => LinearGradient(
    colors: [primary.withValues(alpha: 0.95), primary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Surface gradient: very subtle card to paper wash for content depth.
  static LinearGradient surfaceGradient(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return LinearGradient(
      colors: [
        isDark
            ? AppSemanticColors.darkSurface.withValues(alpha: 0.5)
            : AppSemanticColors.card.withValues(alpha: 0.5),
        isDark ? AppSemanticColors.darkScaffold : AppSemanticColors.paper,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  /// Shimmer gradient for skeleton loading.
  static LinearGradient shimmerGradient({
    required Color baseColor,
    required Color highlightColor,
    required double sweepPosition,
  }) {
    return LinearGradient(
      begin: Alignment(-1 + 2 * sweepPosition, 0),
      end: Alignment(1 + 2 * sweepPosition, 0),
      colors: [baseColor, highlightColor, baseColor],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  /// Success status gradient: subtle green wash.
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFFDCEAD4), Color(0xFFC2DAB2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Warning status gradient: subtle amber wash.
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF5E8B8), Color(0xFFE8D5A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Error status gradient: subtle red wash.
  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFF8D5C8), Color(0xFFF0C0B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Waitlist/nudge card gradient: primary-tinted subtle wash.
  static LinearGradient nudgeGradient(Color _) => LinearGradient(
    colors: [
      AppSemanticColors.accent.withValues(alpha: 0.08),
      AppSemanticColors.accent.withValues(alpha: 0.03),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueCategoryGradient = LinearGradient(
    colors: [AppSemanticColors.blueSoft, Color(0x00FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleCategoryGradient = LinearGradient(
    colors: [AppSemanticColors.purpleSoft, Color(0x00FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenCategoryGradient = LinearGradient(
    colors: [AppSemanticColors.greenSoft, Color(0x00FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient yellowCategoryGradient = LinearGradient(
    colors: [AppSemanticColors.yellowSoft, Color(0x00FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeCategoryGradient = LinearGradient(
    colors: [AppSemanticColors.orangeSoft, Color(0x00FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealCategoryGradient = LinearGradient(
    colors: [AppSemanticColors.tealSoft, Color(0x00FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkCategoryGradient = LinearGradient(
    colors: [AppSemanticColors.pinkSoft, Color(0x00FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coralCategoryGradient = LinearGradient(
    colors: [AppSemanticColors.coralSoft, Color(0x00FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
