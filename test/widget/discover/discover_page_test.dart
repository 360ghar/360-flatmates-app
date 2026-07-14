import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flatmates_app/core/location/location_data.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/discover/discover_page.dart';
import 'package:flatmates_app/features/discover/presentation/widgets/home_section_widgets.dart';
import 'package:flatmates_app/features/location/application/location_controller.dart';

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

Map<String, dynamic> _listingJson(int id) => {
  'id': id,
  'owner_id': 100 + id,
  'property_type': 'flatmate',
  'title': 'Listing $id',
  'city': 'Bangalore',
  'state': 'Karnataka',
  'locality': 'Koramangala',
  'latitude': 12.9352,
  'longitude': 77.6245,
  'monthly_rent': 20000.0,
  'main_image_url': 'https://example.com/photo$id.jpg',
  'image_urls': ['https://example.com/photo$id.jpg'],
  'bedrooms': 2,
  'bathrooms': 2,
  'area_sqft': 1000.0,
  'features': ['wifi'],
  'available_from': '2025-06-01T00:00:00Z',
  'status': 'live',
  'interest_count': 5,
  'view_count': 100,
  'like_count': 10,
  'is_available': true,
  'listing_preferences': {
    'sharing_type': 'private_room',
    'gender_preference': 'any',
  },
  'owner': {'id': 100 + id, 'full_name': 'Owner $id', 'mode': 'room_poster'},
  'created_at': '2025-05-01T10:00:00Z',
};

/// A fake [LocationController] that returns a pre-set selected location and
/// no-ops all GPS/network methods so the discover page doesn't hit platform
/// channels in widget tests.
class _FakeLocationController extends LocationController {
  @override
  LocationState build() => const LocationState(
    selectedLocation: LocationData(
      name: 'Koramangala, Bangalore',
      latitude: 12.9352,
      longitude: 77.6245,
    ),
  );

  @override
  Future<void> getCurrentLocation({bool forceRefresh = false}) async {}

  @override
  void selectLocation(LocationData location) {}

  @override
  Future<void> selectAndPersistLocation(LocationData location) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DiscoverPage', () {
    testWidgets('renders home search bar and feed cards', (tester) async {
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
      );
      apiClient.dio.httpClientAdapter = _ScriptedAdapter((options) {
        if (options.path == '/properties') {
          return _ok({
            'items': List.generate(3, (i) => _listingJson(i + 1)),
            'next_cursor': null,
            'has_more': false,
          });
        }
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
        child: const DiscoverPage(),
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          locationControllerProvider.overrideWith(
            () => _FakeLocationController(),
          ),
        ],
      );

      await tester.pumpWidget(widget);
      // Pump through the initial load cycle (microtask + HTTP + settle).
      // Use pump() instead of pumpAndSettle() because the page may have
      // continuous animations (shimmer skeletons) that never settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Home search bar should be present.
      expect(find.byType(HomeSearchBar), findsOneWidget);

      // At least one feed card should be rendered.
      expect(find.byKey(const Key('discover_feed_card_0')), findsOneWidget);
    });
  });
}
