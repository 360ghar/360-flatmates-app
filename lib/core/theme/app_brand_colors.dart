import 'package:flutter/material.dart';

/// Third-party brand colours that must match the brand's own guidelines,
/// not the Paper Diorama palette.
abstract final class AppBrandColors {
  /// Google Sign-In button (Google identity branding guidelines).
  static ({Color fill, Color label, Color stroke, Color pressed}) google(
    Brightness b,
  ) => b == Brightness.dark
      ? (
          fill: const Color(0xFF131314),
          label: const Color(0xFFE3E3E3),
          stroke: const Color(0xFF8E918F),
          pressed: const Color(0xFF1E1F20),
        )
      : (
          fill: const Color(0xFFFFFFFF),
          // Google identity branding guidelines (light): label #1F1F1F,
          // stroke #747775.
          label: const Color(0xFF1F1F1F),
          stroke: const Color(0xFF747775),
          pressed: const Color(0xFFF8F9FA),
        );
}
