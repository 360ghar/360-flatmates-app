import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/chats/application/cursor_list_controller.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/chats/conversations_page.dart';

import '../../helpers/test_helpers.dart';

/// A fake [ConversationsListController] that returns an empty page without
/// touching the repository, so the tab renders its empty state.
class _EmptyConversationsController extends ConversationsListController {
  @override
  AsyncValue<CursorListState<ConversationSummaryModel>> build() {
    return const AsyncValue.data(
      CursorListState<ConversationSummaryModel>(items: [], hasMore: false),
    );
  }

  @override
  Future<
    ({List<ConversationSummaryModel> items, String? nextCursor, bool hasMore})
  >
  fetchPage({String? cursor}) async {
    return (
      items: const <ConversationSummaryModel>[],
      nextCursor: null,
      hasMore: false,
    );
  }
}

class _EmptyIncomingLikesController extends IncomingLikesController {
  @override
  AsyncValue<CursorListState<IncomingLikeModel>> build() {
    return const AsyncValue.data(
      CursorListState<IncomingLikeModel>(items: [], hasMore: false),
    );
  }

  @override
  Future<({List<IncomingLikeModel> items, String? nextCursor, bool hasMore})>
  fetchPage({String? cursor}) async {
    return (
      items: const <IncomingLikeModel>[],
      nextCursor: null,
      hasMore: false,
    );
  }
}

class _EmptyOutgoingLikesController extends OutgoingLikesController {
  @override
  AsyncValue<CursorListState<OutgoingLikeModel>> build() {
    return const AsyncValue.data(
      CursorListState<OutgoingLikeModel>(items: [], hasMore: false),
    );
  }

  @override
  Future<({List<OutgoingLikeModel> items, String? nextCursor, bool hasMore})>
  fetchPage({String? cursor}) async {
    return (
      items: const <OutgoingLikeModel>[],
      nextCursor: null,
      hasMore: false,
    );
  }
}

void main() {
  group('ConversationsPage', () {
    testWidgets('renders three tabs (chats, likes, liked)', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          overrides: [
            conversationsListControllerProvider.overrideWith(
              _EmptyConversationsController.new,
            ),
            incomingLikesListControllerProvider.overrideWith(
              _EmptyIncomingLikesController.new,
            ),
            outgoingLikesListControllerProvider.overrideWith(
              _EmptyOutgoingLikesController.new,
            ),
          ],
          child: const ConversationsPage(),
        ),
      );

      // The segmented control renders three tab keys.
      expect(find.byKey(const Key('chats_chats_tab')), findsOneWidget);
      expect(find.byKey(const Key('chats_likes_tab')), findsOneWidget);
      expect(find.byKey(const Key('chats_liked_tab')), findsOneWidget);

      // Use pump instead of pumpAndSettle to avoid timing out on
      // continuous shimmer/loading animations from FlatmatesScreen.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
