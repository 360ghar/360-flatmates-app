import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chats/application/cursor_list_controller.dart';
import 'blocked_user_model.dart';
import 'blocked_users_repository.dart';

/// Cursor-paginated controller for the user's blocked users.
class BlockedUsersListController extends CursorListController<BlockedUser> {
  @override
  Future<({List<BlockedUser> items, String? nextCursor, bool hasMore})>
  fetchPage({String? cursor}) async {
    return ref
        .read(blockedUsersRepositoryProvider)
        .getBlockedUsersPage(cursor: cursor);
  }

  @override
  bool matchesItem(BlockedUser a, BlockedUser b) =>
      a.blockedUserId == b.blockedUserId;

  /// Unblocks [blockedUserId], then reloads this list and the chat and
  /// likes lists: the unblock restores that user's likes and conversations.
  Future<void> unblock(int blockedUserId) async {
    await ref.read(blockedUsersRepositoryProvider).unblockUser(blockedUserId);
    // refresh(), not invalidateSelf(): a failed reload keeps the rows already
    // on screen instead of dropping the whole list into an error state.
    await refresh();
    // The chat and like lists are off-screen here, so their reloads must not
    // hold up the button spinner or the success toast.
    unawaited(refreshChatListControllers(ref));
  }
}

final blockedUsersListControllerProvider =
    NotifierProvider<
      BlockedUsersListController,
      AsyncValue<CursorListState<BlockedUser>>
    >(BlockedUsersListController.new);
