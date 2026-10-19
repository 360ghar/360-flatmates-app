import 'package:flatmates_app/features/auth/presentation/enter_phone_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/foldable_surfaces.dart';
import '../../helpers/test_helpers.dart';

/// Guards a defect the iOS 27.1 Duo simulator pass surfaced: in the unfolded
/// portrait pose the app logged
///
/// ```
/// 'package:flutter/src/widgets/scroll_controller.dart': Failed assertion:
/// line 172 pos 12: '_positions.length == 1': ScrollController attached to
/// multiple scroll views.
/// ```
///
/// It is not only a debug banner. `ScrollController.offset` asserts a single
/// attached position, and `hasClients` is true for *any* non-zero count — so
/// the parallax reader (`paper_scene.dart`, `controller.hasClients ?
/// controller.offset : 0.0`) throws a `StateError` in a release build if a
/// second position ever exists. `EnterPhonePage` is the page that shares one
/// controller between a scroll view and the parallax scene, so it is the page
/// to hold to account.
///
/// These tests fold and unfold the real page, with its real controller, across
/// every pose — including the mid-transition frames, which is where a second
/// attachment would appear.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  /// Pumps the real [EnterPhonePage] at [size] with the Duo's insets.
  Future<void> pumpEnterPhone(WidgetTester tester, Size size) async {
    FoldableSurfaces.useSurface(tester, size);
    final widget = await testableWidgetAsync(
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: FoldableSurfaces.duoSafeArea),
          child: const EnterPhonePage(),
        ),
      ),
    );
    await tester.pumpWidget(widget);
    // Past the page rise, so the tree is settled before we resize it.
    await tester.pump(const Duration(milliseconds: 1000));
  }

  /// The controller the page actually attached, read off the live scroll view.
  ScrollController? attachedController(WidgetTester tester) {
    final scrollables = tester.widgetList<Scrollable>(find.byType(Scrollable));
    for (final scrollable in scrollables) {
      final controller = scrollable.controller;
      if (controller != null) return controller;
    }
    return null;
  }

  testWidgets('unfolded portrait lays out without a controller assertion', (
    tester,
  ) async {
    // The pose the simulator pass reported the assertion in.
    await pumpEnterPhone(tester, FoldableSurfaces.openPortrait);

    expect(
      tester.takeException(),
      isNull,
      reason:
          'the unfolded portrait pose must not attach the page '
          'controller to more than one scroll view',
    );

    final controller = attachedController(tester);
    expect(controller, isNotNull, reason: 'the page must have a controller');
    expect(
      controller!.positions.length,
      1,
      reason: 'exactly one scroll position may be attached',
    );
  });

  testWidgets('every pose keeps exactly one attached scroll position', (
    tester,
  ) async {
    await pumpEnterPhone(tester, FoldableSurfaces.foldedPortrait);

    for (final size in FoldableSurfaces.all) {
      await FoldableSurfaces.resizeTo(tester, size);
      expect(
        tester.takeException(),
        isNull,
        reason: 'resizing to $size must not raise',
      );

      final controller = attachedController(tester);
      expect(
        controller,
        isNotNull,
        reason: 'the controller must survive the resize to $size',
      );
      expect(
        controller!.positions.length,
        1,
        reason:
            'the resize to $size must not leave a second attached '
            'position behind',
      );
    }
  });

  testWidgets('a full fold cycle does not accumulate scroll positions', (
    tester,
  ) async {
    await pumpEnterPhone(tester, FoldableSurfaces.foldedPortrait);
    final first = attachedController(tester);
    expect(first, isNotNull);

    // Fold open, read the parallax path, fold back, repeat. A leak would show
    // up as positions.length > 1 on a later pass.
    for (var i = 0; i < 3; i++) {
      await FoldableSurfaces.resizeTo(tester, FoldableSurfaces.openLandscape);
      await FoldableSurfaces.resizeTo(tester, FoldableSurfaces.foldedPortrait);
      expect(
        tester.takeException(),
        isNull,
        reason: 'fold cycle $i must not raise',
      );
    }

    final last = attachedController(tester);
    expect(last, isNotNull);
    expect(
      last!.positions.length,
      1,
      reason: 'three fold cycles must not accumulate positions',
    );
    // The same controller instance throughout: a new one would mean the page
    // state was torn down, which is the bug the reading-column cap used to
    // have.
    expect(
      identical(first, last),
      isTrue,
      reason: 'the page must keep its own controller across folds',
    );
  });
}
