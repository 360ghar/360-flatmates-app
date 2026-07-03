import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chats/application/cursor_list_controller.dart';
import '../visits_repository.dart';

/// Cursor-paginated controller for the user's visits list.
class VisitsListController extends CursorListController<VisitItem> {
  @override
  Future<({List<VisitItem> items, String? nextCursor, bool hasMore})>
  fetchPage({String? cursor}) async {
    return ref.read(visitsRepositoryProvider).fetchVisitsPage(cursor: cursor);
  }

  @override
  bool matchesItem(VisitItem a, VisitItem b) => a.id == b.id;
}

final visitsListControllerProvider =
    NotifierProvider<
      VisitsListController,
      AsyncValue<CursorListState<VisitItem>>
    >(VisitsListController.new);
