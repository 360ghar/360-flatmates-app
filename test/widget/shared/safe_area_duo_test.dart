import 'package:flatmates_app/core/theme/app_spacing.dart';
import 'package:flatmates_app/core/widgets/location_selector.dart';
import 'package:flatmates_app/features/auth/presentation/enter_phone_page.dart';
import 'package:flatmates_app/features/auth/presentation/splash_page.dart';
import 'package:flatmates_app/features/profile/profile_page.dart';
import 'package:flatmates_app/features/shared/presentation/components.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

/// The iPhone Duo's safe area, **as measured** on the booted iOS 27.1
/// simulator: the status bar and camera are on the **top** edge (82 dp) and the
/// home indicator is on the bottom (34 dp). There is no right-edge inset.
///
/// This file previously asserted an 84 dp *right-edge* inset on the theory that
/// the Duo moves its system bars to the right edge. That was wrong — see the
/// correction note in `foldable_surfaces.dart`. The assertions below now drive
/// the real inset.
const EdgeInsets _duoInset = EdgeInsets.only(top: 82, bottom: 34);

/// Folded portrait — the pose where the reading column cap (720) does not
/// apply, so a page's content really does reach the screen edges.
const Size _foldedPortrait = Size(466, 678);

/// Open landscape — 951 dp, the pose that renders the 96 dp rail. Content is
/// inside the 720 dp reading column here.
const Size _openLandscape = Size(951, 669);

const double _topInset = 82;
const double _rightInset = 0;
const double _bottomInset = 34;

/// Pumps [page] at an exact logical viewport size with an exact safe area.
///
/// The padding is injected through `MediaQuery.copyWith` so the page reads it
/// from `MediaQuery.paddingOf` exactly as it does on the device, without
/// touching the test view's own padding.
Future<void> _pumpPage(
  WidgetTester tester, {
  required Widget page,
  required Size size,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final widget = await testableWidgetAsync(
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(padding: padding),
        child: page,
      ),
    ),
  );
  await tester.pumpWidget(widget);
  // Past the 320 ms page rise and the splash page's own 800 ms stagger.
  await tester.pump(const Duration(milliseconds: 1000));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('EnterPhonePage — safe-area insets', () {
    // The page opts out of SafeArea (`useSafeArea: false`) so the cut-paper
    // scene can bleed under the status bar, and hand-rolls the insets for the
    // form below it. It compensated bottom only, which left the identifier
    // field and the Continue CTA under the status bar.
    testWidgets('the form stays inside the surface', (tester) async {
      await _pumpPage(
        tester,
        page: const EnterPhonePage(),
        size: _foldedPortrait,
        padding: _duoInset,
      );

      expect(tester.takeException(), isNull);

      // The Duo reports no right inset, so the safe edge is the surface edge.
      const safeRightEdge = 466 - _rightInset;

      final field = tester.getRect(find.byType(TextField));
      expect(field.right, lessThanOrEqualTo(safeRightEdge));
      // Still on screen, not pushed off the left edge.
      expect(field.left, greaterThanOrEqualTo(0));

      final cta = find.byKey(const Key('enter_phone_continue_cta'));
      expect(cta, findsWidgets);
      expect(tester.getRect(cta.first).right, lessThanOrEqualTo(safeRightEdge));
    });

    testWidgets('the page clears the 82 dp TOP inset', (tester) async {
      // The inset that actually bites on this device. The page is full-bleed
      // by design, so the scene bleeds under the status bar and must reserve
      // the inset itself — `PaperSceneHeader` does it with
      // `EdgeInsets.only(top: paddingOf(context).top)`.
      await _pumpPage(
        tester,
        page: const EnterPhonePage(),
        size: _foldedPortrait,
        padding: _duoInset,
      );

      expect(tester.takeException(), isNull);

      // 1. The mechanism is pinned: something in the page reserves exactly the
      //    platform's top inset.
      final reservedTop = tester
          .widgetList<Padding>(find.byType(Padding))
          .map((p) => p.padding)
          .whereType<EdgeInsets>()
          .map((e) => e.top);
      expect(
        reservedTop,
        contains(_topInset),
        reason: 'the scene must reserve the top inset explicitly',
      );

      // 2. And the visible result: the page title sits below the camera.
      final title = find.text('Welcome');
      expect(title, findsOneWidget);
      expect(
        tester.getRect(title).top,
        greaterThanOrEqualTo(_topInset),
        reason: 'the title must not sit under the status bar',
      );
    });

    testWidgets('the form reserves the bottom inset', (tester) async {
      await _pumpPage(
        tester,
        page: const EnterPhonePage(),
        size: _foldedPortrait,
        padding: _duoInset,
      );

      final paddings = tester
          .widgetList<Padding>(
            find.descendant(
              of: find.byType(AutofillGroup),
              matching: find.byType(Padding),
            ),
          )
          .map((p) => p.padding)
          .whereType<EdgeInsets>();

      // The form's own padding carries the bottom inset on top of the 16 dp
      // gutter. This is the exact padding the running app applied on the Duo
      // simulator: EdgeInsets(16.0, 16.0, 16.0, 58.0).
      expect(
        paddings,
        contains(
          const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.base,
            AppSpacing.screen + _rightInset,
            AppSpacing.lg + _bottomInset,
          ),
        ),
      );
    });

    testWidgets('466 dp with no insets is unchanged', (tester) async {
      await _pumpPage(
        tester,
        page: const EnterPhonePage(),
        size: _foldedPortrait,
      );

      // The pre-change geometry: the CTA spans the 16 dp page gutters and
      // nothing else. A viewport with no insets must not gain any.
      final cta = find.byKey(const Key('enter_phone_continue_cta'));
      expect(cta, findsWidgets);
      final rect = tester.getRect(cta.first);
      expect(rect.left, AppSpacing.screen);
      expect(rect.right, _foldedPortrait.width - AppSpacing.screen);
    });

    testWidgets('the same page clears the inset in the open landscape pose', (
      tester,
    ) async {
      // Not the discriminating case — at 951 dp the 720 dp reading column is
      // centred with 115 dp of margin either side, so it clears the inset even
      // without the form's own compensation. The folded pose above is where
      // the fix matters; this pins that the open pose is not made worse.
      await _pumpPage(
        tester,
        page: const EnterPhonePage(),
        size: _openLandscape,
        padding: _duoInset,
      );

      expect(tester.takeException(), isNull);
      final field = tester.getRect(find.byType(TextField));
      expect(
        field.right,
        lessThanOrEqualTo(_openLandscape.width - _rightInset),
      );
    });
  });

  group('SplashPage — right-edge inset', () {
    // This page also opts out of SafeArea, but its two inner SafeAreas cover
    // left/right themselves: the brand block uses `SafeArea(bottom: false)`
    // and the bottom strip `SafeArea(top: false)`. Verified rather than
    // changed — the assertions below are exact, so they fail if either
    // SafeArea stops covering the horizontal insets.
    testWidgets('the brand block is centred inside the safe box', (
      tester,
    ) async {
      await _pumpPage(
        tester,
        page: const SplashPage(),
        size: _foldedPortrait,
        padding: _duoInset,
      );

      expect(tester.takeException(), isNull);

      final locale = lookupAppLocalizations(const Locale('en'));
      final tagline = find.text(
        '${locale.splashTaglineLine1}\n${locale.splashTaglineLine2}',
      );
      expect(tagline, findsOneWidget);
      // Centred in 0..(466 - 84), not in 0..466.
      expect(
        tester.getRect(tagline).center.dx,
        closeTo((_foldedPortrait.width - _rightInset) / 2, 1),
      );
    });

    testWidgets('the progress strip is centred inside the safe box', (
      tester,
    ) async {
      await _pumpPage(
        tester,
        page: const SplashPage(),
        size: _foldedPortrait,
        padding: _duoInset,
      );

      final bar = find.byType(LinearProgressIndicator);
      expect(bar, findsOneWidget);
      expect(
        tester.getRect(bar).center.dx,
        closeTo((_foldedPortrait.width - _rightInset) / 2, 1),
      );
    });

    testWidgets('466 dp with no insets is unchanged', (tester) async {
      await _pumpPage(tester, page: const SplashPage(), size: _foldedPortrait);

      final bar = find.byType(LinearProgressIndicator);
      expect(bar, findsOneWidget);
      expect(tester.getRect(bar).center.dx, closeTo(466 / 2, 1));
    });
  });

  group('LocationSelector label cap', () {
    test('a phone keeps the 160 dp cap and a wide bar lifts it', () {
      expect(LocationSelector.labelCap(320), 160);
      expect(LocationSelector.labelCap(466), 233);
      expect(LocationSelector.labelCap(600), 300);
      // Capped at half the reading column above 720.
      expect(LocationSelector.labelCap(855), 360);
      expect(LocationSelector.labelCap(1200), 360);
    });

    // A 41-character locality: 533 px of text at the label's 13 px size in
    // the test font, so it truncates under any cap below that.
    const longLocality = 'Koramangala 5th Block, Bengaluru, Karnat';

    Future<void> pumpBar(
      WidgetTester tester, {
      required double width,
      bool nestedRow = false,
    }) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const pill = LocationSelector(displayText: longLocality);
      await tester.pumpWidget(
        testableWidget(
          child: Scaffold(
            body: Row(
              children: [
                // A bar hands a non-flex child an unbounded width. That is the
                // shape a `Flexible` cap would assert on, so it is the shape
                // this test pins.
                if (nestedRow)
                  const Row(mainAxisSize: MainAxisSize.min, children: [pill])
                else ...[
                  const Spacer(),
                  pill,
                ],
              ],
            ),
          ),
        ),
      );
    }

    Finder label() => find.descendant(
      of: find.byType(LocationSelector),
      matching: find.byType(Text),
    );

    testWidgets('320 dp still ellipsizes inside 160 dp, without overflow', (
      tester,
    ) async {
      await pumpBar(tester, width: 320);

      expect(tester.takeException(), isNull);
      expect(tester.getSize(label()).width, 160);
      expect(tester.widget<Text>(label()).overflow, TextOverflow.ellipsis);
      expect(
        tester.getRect(find.byType(LocationSelector)).right,
        lessThanOrEqualTo(320),
      );
    });

    testWidgets('855 dp shows more of the location than 160 dp would allow', (
      tester,
    ) async {
      await pumpBar(tester, width: 855);

      expect(tester.takeException(), isNull);
      final width = tester.getSize(label()).width;
      expect(width, greaterThan(160));
      expect(width, 360);
      expect(
        tester.getRect(find.byType(LocationSelector)).right,
        lessThanOrEqualTo(855),
      );
    });

    testWidgets('an unbounded bar does not assert', (tester) async {
      await pumpBar(tester, width: 855, nestedRow: true);

      // The width-derived cap holds in an unbounded parent, where a flex
      // child would throw "non-zero flex but incoming width constraints are
      // unbounded".
      expect(tester.takeException(), isNull);
      expect(tester.getSize(label()).width, 360);
    });
  });

  group('ProfilePage menu cards at 720 dp', () {
    testWidgets('menu rows stay leading-aligned inside the reading column', (
      tester,
    ) async {
      await _pumpPage(
        tester,
        page: const ProfilePage(),
        size: _openLandscape,
        padding: _duoInset,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final locale = lookupAppLocalizations(const Locale('en'));
      final label = find.text(locale.profileMenuPostListing);
      expect(label, findsOneWidget);

      final card = tester.getRect(
        find.ancestor(of: label, matching: find.byType(FlatmatesCard)).first,
      );
      final row = tester.getRect(label);

      // The card is the 720 dp reading column minus the page gutters. The
      // page-level SafeArea reserves the 84 dp right inset first, so the
      // column is centred in the remaining 867 dp, not in the full 951.
      expect(card.width, closeTo(720 - AppSpacing.screen * 2, 1));
      expect(
        card.left,
        closeTo((951 - _rightInset - 720) / 2 + AppSpacing.screen, 1),
      );

      // The label hugs the card's leading edge (16 dp padding + 32 dp icon
      // slot + 12 dp gap = 60 dp), so the row still reads as a list row
      // rather than as two distant islands.
      expect(row.left - card.left, closeTo(60, 1));
    });
  });
}
