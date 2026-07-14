import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/compatibility/compatibility_engine.dart';
import '../../core/config/endpoints.dart';
import '../../core/providers.dart';
import '../../core/utils/paged_envelope.dart';
import '../../core/utils/safe_json_list.dart';
import 'domain/chat_models.dart';

export 'domain/chat_models.dart';

class ChatsRepository {
  const ChatsRepository(this._ref);

  static const _messagesRealtimeTable = 'messages';

  final Ref _ref;

  /// Fetches a single page of conversations using cursor pagination. The
  /// backend wraps all list endpoints in
  /// `{ items, next_cursor, has_more, limit }`.
  Future<
    ({List<ConversationSummaryModel> items, String? nextCursor, bool hasMore})
  >
  fetchConversationsPage({String? cursor, int limit = 20}) async {
    final queryParameters = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }
    final response = await _ref
        .read(apiClientProvider)
        .get(
          FlatmatesEndpoints.conversations,
          queryParameters: queryParameters,
        );
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    return parsePagedEnvelope(
      data,
      ConversationSummaryModel.fromJson,
      label: 'conversations',
    );
  }

  /// Backwards-compatible helper returning the first page as a list.
  Future<List<ConversationSummaryModel>> fetchConversations() async {
    final page = await fetchConversationsPage();
    return page.items;
  }

  /// Fetches a single page of incoming likes using cursor pagination.
  Future<({List<IncomingLikeModel> items, String? nextCursor, bool hasMore})>
  fetchIncomingLikesPage({String? cursor, int limit = 20}) async {
    final queryParameters = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }
    final response = await _ref
        .read(apiClientProvider)
        .get(
          FlatmatesEndpoints.incomingLikes,
          queryParameters: queryParameters,
        );
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    return parsePagedEnvelope(
      data,
      IncomingLikeModel.fromJson,
      label: 'incomingLikes',
    );
  }

  /// Backwards-compatible helper returning the first page as a list.
  Future<List<IncomingLikeModel>> fetchIncomingLikes() async {
    final page = await fetchIncomingLikesPage();
    return page.items;
  }

  /// Fetches a single page of outgoing likes using cursor pagination.
  Future<({List<OutgoingLikeModel> items, String? nextCursor, bool hasMore})>
  fetchOutgoingLikesPage({String? cursor, int limit = 20}) async {
    final queryParameters = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }
    final response = await _ref
        .read(apiClientProvider)
        .get(
          FlatmatesEndpoints.outgoingLikes,
          queryParameters: queryParameters,
        );
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    return parsePagedEnvelope(
      data,
      OutgoingLikeModel.fromJson,
      label: 'outgoingLikes',
    );
  }

  /// Backwards-compatible helper returning the first page as a list.
  Future<List<OutgoingLikeModel>> fetchOutgoingLikes() async {
    final page = await fetchOutgoingLikesPage();
    return page.items;
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

  /// Fetches a page of messages (newest first page when [beforeId] is null).
  ///
  /// Backend contract (not CursorPage):
  /// `GET .../messages?limit=&before_id=` →
  /// `{ messages, total, has_more }`. Pass the previous page's
  /// [MessageListResponse.nextBeforeId] to load older history.
  Future<MessageListResponse> fetchMessages(
    int conversationId, {
    int? beforeId,
    int limit = 50,
  }) async {
    final queryParameters = <String, dynamic>{'limit': limit};
    if (beforeId != null && beforeId > 0) {
      queryParameters['before_id'] = beforeId;
    }
    final response = await _ref
        .read(apiClientProvider)
        .get(
          FlatmatesEndpoints.conversationMessages(conversationId),
          queryParameters: queryParameters,
        );
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    final messages = safeJsonList(
      data['messages'] as List?,
      ChatMessage.fromJson,
      label: 'messages',
    );
    final hasMore = data['has_more'] as bool? ?? false;
    // Chronological page: index 0 is oldest — use as next before_id.
    final nextBeforeId = hasMore && messages.isNotEmpty
        ? messages.first.id
        : null;
    return MessageListResponse(
      messages: messages,
      hasMore: hasMore,
      nextBeforeId: nextBeforeId,
      total: (data['total'] as num?)?.toInt(),
    );
  }

  Stream<List<ChatMessage>> watchMessages(int conversationId) {
    late final StreamController<List<ChatMessage>> controller;
    StreamSubscription<List<ChatMessage>>? realtimeSubscription;
    var hasEmittedMessages = false;
    var isRefetching = false;
    var consecutiveErrorRefetches = 0;
    Timer? errorRefetchTimer;

    void emitMessages(List<ChatMessage> messages) {
      if (controller.isClosed) return;
      hasEmittedMessages = true;
      controller.add(messages);
    }

    Future<void> refetch() async {
      if (isRefetching) return;
      isRefetching = true;
      try {
        final response = await fetchMessages(conversationId);
        emitMessages(response.messages);
      } catch (error, stackTrace) {
        if (!controller.isClosed && !hasEmittedMessages) {
          controller.addError(error, stackTrace);
        }
      } finally {
        isRefetching = false;
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
              .listen(
                (messages) {
                  consecutiveErrorRefetches = 0;
                  emitMessages(messages);
                },
                onError: (e) {
                  debugPrint(
                    'ChatsRepository.watchMessages: realtime stream error: $e',
                  );
                  // A flapping realtime connection can emit errors in rapid
                  // succession; back off so each error doesn't hit the API.
                  if (errorRefetchTimer?.isActive ?? false) return;
                  final delay = Duration(
                    seconds: 1 << consecutiveErrorRefetches.clamp(0, 5),
                  );
                  consecutiveErrorRefetches++;
                  errorRefetchTimer = Timer(delay, () {
                    if (controller.isClosed) return;
                    unawaited(refetch());
                  });
                },
              );
        } catch (e) {
          debugPrint(
            'ChatsRepository.watchMessages: realtime subscription failed: $e',
          );
        }
      },
      onCancel: () async {
        errorRefetchTimer?.cancel();
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

  /// Fetches the full flatmates profile of another user. Returns null when
  /// the profile is unavailable (deleted, blocked, or 404) so callers can
  /// degrade gracefully instead of erroring the whole page.
  Future<Map<String, dynamic>?> fetchPeerProfile(int userId) async {
    try {
      final response = await _ref
          .read(apiClientProvider)
          .get('${FlatmatesEndpoints.flatmatesProfiles}/$userId');
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('ChatsRepository.fetchPeerProfile: $e');
      return null;
    }
  }

  /// Fetches per-dimension compatibility data against a peer. Returns null
  /// when the breakdown is unavailable (no dimensions, or HTTP error).
  ///
  /// The backend may emit `overall_percentage: null` when no dimensions are
  /// comparable while still returning per-dimension "not enough data" rows.
  /// We parse dimensions even in that case so the UI can show the breakdown
  /// section. Dimensions with empty user/peer values are filtered out so
  /// missing data is never misrepresented as a mismatch (0% bars).
  Future<CompatibilityResult?> fetchPeerCompatibility(int userId) async {
    try {
      final response = await _ref
          .read(apiClientProvider)
          .get(FlatmatesEndpoints.flatmatesPeerCompatibility(userId));
      final data = response.data;
      if (data is! Map) return null;
      final dims = data['dimensions'] as List?;
      if (dims == null || dims.isEmpty) return null;
      final overallPct = (data['overall_percentage'] as num?)?.toDouble();

      final dimensions = dims
          .whereType<Map>()
          .map((d) {
            final m = Map<String, dynamic>.from(d);
            return CompatibilityDimension(
              key: m['name'] as String? ?? '',
              weight: (m['weight'] as num?)?.toDouble() ?? 0,
              userValue: m['user_value'] as String? ?? '',
              peerValue: m['peer_value'] as String? ?? '',
              score: (m['score'] as num?)?.toDouble() ?? 0,
              isMatch: m['match'] as bool? ?? false,
              summary: m['summary'] as String? ?? '',
            );
          })
          // Skip dimensions where either side has no data — the backend
          // emits these with score=0 and summary "not enough data". Showing
          // them as 0% bars would misrepresent missing data as mismatch.
          .where((dim) => dim.userValue.isNotEmpty || dim.peerValue.isNotEmpty)
          .toList();

      if (dimensions.isEmpty) return null;

      return CompatibilityResult(
        percentage: overallPct ?? 0,
        dimensions: dimensions,
        topMatchChips:
            (data['summary'] as List?)?.whereType<String>().toList() ??
            const [],
      );
    } catch (e) {
      debugPrint('ChatsRepository.fetchPeerCompatibility: $e');
      return null;
    }
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
    return safeJsonList(rows, ChatMessage.fromJson, label: 'realtimeMessages');
  }
}

final chatsRepositoryProvider = Provider<ChatsRepository>(
  (ref) => ChatsRepository(ref),
);

final conversationsProvider = FutureProvider<List<ConversationSummaryModel>>(
  (ref) => ref.watch(chatsRepositoryProvider).fetchConversations(),
);

final incomingLikesProvider = FutureProvider<List<IncomingLikeModel>>(
  (ref) => ref.watch(chatsRepositoryProvider).fetchIncomingLikes(),
);

final outgoingLikesProvider = FutureProvider<List<OutgoingLikeModel>>(
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

final messagesStreamProvider = StreamProvider.family
    .autoDispose<List<ChatMessage>, int>(
      (ref, conversationId) =>
          ref.watch(chatsRepositoryProvider).watchMessages(conversationId),
    );

final peerProfileProvider = FutureProvider.family<Map<String, dynamic>?, int>(
  (ref, userId) => ref.watch(chatsRepositoryProvider).fetchPeerProfile(userId),
);

final peerCompatibilityProvider =
    FutureProvider.family<CompatibilityResult?, int>(
      (ref, userId) =>
          ref.watch(chatsRepositoryProvider).fetchPeerCompatibility(userId),
    );
