import 'package:flutter/widgets.dart';

/// Canonical motion/animation tokens from DESIGN.md.
///
/// All durations use ease-out curves only. Respect reduced motion.
abstract final class AppMotion {
  // Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 300);

  // Named durations for specific use-cases
  static const Duration chipSelect = fast;
  static const Duration segmentTransition = Duration(milliseconds: 220);
  static const Duration pageTransition = Duration(milliseconds: 250);
  static const Duration tabSwitch = Duration(milliseconds: 200);
  static const Duration buttonPress = fast;
  static const Duration cardAppear = slow;
  static const Duration cardStagger = Duration(milliseconds: 50);
  static const Duration compatibilityRing = slow;
  static const Duration matchCelebration = Duration(milliseconds: 600);
  static const Duration bottomSheet = Duration(milliseconds: 280);
  static const Duration fabExpand = Duration(milliseconds: 250);
  static const Duration skeletonShimmer = Duration(milliseconds: 1200);

  // --- New premium durations ---
  static const Duration heroTransition = Duration(milliseconds: 300);
  static const Duration animatedSwitcher = standard;
  static const Duration fadeInEntry = Duration(milliseconds: 200);
  static const Duration staggerItem = Duration(milliseconds: 100);
  static const Duration breathing = Duration(seconds: 2);

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

  /// Returns a staggered [Interval] for list items.
  ///
  /// [index] is the item index, [totalItems] is the total count,
  /// and [staggerMs] is the delay between each item (default 50ms).
  /// The interval covers the item's own animation window.
  static Interval staggerInterval({
    required int index,
    int totalItems = 6,
    int staggerMs = 50,
  }) {
    final totalMs =
        staggerMs * totalItems + 300; // 300ms for last item's own anim
    final start = (staggerMs * index) / totalMs;
    final end = (staggerMs * index + 300) / totalMs;
    return Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0));
  }
}
