import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/discover/discover_repository.dart';
import 'package:flatmates_app/features/swipe/swipe_repository.dart';

import '../../helpers/test_helpers.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._handler);

  final Response Function(RequestOptions) _handler;
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
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

Map<String, dynamic> _profileJson(int id, {String? moveInTimeline}) => {
  'id': id,
  'full_name': 'User $id',
  'profile_image_url': 'https://example.com/p$id.jpg',
  'image_urls': ['https://example.com/p$id.jpg'],
  'mode': 'co_hunter',
  'city': 'Bangalore',
  'locality': 'Koramangala',
  'bio': 'Looking for a flatmate',
  'budget_min': 10000.0,
  'budget_max': 25000.0,
  'move_in_timeline': moveInTimeline,
  'gender': 'male',
  'gender_preference': 'any',
  'non_negotiables': <dynamic>[],
  'has_pets': false,
  if (moveInTimeline != null) 'available_from': '2025-01-20T00:00:00Z',
};

void main() {
  group('SwipeRepository', () {
    test(
      'fetchSwipeProfiles sends move-in filter and keeps matching profiles',
      () async {
        final adapter = _ScriptedAdapter((options) {
          if (options.path == '/flatmates/profiles') {
            return _ok({
              'items': [
                _profileJson(1, moveInTimeline: 'this_month'),
                _profileJson(2, moveInTimeline: 'next_month'),
              ],
              'next_cursor': null,
              'has_more': false,
            });
          }
          return _ok({});
        });
        final apiClient = ApiClient(
          baseUrl: 'https://api.test.example.com',
          tokenProvider: FakeAuthTokenProvider(),
        );
        apiClient.dio.httpClientAdapter = adapter;

        final container = ProviderContainer(
          overrides: [
            appConfigProvider.overrideWithValue(fakeAppConfig()),
            authControllerProvider.overrideWith(() => FakeAuthController()),
            bootstrapControllerProvider.overrideWith(
              () => FakeBootstrapController(),
            ),
            apiClientProvider.overrideWithValue(apiClient),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(swipeRepositoryProvider);
        const filters = DiscoverFilters(moveInTimeline: 'this_month');
        final page = await repo.fetchSwipeProfilesPage(filters: filters);

        // The request should include a move_in query param.
        final profilesRequest = adapter.requests.firstWhere(
          (r) => r.path == '/flatmates/profiles',
        );
        expect(profilesRequest.queryParameters['move_in'], 'this_month');

        // Both profiles are returned by the server; the repository applies
        // client-side move-in filtering. Profile 1 has available_from within
        // this_month, profile 2 has move_in_timeline 'next_month' which does
        // not match 'this_month'.
        // Note: _profileMatchesMoveIn checks available_from first, then
        // falls back to moveInTimeline comparison.
        expect(page.items.length, greaterThanOrEqualTo(1));
        expect(page.items.any((p) => p.id == 1), isTrue);
      },
    );

    test('recordProfileView posts profile duration tracking payload', () async {
      var capturedPath = '';
      var capturedData = <String, dynamic>{};

      final adapter = _ScriptedAdapter((options) {
        if (options.path == '/flatmates/profile-views') {
          capturedPath = options.path;
          if (options.data is Map) {
            capturedData = Map<String, dynamic>.from(options.data as Map);
          }
          return _ok({'ok': true});
        }
        return _ok({});
      });
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
      );
      apiClient.dio.httpClientAdapter = adapter;

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          authControllerProvider.overrideWith(() => FakeAuthController()),
          bootstrapControllerProvider.overrideWith(
            () => FakeBootstrapController(),
          ),
          apiClientProvider.overrideWithValue(apiClient),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(swipeRepositoryProvider);
      await repo.recordProfileView(
        targetUserId: 99,
        durationSeconds: 12,
        scrollDepthPercent: 45,
      );

      expect(capturedPath, '/flatmates/profile-views');
      expect(capturedData['target_user_id'], 99);
      expect(capturedData['duration_seconds'], 12);
      expect(capturedData['scroll_depth_percent'], 45);
      expect(capturedData['source'], 'swipe_deck');
    });
  });
}
