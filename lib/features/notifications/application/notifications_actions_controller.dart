import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      _reloadKeepingList();
    } catch (e) {
      debugPrint('NotificationsActionsController.markRead: $e');
      rethrow;
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllAsRead();
      _reloadKeepingList();
    } catch (e) {
      debugPrint('NotificationsActionsController.markAllRead: $e');
      rethrow;
    }
  }

  /// Reloads the first page while the current list stays on screen.
  /// Invalidating would drop to the loading state and flash the skeleton.
  void _reloadKeepingList() {
    unawaited(
      _ref.read(notificationsListControllerProvider.notifier).refresh(),
    );
  }
}

final notificationsActionsControllerProvider =
    Provider<NotificationsActionsController>(
      NotificationsActionsController.new,
    );
