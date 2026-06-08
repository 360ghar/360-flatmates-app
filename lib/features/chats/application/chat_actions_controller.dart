import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chats_repository.dart';

class ChatActionsController {
  ChatActionsController(this._repository);
  final ChatsRepository _repository;

  Future<void> blockUser(int peerId) async {
    await _repository.blockUser(peerId);
  }

  Future<void> reportUser(int peerId, String reason) async {
    await _repository.reportUser(peerId, reason);
  }

  Future<void> unmatchConversation(int conversationId, int peerId) async {
    await _repository.unmatchConversation(conversationId, peerId);
  }
}

final chatActionsControllerProvider = Provider<ChatActionsController>((ref) {
  return ChatActionsController(ref.read(chatsRepositoryProvider));
});
