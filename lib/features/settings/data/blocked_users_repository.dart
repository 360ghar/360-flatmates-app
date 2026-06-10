import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../core/utils/safe_json_list.dart';
import 'blocked_user_model.dart';

class BlockedUsersRepository {
  const BlockedUsersRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<BlockedUser>> getBlockedUsers() async {
    final response = await _apiClient.get(FlatmatesEndpoints.blocks);
    final data = response.data;
    return safeJsonList(
      data is List ? data : null,
      BlockedUser.fromJson,
      label: 'blockedUsers',
    );
  }

  Future<void> unblockUser(int blockedUserId) async {
    await _apiClient.delete(FlatmatesEndpoints.block(blockedUserId));
  }
}

final blockedUsersRepositoryProvider = Provider<BlockedUsersRepository>(
  (ref) => BlockedUsersRepository(apiClient: ref.watch(apiClientProvider)),
);

final blockedUsersProvider = FutureProvider<List<BlockedUser>>((ref) {
  return ref.watch(blockedUsersRepositoryProvider).getBlockedUsers();
});
