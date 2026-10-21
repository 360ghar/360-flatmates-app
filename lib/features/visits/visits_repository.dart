import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/endpoints.dart';
import '../../core/domain/wire_enums.dart';
import '../../core/providers.dart';
import '../../core/utils/paged_envelope.dart';
import '../../l10n/gen/app_localizations.dart';
import '../chats/chats_repository.dart';

/// The other person of a visit: a name and an avatar, nothing else
/// (`PublicUserRef`).
class VisitCounterparty {
  const VisitCounterparty({required this.id, this.displayName, this.avatarUrl});

  final int id;
  final String? displayName;
  final String? avatarUrl;

  /// Null when the object has no usable id.
  static VisitCounterparty? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = (json['id'] as num?)?.toInt();
    if (id == null || id <= 0) return null;
    return VisitCounterparty(
      id: id,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class VisitItem {
  const VisitItem({
    required this.id,
    required this.propertyTitle,
    required this.status,
    required this.scheduledDate,
    required this.visitContext,
    this.conversationId,
    this.counterpartyUserId,
    this.timeSlotLabel,
    this.counterparty,
    this.cancellationReason,
  });

  final int id;
  final String propertyTitle;

  /// Null for a status this build does not know.
  final VisitStatus? status;
  final DateTime scheduledDate;

  /// Null for a context this build does not know.
  final VisitContext? visitContext;
  final int? conversationId;
  final int? counterpartyUserId;

  /// The slot the visitor chose (`morning`, an hour range, ...), as stored by
  /// the server. Null when the visit was requested without one.
  final String? timeSlotLabel;
  final VisitCounterparty? counterparty;

  /// The reason sent with a cancel (or a reschedule).
  final String? cancellationReason;

  /// This visit with the fields the server changes taken from [fresh] (the
  /// visit a confirm, reschedule or cancel call returned). The property title
  /// stays: the action responses do not always carry the property.
  VisitItem withServerState(VisitItem fresh) => VisitItem(
    id: id,
    propertyTitle: propertyTitle,
    status: fresh.status,
    scheduledDate: fresh.scheduledDate,
    visitContext: fresh.visitContext ?? visitContext,
    conversationId: conversationId,
    counterpartyUserId: counterpartyUserId,
    timeSlotLabel: fresh.timeSlotLabel ?? timeSlotLabel,
    counterparty: counterparty,
    cancellationReason: fresh.cancellationReason ?? cancellationReason,
  );

  /// Throws [FormatException] when `scheduled_date` is missing or not a date:
  /// a visit at an invented time is worse than no row, so list parsing skips
  /// it (and logs).
  factory VisitItem.fromJson(Map<String, dynamic> json) {
    final scheduled = DateTime.tryParse(
      json['scheduled_date'] as String? ?? '',
    );
    if (scheduled == null) {
      throw FormatException(
        'visit ${json['id']} has no readable scheduled_date: '
        '${json['scheduled_date']}',
      );
    }
    final property = Map<String, dynamic>.from(
      json['property'] as Map? ?? const {},
    );
    final slot = (json['time_slot_label'] as String?)?.trim();
    return VisitItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      propertyTitle: property['title'] as String? ?? 'Visit',
      status: VisitStatus.fromJson(json['status']),
      scheduledDate: scheduled,
      visitContext: VisitContext.fromJson(json['visit_context']),
      conversationId: (json['conversation_id'] as num?)?.toInt(),
      counterpartyUserId: (json['counterparty_user_id'] as num?)?.toInt(),
      timeSlotLabel: slot == null || slot.isEmpty ? null : slot,
      counterparty: VisitCounterparty.tryParse(json['counterparty_user']),
      cancellationReason: json['cancellation_reason'] as String?,
    );
  }
}

class VisitsRepository {
  const VisitsRepository(this._ref);

  final Ref _ref;

  /// Fetches a single page of the user's visits using cursor pagination.
  ///
  /// Returns the parsed items plus the cursor metadata callers need to fetch
  /// the next page. The backend wraps all list endpoints in
  /// `{ items, next_cursor, has_more, limit }`.
  Future<({List<VisitItem> items, String? nextCursor, bool hasMore})>
  fetchVisitsPage({String? cursor, int limit = 20}) async {
    final queryParameters = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }
    final response = await _ref
        .read(apiClientProvider)
        .get(FlatmatesEndpoints.visits, queryParameters: queryParameters);
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    return parsePagedEnvelope(data, VisitItem.fromJson, label: 'visits');
  }

  /// The full list: follows `next_cursor` until the list ends.
  Future<List<VisitItem>> fetchVisits() async {
    final items = <VisitItem>[];
    String? cursor;
    while (true) {
      final page = await fetchVisitsPage(cursor: cursor, limit: 100);
      items.addAll(page.items);
      if (!page.hasMore ||
          page.nextCursor == null ||
          page.nextCursor!.isEmpty) {
        break;
      }
      cursor = page.nextCursor;
    }
    return items;
  }

  /// `POST /visits` for a flatmate meet. Returns the created visit.
  ///
  /// [timeSlotLabel] is stored by the server (max 64 characters). The date is
  /// sent as UTC with a `Z`: the API refuses a time with no offset.
  Future<VisitItem> scheduleFlatmateVisit({
    required int propertyId,
    required int counterpartyUserId,
    required int conversationId,
    required DateTime scheduledDate,
    String? note,
    String? timeSlotLabel,
  }) async {
    final slot = timeSlotLabel?.trim();
    final response = await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.visits,
          data: {
            'property_id': propertyId,
            'scheduled_date': scheduledDate.toUtc().toIso8601String(),
            'visit_context': VisitContext.flatmateMeet.wire,
            'counterparty_user_id': counterpartyUserId,
            'conversation_id': conversationId,
            if (slot != null && slot.isNotEmpty)
              'time_slot_label': slot.length > 64
                  ? slot.substring(0, 64)
                  : slot,
            if (note != null && note.trim().isNotEmpty)
              'special_requirements': note.trim(),
          },
        );
    return _visitFrom(response.data);
  }

  VisitItem _visitFrom(Object? body) =>
      VisitItem.fromJson(Map<String, dynamic>.from(body as Map? ?? const {}));

  /// Schedules a visit and sends a best-effort notification message to the chat.
  /// If the chat message fails after the visit was scheduled, the visit still succeeds.
  Future<VisitItem> scheduleVisitAndNotify({
    required int propertyId,
    required int counterpartyUserId,
    required int conversationId,
    required DateTime scheduledDate,
    required AppLocalizations locale,
    String? note,
    String? timeSlotLabel,
  }) async {
    final visit = await scheduleFlatmateVisit(
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
        // Sent as a `text` message (the default): the API takes `text` or
        // `image` from a client, and a `visit_request` message is a 422. The
        // visit id in the metadata makes it a card.
        // Persisted server-side and shown verbatim to the recipient, so format
        // with the sender's locale and localize the prefix. Only messages
        // created after this change carry the localized form.
        body: locale.visitRequestedFor(
          timeSlotLabel ??
              DateFormat(
                'd MMM, h:mm a',
                locale.localeName,
              ).format(scheduledDate.toLocal()),
        ),
        metadata: {
          'visit_id': visit.id,
          'status': VisitStatus.requested.wire,
          'scheduled_date': scheduledDate.toUtc().toIso8601String(),
          if (timeSlotLabel != null && timeSlotLabel.trim().isNotEmpty)
            'time_slot_label': timeSlotLabel.trim(),
        },
      );
    } catch (e) {
      // Visit was scheduled; notification is best-effort
      debugPrint(
        'VisitsRepository.scheduleVisitAndNotify: chat notification failed: $e',
      );
    }
    return visit;
  }

  /// `PUT /visits/{id}` with status `confirmed` (the only status this route
  /// takes). Returns the updated visit.
  Future<VisitItem> confirmVisit(int visitId) async {
    final response = await _ref
        .read(apiClientProvider)
        .put(
          FlatmatesEndpoints.visit(visitId),
          data: {'status': VisitStatus.confirmed.wire},
        );
    return _visitFrom(response.data);
  }

  /// Suggests a new visit time via `POST /visits/{id}/reschedule`. The server
  /// moves the visit to `reschedule_suggested` and returns it. [reason] is
  /// optional.
  Future<VisitItem> rescheduleVisit(
    int visitId,
    DateTime newDate, {
    String? reason,
  }) async {
    final text = reason?.trim();
    final response = await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.visitReschedule(visitId),
          data: {
            'new_date': newDate.toUtc().toIso8601String(),
            if (text != null && text.isNotEmpty) 'reason': text,
          },
        );
    return _visitFrom(response.data);
  }

  /// Cancels via `POST /visits/{id}/cancel`, which stores [reason] (required,
  /// 1 to 1000 characters) as the cancellation reason, and returns the visit.
  Future<VisitItem> cancelVisit(int visitId, {required String reason}) async {
    final text = reason.trim();
    final response = await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.visitCancel(visitId),
          data: {'reason': text.length > 1000 ? text.substring(0, 1000) : text},
        );
    return _visitFrom(response.data);
  }
}

final visitsRepositoryProvider = Provider<VisitsRepository>(
  (ref) => VisitsRepository(ref),
);

final visitsProvider = FutureProvider<List<VisitItem>>(
  (ref) => ref.watch(visitsRepositoryProvider).fetchVisits(),
);
