import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/visits/visits_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/test_helpers.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.handler);
  final Response<dynamic> Function(RequestOptions) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = handler(options);
    return ResponseBody.fromString(
      jsonEncode(response.data),
      response.statusCode ?? 200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

ProviderContainer _containerWithAdapter(
  Response<dynamic> Function(RequestOptions) handler,
) {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(fakeAppConfig()),
      authTokenProviderProvider.overrideWithValue(FakeAuthTokenProvider()),
      apiClientProvider.overrideWithValue(
        ApiClient(
          baseUrl: 'https://api.test.example.com',
          tokenProvider: FakeAuthTokenProvider(),
        )..dio.httpClientAdapter = _ScriptedAdapter(handler),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('VisitsRepository', () {
    test(
      'scheduleVisitAndNotify creates structured visit request message',
      () async {
        final requests = <RequestOptions>[];
        final container = _containerWithAdapter((options) {
          requests.add(options);
          if (options.path == '/visits' && options.method == 'POST') {
            return Response<dynamic>(
              data: {'id': 77},
              statusCode: 200,
              requestOptions: options,
            );
          }
          // Chat message POST.
          if (options.path == '/flatmates/conversations/10/messages' &&
              options.method == 'POST') {
            return Response<dynamic>(
              data: {},
              statusCode: 200,
              requestOptions: options,
            );
          }
          return Response<dynamic>(
            data: {},
            statusCode: 200,
            requestOptions: options,
          );
        });

        final repo = container.read(visitsRepositoryProvider);
        final visitId = await repo.scheduleVisitAndNotify(
          propertyId: 42,
          counterpartyUserId: 2,
          conversationId: 10,
          scheduledDate: DateTime.utc(2025, 5, 20, 15),
          note: 'Excited to see it',
          timeSlotLabel: 'Afternoon',
        );

        expect(visitId, 77);

        // First request: the visit POST.
        final visitPost = requests.firstWhere(
          (r) => r.path == '/visits' && r.method == 'POST',
        );
        final visitData = Map<String, dynamic>.from(visitPost.data as Map);
        expect(visitData['property_id'], 42);
        expect(visitData['counterparty_user_id'], 2);
        expect(visitData['conversation_id'], 10);
        expect(visitData['visit_context'], 'flatmate_meet');
        expect(visitData['time_slot_label'], 'Afternoon');
        expect(visitData['special_requirements'], 'Excited to see it');

        // Second request: the chat notification message.
        final messagePost = requests.firstWhere(
          (r) =>
              r.path == '/flatmates/conversations/10/messages' &&
              r.method == 'POST',
        );
        final messageData = Map<String, dynamic>.from(messagePost.data as Map);
        expect(messageData['message_type'], 'visit_request');
        expect(messageData['body'], contains('Afternoon'));
        final metadata = messageData['metadata'] as Map<String, dynamic>;
        expect(metadata['visit_id'], 77);
        expect(metadata['status'], 'requested');
        expect(metadata['time_slot_label'], 'Afternoon');
      },
    );

    test('fetchVisits returns visits grouped by status', () async {
      final container = _containerWithAdapter((options) {
        return Response<dynamic>(
          data: {
            'items': [
              {
                'id': 1,
                'property': {'title': 'Flat A'},
                'status': 'confirmed',
                'scheduled_date': '2025-05-20T15:00:00Z',
                'visit_context': 'flatmate_meet',
                'conversation_id': 10,
              },
              {
                'id': 2,
                'property': {'title': 'Flat B'},
                'status': 'requested',
                'scheduled_date': '2025-05-21T10:00:00Z',
                'visit_context': 'property_tour',
              },
              {
                'id': 3,
                'property': {'title': 'Flat C'},
                'status': 'cancelled',
                'scheduled_date': '2025-05-18T10:00:00Z',
                'visit_context': 'flatmate_meet',
              },
            ],
            'next_cursor': null,
            'has_more': false,
          },
          statusCode: 200,
          requestOptions: options,
        );
      });

      final repo = container.read(visitsRepositoryProvider);
      final visits = await repo.fetchVisits();

      expect(visits.length, 3);
      final byStatus = {for (final v in visits) v.status: v};
      expect(
        byStatus.keys,
        containsAll(['confirmed', 'requested', 'cancelled']),
      );
      expect(byStatus['confirmed']!.propertyTitle, 'Flat A');
    });

    test('confirmVisit posts confirmation payload', () async {
      Map<String, dynamic>? sentData;
      String? method;
      String? path;
      final container = _containerWithAdapter((options) {
        method = options.method;
        path = options.path;
        sentData = options.data is Map
            ? Map<String, dynamic>.from(options.data as Map)
            : null;
        return Response<dynamic>(
          data: {},
          statusCode: 200,
          requestOptions: options,
        );
      });

      final repo = container.read(visitsRepositoryProvider);
      await repo.confirmVisit(5);

      expect(method, 'PUT');
      expect(path, '/visits/5');
      expect(sentData!['status'], 'confirmed');
    });

    test('cancelVisit posts cancellation payload', () async {
      Map<String, dynamic>? sentData;
      String? method;
      String? path;
      final container = _containerWithAdapter((options) {
        method = options.method;
        path = options.path;
        sentData = options.data is Map
            ? Map<String, dynamic>.from(options.data as Map)
            : null;
        return Response<dynamic>(
          data: {},
          statusCode: 200,
          requestOptions: options,
        );
      });

      final repo = container.read(visitsRepositoryProvider);
      await repo.cancelVisit(8);

      expect(method, 'PUT');
      expect(path, '/visits/8');
      expect(sentData!['status'], 'cancelled');
    });
  });
}
