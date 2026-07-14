import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
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

Map<String, dynamic> _profileJson(
  int id, {
  String? foodHabits,
  String? smokingDrinking,
  String? gender,
  String? genderPreference,
  bool hasPets = false,
  String? partyHabit,
  String? cleanliness,
  String? guestsPolicy,
}) => {
  'id': id,
  'full_name': 'User $id',
  'mode': 'co_hunter',
  'city': 'Bangalore',
  'locality': 'Koramangala',
  'bio': 'Hi',
  'budget_min': 10000.0,
  'budget_max': 25000.0,
  'gender': gender,
  'gender_preference': genderPreference ?? 'any',
  'non_negotiables': <dynamic>[],
  'has_pets': hasPets,
  'food_habits': foodHabits,
  'smoking_drinking': smokingDrinking,
  'party_habit': partyHabit,
  'cleanliness': cleanliness,
  'guests_policy': guestsPolicy,
};

/// A fake [BootstrapController] that returns a profile with the given
/// non-negotiables and gender preference.
class _CustomBootstrapController extends BootstrapController {
  _CustomBootstrapController(this._data);

  final BootstrapData _data;

  @override
  Future<BootstrapData?> build() async {
    state = AsyncValue.data(_data);
    return _data;
  }
}

BootstrapData _bootstrapWithNegs(
  List<String> nonNegotiables, {
  String? genderPreference,
}) {
  return BootstrapData(
    profile: FlatmatesProfileModel(
      id: 1,
      fullName: 'Test User',
      mode: 'co_hunter',
      profileStatus: 'active',
      onboardingCompleted: true,
      genderPreference: genderPreference,
      preferences: {'non_negotiables': nonNegotiables},
    ),
  );
}

ProviderContainer _containerWithProfile(
  BootstrapData data,
  Response Function(RequestOptions) handler,
) {
  final adapter = _ScriptedAdapter(handler);
  final apiClient = ApiClient(
    baseUrl: 'https://api.test.example.com',
    tokenProvider: FakeAuthTokenProvider(),
  );
  apiClient.dio.httpClientAdapter = adapter;

  return ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(fakeAppConfig()),
      authControllerProvider.overrideWith(() => FakeAuthController()),
      bootstrapControllerProvider.overrideWith(
        () => _CustomBootstrapController(data),
      ),
      apiClientProvider.overrideWithValue(apiClient),
    ],
  );
}

void main() {
  group('SwipeRepository deal-breaker filtering', () {
    test('excludes peers that violate the user non-negotiables', () async {
      final data = _bootstrapWithNegs(['no_smoking', 'food_veg_only']);
      final container = _containerWithProfile(data, (options) {
        if (options.path == '/flatmates/profiles') {
          return _ok({
            'items': [
              // Smoker — should be excluded by no_smoking.
              _profileJson(
                1,
                smokingDrinking: 'smoke_outside',
                foodHabits: 'vegetarian',
              ),
              // Non-vegetarian — should be excluded by food_veg_only.
              _profileJson(
                2,
                smokingDrinking: 'neither',
                foodHabits: 'non_vegetarian',
              ),
              // Clean peer — should be kept.
              _profileJson(
                3,
                smokingDrinking: 'neither',
                foodHabits: 'vegetarian',
              ),
            ],
            'next_cursor': null,
            'has_more': false,
          });
        }
        return _ok({});
      });
      addTearDown(container.dispose);

      final repo = container.read(swipeRepositoryProvider);
      final page = await repo.fetchSwipeProfilesPage();

      final ids = page.items.map((p) => p.id).toSet();
      expect(ids, contains(3));
      expect(ids, isNot(contains(1)));
      expect(ids, isNot(contains(2)));
    });

    test('food_veg_only filters out non-vegetarian peers', () async {
      final data = _bootstrapWithNegs(['food_veg_only']);
      final container = _containerWithProfile(data, (options) {
        if (options.path == '/flatmates/profiles') {
          return _ok({
            'items': [
              _profileJson(1, foodHabits: 'non_vegetarian'),
              _profileJson(2, foodHabits: 'vegetarian'),
              _profileJson(3, foodHabits: 'non_veg'),
            ],
            'next_cursor': null,
            'has_more': false,
          });
        }
        return _ok({});
      });
      addTearDown(container.dispose);

      final repo = container.read(swipeRepositoryProvider);
      final page = await repo.fetchSwipeProfilesPage();

      final ids = page.items.map((p) => p.id).toSet();
      expect(ids, contains(2));
      expect(ids, isNot(contains(1)));
      expect(ids, isNot(contains(3)));
    });

    test('no_smoking filters out smokers but keeps non-smokers', () async {
      final data = _bootstrapWithNegs(['no_smoking']);
      final container = _containerWithProfile(data, (options) {
        if (options.path == '/flatmates/profiles') {
          return _ok({
            'items': [
              _profileJson(1, smokingDrinking: 'smoke_outside'),
              _profileJson(2, smokingDrinking: 'both_fine'),
              _profileJson(3, smokingDrinking: 'neither'),
              _profileJson(4, smokingDrinking: 'drink_occasionally'),
            ],
            'next_cursor': null,
            'has_more': false,
          });
        }
        return _ok({});
      });
      addTearDown(container.dispose);

      final repo = container.read(swipeRepositoryProvider);
      final page = await repo.fetchSwipeProfilesPage();

      final ids = page.items.map((p) => p.id).toSet();
      // Non-smokers kept.
      expect(ids, contains(3));
      expect(ids, contains(4));
      // Smokers excluded.
      expect(ids, isNot(contains(1)));
      expect(ids, isNot(contains(2)));
    });

    test('no non-negotiables keeps every returned profile', () async {
      final data = _bootstrapWithNegs([]);
      final container = _containerWithProfile(data, (options) {
        if (options.path == '/flatmates/profiles') {
          return _ok({
            'items': [
              _profileJson(1, foodHabits: 'non_vegetarian'),
              _profileJson(2, smokingDrinking: 'smoke_outside'),
              _profileJson(3, smokingDrinking: 'neither'),
            ],
            'next_cursor': null,
            'has_more': false,
          });
        }
        return _ok({});
      });
      addTearDown(container.dispose);

      final repo = container.read(swipeRepositoryProvider);
      final page = await repo.fetchSwipeProfilesPage();

      expect(page.items.length, 3);
    });

    test('sends non_negotiables and gender_preference query params', () async {
      final data = _bootstrapWithNegs([
        'food_veg_only',
      ], genderPreference: 'male');
      final adapter = _ScriptedAdapter((options) {
        if (options.path == '/flatmates/profiles') {
          return _ok({
            'items': <dynamic>[],
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
            () => _CustomBootstrapController(data),
          ),
          apiClientProvider.overrideWithValue(apiClient),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(swipeRepositoryProvider);
      await repo.fetchSwipeProfilesPage();

      final request = adapter.requests.firstWhere(
        (r) => r.path == '/flatmates/profiles',
      );
      expect(request.queryParameters['non_negotiables'], 'food_veg_only');
      expect(request.queryParameters['gender_preference'], 'male');
    });

    test('gender_preference "any" is not sent as a query param', () async {
      final data = _bootstrapWithNegs(['no_smoking'], genderPreference: 'any');
      final adapter = _ScriptedAdapter((options) {
        if (options.path == '/flatmates/profiles') {
          return _ok({
            'items': <dynamic>[],
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
            () => _CustomBootstrapController(data),
          ),
          apiClientProvider.overrideWithValue(apiClient),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(swipeRepositoryProvider);
      await repo.fetchSwipeProfilesPage();

      final request = adapter.requests.firstWhere(
        (r) => r.path == '/flatmates/profiles',
      );
      expect(request.queryParameters.containsKey('gender_preference'), isFalse);
      // non_negotiables should still be sent.
      expect(request.queryParameters['non_negotiables'], 'no_smoking');
    });
  });
}
