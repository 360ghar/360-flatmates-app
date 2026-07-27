import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../core/utils/paged_envelope.dart';
import 'blocked_user_model.dart';

class BlockedUsersRepository {
  const BlockedUsersRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Fetches a single page of the user's blocked users using cursor pagination.
  /// The backend wraps all list endpoints in
  /// `{ items, next_cursor, has_more, limit }`.
  Future<({List<BlockedUser> items, String? nextCursor, bool hasMore})>
  getBlockedUsersPage({String? cursor, int limit = 20}) async {
    final queryParameters = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }
    final response = await _apiClient.get(
      FlatmatesEndpoints.blocks,
      queryParameters: queryParameters,
    );
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    return parsePagedEnvelope(
      data,
      BlockedUser.fromJson,
      label: 'blockedUsers',
    );
  }

  /// Aggregates every page of blocked users into a single list.
  Future<List<BlockedUser>> getBlockedUsers() async {
    final all = <BlockedUser>[];
    String? cursor;
    do {
      final page = await getBlockedUsersPage(cursor: cursor);
      all.addAll(page.items);
      cursor = page.nextCursor;
      if (page.items.isEmpty) break;
    } while (cursor != null && cursor.isNotEmpty);
    return all;
  }

  Future<void> unblockUser(int blockedUserId) async {
    await _apiClient.delete(FlatmatesEndpoints.block(blockedUserId));
  }
}

final blockedUsersRepositoryProvider = Provider<BlockedUsersRepository>(
  (ref) => BlockedUsersRepository(apiClient: ref.watch(apiClientProvider)),
);
