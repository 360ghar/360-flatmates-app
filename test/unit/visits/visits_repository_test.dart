import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/domain/wire_enums.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/visits/visits_repository.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';
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

/// A visit as `POST /visits`, `PUT /visits/{id}` and the list send it.
Map<String, dynamic> _visit(int id, {Map<String, dynamic> extra = const {}}) =>
    {
      'id': id,
      'property_id': 42,
      'user_id': 1,
      'scheduled_date': '2025-05-20T15:00:00Z',
      'time_slot_label': null,
      'status': 'requested',
      'visit_context': 'flatmate_meet',
      'conversation_id': 10,
      'counterparty_user_id': 2,
      'counterparty_user': {
        'id': 2,
        'display_name': 'Priya P',
        'avatar_url': 'https://cdn.example.com/u/2.jpg',
      },
      'property': {'id': 42, 'title': 'Flat A'},
      ...extra,
    };

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
              data: _visit(77, extra: {'time_slot_label': 'Afternoon'}),
              statusCode: 201,
              requestOptions: options,
            );
          }
          return Response<dynamic>(
            data: {},
            statusCode: 201,
            requestOptions: options,
          );
        });

        final repo = container.read(visitsRepositoryProvider);
        final locale = await AppLocalizations.delegate.load(const Locale('en'));
        final visit = await repo.scheduleVisitAndNotify(
          propertyId: 42,
          counterpartyUserId: 2,
          conversationId: 10,
          scheduledDate: DateTime.utc(2025, 5, 20, 15),
          locale: locale,
          note: 'Excited to see it',
          timeSlotLabel: 'Afternoon',
        );

        expect(visit.id, 77);
        // The slot is stored by the server and comes back on the visit.
        expect(visit.timeSlotLabel, 'Afternoon');

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
        // The date is UTC with a Z: the API refuses a time with no offset.
        expect(visitData['scheduled_date'], '2025-05-20T15:00:00.000Z');
        // Keys VisitCreate does not declare are a 422.
        expect(visitData.containsKey('visit_notes'), isFalse);

        final messagePost = requests.firstWhere(
          (r) =>
              r.path == '/flatmates/conversations/10/messages' &&
              r.method == 'POST',
        );
        final messageData = Map<String, dynamic>.from(messagePost.data as Map);
        // `visit_request` is a 422 for a client: the card is a text message
        // with the visit in its metadata.
        expect(messageData['message_type'], 'text');
        expect(messageData['body'], contains('Afternoon'));
        final metadata = messageData['metadata'] as Map<String, dynamic>;
        expect(metadata['visit_id'], 77);
        expect(metadata['status'], 'requested');
        expect(metadata['time_slot_label'], 'Afternoon');
      },
    );

    test('a time slot label longer than 64 characters is cut', () async {
      Map<String, dynamic>? sent;
      final container = _containerWithAdapter((options) {
        sent = Map<String, dynamic>.from(options.data as Map);
        return Response<dynamic>(
          data: _visit(78),
          statusCode: 201,
          requestOptions: options,
        );
      });

      await container
          .read(visitsRepositoryProvider)
          .scheduleFlatmateVisit(
            propertyId: 42,
            counterpartyUserId: 2,
            conversationId: 10,
            scheduledDate: DateTime.utc(2025, 5, 20, 15),
            timeSlotLabel: 'x' * 90,
          );

      expect((sent!['time_slot_label'] as String).length, 64);
    });

    test('fetchVisits reads every status and the counterparty', () async {
      final container = _containerWithAdapter((options) {
        return Response<dynamic>(
          data: {
            'items': [
              _visit(1, extra: {'status': 'confirmed'}),
              _visit(
                2,
                extra: {
                  'status': 'requested',
                  'property': {'id': 43, 'title': 'Flat B'},
                  'visit_context': 'property_tour',
                  'time_slot_label': 'Morning',
                },
              ),
              _visit(3, extra: {'status': 'cancelled'}),
              _visit(4, extra: {'status': 'reschedule_suggested'}),
            ],
            'next_cursor': null,
            'has_more': false,
            'limit': 100,
            'total': null,
          },
          statusCode: 200,
          requestOptions: options,
        );
      });

      final visits = await container
          .read(visitsRepositoryProvider)
          .fetchVisits();

      expect(visits.map((v) => v.status), [
        VisitStatus.confirmed,
        VisitStatus.requested,
        VisitStatus.cancelled,
        VisitStatus.rescheduleSuggested,
      ]);
      expect(visits[0].propertyTitle, 'Flat A');
      expect(visits[1].visitContext, VisitContext.propertyTour);
      expect(visits[1].timeSlotLabel, 'Morning');
      // The counterparty is a name and an avatar, nothing else.
      expect(visits[0].counterparty!.id, 2);
      expect(visits[0].counterparty!.displayName, 'Priya P');
      expect(
        visits[0].counterparty!.avatarUrl,
        'https://cdn.example.com/u/2.jpg',
      );
    });

    test('fetchVisits follows next_cursor and sends limit 100', () async {
      final queries = <Map<String, dynamic>>[];
      final container = _containerWithAdapter((options) {
        queries.add(Map<String, dynamic>.from(options.queryParameters));
        final first = options.queryParameters['cursor'] == null;
        return Response<dynamic>(
          data: {
            'items': [_visit(first ? 1 : 2)],
            'next_cursor': first ? 'page-2' : null,
            'has_more': first,
            'limit': 100,
            'total': null,
          },
          statusCode: 200,
          requestOptions: options,
        );
      });

      final visits = await container
          .read(visitsRepositoryProvider)
          .fetchVisits();

      expect(visits.map((v) => v.id), [1, 2]);
      expect(queries.map((q) => q['limit']), [100, 100]);
      expect(queries.map((q) => q['cursor']), [null, 'page-2']);
    });

    test('a visit with an unreadable date is skipped, not shown now', () async {
      final container = _containerWithAdapter((options) {
        return Response<dynamic>(
          data: {
            'items': [
              _visit(1),
              _visit(2, extra: {'scheduled_date': 'not a date'}),
              _visit(3, extra: {'scheduled_date': null}),
            ],
            'next_cursor': null,
            'has_more': false,
            'limit': 20,
            'total': null,
          },
          statusCode: 200,
          requestOptions: options,
        );
      });

      final visits = await container
          .read(visitsRepositoryProvider)
          .fetchVisits();

      expect(visits.map((v) => v.id), [1]);
    });

    test('a status this build does not know is null, not a real status', () {
      final visit = VisitItem.fromJson(_visit(9, extra: {'status': 'ghosted'}));

      expect(visit.status, isNull);
    });

    test(
      'confirmVisit puts the confirmed status and returns the visit',
      () async {
        Map<String, dynamic>? sentData;
        String? method;
        String? path;
        final container = _containerWithAdapter((options) {
          method = options.method;
          path = options.path;
          sentData = Map<String, dynamic>.from(options.data as Map);
          return Response<dynamic>(
            data: _visit(5, extra: {'status': 'confirmed'}),
            statusCode: 200,
            requestOptions: options,
          );
        });

        final visit = await container
            .read(visitsRepositoryProvider)
            .confirmVisit(5);

        expect(method, 'PUT');
        expect(path, '/visits/5');
        expect(sentData, {'status': 'confirmed'});
        expect(visit.status, VisitStatus.confirmed);
      },
    );

    test(
      'rescheduleVisit posts new_date with an offset and a reason',
      () async {
        Map<String, dynamic>? sentData;
        String? method;
        String? path;
        final container = _containerWithAdapter((options) {
          method = options.method;
          path = options.path;
          sentData = Map<String, dynamic>.from(options.data as Map);
          return Response<dynamic>(
            data: _visit(
              5,
              extra: {
                'status': 'reschedule_suggested',
                'scheduled_date': '2025-05-22T09:00:00Z',
              },
            ),
            statusCode: 200,
            requestOptions: options,
          );
        });

        final visit = await container
            .read(visitsRepositoryProvider)
            .rescheduleVisit(
              5,
              DateTime.utc(2025, 5, 22, 9),
              reason: 'Traffic',
            );

        expect(method, 'POST');
        expect(path, '/visits/5/reschedule');
        expect(sentData, {
          'new_date': '2025-05-22T09:00:00.000Z',
          'reason': 'Traffic',
        });
        // The returned visit carries the new state.
        expect(visit.status, VisitStatus.rescheduleSuggested);
        expect(visit.scheduledDate, DateTime.utc(2025, 5, 22, 9));
      },
    );

    test('cancelVisit posts the reason to the cancel route', () async {
      Map<String, dynamic>? sentData;
      String? method;
      String? path;
      final container = _containerWithAdapter((options) {
        method = options.method;
        path = options.path;
        sentData = Map<String, dynamic>.from(options.data as Map);
        return Response<dynamic>(
          data: _visit(
            8,
            extra: {
              'status': 'cancelled',
              'cancellation_reason': 'Plans changed',
            },
          ),
          statusCode: 200,
          requestOptions: options,
        );
      });

      final visit = await container
          .read(visitsRepositoryProvider)
          .cancelVisit(8, reason: '  Plans changed  ');

      // Never PUT with status cancelled: that is a 422 now.
      expect(method, 'POST');
      expect(path, '/visits/8/cancel');
      expect(sentData, {'reason': 'Plans changed'});
      expect(visit.status, VisitStatus.cancelled);
      expect(visit.cancellationReason, 'Plans changed');
    });
  });
}
