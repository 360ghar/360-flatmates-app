import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/endpoints.dart';
import '../../core/providers.dart';
import '../../core/utils/safe_json_list.dart';
import '../chats/chats_repository.dart';

class VisitItem {
  const VisitItem({
    required this.id,
    required this.propertyTitle,
    required this.status,
    required this.scheduledDate,
    required this.visitContext,
    this.conversationId,
    this.counterpartyUserId,
  });

  final int id;
  final String propertyTitle;
  final String status;
  final DateTime scheduledDate;
  final String visitContext;
  final int? conversationId;
  final int? counterpartyUserId;

  factory VisitItem.fromJson(Map<String, dynamic> json) {
    final property = Map<String, dynamic>.from(
      json['property'] as Map? ?? const {},
    );
    return VisitItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      propertyTitle: property['title'] as String? ?? 'Visit',
      status: json['status'] as String? ?? 'unknown',
      scheduledDate:
          DateTime.tryParse(json['scheduled_date'] as String? ?? '') ??
          DateTime.now(),
      visitContext: json['visit_context'] as String? ?? 'property_tour',
      conversationId: (json['conversation_id'] as num?)?.toInt(),
      counterpartyUserId: (json['counterparty_user_id'] as num?)?.toInt(),
    );
  }
}

class VisitsRepository {
  const VisitsRepository(this._ref);

  final Ref _ref;

  Future<List<VisitItem>> fetchVisits() async {
    final response = await _ref
        .read(apiClientProvider)
        .get(FlatmatesEndpoints.visits);
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    return safeJsonList(
      data['visits'] as List?,
      VisitItem.fromJson,
      label: 'visits',
    );
  }

  Future<int> scheduleFlatmateVisit({
    required int propertyId,
    required int counterpartyUserId,
    required int conversationId,
    required DateTime scheduledDate,
    String? note,
    String? timeSlotLabel,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.visits,
          data: {
            'property_id': propertyId,
            'scheduled_date': scheduledDate.toUtc().toIso8601String(),
            'visit_context': 'flatmate_meet',
            'counterparty_user_id': counterpartyUserId,
            'conversation_id': conversationId,
            if (timeSlotLabel != null && timeSlotLabel.trim().isNotEmpty)
              'time_slot_label': timeSlotLabel.trim(),
            if (note != null && note.trim().isNotEmpty)
              'special_requirements': note.trim(),
          },
        );
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    return (data['id'] as num?)?.toInt() ?? 0;
  }

  /// Schedules a visit and sends a best-effort notification message to the chat.
  /// If the chat message fails after the visit was scheduled, the visit still succeeds.
  Future<int> scheduleVisitAndNotify({
    required int propertyId,
    required int counterpartyUserId,
    required int conversationId,
    required DateTime scheduledDate,
    String? note,
    String? timeSlotLabel,
  }) async {
    final visitId = await scheduleFlatmateVisit(
      propertyId: propertyId,
      counterpartyUserId: counterpartyUserId,
      conversationId: conversationId,
      scheduledDate: scheduledDate,
      note: note,
      timeSlotLabel: timeSlotLabel,
    );
    // Best-effort notification
    try {
      final chatsRepo = _ref.read(chatsRepositoryProvider);
      await chatsRepo.sendMessage(
        conversationId: conversationId,
        messageType: 'visit_request',
        body:
            'Visit requested for ${timeSlotLabel ?? DateFormat('d MMM, h:mm a').format(scheduledDate.toLocal())}',
        metadata: {
          'visit_id': visitId,
          'status': 'scheduled',
          'scheduled_date': scheduledDate.toUtc().toIso8601String(),
          'time_slot_label': ?timeSlotLabel,
        },
      );
    } catch (e) {
      // Visit was scheduled; notification is best-effort
      debugPrint(
        'VisitsRepository.scheduleVisitAndNotify: chat notification failed: $e',
      );
    }
    return visitId;
  }

  Future<void> confirmVisit(int visitId) async {
    await _ref
        .read(apiClientProvider)
        .put(FlatmatesEndpoints.visit(visitId), data: {'status': 'confirmed'});
  }

  Future<void> rescheduleVisit(int visitId, DateTime newDate) async {
    await _ref
        .read(apiClientProvider)
        .put(
          FlatmatesEndpoints.visit(visitId),
          data: {
            'scheduled_date': newDate.toUtc().toIso8601String(),
            'status': 'requested',
          },
        );
  }

  Future<void> cancelVisit(int visitId) async {
    await _ref
        .read(apiClientProvider)
        .put(FlatmatesEndpoints.visit(visitId), data: {'status': 'cancelled'});
  }
}

final visitsRepositoryProvider = Provider<VisitsRepository>(
  (ref) => VisitsRepository(ref),
);

final visitsProvider = FutureProvider<List<VisitItem>>(
  (ref) => ref.watch(visitsRepositoryProvider).fetchVisits(),
);
