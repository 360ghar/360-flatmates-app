import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/bootstrap_controller.dart';
import '../chats_repository.dart';
import 'cursor_list_controller.dart';

class MessagesState {
  const MessagesState({
    this.messages = const [],
    this.pendingMessages = const [],
    this.isLoading = false,
    this.isLoadingOlder = false,
    this.isSending = false,
    this.hasMoreOlder = true,
    this.oldestCursor,
    this.error,
  });

  /// Authoritative messages from the realtime stream / HTTP refetch.
  final List<ChatMessage> messages;

  /// Optimistic messages (negative ids) not yet confirmed by the backend.
  final List<ChatMessage> pendingMessages;

  final bool isLoading;
  final bool isLoadingOlder;
  final bool isSending;
  final bool hasMoreOlder;
  final String? oldestCursor;
  final Object? error;

  bool get hasError => error != null;

  /// What the UI renders: authoritative + still-unconfirmed optimistic.
  List<ChatMessage> get displayMessages => [...messages, ...pendingMessages];

  MessagesState copyWith({
    List<ChatMessage>? messages,
    List<ChatMessage>? pendingMessages,
    bool? isLoading,
    bool? isLoadingOlder,
    bool? isSending,
    bool? hasMoreOlder,
    String? oldestCursor,
    bool clearOldestCursor = false,
    Object? error,
    bool clearError = false,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      pendingMessages: pendingMessages ?? this.pendingMessages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      isSending: isSending ?? this.isSending,
      hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
      oldestCursor: clearOldestCursor
          ? null
          : (oldestCursor ?? this.oldestCursor),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Removes pending messages that the backend has confirmed, greedily
/// consuming one real row per pending message so a double-send of identical
/// text keeps the second bubble until its own row arrives.
@visibleForTesting
List<ChatMessage> pruneConfirmedPending(
  List<ChatMessage> real,
  List<ChatMessage> pending,
) {
  if (pending.isEmpty) return pending;
  final unconsumed = real.where((m) => m.id > 0).toList();
  final remaining = <ChatMessage>[];
  for (final candidate in pending) {
    final index = unconsumed.indexWhere((m) => _confirms(m, candidate));
    if (index >= 0) {
      unconsumed.removeAt(index);
    } else {
      remaining.add(candidate);
    }
  }
  return remaining;
}

/// Merges a refetched snapshot into the current list by id, so a refetch
/// that raced with a newer realtime emission can't drop messages that
/// arrived in between. Refetched rows win for shared ids (fresher read
/// receipts); ordering follows createdAt ascending like the backend.
@visibleForTesting
List<ChatMessage> mergeMessages(
  List<ChatMessage> current,
  List<ChatMessage> refetched,
) {
  final byId = {
    for (final message in current) message.id: message,
    for (final message in refetched) message.id: message,
  };
  return byId.values.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}

bool _confirms(ChatMessage real, ChatMessage pending) {
  return real.senderId == pending.senderId &&
      real.messageType == pending.messageType &&
      (real.body ?? '') == (pending.body ?? '') &&
      (real.attachmentUrl ?? '') == (pending.attachmentUrl ?? '') &&
      // Window guards against an identical older message confirming a new
      // optimistic bubble.
      real.createdAt.difference(pending.createdAt).inMinutes.abs() <= 2;
}

class MessagesController extends AutoDisposeFamilyNotifier<MessagesState, int> {
  int _currentUserId = 0;
  int _nextOptimisticId = -1;

  @override
  MessagesState build(int conversationId) {
    _currentUserId = ref.watch(
      bootstrapControllerProvider.select((s) => s.valueOrNull?.profile.id ?? 0),
    );
    ref.listen(
      messagesStreamProvider(conversationId),
      (previous, next) => _onStreamUpdate(next),
    );
    final initial = ref.read(messagesStreamProvider(conversationId));
    // Seed the oldest-message cursor from the initial page so the first
    // loadOlder() paginates backward instead of re-downloading page 1.
    unawaited(_seedOldestCursor(conversationId));
    return MessagesState(
      messages: initial.valueOrNull ?? const [],
      isLoading: initial.isLoading && !initial.hasValue,
      error: initial.hasError && !initial.hasValue ? initial.error : null,
    );
  }

  void _onStreamUpdate(AsyncValue<List<ChatMessage>> next) {
    final messages = next.valueOrNull;
    if (messages != null) {
      state = state.copyWith(
        messages: messages,
        pendingMessages: pruneConfirmedPending(messages, state.pendingMessages),
        isLoading: false,
        clearError: true,
      );
    } else if (next.hasError && state.messages.isEmpty) {
      state = state.copyWith(isLoading: false, error: next.error);
    }
  }

  bool _seedingCursor = false;

  /// Fetches the first page of messages to seed [MessagesState.oldestCursor]
  /// so the first [loadOlder] call actually paginates backward. No-op if the
  /// cursor is already seeded or a seed is in flight.
  Future<void> _seedOldestCursor(int conversationId) async {
    if (_seedingCursor || state.oldestCursor != null) return;
    _seedingCursor = true;
    try {
      final response = await ref
          .read(chatsRepositoryProvider)
          .fetchMessages(conversationId);
      state = state.copyWith(
        messages: mergeMessages(state.messages, response.messages),
        pendingMessages: pruneConfirmedPending(
          response.messages,
          state.pendingMessages,
        ),
        hasMoreOlder: response.hasMore,
        oldestCursor: response.nextCursor,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      debugPrint(
        'MessagesController._seedOldestCursor failed for conversation '
        '$conversationId: $e',
      );
    } finally {
      _seedingCursor = false;
    }
  }

  /// Loads older messages using cursor pagination. Concatenates the older
  /// page in front of the current messages so the user can scroll back
  /// through history. A no-op when a load is already in flight or the
  /// server already returned the end of the thread.
  Future<void> loadOlder() async {
    final conversationId = arg;
    if (state.isLoadingOlder || !state.hasMoreOlder) return;
    if (state.oldestCursor == null) {
      await _seedOldestCursor(conversationId);
      if (state.isLoadingOlder || !state.hasMoreOlder) return;
    }
    state = state.copyWith(isLoadingOlder: true, clearError: true);
    try {
      final response = await ref
          .read(chatsRepositoryProvider)
          .fetchMessages(conversationId, cursor: state.oldestCursor);
      // Newer realtime arrivals may have appeared during the request; merge
      // by id so we never drop or duplicate a message.
      final merged = mergeMessages(response.messages, state.messages);
      state = state.copyWith(
        messages: merged,
        hasMoreOlder: response.hasMore,
        oldestCursor: response.nextCursor,
        isLoadingOlder: false,
      );
    } catch (e) {
      debugPrint(
        'MessagesController.loadOlder failed for conversation '
        '$conversationId: $e',
      );
      state = state.copyWith(isLoadingOlder: false, error: e);
    }
  }

  /// Sends a message optimistically: the bubble appears immediately and is
  /// confirmed by an authoritative refetch so it persists even when the
  /// Supabase realtime stream is down. Rethrows on send failure after
  /// removing the optimistic bubble so the UI can restore input and toast.
  Future<void> sendMessage({
    String? body,
    String? attachmentUrl,
    String messageType = 'text',
  }) async {
    final conversationId = arg;
    final optimistic = ChatMessage(
      id: _nextOptimisticId--,
      conversationId: conversationId,
      senderId: _currentUserId,
      body: body,
      messageType: messageType,
      createdAt: DateTime.now(),
      attachmentUrl: attachmentUrl,
    );
    state = state.copyWith(
      isSending: true,
      pendingMessages: [...state.pendingMessages, optimistic],
    );

    final repo = ref.read(chatsRepositoryProvider);
    try {
      await repo.sendMessage(
        conversationId: conversationId,
        body: body,
        attachmentUrl: attachmentUrl,
        messageType: messageType,
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        pendingMessages: state.pendingMessages
            .where((m) => m.id != optimistic.id)
            .toList(),
      );
      rethrow;
    }

    state = state.copyWith(isSending: false);
    ref.invalidate(conversationsProvider);
    ref.invalidate(conversationsListControllerProvider);

    // The POST succeeded; keep the optimistic bubble even if this refetch
    // fails — the realtime stream or a later refetch will confirm it.
    try {
      final response = await repo.fetchMessages(conversationId);
      final merged = mergeMessages(state.messages, response.messages);
      state = state.copyWith(
        messages: merged,
        pendingMessages: pruneConfirmedPending(merged, state.pendingMessages),
        hasMoreOlder: response.hasMore,
        oldestCursor: response.nextCursor ?? state.oldestCursor,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      debugPrint(
        'MessagesController.sendMessage: refetch failed for conversation '
        '$conversationId: $e',
      );
    }
  }

  Future<void> markAsRead() async {
    try {
      await ref.read(chatsRepositoryProvider).markMessagesAsRead(arg);
    } catch (e) {
      debugPrint(
        'MessagesController.markAsRead failed for conversation $arg: $e',
      );
    }
  }
}

final messagesControllerProvider = NotifierProvider.family
    .autoDispose<MessagesController, MessagesState, int>(
      MessagesController.new,
    );
