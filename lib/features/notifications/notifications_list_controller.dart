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

  /// Marks every cached notification read in place.
  ///
  /// The actions controller applies this before its post-mutation refetch, so
  /// a refetch that fails keeps the visible result: [CursorListController.load]
  /// retains the current rows on error, and the unread badges stay cleared
  /// instead of flipping back.
  void markAllReadLocally() => _mapItems(_asRead);

  /// Marks the cached notification with [notificationId] read in place.
  void markReadLocally(String notificationId) =>
      _mapItems((n) => n.id == notificationId ? _asRead(n) : n);

  void _mapItems(NotificationModel Function(NotificationModel) transform) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      current.copyWith(items: current.items.map(transform).toList()),
    );
  }
}

/// The same notification with `isRead` set. [NotificationModel] has no
/// `copyWith`, and the read flag is the only field this feature mutates.
NotificationModel _asRead(NotificationModel n) => NotificationModel(
  id: n.id,
  type: n.type,
  title: n.title,
  body: n.body,
  isRead: true,
  createdAt: n.createdAt,
  referenceId: n.referenceId,
  route: n.route,
);

final notificationsListControllerProvider =
    NotifierProvider<
      NotificationsListController,
      AsyncValue<CursorListState<NotificationModel>>
    >(NotificationsListController.new);
