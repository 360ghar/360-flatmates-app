import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/location/presentation/map_widgets.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('MiniMapView', () {
    testWidgets('shows Open in Maps badge and fires onTap on map surface', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        wrap(
          MiniMapView(
            latitude: 28.6139,
            longitude: 77.2090,
            height: 180,
            onTap: () => tapped = true,
          ),
        ),
      );
      // flutter_map may schedule tile loads; settle without waiting forever.
      await tester.pump();

      expect(find.text('Open in Maps'), findsOneWidget);
      expect(find.byKey(const Key('flat_map_open')), findsOneWidget);

      await tester.tap(find.byKey(const Key('flat_map_open')));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('tapping near Open in Maps badge still fires onTap', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 320,
            child: MiniMapView(
              latitude: 28.6139,
              longitude: 77.2090,
              height: 180,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap the top-right corner where the badge sits — hit target is the
      // full-surface InkWell, not the decorative IgnorePointer badge.
      final map = tester.getRect(find.byKey(const Key('flat_map_open')));
      await tester.tapAt(Offset(map.right - 24, map.top + 16));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('without onTap, map is not tappable and badge is hidden', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const MiniMapView(latitude: 28.6139, longitude: 77.2090, height: 140),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('flat_map_open')), findsNothing);
      expect(find.text('Open in Maps'), findsNothing);
    });
  });
}
