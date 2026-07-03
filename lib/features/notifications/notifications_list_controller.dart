import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chats/application/cursor_list_controller.dart';
import 'notifications_repository.dart';

/// Cursor-paginated controller for the user's notifications feed.
class NotificationsListController
    extends CursorListController<NotificationModel> {
  @override
  Future<({List<NotificationModel> items, String? nextCursor, bool hasMore})>
  fetchPage({String? cursor}) async {
    return ref
        .read(notificationsRepositoryProvider)
        .fetchNotificationsPage(cursor: cursor);
  }

  @override
  bool matchesItem(NotificationModel a, NotificationModel b) => a.id == b.id;
}

final notificationsListControllerProvider =
    NotifierProvider<
      NotificationsListController,
      AsyncValue<CursorListState<NotificationModel>>
    >(NotificationsListController.new);
