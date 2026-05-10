import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/bootstrap_controller.dart';
import '../chats_repository.dart';

class MessagesState {
  const MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.pendingMessage,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final Object? error;
  final ChatMessage? pendingMessage;

  bool get hasError => error != null;

  MessagesState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    Object? error,
    bool clearError = false,
    ChatMessage? pendingMessage,
    bool clearPending = false,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
      pendingMessage: clearPending
          ? null
          : (pendingMessage ?? this.pendingMessage),
    );
  }
}

class MessagesController extends FamilyNotifier<MessagesState, int> {
  int _currentUserId = 0;

  @override
  MessagesState build(int conversationId) {
    _currentUserId = ref.watch(
      bootstrapControllerProvider.select((s) => s.valueOrNull?.profile.id ?? 0),
    );
    load(conversationId);
    return const MessagesState(isLoading: true);
  }

  Future<void> load(int conversationId) async {
    try {
      final repo = ref.read(chatsRepositoryProvider);
      final messages = await repo.fetchMessages(conversationId);
      state = state.copyWith(
        messages: messages,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> sendMessage({
    required int conversationId,
    String? body,
    String? attachmentUrl,
    String messageType = 'text',
  }) async {
    if (state.isSending) return;

    final optimisticMessage = ChatMessage(
      id: -1,
      conversationId: conversationId,
      senderId: _currentUserId,
      body: body,
      messageType: messageType,
      createdAt: DateTime.now(),
      attachmentUrl: attachmentUrl,
    );

    state = state.copyWith(isSending: true, pendingMessage: optimisticMessage);

    try {
      final repo = ref.read(chatsRepositoryProvider);
      await repo.sendMessage(
        conversationId: conversationId,
        body: body,
        attachmentUrl: attachmentUrl,
        messageType: messageType,
      );
      state = state.copyWith(isSending: false, clearPending: true);
      await load(conversationId);
    } catch (e) {
      state = state.copyWith(isSending: false, clearPending: true, error: e);
    }
  }

  Future<void> markAsRead(int conversationId) async {
    try {
      final repo = ref.read(chatsRepositoryProvider);
      await repo.markMessagesAsRead(conversationId);
    } catch (_) {}
  }
}

final messagesControllerProvider =
    NotifierProvider.family<MessagesController, MessagesState, int>(
      MessagesController.new,
    );
