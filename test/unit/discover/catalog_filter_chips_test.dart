import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/discover/presentation/widgets/search_filter_widgets.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('CatalogFilterChips keys', () {
    testWidgets(
      'assigns stable, unique keys when the catalog lists colliding private ids',
      (tester) async {
        // private_room and master_bedroom both collapse to "private" suffix.
        // With a keyPrefix, the first keeps the clean key; the second falls
        // back to its raw id so no duplicate key is generated.
        final options = <({String id, String label})>[
          (id: 'private_room', label: 'Private Room'),
          (id: 'master_bedroom', label: 'Master Bedroom'),
          (id: 'shared_room', label: 'Shared Room'),
        ];

        await tester.pumpWidget(
          wrap(
            CatalogFilterChips(
              options: options,
              selectedId: 'private_room',
              anyKey: 'any',
              keyPrefix: 'search_room_type',
              onSelected: (_) {},
            ),
          ),
        );

        // If duplicate keys existed, Flutter would throw during pump.
        // Verify all three chips rendered.
        expect(find.byType(CatalogFilterChips), findsOneWidget);
        expect(find.text('Private Room'), findsOneWidget);
        expect(find.text('Master Bedroom'), findsOneWidget);
        expect(find.text('Shared Room'), findsOneWidget);
      },
    );

    testWidgets(
      'disambiguates the any / no-preference collision without throwing',
      (tester) async {
        // "any" (the anyKey) and "no_preference" both map to the "any" suffix.
        // The chip widget must not throw a duplicate key error.
        final options = <({String id, String label})>[
          (id: 'any', label: 'Any'),
          (id: 'no_preference', label: 'No Preference'),
        ];

        await tester.pumpWidget(
          wrap(
            CatalogFilterChips(
              options: options,
              selectedId: 'any',
              anyKey: 'any',
              keyPrefix: 'search_room_type',
              onSelected: (_) {},
            ),
          ),
        );

        expect(find.byType(CatalogFilterChips), findsOneWidget);
        expect(find.text('Any'), findsOneWidget);
        expect(find.text('No Preference'), findsOneWidget);
      },
    );
  });
}
