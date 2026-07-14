import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chats_repository.dart';
import 'cursor_list_controller.dart';

class ChatActionsController {
  ChatActionsController(this._ref);
  final Ref _ref;

  ChatsRepository get _repository => _ref.read(chatsRepositoryProvider);

  Future<void> blockUser(int peerId) async {
    await _repository.blockUser(peerId);
    // Blocking removes the conversation and any pending likes from the peer,
    // so refresh the lists the user returns to after blocking.
    await invalidateChatListControllers(_ref);
    _ref.invalidate(conversationsProvider);
    _ref.invalidate(incomingLikesProvider);
    _ref.invalidate(outgoingLikesProvider);
  }

  Future<void> reportUser(int peerId, String reason) async {
    await _repository.reportUser(peerId, reason);
  }

  Future<void> unmatchConversation(int conversationId, int peerId) async {
    await _repository.unmatchConversation(conversationId, peerId);
    // Unmatching drops the conversation; refresh so the stale row disappears.
    await invalidateChatListControllers(_ref);
    _ref.invalidate(conversationsProvider);
    _ref.invalidate(incomingLikesProvider);
    _ref.invalidate(outgoingLikesProvider);
  }

  /// Submits QnA answers and returns the refreshed conversation, or null
  /// on failure. Keeps repository calls out of the page layer.
  Future<ConversationSummaryModel?> submitQnA(
    int conversationId,
    Map<String, String> answers,
  ) async {
    try {
      await _repository.submitQnA(conversationId, answers);
      final updated = await _repository.fetchConversation(conversationId);
      _ref.invalidate(conversationProvider(conversationId));
      return updated;
    } catch (e) {
      debugPrint('ChatActionsController.submitQnA failed: $e');
      return null;
    }
  }

  /// Returns the new conversation id, or null if the backend created none.
  Future<int?> matchIncomingLike({
    required int peerId,
    int? contextPropertyId,
  }) async {
    final conversationId = await _repository.matchIncomingLike(
      peerId: peerId,
      contextPropertyId: contextPropertyId,
    );
    await invalidateChatListControllers(_ref);
    _ref.invalidate(incomingLikesProvider);
    _ref.invalidate(conversationsProvider);
    return conversationId;
  }
}

final chatActionsControllerProvider = Provider<ChatActionsController>(
  ChatActionsController.new,
);
