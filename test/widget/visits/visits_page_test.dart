import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/domain/wire_enums.dart';
import 'package:flatmates_app/features/chats/application/cursor_list_controller.dart';
import 'package:flatmates_app/features/visits/application/visits_list_controller.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_button.dart';
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

/// Keeps what the page sends to the cancel route; no network.
class _RecordingVisitsRepository extends VisitsRepository {
  _RecordingVisitsRepository(super.ref, this.cancelled);

  final List<({int id, String reason})> cancelled;

  @override
  Future<List<VisitItem>> fetchVisits() async => const [];

  @override
  Future<VisitItem> cancelVisit(int visitId, {required String reason}) async {
    cancelled.add((id: visitId, reason: reason));
    return VisitItem(
      id: visitId,
      propertyTitle: 'Flat B',
      status: VisitStatus.cancelled,
      scheduledDate: DateTime.now().add(const Duration(days: 2)),
      visitContext: VisitContext.flatmateMeet,
      cancellationReason: reason,
    );
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
          status: VisitStatus.confirmed,
          scheduledDate: future,
          visitContext: VisitContext.flatmateMeet,
          conversationId: 10,
        ),
        VisitItem(
          id: 2,
          propertyTitle: 'Flat B',
          status: VisitStatus.requested,
          scheduledDate: future,
          visitContext: VisitContext.flatmateMeet,
        ),
        VisitItem(
          id: 3,
          propertyTitle: 'Flat C',
          status: VisitStatus.cancelled,
          scheduledDate: past,
          visitContext: VisitContext.flatmateMeet,
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

    testWidgets('cancel asks for a reason and posts it to the cancel route', (
      tester,
    ) async {
      final future = DateTime.now().add(const Duration(days: 2));
      final cancelled = <({int id, String reason})>[];

      await tester.pumpWidget(
        testableWidget(
          overrides: [
            visitsListControllerProvider.overrideWith(
              () => _FakeVisitsListController([
                VisitItem(
                  id: 2,
                  propertyTitle: 'Flat B',
                  status: VisitStatus.requested,
                  scheduledDate: future,
                  visitContext: VisitContext.flatmateMeet,
                ),
              ]),
            ),
            visitsRepositoryProvider.overrideWith(
              (ref) => _RecordingVisitsRepository(ref, cancelled),
            ),
          ],
          child: const VisitsPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Cancel visit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The cancel route refuses an empty reason: Confirm stays disabled.
      final confirm = find.byKey(const Key('visit_cancel_dialog_confirm'));
      expect(tester.widget<FlatmatesButton>(confirm).onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('visit_cancel_reason_field')),
        '  Plans changed  ',
      );
      await tester.pump();
      expect(tester.widget<FlatmatesButton>(confirm).onPressed, isNotNull);

      await tester.tap(confirm);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(cancelled, [(id: 2, reason: 'Plans changed')]);
    });

    testWidgets('backing out of the cancel dialog sends nothing', (
      tester,
    ) async {
      final future = DateTime.now().add(const Duration(days: 2));
      final cancelled = <({int id, String reason})>[];

      await tester.pumpWidget(
        testableWidget(
          overrides: [
            visitsListControllerProvider.overrideWith(
              () => _FakeVisitsListController([
                VisitItem(
                  id: 2,
                  propertyTitle: 'Flat B',
                  status: VisitStatus.requested,
                  scheduledDate: future,
                  visitContext: VisitContext.flatmateMeet,
                ),
              ]),
            ),
            visitsRepositoryProvider.overrideWith(
              (ref) => _RecordingVisitsRepository(ref, cancelled),
            ),
          ],
          child: const VisitsPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Cancel visit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('visit_cancel_dialog_back')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(cancelled, isEmpty);
    });
  });
}
