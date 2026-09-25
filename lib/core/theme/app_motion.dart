import 'package:flutter/widgets.dart';

/// Motion tokens. See DESIGN.md §7.
///
/// Content is never hidden behind motion: entrances move things that start
/// fully visible. Every animation respects [reduceMotion].
abstract final class AppMotion {
  // Durations
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);

  /// Delay between paper layers in an entrance (back layers first).
  static const Duration layerStagger = Duration(milliseconds: 40);

  /// Distance a layer rises into place on entrance.
  static const double layerRise = 12;

  /// Pressed scale for buttons and chips.
  static const double pressScale = 0.98;

  static const Curve paperOut = Cubic(0.2, 0.7, 0.2, 1);

  /// Symmetric in/out for the skeleton tone pulse (it runs back and forth).
  static const Curve tonePulse = Curves.easeInOut;
  static const Curve paperSettle = Cubic(0.3, 1.3, 0.5, 1);

  // Named durations for specific use-cases
  static const Duration chipSelect = fast;
  static const Duration segmentTransition = Duration(milliseconds: 220);
  static const Duration pageTransition = Duration(milliseconds: 250);
  static const Duration tabSwitch = Duration(milliseconds: 200);
  static const Duration buttonPress = fast;
  static const Duration cardAppear = slow;
  static const Duration cardStagger = layerStagger;
  static const Duration compatibilityRing = slow;
  static const Duration matchCelebration = Duration(milliseconds: 600);

  /// How long the match confetti keeps emitting.
  static const Duration confettiBurst = Duration(seconds: 2);
  static const Duration bottomSheet = Duration(milliseconds: 280);
  static const Duration fabExpand = Duration(milliseconds: 250);
  static const Duration skeletonShimmer = Duration(milliseconds: 1200);

  // --- New premium durations ---
  static const Duration heroTransition = Duration(milliseconds: 300);
  static const Duration animatedSwitcher = standard;
  static const Duration fadeInEntry = Duration(milliseconds: 200);
  static const Duration staggerItem = layerStagger;
  static const Duration breathing = Duration(seconds: 2);

  /// Delay before the chat mode/intent tooltip appears after open.
  static const Duration modeTooltipShowDelay = Duration(milliseconds: 450);

  /// Auto-dismiss window for the chat mode/intent tooltip.
  static const Duration modeTooltipAutoDismiss = Duration(seconds: 5);

  // Curves — ease-out only per DESIGN.md
  static const Curve easeOutCubic = Cubic(0.33, 0, 0.2, 1);
  static const Curve easeOutQuart = Cubic(0.25, 0, 0, 1);
  static const Curve easeOutExpo = Cubic(0.16, 1, 0.3, 1);
  static const Curve easeOutBack = Cubic(
    0.34,
    1.56,
    0.64,
    1,
  ); // slight overshoot for FAB only

  /// Checks if the user prefers reduced motion.
  static bool reduceMotion(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  /// Returns the given duration or [Duration.zero] if reduced motion is active.
  static Duration durationOrZero(BuildContext context, Duration duration) {
    return reduceMotion(context) ? Duration.zero : duration;
  }

  /// Total length of an entrance with [count] staggered layers.
  static Duration staggerTotal(int count) => slow + layerStagger * (count - 1);

  /// The window of layer [index] inside a [staggerTotal] entrance of [count]
  /// layers. Each layer starts [layerStagger] after the one before it and
  /// runs for [slow]. Index 0 is the back layer (DESIGN.md §7).
  static Interval staggerInterval({
    required int index,
    required int count,
    Curve curve = paperOut,
  }) {
    final total = staggerTotal(count).inMilliseconds;
    final start = layerStagger.inMilliseconds * index;
    return Interval(
      start / total,
      (start + slow.inMilliseconds) / total,
      curve: curve,
    );
  }
}
