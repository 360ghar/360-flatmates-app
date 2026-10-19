import 'package:flatmates_app/features/shared/presentation/flatmates_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The body probe.
///
/// `width: double.infinity` makes it fill whatever width the screen hands it
/// (a bare `SizedBox` collapses to zero under the Scaffold body's loose
/// constraints). The explicit `height` is forced up to the scrollable branch's
/// `minHeight`, so one probe measures both the width cap and the height
/// constraint.
const _probe = Key('duo_probe_probe');

const _probeWidget = SizedBox(key: _probe, width: double.infinity, height: 10);

/// Pumps a [FlatmatesScreen] at an exact logical viewport size.
Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required double height,
  bool scrollable = false,
  EdgeInsetsGeometry? padding,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: FlatmatesScreen(
        scrollable: scrollable,
        padding: padding,
        body: _probeWidget,
      ),
    ),
  );
  // Let the rise animation finish so the probe's geometry is the resting one.
  await tester.pumpAndSettle();
}

void main() {
  // The four iPhone Duo poses, plus 320 dp (the smallest phone the repo
  // supports) and 1200 (past the 1024 wide boundary).
  const foldedPortrait = Size(466, 678);
  const openPortrait = Size(669, 951);
  const foldedLandscape = Size(678, 466);
  const openLandscape = Size(951, 669);

  /// Default scrollable-branch padding is `AppSpacing.horizontalScreen` (16).
  const gutter = 16.0;

  group('phone poses are unchanged by the width cap', () {
    // The non-scrollable branch applies no padding of its own, so the body
    // spans the full viewport. 720 is never reached at these widths.
    for (final size in [
      foldedPortrait,
      openPortrait,
      foldedLandscape,
      const Size(320, 568),
    ]) {
      testWidgets('${size.width}x${size.height} spans the full width', (
        tester,
      ) async {
        await _pump(tester, width: size.width, height: size.height);

        final rect = tester.getRect(find.byKey(_probe));
        expect(rect.width, size.width);
        expect(rect.left, 0);
      });
    }

    testWidgets('466 dp scrollable body keeps its 16 dp gutters', (
      tester,
    ) async {
      await _pump(
        tester,
        width: foldedPortrait.width,
        height: foldedPortrait.height,
        scrollable: true,
      );

      final rect = tester.getRect(find.byKey(_probe));
      expect(rect.width, foldedPortrait.width - gutter * 2);
      expect(rect.left, gutter);
    });

    testWidgets('the SafeArea wrapper is still applied', (tester) async {
      await _pump(tester, width: 466, height: 678);

      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('the rise animation still runs on the body', (tester) async {
      tester.view.physicalSize = const Size(466, 678);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: FlatmatesScreen(body: _probeWidget)),
      );
      // First frame: the body is visible (never faded) but translated down.
      await tester.pump();
      final firstFrame = tester.getTopLeft(find.byKey(_probe)).dy;

      await tester.pumpAndSettle();
      final settled = tester.getTopLeft(find.byKey(_probe)).dy;

      expect(firstFrame, greaterThanOrEqualTo(settled));
      expect(settled, 0);
    });
  });

  group('951 dp open landscape caps the body', () {
    testWidgets('content is centred at 720 dp, not 951', (tester) async {
      await _pump(
        tester,
        width: openLandscape.width,
        height: openLandscape.height,
      );

      final rect = tester.getRect(find.byKey(_probe));
      expect(rect.width, 720);
      // (951 - 720) / 2 = 115.5 of centring.
      expect(rect.left, 115.5);
      expect(rect.width, lessThan(openLandscape.width));
    });

    testWidgets('1023 dp is capped at 720, and the cap lifts at 1024', (
      tester,
    ) async {
      await _pump(tester, width: 1023, height: 800);

      var rect = tester.getRect(find.byKey(_probe));
      expect(rect.width, 720);
      expect(rect.left, (1023 - 720) / 2);

      // From the 1024 wide boundary up the reading column is unbounded, so a
      // desktop viewport is free to use all of it.
      await _pump(tester, width: 1200, height: 800);

      rect = tester.getRect(find.byKey(_probe));
      expect(rect.width, 1200);
      expect(rect.left, 0);
    });

    testWidgets('a page that passes its own padding still looks right', (
      tester,
    ) async {
      const ownPadding = EdgeInsets.symmetric(horizontal: 24);

      await _pump(
        tester,
        width: openLandscape.width,
        height: openLandscape.height,
        padding: ownPadding,
      );

      final rect = tester.getRect(find.byKey(_probe));
      expect(rect.width, 720 - 48);
      expect(rect.left, 115.5 + 24);
    });

    testWidgets('a narrow page with its own padding is not shifted', (
      tester,
    ) async {
      const ownPadding = EdgeInsets.symmetric(horizontal: 24);

      await _pump(tester, width: 466, height: 678, padding: ownPadding);

      final rect = tester.getRect(find.byKey(_probe));
      expect(rect.width, 466 - 48);
      expect(rect.left, 24);
    });
  });

  group('scrollable branch after the cap', () {
    testWidgets('466 dp: minHeight still spans the viewport', (tester) async {
      await _pump(
        tester,
        width: foldedPortrait.width,
        height: foldedPortrait.height,
        scrollable: true,
      );

      final rect = tester.getRect(find.byKey(_probe));
      // No vertical padding, so minHeight = 678 and the probe is stretched.
      expect(rect.height, 678);
      expect(rect.width, foldedPortrait.width - gutter * 2);
    });

    testWidgets('951 dp: the width cap does not shrink the minHeight', (
      tester,
    ) async {
      await _pump(
        tester,
        width: openLandscape.width,
        height: openLandscape.height,
        scrollable: true,
      );

      final rect = tester.getRect(find.byKey(_probe));
      // The LayoutBuilder inside the scrollable branch still sees the full
      // page height, so minHeight is 669 even though the width is capped.
      expect(rect.height, 669);
      expect(rect.width, 720 - gutter * 2);
      expect(rect.left, 115.5 + gutter);
    });

    testWidgets('951 dp: a taller body scrolls instead of being clipped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(951, 669);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: FlatmatesScreen(
            scrollable: true,
            body: SizedBox(key: _probe, width: double.infinity, height: 2000),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rect = tester.getRect(find.byKey(_probe));
      expect(rect.height, 2000);
      expect(rect.width, 720 - gutter * 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a short non-scrollable body is not stretched by the cap', (
      tester,
    ) async {
      await _pump(
        tester,
        width: openLandscape.width,
        height: openLandscape.height,
      );

      // The cap sets a width only, so a body that hugs its content still
      // hugs it: the height constraints are the ones the page rect loosens,
      // exactly as before the cap existed.
      final rect = tester.getRect(find.byKey(_probe));
      expect(rect.height, 10);
      expect(rect.top, 0);
    });
  });
}
