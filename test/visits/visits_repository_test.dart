import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/config/endpoints.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/visits/visits_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('VisitsRepository', () {
    test(
      'scheduleVisitAndNotify creates structured visit request message',
      () async {
        final adapter = _QueueAdapter([
          {'id': 88},
          {'id': 501},
        ]);
        final apiClient = ApiClient(
          baseUrl: 'https://api.test.example.com',
          tokenProvider: FakeAuthTokenProvider(),
        );
        apiClient.dio.httpClientAdapter = adapter;
        final container = ProviderContainer(
          overrides: [apiClientProvider.overrideWithValue(apiClient)],
        );
        addTearDown(container.dispose);

        final scheduledDate = DateTime.utc(2026, 5, 8, 9, 30);
        final visitId = await container
            .read(visitsRepositoryProvider)
            .scheduleVisitAndNotify(
              propertyId: 12,
              counterpartyUserId: 44,
              conversationId: 5,
              scheduledDate: scheduledDate,
              note: 'Main gate',
              timeSlotLabel: 'Morning',
            );

        expect(visitId, 88);
        expect(adapter.requests, hasLength(2));
        expect(adapter.requests.first.path, FlatmatesEndpoints.visits);
        expect(adapter.requests.first.data, {
          'property_id': 12,
          'scheduled_date': scheduledDate.toIso8601String(),
          'visit_context': 'flatmate_meet',
          'counterparty_user_id': 44,
          'conversation_id': 5,
          'time_slot_label': 'Morning',
          'special_requirements': 'Main gate',
        });
        expect(
          adapter.requests.last.path,
          FlatmatesEndpoints.conversationMessages(5),
        );
        expect(adapter.requests.last.data, {
          'body': 'Visit requested for Morning',
          'message_type': 'visit_request',
          'metadata': {
            'visit_id': 88,
            'status': 'scheduled',
            'scheduled_date': scheduledDate.toIso8601String(),
            'time_slot_label': 'Morning',
          },
        });
      },
    );

    test(
      'scheduleVisit still returns id when chat notification fails',
      () async {
        // First call (create visit) succeeds; second (chat message) 500s.
        final adapter = _StatusQueueAdapter([
          const _FakeResponse(200, {'id': 73}),
          const _FakeResponse(500, {'detail': 'boom'}),
        ]);
        final container = _containerWith(adapter);
        addTearDown(container.dispose);

        final visitId = await container
            .read(visitsRepositoryProvider)
            .scheduleVisitAndNotify(
              propertyId: 1,
              counterpartyUserId: 2,
              conversationId: 3,
              scheduledDate: DateTime.utc(2026, 6, 1, 10),
            );

        // Visit creation is authoritative; best-effort notification failure is
        // swallowed so the user still sees a scheduled visit.
        expect(visitId, 73);
        expect(adapter.requests, hasLength(2));
      },
    );

    test(
      'confirmVisit PUTs the confirmed status to the visit endpoint',
      () async {
        final adapter = _StatusQueueAdapter([const _FakeResponse(200, {})]);
        final container = _containerWith(adapter);
        addTearDown(container.dispose);

        await container.read(visitsRepositoryProvider).confirmVisit(42);

        expect(adapter.requests.single.method, 'PUT');
        expect(adapter.requests.single.path, FlatmatesEndpoints.visit(42));
        expect(adapter.requests.single.data, {'status': 'confirmed'});
      },
    );

    test('cancelVisit PUTs the cancelled status', () async {
      final adapter = _StatusQueueAdapter([const _FakeResponse(200, {})]);
      final container = _containerWith(adapter);
      addTearDown(container.dispose);

      await container.read(visitsRepositoryProvider).cancelVisit(9);

      expect(adapter.requests.single.data, {'status': 'cancelled'});
    });

    test(
      'rescheduleVisit sends UTC date and resets status to requested',
      () async {
        final adapter = _StatusQueueAdapter([const _FakeResponse(200, {})]);
        final container = _containerWith(adapter);
        addTearDown(container.dispose);

        // A local time is converted to UTC on the wire.
        final newDate = DateTime(2026, 7, 4, 15, 30);
        await container
            .read(visitsRepositoryProvider)
            .rescheduleVisit(5, newDate);

        expect(adapter.requests.single.method, 'PUT');
        expect(adapter.requests.single.path, FlatmatesEndpoints.visit(5));
        expect(adapter.requests.single.data, {
          'scheduled_date': newDate.toUtc().toIso8601String(),
          'status': 'requested',
        });
      },
    );

    test('fetchVisits parses the visits envelope into VisitItems', () async {
      final adapter = _StatusQueueAdapter([
        const _FakeResponse(200, {
          'visits': [
            {
              'id': 5,
              'status': 'confirmed',
              'scheduled_date': '2026-05-20T15:00:00Z',
              'visit_context': 'flatmate_meet',
              'conversation_id': 10,
              'counterparty_user_id': 2,
              'property': {'title': 'Modern 2BHK in Koramangala'},
            },
          ],
        }),
      ]);
      final container = _containerWith(adapter);
      addTearDown(container.dispose);

      final visits = await container
          .read(visitsRepositoryProvider)
          .fetchVisits();

      expect(visits, hasLength(1));
      final visit = visits.single;
      expect(visit.id, 5);
      expect(visit.status, 'confirmed');
      expect(visit.propertyTitle, 'Modern 2BHK in Koramangala');
      expect(visit.visitContext, 'flatmate_meet');
      expect(visit.conversationId, 10);
      expect(visit.counterpartyUserId, 2);
      expect(visit.scheduledDate, DateTime.utc(2026, 5, 20, 15));
    });

    test('fetchVisits tolerates a missing visits key and bad rows', () async {
      final adapter = _StatusQueueAdapter([const _FakeResponse(200, {})]);
      final container = _containerWith(adapter);
      addTearDown(container.dispose);

      final visits = await container
          .read(visitsRepositoryProvider)
          .fetchVisits();

      expect(visits, isEmpty);
    });
  });
}

ProviderContainer _containerWith(HttpClientAdapter adapter) {
  final apiClient = ApiClient(
    baseUrl: 'https://api.test.example.com',
    tokenProvider: FakeAuthTokenProvider(),
  );
  apiClient.dio.httpClientAdapter = adapter;
  return ProviderContainer(
    overrides: [apiClientProvider.overrideWithValue(apiClient)],
  );
}

class _FakeResponse {
  const _FakeResponse(this.statusCode, this.body);
  final int statusCode;
  final Object body;
}

/// Queue adapter that lets each response carry its own status code, so error
/// paths (e.g. a failing best-effort chat notification) can be exercised.
class _StatusQueueAdapter implements HttpClientAdapter {
  _StatusQueueAdapter(this._responses);

  final List<_FakeResponse> _responses;
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = _responses.isEmpty
        ? const _FakeResponse(200, {})
        : _responses.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _QueueAdapter implements HttpClientAdapter {
  _QueueAdapter(this._responses);

  final List<Object> _responses;
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = _responses.isEmpty ? const {} : _responses.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
