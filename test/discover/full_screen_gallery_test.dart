import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/discover/presentation/widgets/full_screen_gallery.dart';

import '../helpers/test_helpers.dart';

void main() {
  const images = ['https://example.com/a.jpg', 'https://example.com/b.jpg'];

  Future<void> pumpGallery(WidgetTester tester) async {
    await tester.pumpWidget(
      testableWidget(
        child: const FullScreenGallery(images: images, initialIndex: 0),
      ),
    );
    await tester.pump();
  }

  Future<void> doubleTapImage(WidgetTester tester) async {
    final center = tester.getCenter(find.byType(InteractiveViewer));
    await tester.tapAt(center);
    await tester.pump(kDoubleTapMinTime + const Duration(milliseconds: 20));
    await tester.tapAt(center);
    // Let the zoom animation finish and the zoom state propagate. The first
    // pump starts the ticker, the rest drive it past completion.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
  }

  testWidgets('renders counter and swipes between pages at 1x', (tester) async {
    await pumpGallery(tester);

    expect(find.text('1 / 2'), findsOneWidget);
    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.physics, isA<PageScrollPhysics>());
  });

  testWidgets('double-tap zooms in and locks page swipe', (tester) async {
    await pumpGallery(tester);

    await doubleTapImage(tester);

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.physics, isA<NeverScrollableScrollPhysics>());

    // Double-tap again zooms back out and re-enables paging.
    await tester.pump(const Duration(milliseconds: 400));
    await doubleTapImage(tester);

    final pageViewAfter = tester.widget<PageView>(find.byType(PageView));
    expect(pageViewAfter.physics, isA<PageScrollPhysics>());
  });

  Future<void> openGalleryRoute(WidgetTester tester) async {
    await tester.pumpWidget(
      testableWidget(
        child: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  FullScreenGallery.open(context: context, images: images),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('gallery_close_button')), findsOneWidget);
  }

  testWidgets('close button pops the gallery route', (tester) async {
    await openGalleryRoute(tester);

    await tester.tap(find.byKey(const Key('gallery_close_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('gallery_close_button')), findsNothing);
  });

  testWidgets('vertical drag at 1x dismisses the gallery', (tester) async {
    await openGalleryRoute(tester);

    await tester.drag(
      find.byType(PageView),
      const Offset(0, 200),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('gallery_close_button')), findsNothing);
  });

  testWidgets('vertical drag while zoomed pans instead of dismissing', (
    tester,
  ) async {
    await openGalleryRoute(tester);

    await doubleTapImage(tester);
    await tester.drag(
      find.byType(PageView),
      const Offset(0, 200),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('gallery_close_button')), findsOneWidget);
  });
}
