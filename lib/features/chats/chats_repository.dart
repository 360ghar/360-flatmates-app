import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/endpoints.dart';
import '../../core/providers.dart';
import '../bootstrap/bootstrap_controller.dart';
import 'domain/chat_models.dart';

export 'domain/chat_models.dart';

class ChatsRepository {
  const ChatsRepository(this._ref);

  static const _messagesRealtimeTable = 'user_messages';

  final Ref _ref;

  Future<List<ConversationSummaryModel>> fetchConversations() async {
    final response = await _ref
        .read(apiClientProvider)
        .get(FlatmatesEndpoints.conversations);
    final rows = (response.data as List? ?? const []);
    return rows
        .map(
          (item) => ConversationSummaryModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<IncomingLikeModel>> fetchIncomingLikes() async {
    final response = await _ref
        .read(apiClientProvider)
        .get(FlatmatesEndpoints.incomingLikes);
    final rows = (response.data as List? ?? const []);
    return rows
        .map(
          (item) => IncomingLikeModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<IncomingLikeModel>> fetchOutgoingLikes() async {
    final response = await _ref
        .read(apiClientProvider)
        .get(FlatmatesEndpoints.outgoingLikes);
    final rows = (response.data as List? ?? const []);
    return rows
        .map(
          (item) => IncomingLikeModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<int?> matchIncomingLike({
    required int peerId,
    int? contextPropertyId,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.swipes,
          data: {
            'target_type': 'user',
            'action': 'like',
            'target_user_id': peerId,
            'context_property_id': ?contextPropertyId,
          },
        );
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return (data['conversation_id'] as num?)?.toInt();
  }

  Future<ConversationSummaryModel> fetchConversation(int conversationId) async {
    final response = await _ref
        .read(apiClientProvider)
        .get(FlatmatesEndpoints.conversation(conversationId));
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return ConversationSummaryModel.fromJson(data);
  }

  Future<MessageListResponse> fetchMessages(int conversationId) async {
    final response = await _ref
        .read(apiClientProvider)
        .get(FlatmatesEndpoints.conversationMessages(conversationId));
    final data = response.data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final rows = (map['messages'] as List? ?? const []);
      final messages = rows
          .map(
            (item) =>
                ChatMessage.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      return MessageListResponse(
        messages: messages,
        total: (map['total'] as num?)?.toInt() ?? messages.length,
        hasMore: map['has_more'] as bool? ?? false,
      );
    }
    // Fallback: handle legacy responses that return a raw list
    final rows = (data as List? ?? const []);
    final messages = rows
        .map(
          (item) =>
              ChatMessage.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    return MessageListResponse(
      messages: messages,
      total: messages.length,
      hasMore: false,
    );
  }

  Stream<List<ChatMessage>> watchMessages(int conversationId) {
    late final StreamController<List<ChatMessage>> controller;
    StreamSubscription<List<ChatMessage>>? realtimeSubscription;
    var hasEmittedMessages = false;
    var _isRefetching = false;

    void emitMessages(List<ChatMessage> messages) {
      if (controller.isClosed) return;
      hasEmittedMessages = true;
      controller.add(messages);
    }

    Future<void> refetch() async {
      if (_isRefetching) return;
      _isRefetching = true;
      try {
        final response = await fetchMessages(conversationId);
        emitMessages(response.messages);
      } catch (error, stackTrace) {
        if (!controller.isClosed && !hasEmittedMessages) {
          controller.addError(error, stackTrace);
        }
      } finally {
        _isRefetching = false;
      }
    }

    controller = StreamController<List<ChatMessage>>(
      onListen: () {
        unawaited(refetch());

        try {
          realtimeSubscription = Supabase.instance.client
              .from(_messagesRealtimeTable)
              .stream(primaryKey: ['id'])
              .eq('conversation_id', conversationId)
              .order('created_at', ascending: true)
              .map(_parseMessageRows)
              .listen(emitMessages, onError: (e) {
                debugPrint(
                  'ChatsRepository.watchMessages: realtime stream error: $e',
                );
                unawaited(refetch());
              });
        } catch (e) {
          debugPrint(
            'ChatsRepository.watchMessages: realtime subscription failed: $e',
          );
        }
      },
      onCancel: () async {
        await realtimeSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  Future<void> sendMessage({
    required int conversationId,
    String? body,
    String? attachmentUrl,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.conversationMessages(conversationId),
          data: {
            'body': ?body,
            'attachment_url': ?attachmentUrl,
            'message_type': messageType,
            'metadata': ?metadata,
          },
        );
  }

  Future<void> markMessagesAsRead(int conversationId) async {
    await _ref
        .read(apiClientProvider)
        .post(FlatmatesEndpoints.conversationMarkRead(conversationId));
  }

  Future<void> blockUser(int userId) async {
    await _ref
        .read(apiClientProvider)
        .post(FlatmatesEndpoints.blocks, data: {'blocked_user_id': userId});
  }

  Future<void> unmatchConversation(int conversationId, int peerId) async {
    await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.blocks,
          data: {'blocked_user_id': peerId, 'unmatch_only': true},
        );
  }

  Future<void> reportUser(int userId, String reason) async {
    await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.reports,
          data: {'reported_user_id': userId, 'reason': reason},
        );
  }

  Future<void> submitQnA(
    int conversationId,
    Map<String, String> answers,
  ) async {
    final normalizedAnswers = _normalizeQnAAnswers(answers);
    await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.conversationQnA(conversationId),
          data: {'answers': normalizedAnswers},
        );
  }

  Map<String, String> _normalizeQnAAnswers(Map<String, String> answers) {
    const aliases = {'q1': '0', 'q2': '1', 'q3': '2'};
    final normalized = <String, String>{};
    for (final entry in answers.entries) {
      final key = aliases[entry.key] ?? entry.key;
      if (key != '0' && key != '1' && key != '2') continue;
      final value = entry.value.trim();
      if (value.isEmpty) continue;
      normalized[key] = value;
    }
    return normalized;
  }

  static List<ChatMessage> _parseMessageRows(List<Map<String, dynamic>> rows) {
    return rows
        .map((row) => ChatMessage.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }
}

final chatsRepositoryProvider = Provider<ChatsRepository>(
  (ref) => ChatsRepository(ref),
);

/// Subscribes to Supabase realtime changes on `user_conversations` and
/// invalidates [conversationsProvider] whenever a row changes (new message,
/// new conversation, read-status update, etc.).
///
/// Must be activated from the UI/provider tree (e.g. `app.dart` or
/// `sseEventRouterProvider`) by watching or listening to this provider.
final conversationsRealtimeProvider = StreamProvider<void>((ref) {
  final userId = ref.watch(
    bootstrapControllerProvider.select((s) => s.valueOrNull?.profile.id),
  );
  if (userId == null) return const Stream<void>.empty();

  final controller = StreamController<void>.broadcast();
  final client = Supabase.instance.client;

  void onChanged(_) {
    if (!controller.isClosed) {
      Future.microtask(() => ref.invalidate(conversationsProvider));
    }
  }

  final sub1 = client
      .from('user_conversations')
      .stream(primaryKey: ['id'])
      .eq('user_one_id', userId)
      .listen(onChanged);

  final sub2 = client
      .from('user_conversations')
      .stream(primaryKey: ['id'])
      .eq('user_two_id', userId)
      .listen(onChanged);

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    controller.close();
  });

  return controller.stream;
});

final conversationsProvider = FutureProvider<List<ConversationSummaryModel>>(
  (ref) => ref.watch(chatsRepositoryProvider).fetchConversations(),
);

final incomingLikesProvider = FutureProvider<List<IncomingLikeModel>>(
  (ref) => ref.watch(chatsRepositoryProvider).fetchIncomingLikes(),
);

final outgoingLikesProvider = FutureProvider<List<IncomingLikeModel>>(
  (ref) => ref.watch(chatsRepositoryProvider).fetchOutgoingLikes(),
);

final conversationProvider =
    FutureProvider.family<ConversationSummaryModel, int>(
      (ref, conversationId) =>
          ref.watch(chatsRepositoryProvider).fetchConversation(conversationId),
    );

final messagesProvider = FutureProvider.family<MessageListResponse, int>(
  (ref, conversationId) =>
      ref.watch(chatsRepositoryProvider).fetchMessages(conversationId),
);

final messagesStreamProvider = StreamProvider.family<List<ChatMessage>, int>(
  (ref, conversationId) =>
      ref.watch(chatsRepositoryProvider).watchMessages(conversationId),
);
