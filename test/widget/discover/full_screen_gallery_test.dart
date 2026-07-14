import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/discover/presentation/widgets/full_screen_gallery.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

void main() {
  Widget host({required List<String> images, int initialIndex = 0}) {
    return MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              key: const Key('open_gallery'),
              onPressed: () => FullScreenGallery.open(
                context: context,
                images: images,
                initialIndex: initialIndex,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  // Use pump() instead of pumpAndSettle() because FlatmatesNetworkImage
  // loads network images that never complete in the test environment,
  // keeping the frame scheduler busy indefinitely.
  const settleDuration = Duration(milliseconds: 500);

  group('FullScreenGallery', () {
    testWidgets('renders counter and swipes between pages at 1x', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          images: [
            'https://example.com/a.jpg',
            'https://example.com/b.jpg',
            'https://example.com/c.jpg',
          ],
        ),
      );

      // Open the gallery.
      await tester.tap(find.byKey(const Key('open_gallery')));
      await tester.pump();
      await tester.pump(settleDuration);

      // Counter should show "1 / 3".
      expect(find.text('1 / 3'), findsOneWidget);

      // Swipe left to go to the next page.
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 2000);
      await tester.pump();
      await tester.pump(settleDuration);

      // Counter should now show "2 / 3".
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('double-tap zooms in and locks page swipe', (tester) async {
      await tester.pumpWidget(
        host(
          images: ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
        ),
      );

      await tester.tap(find.byKey(const Key('open_gallery')));
      await tester.pump();
      await tester.pump(settleDuration);

      expect(find.text('1 / 2'), findsOneWidget);

      // Double-tap to zoom in.
      await tester.tap(find.byType(PageView));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byType(PageView));
      await tester.pump();
      await tester.pump(settleDuration);

      // After zooming, the page swipe physics should be NeverScrollable.
      // We verify by attempting a fling and checking the counter stays at 1/2.
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 2000);
      await tester.pump();
      await tester.pump(settleDuration);

      // Counter should still be "1 / 2" because swipe is locked while zoomed.
      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets('close button pops the gallery route', (tester) async {
      await tester.pumpWidget(host(images: ['https://example.com/a.jpg']));

      await tester.tap(find.byKey(const Key('open_gallery')));
      await tester.pump();
      await tester.pump(settleDuration);

      // Gallery should be open.
      expect(find.byKey(const Key('gallery_close_button')), findsOneWidget);

      // Tap close.
      await tester.tap(find.byKey(const Key('gallery_close_button')));
      await tester.pump();
      await tester.pump(settleDuration);

      // Gallery should be gone; the host button should be visible again.
      expect(find.byKey(const Key('gallery_close_button')), findsNothing);
      expect(find.byKey(const Key('open_gallery')), findsOneWidget);
    });

    testWidgets('vertical drag at 1x dismisses the gallery', (tester) async {
      await tester.pumpWidget(host(images: ['https://example.com/a.jpg']));

      await tester.tap(find.byKey(const Key('open_gallery')));
      await tester.pump();
      await tester.pump(settleDuration);

      // Fling down hard enough to exceed the dismiss velocity threshold.
      await tester.fling(
        find.byType(FullScreenGallery),
        const Offset(0, 400),
        2000,
      );
      await tester.pump();
      await tester.pump(settleDuration);

      // Gallery should be dismissed.
      expect(find.byType(FullScreenGallery), findsNothing);
      expect(find.byKey(const Key('open_gallery')), findsOneWidget);
    });

    testWidgets('vertical drag while zoomed pans instead of dismissing', (
      tester,
    ) async {
      await tester.pumpWidget(host(images: ['https://example.com/a.jpg']));

      await tester.tap(find.byKey(const Key('open_gallery')));
      await tester.pump();
      await tester.pump(settleDuration);

      // Zoom in first with a double-tap.
      await tester.tap(find.byType(PageView));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byType(PageView));
      await tester.pump();
      await tester.pump(settleDuration);

      // Attempt a vertical drag — while zoomed, the gallery's
      // onVerticalDragUpdate is null so the gesture is claimed by
      // InteractiveViewer (panning) rather than dismissing.
      await tester.fling(
        find.byType(FullScreenGallery),
        const Offset(0, 400),
        2000,
      );
      await tester.pump();
      await tester.pump(settleDuration);

      // Gallery should still be present (not dismissed).
      expect(find.byType(FullScreenGallery), findsOneWidget);
    });
  });
}
