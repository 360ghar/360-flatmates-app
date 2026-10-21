import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// The body of an answer the fake server gives.
typedef FakeAnswer = ({int status, Object? body, Map<String, String> headers});

/// An answer with [body] and [status] 200.
FakeAnswer ok(Object? body, {int status = 200}) =>
    (status: status, body: body, headers: const {});

/// An error answer: [body] with an error status.
FakeAnswer failure(
  int status,
  Object? body, {
  Map<String, String> headers = const {},
}) => (status: status, body: body, headers: headers);

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.respond, this.requests);

  final FakeAnswer Function(RequestOptions) respond;
  final List<RequestOptions> requests;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final answer = respond(options);
    final body = answer.body;
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      answer.status,
      headers: {
        'content-type': ['application/json'],
        for (final entry in answer.headers.entries) entry.key: [entry.value],
      },
    );
  }
}

/// A provider container whose API client talks to a fake server: [respond]
/// answers each request, and every request is kept in [requests] for the test
/// to read (path, query, body).
class RecordingApi {
  RecordingApi(
    FakeAnswer Function(RequestOptions) respond, {
    List<Override> overrides = const [],
  }) {
    client = ApiClient(
      baseUrl: 'https://api.test.example.com',
      tokenProvider: FakeAuthTokenProvider(),
    )..dio.httpClientAdapter = _RecordingAdapter(respond, requests);
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(fakeAppConfig()),
        authTokenProviderProvider.overrideWithValue(FakeAuthTokenProvider()),
        apiClientProvider.overrideWithValue(client),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
  }

  /// The API client of [container]. A widget test overrides `apiClientProvider`
  /// with it in its own `ProviderScope`.
  late final ApiClient client;

  late final ProviderContainer container;
  final requests = <RequestOptions>[];

  RequestOptions get last => requests.last;

  /// The JSON body of the last request as a map.
  Map<String, dynamic> get lastBody =>
      Map<String, dynamic>.from(last.data as Map);

  /// The requests of [method] and [path].
  Iterable<RequestOptions> to(String method, String path) =>
      requests.where((r) => r.method == method && r.path == path);
}
