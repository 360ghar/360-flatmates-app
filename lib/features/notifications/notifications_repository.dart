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

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
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

  /// Backwards-compatible helper that returns the first page as a list.
  Future<List<NotificationModel>> fetchNotifications() async {
    final page = await fetchNotificationsPage();
    return page.items;
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
