import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chats/application/cursor_list_controller.dart';
import '../notifications_list_controller.dart';
import '../notifications_repository.dart';

/// Application-layer controller for notification mutations (mark read /
/// mark all read). Keeps repository calls + invalidation out of the widget
/// layer (see CLAUDE.md "Business logic in controllers").
class NotificationsActionsController {
  NotificationsActionsController(this._ref);

  final Ref _ref;

  NotificationsRepository get _repository =>
      _ref.read(notificationsRepositoryProvider);

  Future<void> markRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      _markLocally((list) => list.markReadLocally(notificationId));
      _reloadKeepingList();
    } catch (e) {
      debugPrint('NotificationsActionsController.markRead: $e');
      rethrow;
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllAsRead();
      _markLocally((list) => list.markAllReadLocally());
      _reloadKeepingList();
    } catch (e) {
      debugPrint('NotificationsActionsController.markAllRead: $e');
      rethrow;
    }
  }

  /// Applies the server-confirmed read state to the cached list before the
  /// refetch. [refreshKeepingList] keeps the current rows when the refetch
  /// fails, so without this the badges would flip back to unread and the
  /// mark-all action would stay enabled.
  ///
  /// No-op when the list is not alive — there is nothing cached to update.
  void _markLocally(void Function(NotificationsListController) apply) {
    if (!_ref.exists(notificationsListControllerProvider)) return;
    apply(_ref.read(notificationsListControllerProvider.notifier));
  }

  /// Reloads the first page in place, keeping the rows on screen (see
  /// [refreshKeepingList]).
  ///
  /// Deliberately not awaited: `markRead` gates the tap-through navigation on
  /// this call, so blocking on a network round trip would stall the push.
  void _reloadKeepingList() {
    unawaited(refreshKeepingList(_ref, notificationsListControllerProvider));
  }
}

final notificationsActionsControllerProvider =
    Provider<NotificationsActionsController>(
      NotificationsActionsController.new,
    );
