import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/chats/application/cursor_list_controller.dart';
import 'package:flatmates_app/features/visits/application/visits_list_controller.dart';
import 'package:flatmates_app/features/visits/visits_page.dart';
import 'package:flatmates_app/features/visits/visits_repository.dart';

import '../../helpers/test_helpers.dart';

class _FakeVisitsListController extends VisitsListController {
  final List<VisitItem> _items;

  _FakeVisitsListController(this._items);

  @override
  AsyncValue<CursorListState<VisitItem>> build() {
    return AsyncValue.data(
      CursorListState<VisitItem>(items: _items, hasMore: false),
    );
  }

  @override
  Future<({List<VisitItem> items, String? nextCursor, bool hasMore})>
  fetchPage({String? cursor}) async {
    return (items: _items, nextCursor: null, hasMore: false);
  }
}

void main() {
  group('VisitsPage', () {
    testWidgets('renders visits list with status sections', (tester) async {
      final future = DateTime.now().add(const Duration(days: 2));
      final past = DateTime.now().subtract(const Duration(days: 2));

      final visits = [
        VisitItem(
          id: 1,
          propertyTitle: 'Flat A',
          status: 'confirmed',
          scheduledDate: future,
          visitContext: 'flatmate_meet',
          conversationId: 10,
        ),
        VisitItem(
          id: 2,
          propertyTitle: 'Flat B',
          status: 'requested',
          scheduledDate: future,
          visitContext: 'flatmate_meet',
        ),
        VisitItem(
          id: 3,
          propertyTitle: 'Flat C',
          status: 'cancelled',
          scheduledDate: past,
          visitContext: 'flatmate_meet',
        ),
      ];

      await tester.pumpWidget(
        testableWidget(
          overrides: [
            visitsListControllerProvider.overrideWith(
              () => _FakeVisitsListController(visits),
            ),
          ],
          child: const VisitsPage(),
        ),
      );
      // Use pump with a duration instead of pumpAndSettle to avoid
      // timing out on continuous shimmer/loading animations.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Status section headers should be rendered. The status label
      // text may also appear in visit card badges, so use findsWidgets.
      expect(find.text('Confirmed'), findsWidgets);
      expect(find.text('Requested'), findsWidgets);
      expect(find.text('Past'), findsOneWidget);

      // Visit property titles should appear.
      expect(find.text('Flat A'), findsOneWidget);
      expect(find.text('Flat B'), findsOneWidget);
      expect(find.text('Flat C'), findsOneWidget);
    });

    testWidgets('renders empty state when no visits', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          overrides: [
            visitsListControllerProvider.overrideWith(
              () => _FakeVisitsListController(const []),
            ),
          ],
          child: const VisitsPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No visits scheduled yet.'), findsOneWidget);
    });
  });
}
