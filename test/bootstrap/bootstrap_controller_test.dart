import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/config/endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';

import '../helpers/test_helpers.dart';

void main() {
  test('refresh while logged out does not request bootstrap', () async {
    final adapter = _RecordingAdapter();
    final apiClient = ApiClient(
      baseUrl: fakeAppConfig().apiBaseUrl,
      tokenProvider: FakeAuthTokenProvider(),
    )..dio.httpClientAdapter = adapter;
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(FakeAuthController.new),
        apiClientProvider.overrideWithValue(apiClient),
      ],
    );
    addTearDown(container.dispose);

    await container.read(bootstrapControllerProvider.notifier).refresh();

    expect(await container.read(bootstrapControllerProvider.future), isNull);
    expect(adapter.requestPaths, isEmpty);
  });

  test(
    'bootstrap starts automatically when auth becomes logged in after initial null build',
    () async {
      final adapter = _RecordingAdapter();
      final apiClient = ApiClient(
        baseUrl: fakeAppConfig().apiBaseUrl,
        tokenProvider: FakeAuthTokenProvider(),
      )..dio.httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(FakeAuthController.new),
          apiClientProvider.overrideWithValue(apiClient),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen<AsyncValue<BootstrapData?>>(
        bootstrapControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      expect(await container.read(bootstrapControllerProvider.future), isNull);
      expect(adapter.requestPaths, isEmpty);

      await container
          .read(authControllerProvider.notifier)
          .signInWithPassword(phone: '+919999999999', password: 'Password1');

      final data = await container.read(bootstrapControllerProvider.future);

      expect(data?.profile.id, 42);
      expect(
        container.read(authControllerProvider).authStage,
        AuthStage.active,
      );
      expect(adapter.requestPaths, hasLength(2));
      expect(adapter.requestPaths, contains(FlatmatesEndpoints.bootstrap));
      expect(
        adapter.requestPaths,
        contains(Uri.parse(FlatmatesEndpoints.authState).path),
      );
    },
  );
}

final class _RecordingAdapter implements HttpClientAdapter {
  final requestPaths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestPaths.add(options.uri.path);

    if (options.uri.path == FlatmatesEndpoints.bootstrap) {
      return _jsonResponse({
        'profile': {
          'id': 42,
          'full_name': 'Test User',
          'phone': '+919999999999',
          'mode': 'co_hunter',
          'profile_status': 'active',
          'onboarding_completed': true,
        },
        'catalogs': <Map<String, Object?>>[],
        'active_listing_count': 0,
        'conversation_count': 0,
        'unread_message_count': 0,
      });
    }

    if (options.uri.path == Uri.parse(FlatmatesEndpoints.authState).path) {
      return _jsonResponse({
        'stage': 'active',
        'next_action': 'grant_access',
        'missing_fields': <String>[],
      });
    }

    return _jsonResponse({'detail': 'not found'}, statusCode: 404);
  }

  @override
  void close({bool force = false}) {}

  ResponseBody _jsonResponse(
    Map<String, Object?> data, {
    int statusCode = 200,
  }) {
    return ResponseBody.fromString(
      jsonEncode(data),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
