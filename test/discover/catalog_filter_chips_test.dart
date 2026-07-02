import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/discover/presentation/widgets/search_filter_widgets.dart';

Widget _harness(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets(
    'assigns stable, unique keys when the catalog lists colliding private ids',
    (tester) async {
      // 'private_room' and 'master_bedroom' both normalize to 'private'.
      // Without uniqueness-aware keys this renders two widgets with the same
      // Key and Flutter throws "Duplicate keys found".
      await tester.pumpWidget(
        _harness(
          CatalogFilterChips(
            keyPrefix: 'search_room_type',
            anyKey: 'any',
            selectedId: 'any',
            onSelected: (_) {},
            options: const [
              (id: 'any', label: 'Any'),
              (id: 'private_room', label: 'Private room'),
              (id: 'master_bedroom', label: 'Master bedroom'),
              (id: 'shared_room', label: 'Shared room'),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // The Maestro selector still resolves to the first private chip.
      expect(find.byKey(const Key('search_room_type_private')), findsOneWidget);
      expect(find.byKey(const Key('search_room_type_any')), findsOneWidget);
      expect(find.byKey(const Key('search_room_type_shared')), findsOneWidget);
    },
  );

  testWidgets(
    'disambiguates the any / no-preference collision without throwing',
    (tester) async {
      // Both 'any' (== anyKey) and 'no_preference' normalize to 'any'.
      await tester.pumpWidget(
        _harness(
          CatalogFilterChips(
            keyPrefix: 'search_room_type',
            anyKey: 'any',
            selectedId: 'any',
            onSelected: (_) {},
            options: const [
              (id: 'any', label: 'Any'),
              (id: 'no_preference', label: 'No preference'),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('search_room_type_any')), findsOneWidget);
    },
  );
}
