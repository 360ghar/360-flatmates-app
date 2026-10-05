import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../chats/application/cursor_list_controller.dart';
import '../visits_repository.dart';
import 'visits_list_controller.dart';

/// Application-layer controller for visit mutations (confirm / cancel /
/// reschedule). Keeps business logic + provider invalidation out of the
/// widget layer (see CLAUDE.md "Business logic in controllers").
class VisitsActionsController {
  VisitsActionsController(this._ref);

  final Ref _ref;

  VisitsRepository get _repository => _ref.read(visitsRepositoryProvider);

  Future<void> confirm(VisitItem item) async {
    await _repository.confirmVisit(item.id);
    _refreshRelated();
  }

  Future<void> cancel(VisitItem item) async {
    await _repository.cancelVisit(item.id);
    _refreshRelated();
  }

  Future<void> reschedule(VisitItem item, DateTime newDate) async {
    await _repository.rescheduleVisit(item.id, newDate);
    _refreshRelated();
  }

  /// Requests a visit and posts the chat notification, then refreshes the
  /// visit lists. Returns the new visit id. Throws on failure.
  Future<int> schedule({
    required int propertyId,
    required int counterpartyUserId,
    required int conversationId,
    required DateTime scheduledDate,
    required AppLocalizations locale,
    String? note,
    String? timeSlotLabel,
  }) async {
    final visitId = await _repository.scheduleVisitAndNotify(
      propertyId: propertyId,
      counterpartyUserId: counterpartyUserId,
      conversationId: conversationId,
      scheduledDate: scheduledDate,
      locale: locale,
      note: note,
      timeSlotLabel: timeSlotLabel,
    );
    _refreshRelated();
    // The visit request posts a `visit_request` chat message, so the
    // conversation list's preview and timestamp are stale. Refresh it in place
    // (`refreshKeepingList`) instead of invalidating it: a failed refetch keeps
    // the conversations already on screen rather than dropping the list.
    unawaited(refreshKeepingList(_ref, conversationsListControllerProvider));
    return visitId;
  }

  /// Refreshes the visit data after a status change.
  ///
  /// [visitsProvider] is a `FutureProvider`, which keeps its previous value
  /// while the refetch is in flight, so invalidating it is safe. The cursor
  /// list is refreshed in place (`refreshKeepingList`) so a failed reload
  /// leaves the rows on screen instead of blanking the visits page.
  ///
  /// The list reload is deliberately not awaited: the callers gate a toast or
  /// navigation on this method, so blocking on a network round trip would stall
  /// them (same pattern as NotificationsActionsController).
  void _refreshRelated() {
    _ref.invalidate(visitsProvider);
    unawaited(refreshKeepingList(_ref, visitsListControllerProvider));
  }
}

final visitsActionsControllerProvider = Provider<VisitsActionsController>(
  VisitsActionsController.new,
);
