import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/chats/application/cursor_list_controller.dart';
import 'package:flatmates_app/features/notifications/notifications_list_controller.dart';
import 'package:flatmates_app/features/notifications/notifications_page.dart';
import 'package:flatmates_app/features/notifications/notifications_repository.dart';

import '../../helpers/test_helpers.dart';

class _FakeNotificationsListController extends NotificationsListController {
  final List<NotificationModel> _items;

  _FakeNotificationsListController(this._items);

  @override
  AsyncValue<CursorListState<NotificationModel>> build() {
    return AsyncValue.data(
      CursorListState<NotificationModel>(items: _items, hasMore: false),
    );
  }

  @override
  Future<({List<NotificationModel> items, String? nextCursor, bool hasMore})>
  fetchPage({String? cursor}) async {
    return (items: _items, nextCursor: null, hasMore: false);
  }
}

void main() {
  group('NotificationsPage', () {
    testWidgets('renders notifications list with mark-all-read button', (
      tester,
    ) async {
      final notifications = [
        NotificationModel(
          id: 'notif-1',
          type: 'new_match',
          title: 'New Match',
          body: 'You have a new match!',
          isRead: false,
          createdAt: DateTime(2025, 5, 16, 9),
        ),
      ];

      await tester.pumpWidget(
        testableWidget(
          overrides: [
            notificationsListControllerProvider.overrideWith(
              () => _FakeNotificationsListController(notifications),
            ),
          ],
          child: const NotificationsPage(),
        ),
      );
      // Use pump with a duration instead of pumpAndSettle to avoid
      // timing out on continuous shimmer/loading animations.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The mark-all-read button in the app bar.
      expect(
        find.byKey(const Key('notification_mark_all_read')),
        findsOneWidget,
      );
      // The notification card title.
      expect(find.text('New Match'), findsOneWidget);
    });

    testWidgets('renders empty state when no notifications', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          overrides: [
            notificationsListControllerProvider.overrideWith(
              () => _FakeNotificationsListController(const []),
            ),
          ],
          child: const NotificationsPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No notifications yet.'), findsOneWidget);
    });
  });
}
