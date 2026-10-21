import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flatmates_app/core/location/location_data.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/discover/application/map_listings_controller.dart';
import 'package:flatmates_app/features/discover/map_view_page.dart';
import 'package:flatmates_app/features/location/application/location_controller.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

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

/// A [LocationController] whose IP lookup result is scripted by the test.
///
/// The GPS half is driven by the mocked geolocator channel below, which
/// reports "location services disabled" — the real IP-fallback path.
class _ScriptedLocationController extends LocationController {
  LocationData? ipResult;

  @override
  Future<LocationData?> getIpLocation() async => ipResult;
}

const _geolocatorChannels = [
  'flutter.baseflow.com/geolocator',
  'flutter.baseflow.com/geolocator_apple',
  'flutter.baseflow.com/geolocator_android',
];
const _geocodingChannel = 'flutter.baseflow.com/geocoding';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();

    // Real plugins cannot answer in a widget test: an unhandled platform
    // channel message never completes, which would hang the GPS path. Report
    // "location services off" so the controller takes its IP fallback, and
    // return no placemarks so the reverse geocode falls back to the IP name.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in _geolocatorChannels) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (call) async {
        return call.method == 'isLocationServiceEnabled' ? false : null;
      });
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel(_geocodingChannel),
      (call) async => <dynamic>[],
    );
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in _geolocatorChannels) {
      messenger.setMockMethodCallHandler(MethodChannel(name), null);
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel(_geocodingChannel),
      null,
    );
  });

  testWidgets('recentres on the IP fallback without a could-not-detect toast', (
    tester,
  ) async {
    final controller = _ScriptedLocationController();
    final apiClient = ApiClient(
      baseUrl: 'https://api.test.example.com',
      tokenProvider: FakeAuthTokenProvider(),
    );
    apiClient.dio.httpClientAdapter = _ScriptedAdapter((options) {
      if (options.path == '/properties') {
        return Response<dynamic>(
          data: {'items': <dynamic>[], 'next_cursor': null, 'has_more': false},
          statusCode: 200,
          requestOptions: options,
        );
      }
      return Response<dynamic>(
        data: <String, dynamic>{},
        statusCode: 200,
        requestOptions: options,
      );
    });

    final widget = await testableWidgetAsync(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        locationControllerProvider.overrideWith(() => controller),
      ],
      child: const MapViewPage(),
    );
    await tester.pumpWidget(widget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MapViewPage)),
      listen: false,
    );

    // Initial auto-detection: the IP lookup fails, so the controller ends in
    // the error state the recentre handler has to survive.
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 20));
      final probe = container.read(locationControllerProvider);
      if (probe.isLoading) continue;
      if (probe.error != null) break;
    }
    expect(controller.ipResult, isNull);
    expect(
      container.read(locationControllerProvider).error,
      LocationError.couldNotDetect,
      reason: 'the earlier detection must have failed for this test to bite',
    );

    // The user taps recentre and this attempt resolves through the IP
    // fallback.
    const fallback = LocationData(
      name: 'Bengaluru, Karnataka',
      latitude: 12.9716,
      longitude: 77.5946,
    );
    controller.ipResult = fallback;

    await tester.tap(find.byIcon(Icons.my_location_rounded));
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (container.read(locationControllerProvider).selectedLocation != null) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 350));

    final locale = await AppLocalizations.delegate.load(const Locale('en'));
    expect(
      find.text(locale.couldNotDetectLocation),
      findsNothing,
      reason: 'a successful IP fallback must not toast a detection failure',
    );
    // The fallback location reached the map chrome, proving the handler
    // recentred instead of bailing out.
    expect(find.text(fallback.name), findsOneWidget);
    expect(
      container.read(mapListingsProvider).filters.latitude,
      fallback.latitude,
    );
    expect(
      container.read(mapListingsProvider).filters.longitude,
      fallback.longitude,
    );
  });
}
