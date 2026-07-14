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
    this.oldestBeforeId,
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

  /// Keyset cursor: pass as `before_id` to load older pages. Null until the
  /// first page is seeded or when no older messages remain.
  final int? oldestBeforeId;
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
    int? oldestBeforeId,
    bool clearOldestBeforeId = false,
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
      oldestBeforeId: clearOldestBeforeId
          ? null
          : (oldestBeforeId ?? this.oldestBeforeId),
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
      // A realtime (re)connect can momentarily emit an empty list before the
      // HTTP refetch lands. Never let a spurious empty emission wipe history
      // we already loaded — otherwise reopening a conversation would silently
      // drop its messages. Also ignore empty emissions while the initial seed
      // fetch is in flight so the cold-open race doesn't flash an empty card.
      if (messages.isEmpty && (state.messages.isNotEmpty || _seedingCursor)) {
        return;
      }
      final previousIds = state.messages.map((m) => m.id).toSet();
      final hadMessages = state.messages.isNotEmpty;
      state = state.copyWith(
        messages: messages,
        pendingMessages: pruneConfirmedPending(messages, state.pendingMessages),
        isLoading: false,
        clearError: true,
      );
      // While this autoDispose controller is alive the thread is open. Re-mark
      // as read only when *new* inbound rows arrive (not on the initial seed)
      // so list badges stay clear without spamming the endpoint.
      if (hadMessages) {
        final hasNewInbound = messages.any(
          (m) =>
              m.id > 0 &&
              m.senderId != _currentUserId &&
              !previousIds.contains(m.id),
        );
        if (hasNewInbound) {
          unawaited(markAsRead());
        }
      }
    } else if (next.hasError) {
      debugPrint(
        'MessagesController stream error for conversation $arg: ${next.error}',
      );
      // Only surface the error if we have nothing to show; otherwise keep the
      // loaded history on screen and let the next emission recover.
      if (state.messages.isEmpty) {
        state = state.copyWith(isLoading: false, error: next.error);
      }
    }
  }

  bool _seedingCursor = false;

  /// Fetches the first page of messages to seed [MessagesState.oldestBeforeId]
  /// so the first [loadOlder] call actually paginates backward. No-op if the
  /// cursor is already seeded or a seed is in flight.
  Future<void> _seedOldestCursor(int conversationId) async {
    if (_seedingCursor || state.oldestBeforeId != null) return;
    _seedingCursor = true;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ref
          .read(chatsRepositoryProvider)
          .fetchMessages(conversationId);
      // Merge so a rich realtime snapshot is not replaced by a thinner HTTP
      // first page (and empty stream races never wipe loaded history).
      final merged = mergeMessages(state.messages, response.messages);
      // Prefer the oldest *loaded* positive id so loadOlder does not
      // re-request rows already present from the stream.
      final oldestLoaded = _oldestPositiveId(merged);
      state = state.copyWith(
        messages: merged,
        pendingMessages: pruneConfirmedPending(merged, state.pendingMessages),
        hasMoreOlder: response.hasMore,
        oldestBeforeId: response.hasMore ? oldestLoaded : null,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      debugPrint(
        'MessagesController._seedOldestCursor failed for conversation '
        '$conversationId: $e',
      );
      // Always clear the loader. Only surface the error if we have no
      // messages to show; otherwise keep the loaded history visible.
      state = state.messages.isEmpty
          ? state.copyWith(isLoading: false, error: e)
          : state.copyWith(isLoading: false);
    } finally {
      _seedingCursor = false;
    }
  }

  /// Authoritative HTTP refetch for the newest page (Broadcast live updates,
  /// post-send confirmation). Merges by id so concurrent realtime rows are
  /// not dropped.
  Future<void> refetchLatest() async {
    final conversationId = arg;
    try {
      final response = await ref
          .read(chatsRepositoryProvider)
          .fetchMessages(conversationId);
      final merged = mergeMessages(state.messages, response.messages);
      // Do not clobber deeper history pagination when only refreshing the
      // newest page after send / Broadcast.
      final seededOlderCursor = state.oldestBeforeId != null;
      state = state.copyWith(
        messages: merged,
        pendingMessages: pruneConfirmedPending(merged, state.pendingMessages),
        hasMoreOlder: seededOlderCursor ? state.hasMoreOlder : response.hasMore,
        oldestBeforeId: state.oldestBeforeId ?? response.nextBeforeId,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      debugPrint(
        'MessagesController.refetchLatest failed for conversation '
        '$conversationId: $e',
      );
    }
  }

  /// Loads older messages using `before_id` keyset pagination. Concatenates
  /// the older page in front of the current messages so the user can scroll
  /// back through history. A no-op when a load is already in flight or the
  /// server already returned the end of the thread.
  Future<void> loadOlder() async {
    final conversationId = arg;
    if (state.isLoadingOlder || !state.hasMoreOlder) return;
    if (state.oldestBeforeId == null) {
      await _seedOldestCursor(conversationId);
      if (state.isLoadingOlder || !state.hasMoreOlder) return;
      if (state.oldestBeforeId == null) return;
    }
    state = state.copyWith(isLoadingOlder: true, clearError: true);
    try {
      final response = await ref
          .read(chatsRepositoryProvider)
          .fetchMessages(conversationId, beforeId: state.oldestBeforeId);
      // Newer realtime arrivals may have appeared during the request; merge
      // by id so we never drop or duplicate a message.
      final merged = mergeMessages(response.messages, state.messages);
      state = state.copyWith(
        messages: merged,
        hasMoreOlder: response.hasMore,
        oldestBeforeId: response.hasMore ? _oldestPositiveId(merged) : null,
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
  ///
  /// Re-entry while [MessagesState.isSending] is ignored so double-taps do
  /// not create duplicate optimistic rows or parallel POSTs.
  Future<void> sendMessage({
    String? body,
    String? attachmentUrl,
    String messageType = 'text',
  }) async {
    if (state.isSending) return;

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
    // fails — Broadcast or a later refetch will confirm it.
    await refetchLatest();
  }

  Future<void> markAsRead() async {
    try {
      await ref.read(chatsRepositoryProvider).markMessagesAsRead(arg);
      // Refresh list unread badges without waiting for Broadcast.
      ref.invalidate(conversationsProvider);
      ref.invalidate(conversationsListControllerProvider);
    } catch (e) {
      debugPrint(
        'MessagesController.markAsRead failed for conversation $arg: $e',
      );
    }
  }
}

int? _oldestPositiveId(List<ChatMessage> messages) {
  int? oldest;
  for (final message in messages) {
    if (message.id <= 0) continue;
    if (oldest == null || message.id < oldest) oldest = message.id;
  }
  return oldest;
}

final messagesControllerProvider = NotifierProvider.family
    .autoDispose<MessagesController, MessagesState, int>(
      MessagesController.new,
    );
