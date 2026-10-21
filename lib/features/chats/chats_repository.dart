import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/compatibility/compatibility_engine.dart';
import '../../core/config/endpoints.dart';
import '../../core/domain/wire_enums.dart';
import '../../core/errors/app_failure.dart';
import '../../core/providers.dart';
import '../../core/utils/paged_envelope.dart';
import 'domain/chat_models.dart';

export 'domain/chat_models.dart';

class ChatsRepository {
  const ChatsRepository(this._ref);

  final Ref _ref;

  /// Largest page the API serves (`limit` above 100 is a 422).
  static const _maxPageSize = 100;

  /// Reads every page of a cursor list. Used where the whole list is needed.
  Future<List<T>> _readAll<T>(
    Future<({List<T> items, String? nextCursor, bool hasMore})> Function(
      String? cursor,
    )
    fetchPage,
  ) async {
    final all = <T>[];
    String? cursor;
    while (true) {
      final page = await fetchPage(cursor);
      all.addAll(page.items);
      final next = page.nextCursor;
      if (!page.hasMore || next == null || next.isEmpty) break;
      cursor = next;
    }
    return all;
  }

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

  /// Every conversation: follows `next_cursor` until the list ends.
  Future<List<ConversationSummaryModel>> fetchConversations() => _readAll(
    (cursor) => fetchConversationsPage(cursor: cursor, limit: _maxPageSize),
  );

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

  /// Every incoming like: follows `next_cursor` until the list ends.
  Future<List<IncomingLikeModel>> fetchIncomingLikes() => _readAll(
    (cursor) => fetchIncomingLikesPage(cursor: cursor, limit: _maxPageSize),
  );

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

  /// Every outgoing like: follows `next_cursor` until the list ends.
  Future<List<OutgoingLikeModel>> fetchOutgoingLikes() => _readAll(
    (cursor) => fetchOutgoingLikesPage(cursor: cursor, limit: _maxPageSize),
  );

  Future<int?> matchIncomingLike({
    required int peerId,
    int? contextPropertyId,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.swipes,
          data: {
            'target_type': SwipeTargetType.user.wire,
            'action': SwipeAction.like.wire,
            'target_user_id': peerId,
            'context_property_id': ?contextPropertyId,
          },
        );
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return (data['conversation_id'] as num?)?.toInt();
  }

  /// Starts a direct conversation with a peer user. Returns the conversation
  /// ID, or null if the backend did not return one. Unlike [matchIncomingLike],
  /// this creates a conversation immediately without requiring a mutual like.
  Future<int?> startConversation({
    required int peerId,
    String? initialMessage,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.conversations,
          data: {'peer_user_id': peerId, 'initial_message': ?initialMessage},
        );
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return (data['id'] as num?)?.toInt();
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

  /// Fetches one page of messages: `GET .../messages?limit=&cursor=`, a
  /// CursorPage. Without [cursor] it is the newest page. Items are
  /// chronological (oldest first); pass the returned [MessagesPage.nextCursor]
  /// back unchanged to load the next older page.
  Future<MessagesPage> fetchMessages(
    int conversationId, {
    String? cursor,
    int limit = 50,
  }) async {
    final queryParameters = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }
    final response = await _ref
        .read(apiClientProvider)
        .get(
          FlatmatesEndpoints.conversationMessages(conversationId),
          queryParameters: queryParameters,
        );
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    final page = parsePagedEnvelope(
      data,
      ChatMessage.fromJson,
      label: 'messages',
    );
    return MessagesPage(
      messages: page.items,
      hasMore: page.hasMore,
      nextCursor: page.hasMore ? page.nextCursor : null,
    );
  }

  Future<void> sendMessage({
    required int conversationId,
    String? body,
    String? attachmentUrl,
    MessageType messageType = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.conversationMessages(conversationId),
          data: {
            'body': ?body,
            'attachment_url': ?attachmentUrl,
            'message_type': messageType.wire,
            'metadata': ?metadata,
          },
        );
  }

  /// One page of `GET /flatmates/matches`.
  Future<({List<MatchSummaryModel> items, String? nextCursor, bool hasMore})>
  fetchMatchesPage({String? cursor, int limit = _maxPageSize}) async {
    final queryParameters = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }
    final response = await _ref
        .read(apiClientProvider)
        .get(FlatmatesEndpoints.matches, queryParameters: queryParameters);
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    return parsePagedEnvelope(
      data,
      MatchSummaryModel.fromJson,
      label: 'matches',
    );
  }

  /// The phone of [peerId], from the match contact route
  /// (`GET /flatmates/matches/{match_id}/contact`), or null when there is no
  /// active match with that user, or the match has no phone.
  ///
  /// This is the only way the app learns a peer phone: the peer payloads carry
  /// none. The match id is found in the user's matches.
  Future<String?> fetchMatchPhone(int peerId) async {
    final matches = await _readAll(
      (cursor) => fetchMatchesPage(cursor: cursor),
    );
    final match = matches
        .where((m) => m.peer.id == peerId && m.status == UserMatchStatus.active)
        .firstOrNull;
    if (match == null) return null;
    try {
      final response = await _ref
          .read(apiClientProvider)
          .get(FlatmatesEndpoints.matchContact(match.id));
      final data = response.data;
      if (data is! Map) return null;
      final phone = MatchContactModel.fromJson(
        Map<String, dynamic>.from(data),
      ).phone?.trim();
      return phone == null || phone.isEmpty ? null : phone;
    } on NotFoundFailure catch (e) {
      // 404 MATCH_NOT_FOUND: the pair is closed, or the peer's profile is not
      // visible. There is no phone to show.
      debugPrint('ChatsRepository.fetchMatchPhone: ${e.code}');
      return null;
    }
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

  /// Ends the match with [peerId] without blocking: `POST /flatmates/unmatch`.
  Future<void> unmatchConversation(int conversationId, int peerId) async {
    await _ref
        .read(apiClientProvider)
        .post(FlatmatesEndpoints.unmatch, data: {'peer_user_id': peerId});
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
}

final chatsRepositoryProvider = Provider<ChatsRepository>(
  (ref) => ChatsRepository(ref),
);

final conversationProvider = FutureProvider.autoDispose
    .family<ConversationSummaryModel, int>(
      (ref, conversationId) =>
          ref.watch(chatsRepositoryProvider).fetchConversation(conversationId),
    );

// autoDispose: a failed (null) load must not stay cached for the session.
final peerProfileProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, int>(
      (ref, userId) =>
          ref.watch(chatsRepositoryProvider).fetchPeerProfile(userId),
    );

final peerCompatibilityProvider = FutureProvider.autoDispose
    .family<CompatibilityResult?, int>(
      (ref, userId) =>
          ref.watch(chatsRepositoryProvider).fetchPeerCompatibility(userId),
    );
