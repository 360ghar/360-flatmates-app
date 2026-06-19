import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chats/application/cursor_list_controller.dart';
import 'blocked_user_model.dart';
import 'blocked_users_repository.dart';

/// Cursor-paginated controller for the user's blocked users.
class BlockedUsersListController extends CursorListController<BlockedUser> {
  @override
  Future<
      ({
        List<BlockedUser> items,
        String? nextCursor,
        bool hasMore,
      })> fetchPage({String? cursor}) async {
    return ref
        .read(blockedUsersRepositoryProvider)
        .getBlockedUsersPage(cursor: cursor);
  }
}

final blockedUsersListControllerProvider = NotifierProvider<
    BlockedUsersListController, AsyncValue<CursorListState<BlockedUser>>>(
  BlockedUsersListController.new,
);
