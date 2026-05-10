import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/endpoints.dart';
import '../../core/providers.dart';

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

  Future<List<NotificationModel>> fetchNotifications() async {
    final response = await _ref
        .read(apiClientProvider)
        .get(FlatmatesEndpoints.notifications);
    final rows = (response.data as List? ?? const []);
    return rows
        .whereType<Map>()
        .map(
          (item) => NotificationModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
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

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) {
  return ref.watch(notificationsRepositoryProvider).fetchNotifications();
});
