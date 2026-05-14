import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'place_suggestion.dart';

final nominatimServiceProvider = Provider<NominatimService>((ref) {
  return NominatimService();
});

final class NominatimService {
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static const _defaultBaseUrl = 'https://nominatim.openstreetmap.org';
  static const _defaultUserAgent = '360Flatmates/1.0 (contact@360ghar.com)';

  String get _baseUrl {
    final envUrl = dotenv.env['NOMINATIM_BASE_URL'] ?? '';
    return envUrl.isNotEmpty ? envUrl : _defaultBaseUrl;
  }

  String get _userAgent {
    final envAgent = dotenv.env['NOMINATIM_USER_AGENT'] ?? '';
    return envAgent.isNotEmpty ? envAgent : _defaultUserAgent;
  }

  Future<List<PlaceSuggestion>> search(String query) async {
    if (query.trim().length < 2) return const [];

    try {
      final countryCode = dotenv.env['DEFAULT_COUNTRY'] ?? 'in';
      final response = await _dio.get(
        '$_baseUrl/search',
        queryParameters: <String, dynamic>{
          'q': query,
          'format': 'json',
          'addressdetails': '1',
          'limit': '10',
          'countrycodes': countryCode,
        },
        options: Options(headers: {'User-Agent': _userAgent}),
      );

      final body = response.data is List ? response.data as List : const [];
      return body
          .map((item) {
            final map = item as Map<String, dynamic>;
            final address = map['address'] as Map<String, dynamic>? ?? {};
            final lat = _doubleValue(map['lat']);
            final lon = _doubleValue(map['lon']);
            if (lat == null || lon == null) return null;

            final osmType = _stringValue(map['osm_type']);
            final osmId = _stringValue(map['osm_id']);
            final nominatimPlaceId = _stringValue(map['place_id']);
            final placeId = osmType != null && osmId != null
                ? 'osm:$osmType:$osmId'
                : 'nominatim:${nominatimPlaceId ?? '$lat,$lon'}';
            final displayName = _stringValue(map['display_name']) ?? '';
            final displayNameHead = displayName.split(',').first.trim();
            final name = _stringValue(map['name']) ?? displayNameHead;
            final city =
                _stringValue(address['city']) ??
                _stringValue(address['town']) ??
                _stringValue(address['village']) ??
                _stringValue(address['municipality']);
            final state = _stringValue(address['state']);
            final suburb =
                _stringValue(address['suburb']) ??
                _stringValue(address['neighbourhood']);
            final secondaryParts = [
              suburb != null && suburb != name ? suburb : null,
              city,
              state,
            ].whereType<String>();
            final secondaryText = secondaryParts.toSet().take(3).join(', ');

            return PlaceSuggestion(
              placeId: placeId,
              description: displayName,
              mainText: name,
              secondaryText: secondaryText,
              source: PlaceSuggestionSource.nominatim,
              latitude: lat,
              longitude: lon,
            );
          })
          .whereType<PlaceSuggestion>()
          .toList();
    } on TimeoutException {
      debugPrint('Nominatim: search timeout for query=$query');
      return const [];
    } on DioException catch (e) {
      debugPrint('Nominatim: search error: ${e.message}');
      return const [];
    } catch (e) {
      debugPrint('Nominatim: search error: $e');
      return const [];
    }
  }

  Future<PlaceDetails?> getDetails(PlaceSuggestion suggestion) async {
    if (suggestion.source != PlaceSuggestionSource.nominatim) return null;
    return suggestion.resolvedDetails;
  }

  String? _stringValue(Object? value) {
    if (value == null) return null;
    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? null : stringValue;
  }

  double? _doubleValue(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
