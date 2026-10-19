import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The four iPhone Duo (foldable iPhone) poses, in logical points, and the
/// safe-area insets that come with them.
///
/// The numbers are measurements, not choices. They were taken from the local
/// iOS 27.1 simulator (the Duo's four supported postures) and cross-checked
/// against the published reference geometry, so they are the real surface
/// sizes a fold/unfold hands the framework:
///
/// | Pose                        | Width x Height |
/// |-----------------------------|----------------|
/// | Folded portrait             | 466 x 678      |
/// | Folded landscape            | 678 x 466      |
/// | Open / half-open portrait   | 669 x 951      |
/// | Open / half-open landscape  | 951 x 669      |
///
/// Three of these sizes land on a different `AppBreakpoints` branch, which is
/// the whole reason the poses matter:
///
/// * 466 and 678 are below `medium` (600) — the phone layout.
/// * 669 is at or above `medium` — a 3-column card grid, no reading column.
/// * 951 is at or above `expanded` (900) — the shell swaps its
///   `NavigationBar` for the 96 dp `NavigationRail`, so the usable page width
///   becomes 855 dp, not 951.
///
/// ## Why the insets look wrong
///
/// On the Duo the status bar runs down the **right edge**, not across the top,
/// so every pose carries a **84 pt right inset** and a **34 pt bottom inset**
/// (the home indicator) — and no top inset. That 84 pt is the single most
/// distinctive thing about the device and it is invisible to any test that
/// only sets a surface size: `tester.view.physicalSize` alone leaves the
/// padding at zero, so a page that ignores the inset looks correct in the
/// test and is broken on the device. Use [mediaQueryFor] or [duoSafeArea] to
/// put the inset back.
///
/// Source: the device geometry recorded in `AppBreakpoints` and `AppShell`
/// (both already cite 466 / 669 / 951), extended with the measured safe area.
abstract final class FoldableSurfaces {
  /// Folded, portrait. The smallest pose the app has to lay out.
  static const Size foldedPortrait = Size(466, 678);

  /// Folded, landscape. Wide enough to cross nothing: still below `medium`.
  static const Size foldedLandscape = Size(678, 466);

  /// Open (or half-open), portrait. Crosses `medium` (600).
  static const Size openPortrait = Size(669, 951);

  /// Open (or half-open), landscape. The only pose that crosses `expanded`
  /// (900) and therefore the only one that gets the `NavigationRail`.
  static const Size openLandscape = Size(951, 669);

  /// Every pose, in the order a user folds and unfolds the device:
  /// folded portrait -> open portrait -> folded landscape -> open landscape.
  ///
  /// Table-driven tests iterate this so a new pose only has to be added here.
  static const List<Size> all = [
    foldedPortrait,
    openPortrait,
    foldedLandscape,
    openLandscape,
  ];

  /// The two most distinct poses: the narrowest ([foldedPortrait]) and the
  /// widest ([openLandscape]).
  ///
  /// Golden tests and other byte-comparison tests should use these rather than
  /// [all]. 669 x 951 and 678 x 466 both sit strictly between the two
  /// extremes, and each stays inside the same `AppBreakpoints` branch as one
  /// of them (669 shares `medium` with 466's phone layout; 678 shares it too),
  /// so a third and fourth golden buy no new layout — only four times the
  /// maintenance.
  static const List<Size> extremes = [foldedPortrait, openLandscape];

  /// Width of the status bar / right-edge inset, in logical points.
  static const double rightInset = 84;

  /// Height of the home indicator inset, in logical points.
  static const double bottomInset = 34;

  /// The Duo's safe area: bottom 34 pt, right 84 pt, nothing on top or left.
  static const EdgeInsets duoSafeArea = EdgeInsets.only(
    right: rightInset,
    bottom: bottomInset,
  );

  /// Width of the shell's `NavigationRail` at [openLandscape] and above.
  ///
  /// Mirrors `AppBreakpoints.railWidth`; duplicated rather than imported so
  /// this helper stays free of `lib/` (it is geometry, not app policy).
  static const double railWidth = 96;

  /// Usable width for page content at [size].
  ///
  /// At [openLandscape] the shell pins a 96 dp rail to the left, so 951 dp of
  /// device becomes 855 dp of page. Everywhere else the page gets the whole
  /// width.
  static double pageWidthFor(Size size) =>
      size.width >= 900 ? size.width - railWidth : size.width;

  /// The x coordinate content must not cross on the right: the surface width
  /// minus the 84 pt status-bar inset.
  ///
  /// `tester.getRect(someContent).right <= safeRightEdgeFor(size)` is the
  /// right-inset assertion. Note the reading column
  /// (`AppBreakpoints.contentMaxWidth` = 720, centred) already satisfies it at
  /// 951 dp — 115.5 + 720 = 835.5 < 867 — so the wide pose hides a page that
  /// ignores the inset. Test the inset at [openPortrait] or
  /// [foldedPortrait], where nothing caps the width.
  static double safeRightEdgeFor(Size size) => size.width - rightInset;

  /// A [MediaQueryData] for [size] carrying the Duo's real insets.
  ///
  /// Inject this *below* `MaterialApp` (as `home`'s wrapper) to make a page
  /// see the Duo's padding without a real device:
  ///
  /// ```dart
  /// await tester.pumpWidget(
  ///   testableWidget(
  ///     child: MediaQuery(
  ///       data: FoldableSurfaces.mediaQueryFor(FoldableSurfaces.openPortrait),
  ///       child: const EnterPhonePage(),
  ///     ),
  ///   ),
  /// );
  /// ```
  ///
  /// Pass `padding: EdgeInsets.zero` for the "does the page hand-roll its own
  /// insets?" control case.
  static MediaQueryData mediaQueryFor(
    Size size, {
    EdgeInsets padding = duoSafeArea,
    EdgeInsets viewPadding = duoSafeArea,
    EdgeInsets viewInsets = EdgeInsets.zero,
    TextScaler textScaler = TextScaler.noScaling,
    bool disableAnimations = false,
  }) => MediaQueryData(
    size: size,
    padding: padding,
    // `viewPadding` is read by widgets that hand-roll their insets
    // (`FlatmatesBottomActionBar` uses `viewPaddingOf(context).bottom`), so it
    // has to carry the same numbers as `padding` or the two disagree.
    viewPadding: viewPadding,
    viewInsets: viewInsets,
    textScaler: textScaler,
    disableAnimations: disableAnimations,
  );

  /// Applies [size] to [tester]'s surface and registers the teardown, so a
  /// test is one line and can never leak the size into the next test.
  ///
  /// This drives the *real* view (`tester.view.physicalSize`), which is what
  /// lets a test change the size mid-test with [resizeTo]. It does not set any
  /// padding: pair it with an injected [mediaQueryFor] when the inset matters.
  static void useSurface(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Changes the mounted tree's surface to [size] and pumps the new frame —
  /// the widget-level equivalent of folding or unfolding the device.
  ///
  /// The tree stays mounted: nothing is re-pumped with a fresh widget, so this
  /// exercises exactly the path a real fold takes (a metrics change, a rebuild,
  /// and whatever `State` the framework decides to keep). Any layout error the
  /// new size provokes — a `RenderFlex overflowed` above all — is reported as
  /// an exception, which the caller reads with `tester.takeException()`.
  ///
  /// [settle] covers the page rise animation and the nav indicator; use
  /// [pumpOnly] for a tree with an animation that never settles (shimmer
  /// skeletons), where `pumpAndSettle` would time out.
  static Future<void> resizeTo(
    WidgetTester tester,
    Size size, {
    Duration settle = const Duration(milliseconds: 400),
    bool pumpOnly = false,
  }) async {
    tester.view.physicalSize = size;
    // First pump: the metrics change is delivered and the tree rebuilds at the
    // new size.
    await tester.pump();
    if (pumpOnly) {
      await tester.pump(settle);
      return;
    }
    await tester.pump(settle);
    await tester.pumpAndSettle();
  }
}
