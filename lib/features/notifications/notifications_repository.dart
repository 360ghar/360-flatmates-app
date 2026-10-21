import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/endpoints.dart';
import '../../core/providers.dart';
import '../../core/utils/paged_envelope.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.referenceId,
    this.route,
  });

  final String id;
  final String
  type; // 'new_match', 'new_message', 'listing_approved', 'visit_scheduled', 'visit_confirmed'
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final int? referenceId; // conversation_id, listing_id, visit_id etc.
  final String? route;

  /// Throws [FormatException] when `created_at` is not readable, so the list
  /// parser skips the row instead of dating it at the epoch.
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '');
    if (createdAt == null) {
      throw FormatException(
        'notification ${json['id']} has no readable created_at: '
        '${json['created_at']}',
      );
    }
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: createdAt,
      referenceId: (json['reference_id'] as num?)?.toInt(),
      route: json['route']?.toString(),
    );
  }
}

class NotificationsRepository {
  const NotificationsRepository(this._ref);

  final Ref _ref;

  /// Fetches a single page of the user's notifications using cursor pagination.
  /// The backend wraps all list endpoints in
  /// `{ items, next_cursor, has_more, limit }`.
  Future<({List<NotificationModel> items, String? nextCursor, bool hasMore})>
  fetchNotificationsPage({String? cursor, int limit = 20}) async {
    final queryParameters = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }
    final response = await _ref
        .read(apiClientProvider)
        .get(
          FlatmatesEndpoints.notifications,
          queryParameters: queryParameters,
        );
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    return parsePagedEnvelope(
      data,
      NotificationModel.fromJson,
      label: 'notifications',
    );
  }

  /// `GET /flatmates/notifications/unread-count`: the number of unread
  /// notifications across every page, not only the pages loaded.
  Future<int> fetchUnreadCount() async {
    final response = await _ref
        .read(apiClientProvider)
        .get(FlatmatesEndpoints.notificationsUnreadCount);
    final data = response.data;
    final count = data is Map ? (data['unread_count'] as num?)?.toInt() : null;
    if (count == null || count < 0) {
      throw const FormatException('unread-count has no unread_count');
    }
    return count;
  }

  Future<void> markAsRead(String notificationId) async {
    await _ref
        .read(apiClientProvider)
        .put(
          FlatmatesEndpoints.notificationDetail(notificationId),
          data: {'is_read': true},
        );
  }

  Future<void> markAllAsRead() async {
    await _ref
        .read(apiClientProvider)
        .put(
          FlatmatesEndpoints.notificationMarkAllRead,
          data: {'mark_all_read': true},
        );
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref),
);

/// The unread count of the signed-in account. Dropped when the page closes, so
/// it is read again when the page opens.
final notificationsUnreadCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(notificationsRepositoryProvider).fetchUnreadCount(),
);
