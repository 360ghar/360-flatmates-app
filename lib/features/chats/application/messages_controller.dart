import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/wire_enums.dart';
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
    this.olderCursor,
    this.error,
  });

  /// Authoritative messages from the HTTP pages (newest page on open, a
  /// refetch on each Broadcast event, older pages on scroll back).
  final List<ChatMessage> messages;

  /// Optimistic messages (negative ids) not yet confirmed by the backend.
  final List<ChatMessage> pendingMessages;

  final bool isLoading;
  final bool isLoadingOlder;
  final bool isSending;
  final bool hasMoreOlder;

  /// Opaque cursor of the next older page (`next_cursor`): pass it back
  /// unchanged as `cursor`. Null until the first page is seeded or when no
  /// older messages remain.
  final String? olderCursor;
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
    String? olderCursor,
    bool clearOlderCursor = false,
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
      olderCursor: clearOlderCursor ? null : (olderCursor ?? this.olderCursor),
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
  bool _seeding = false;

  @override
  MessagesState build(int conversationId) {
    _currentUserId = ref.watch(
      bootstrapControllerProvider.select((s) => s.valueOrNull?.profile.id ?? 0),
    );
    // The thread is read over HTTP only: the newest page on open, then a
    // refetch whenever the user channel broadcasts `new_message` or
    // `conversation_updated` for this conversation (see sse_providers.dart).
    // There is no table stream on public.messages.
    Future.microtask(_seed);
    return const MessagesState(isLoading: true);
  }

  /// Loads the newest page and seeds the older-page cursor. No-op while a
  /// seed is in flight.
  Future<void> _seed() async {
    if (_seeding) return;
    _seeding = true;
    final conversationId = arg;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await ref
          .read(chatsRepositoryProvider)
          .fetchMessages(conversationId);
      // Merge so a Broadcast refetch that landed first is not replaced by an
      // older snapshot.
      final merged = mergeMessages(state.messages, page.messages);
      state = state.copyWith(
        messages: merged,
        pendingMessages: pruneConfirmedPending(merged, state.pendingMessages),
        hasMoreOlder: page.hasMore,
        olderCursor: page.nextCursor,
        clearOlderCursor: page.nextCursor == null,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      debugPrint(
        'MessagesController._seed failed for conversation $conversationId: $e',
      );
      // Always clear the loader. Only surface the error if there is nothing
      // to show; otherwise keep the loaded history visible.
      state = state.messages.isEmpty
          ? state.copyWith(isLoading: false, error: e)
          : state.copyWith(isLoading: false);
    } finally {
      _seeding = false;
    }
  }

  /// Authoritative HTTP refetch of the newest page (Broadcast live updates,
  /// post-send confirmation, pull to refresh). Merges by id so rows already on
  /// screen are not dropped.
  Future<void> refetchLatest() async {
    final conversationId = arg;
    try {
      final page = await ref
          .read(chatsRepositoryProvider)
          .fetchMessages(conversationId);
      final previousIds = state.messages.map((m) => m.id).toSet();
      final hadMessages = state.messages.isNotEmpty;
      final merged = mergeMessages(state.messages, page.messages);
      // Do not clobber deeper history pagination when only refreshing the
      // newest page after send / Broadcast: the older cursor is taken from
      // this page only while it has not been seeded yet.
      final unseeded = state.olderCursor == null && state.hasMoreOlder;
      state = state.copyWith(
        messages: merged,
        pendingMessages: pruneConfirmedPending(merged, state.pendingMessages),
        hasMoreOlder: unseeded ? page.hasMore : state.hasMoreOlder,
        olderCursor: unseeded ? page.nextCursor : null,
        isLoading: false,
        clearError: true,
      );
      // While this autoDispose controller is alive the thread is open. Re-mark
      // as read only when new inbound rows arrive (not on the first load) so
      // list badges stay clear without spamming the endpoint.
      if (hadMessages) {
        final hasNewInbound = page.messages.any(
          (m) =>
              m.id > 0 &&
              m.senderId != null &&
              m.senderId != _currentUserId &&
              !previousIds.contains(m.id),
        );
        if (hasNewInbound) unawaited(markAsRead());
      }
    } catch (e) {
      debugPrint(
        'MessagesController.refetchLatest failed for conversation '
        '$conversationId: $e',
      );
    }
  }

  /// Loads the next older page with the cursor from the previous page and puts
  /// it in front of the current messages. A no-op when a load is already in
  /// flight or the server already returned the start of the thread.
  Future<void> loadOlder() async {
    final conversationId = arg;
    if (state.isLoadingOlder || !state.hasMoreOlder) return;
    if (state.olderCursor == null) {
      await _seed();
      if (state.isLoadingOlder || !state.hasMoreOlder) return;
      if (state.olderCursor == null) return;
    }
    state = state.copyWith(isLoadingOlder: true, clearError: true);
    try {
      final page = await ref
          .read(chatsRepositoryProvider)
          .fetchMessages(conversationId, cursor: state.olderCursor);
      // Newer arrivals may have appeared during the request; merge by id so we
      // never drop or duplicate a message.
      final merged = mergeMessages(page.messages, state.messages);
      state = state.copyWith(
        messages: merged,
        hasMoreOlder: page.hasMore,
        olderCursor: page.nextCursor,
        clearOlderCursor: page.nextCursor == null,
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
  /// confirmed by an authoritative refetch. Rethrows on send failure after
  /// removing the optimistic bubble so the UI can restore input and toast.
  ///
  /// Re-entry while [MessagesState.isSending] is ignored so double-taps do
  /// not create duplicate optimistic rows or parallel POSTs.
  Future<void> sendMessage({
    String? body,
    String? attachmentUrl,
    MessageType messageType = MessageType.text,
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
    ref.invalidate(conversationsListControllerProvider);

    // The POST succeeded; keep the optimistic bubble even if this refetch
    // fails: a Broadcast or a later refetch will confirm it.
    await refetchLatest();
  }

  Future<void> markAsRead() async {
    try {
      await ref.read(chatsRepositoryProvider).markMessagesAsRead(arg);
      // Refresh list unread badges without waiting for Broadcast.
      ref.invalidate(conversationsListControllerProvider);
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
