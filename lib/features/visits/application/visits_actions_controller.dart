import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// Refreshes the visits list and, when known, the originating conversation
  /// thread so a visit-status change is reflected in chat too.
  void _invalidateRelated(VisitItem item) {
    _ref.invalidate(visitsListControllerProvider);
    _ref.invalidate(visitsProvider);
    final conversationId = item.conversationId;
    if (conversationId != null) {}
  }
}

final visitsActionsControllerProvider = Provider<VisitsActionsController>(
  VisitsActionsController.new,
);
