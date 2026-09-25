import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
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
    _invalidateRelated(item);
  }

  Future<void> cancel(VisitItem item) async {
    await _repository.cancelVisit(item.id);
    _invalidateRelated(item);
  }

  Future<void> reschedule(VisitItem item, DateTime newDate) async {
    await _repository.rescheduleVisit(item.id, newDate);
    _invalidateRelated(item);
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
    _ref.invalidate(visitsListControllerProvider);
    _ref.invalidate(visitsProvider);
    return visitId;
  }

  /// Refreshes both visit lists after a status change.
  void _invalidateRelated(VisitItem item) {
    _ref.invalidate(visitsListControllerProvider);
    _ref.invalidate(visitsProvider);
  }
}

final visitsActionsControllerProvider = Provider<VisitsActionsController>(
  VisitsActionsController.new,
);
