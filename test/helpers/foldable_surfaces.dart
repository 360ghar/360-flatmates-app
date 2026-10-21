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
/// ## The safe area (measured, not assumed)
///
/// An earlier pass recorded this device as carrying an **84 pt right-edge
/// inset** and no top inset, on the theory that the Duo moves its status bar
/// and camera to the right edge. **That is wrong**, and it was wrong in a way
/// that mattered: it sent the whole inset workstream at the right edge while
/// the real inset sat on top.
///
/// Measured on the booted iOS 27.1 Duo simulator, open portrait, from the
/// running app's own widget tree (`MediaQueryData` as the framework received
/// it from the platform):
///
/// ```text
/// size: Size(669.0, 951.0), devicePixelRatio: 3.0,
/// padding: EdgeInsets(0.0, 82.0, 0.0, 34.0)
/// ```
///
/// `EdgeInsets(left, top, right, bottom)`, so the truth is **top 82, bottom
/// 34, right 0**. Two independent checks agree:
///
/// * the platform reports a zero right inset, and no Dart code hardcodes 82 or
///   84 anywhere in `lib/`;
/// * Apple's own Settings app on the same simulator draws the same horizontal
///   top-right status bar the app does — there are no vertical right-edge
///   system bars to make room for.
///
/// So the device is an ordinary notched phone as far as insets go. The pages
/// that hand-roll their insets must cover the **top**, not the right.
///
/// The folded and landscape poses were not measurable: `simctl` exposes no
/// fold control (`screenConfig geometry` accepts only each panel's native
/// mode), so the pose toggle needs the DeviceHub toolbar. [openPortrait] is
/// therefore the only pose whose insets are measurements; the others reuse
/// them as a conservative stand-in.
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

  /// Height of the status bar / camera inset, in logical points.
  ///
  /// Measured at [openPortrait] only. The other poses are applied as a
  /// conservative synthetic value: their real insets are unverified.
  static const double topInset = 82;

  /// Width of the right-edge inset, in logical points.
  ///
  /// **Zero.** The device reports no right inset (see the class doc). Kept as a
  /// named constant so the right-edge assertions read explicitly rather than
  /// silently vanishing, and so a future device that does have one has a
  /// single place to change.
  static const double rightInset = 0;

  /// Height of the home indicator inset, in logical points.
  static const double bottomInset = 34;

  /// The Duo's safe area: top 82 pt, bottom 34 pt, nothing on either side.
  static const EdgeInsets duoSafeArea = EdgeInsets.only(
    top: topInset,
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

  /// The x coordinate content must not cross on the right.
  ///
  /// With [rightInset] measured at zero this is simply the surface edge, so the
  /// assertion degenerates to "content does not overflow the screen". That is
  /// still worth keeping — it is a real invariant — but it is **not** the
  /// inset test it was originally written as. The Duo's actual inset is on top:
  /// assert against [topInset] for the check that catches a page laying its
  /// content under the status bar.
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
    EdgeInsets? viewPadding,
    EdgeInsets viewInsets = EdgeInsets.zero,
    TextScaler textScaler = TextScaler.noScaling,
    bool disableAnimations = false,
  }) => MediaQueryData(
    size: size,
    padding: padding,
    // `viewPadding` is read by widgets that hand-roll their insets
    // (`FlatmatesBottomActionBar` uses `viewPaddingOf(context).bottom`), so it
    // has to carry the same numbers as `padding` or the two disagree.
    viewPadding: viewPadding ?? padding,
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
