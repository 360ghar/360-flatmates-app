import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/config/endpoints.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/swipe/swipe_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

/// Builds a [ProviderContainer] whose bootstrap profile carries the given
/// non-negotiables, so the repository's deal-breaker filter has input.
ProviderContainer _containerWith({
  required _CapturingAdapter adapter,
  List<String> nonNegotiables = const [],
  String? genderPreference,
}) {
  final apiClient = ApiClient(
    baseUrl: 'https://api.test.example.com',
    tokenProvider: FakeAuthTokenProvider(),
  );
  apiClient.dio.httpClientAdapter = adapter;
  final container = ProviderContainer(
    overrides: [
      apiClientProvider.overrideWithValue(apiClient),
      bootstrapControllerProvider.overrideWith(
        () => _PrefsBootstrapController(
          nonNegotiables: nonNegotiables,
          genderPreference: genderPreference,
        ),
      ),
    ],
  );
  return container;
}

/// Resolves the bootstrap provider so its profile is cached synchronously
/// before the repository reads it via `valueOrNull`.
Future<void> _primeBootstrap(ProviderContainer container) async {
  await container.read(bootstrapControllerProvider.future);
}

String _profilesBody(List<Map<String, dynamic>> profiles) =>
    jsonEncode({
      'items': profiles,
      'next_cursor': null,
      'has_more': false,
      'limit': 20,
    });

void main() {
  group('SwipeRepository deal-breaker filtering', () {
    test('excludes peers that violate the user non-negotiables', () async {
      final adapter = _CapturingAdapter()
        ..responseBody = _profilesBody([
          {'id': 1, 'full_name': 'Pet Owner', 'has_pets': true},
          {'id': 2, 'full_name': 'No Pets', 'has_pets': false},
        ]);
      final container = _containerWith(
        adapter: adapter,
        nonNegotiables: ['no_pets'],
      );
      addTearDown(container.dispose);
      await _primeBootstrap(container);

      final profiles = await container
          .read(swipeRepositoryProvider)
          .fetchSwipeProfiles();

      expect(profiles.map((p) => p.id), [2]);
    });

    test('food_veg_only filters out non-vegetarian peers', () async {
      final adapter = _CapturingAdapter()
        ..responseBody = _profilesBody([
          {'id': 1, 'full_name': 'Veg', 'food_habits': 'vegetarian'},
          {'id': 2, 'full_name': 'NonVeg', 'food_habits': 'non_vegetarian'},
          {'id': 3, 'full_name': 'NoPref', 'food_habits': 'no_preference'},
        ]);
      final container = _containerWith(
        adapter: adapter,
        nonNegotiables: ['food_veg_only'],
      );
      addTearDown(container.dispose);
      await _primeBootstrap(container);

      final profiles = await container
          .read(swipeRepositoryProvider)
          .fetchSwipeProfiles();

      expect(profiles.map((p) => p.id), [1, 3]);
    });

    test('no_smoking filters out smokers but keeps non-smokers', () async {
      final adapter = _CapturingAdapter()
        ..responseBody = _profilesBody([
          {'id': 1, 'full_name': 'Smoker', 'smoking_drinking': 'smoke_outside'},
          {'id': 2, 'full_name': 'Both', 'smoking_drinking': 'both_fine'},
          {'id': 3, 'full_name': 'Clean', 'smoking_drinking': 'neither'},
        ]);
      final container = _containerWith(
        adapter: adapter,
        nonNegotiables: ['no_smoking'],
      );
      addTearDown(container.dispose);
      await _primeBootstrap(container);

      final profiles = await container
          .read(swipeRepositoryProvider)
          .fetchSwipeProfiles();

      expect(profiles.map((p) => p.id), [3]);
    });

    test('no non-negotiables keeps every returned profile', () async {
      final adapter = _CapturingAdapter()
        ..responseBody = _profilesBody([
          {'id': 1, 'has_pets': true},
          {'id': 2, 'food_habits': 'non_vegetarian'},
        ]);
      final container = _containerWith(adapter: adapter);
      addTearDown(container.dispose);
      await _primeBootstrap(container);

      final profiles = await container
          .read(swipeRepositoryProvider)
          .fetchSwipeProfiles();

      expect(profiles.map((p) => p.id), [1, 2]);
    });

    test('sends non_negotiables and gender_preference query params', () async {
      final adapter = _CapturingAdapter()..responseBody = _profilesBody([]);
      final container = _containerWith(
        adapter: adapter,
        nonNegotiables: ['no_pets', 'no_smoking'],
        genderPreference: 'female',
      );
      addTearDown(container.dispose);
      await _primeBootstrap(container);

      await container.read(swipeRepositoryProvider).fetchSwipeProfiles();

      expect(adapter.lastRequest?.path, FlatmatesEndpoints.flatmatesProfiles);
      expect(
        adapter.lastRequest?.queryParameters['non_negotiables'],
        'no_pets,no_smoking',
      );
      expect(
        adapter.lastRequest?.queryParameters['gender_preference'],
        'female',
      );
    });

    test('gender_preference "any" is not sent as a query param', () async {
      final adapter = _CapturingAdapter()..responseBody = _profilesBody([]);
      final container = _containerWith(
        adapter: adapter,
        genderPreference: 'any',
      );
      addTearDown(container.dispose);
      await _primeBootstrap(container);

      await container.read(swipeRepositoryProvider).fetchSwipeProfiles();

      expect(
        adapter.lastRequest?.queryParameters.containsKey('gender_preference'),
        isFalse,
      );
    });
  });
}

class _PrefsBootstrapController extends BootstrapController {
  _PrefsBootstrapController({
    required this.nonNegotiables,
    this.genderPreference,
  });

  final List<String> nonNegotiables;
  final String? genderPreference;

  BootstrapData _data() => BootstrapData(
    profile: FlatmatesProfileModel(
      id: 1,
      genderPreference: genderPreference,
      preferences: {'non_negotiables': nonNegotiables},
    ),
  );

  @override
  Future<BootstrapData?> build() async => _data();

  @override
  Future<void> refresh() async {
    state = AsyncValue.data(_data());
  }
}

class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;
  String responseBody = '{}';

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      responseBody,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
