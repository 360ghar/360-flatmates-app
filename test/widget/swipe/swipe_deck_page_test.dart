import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/swipe/swipe_deck_page.dart';
import 'package:flatmates_app/features/swipe/presentation/widgets/swipe_deck_header.dart';

import '../../helpers/test_helpers.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._handler);

  final Response Function(RequestOptions) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = _handler(options);
    return ResponseBody.fromString(
      jsonEncode(response.data),
      response.statusCode ?? 200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

Response _ok(Object data) =>
    Response(data: data, statusCode: 200, requestOptions: RequestOptions());

Map<String, dynamic> _profileJson(int id) => {
  'id': id,
  'full_name': 'User $id',
  'profile_image_url': null,
  'image_urls': <dynamic>[],
  'mode': 'co_hunter',
  'city': 'Bangalore',
  'locality': 'Koramangala',
  'bio': 'Looking for a flatmate',
  'budget_min': 10000.0,
  'budget_max': 25000.0,
  'move_in_timeline': 'flexible',
  'gender': 'male',
  'gender_preference': 'any',
  'non_negotiables': <dynamic>[],
  'has_pets': false,
};

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SwipeDeckPage', () {
    testWidgets('renders swipe card and filter tune when data is available', (
      tester,
    ) async {
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
      );
      apiClient.dio.httpClientAdapter = _ScriptedAdapter((options) {
        if (options.path == '/flatmates/profiles') {
          return _ok({
            'items': [_profileJson(1), _profileJson(2)],
            'next_cursor': null,
            'has_more': false,
          });
        }
        return _ok({});
      });

      final widget = await testableWidgetAsync(
        child: const SwipeDeckPage(),
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
      );

      await tester.pumpWidget(widget);
      // Use pump() instead of pumpAndSettle() because the page may have
      // continuous animations that never settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // The swipe card (SwipeCardStack keyed 'swipe_card') should be present.
      expect(find.byKey(const Key('swipe_card')), findsOneWidget);

      // The filter tune button should be present.
      expect(find.byKey(const Key('swipe_filter_tune')), findsOneWidget);
    });

    testWidgets('renders empty state when no profiles are available', (
      tester,
    ) async {
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
      );
      apiClient.dio.httpClientAdapter = _ScriptedAdapter((options) {
        if (options.path == '/flatmates/profiles') {
          return _ok({
            'items': <dynamic>[],
            'next_cursor': null,
            'has_more': false,
          });
        }
        return _ok({});
      });

      final widget = await testableWidgetAsync(
        child: const SwipeDeckPage(),
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
      );

      await tester.pumpWidget(widget);
      // Use pump() instead of pumpAndSettle() because the page may have
      // continuous animations that never settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // No swipe card should be rendered.
      expect(find.byKey(const Key('swipe_card')), findsNothing);

      // The filter tune header should still be present (it's always shown).
      expect(find.byType(SwipeDeckHeader), findsOneWidget);
    });
  });
}
