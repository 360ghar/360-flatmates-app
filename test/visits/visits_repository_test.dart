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
          enableLogging: false,
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
  });
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
