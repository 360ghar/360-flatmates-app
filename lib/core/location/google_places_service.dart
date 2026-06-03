import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'place_suggestion.dart';

final googlePlacesServiceProvider = Provider<GooglePlacesService>((ref) {
  return GooglePlacesService();
});

final class GooglePlacesService {
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static const _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  Future<List<PlaceSuggestion>> getPlaceSuggestions(
    String query, {
    ({double latitude, double longitude})? currentLocation,
  }) async {
    const dartDefine = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
    final apiKey = dartDefine.trim().isNotEmpty
        ? dartDefine
        : (dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '');
    if (apiKey.isEmpty || query.trim().length < 2) return const [];

    try {
      const countryDefine = String.fromEnvironment('DEFAULT_COUNTRY');
      final countryCode = countryDefine.trim().isNotEmpty
          ? countryDefine
          : (dotenv.env['DEFAULT_COUNTRY'] ?? 'in');
      final queryParameters = <String, dynamic>{
        'input': query,
        'components': 'country:$countryCode',
        'key': apiKey,
      };
      if (currentLocation != null) {
        queryParameters['location'] =
            '${currentLocation.latitude},${currentLocation.longitude}';
        queryParameters['radius'] = 25000;
      }
      final response = await _dio.get(
        '$_baseUrl/autocomplete/json',
        queryParameters: queryParameters,
      );

      final data = response.data;
      final body = data is Map<String, dynamic>
          ? data
          : json.decode(data.toString()) as Map<String, dynamic>;
      final status = body['status'] as String? ?? '';

      if (status != 'OK') {
        if (kDebugMode && status != 'ZERO_RESULTS') {
          debugPrint('GooglePlaces: status=$status for query=$query');
        }
        return const [];
      }

      final predictions = body['predictions'] as List? ?? [];
      return predictions.map((p) {
        return PlaceSuggestion(
          placeId: p['place_id'] as String? ?? '',
          description: p['description'] as String? ?? '',
          mainText: p['structured_formatting']?['main_text'] as String? ?? '',
          secondaryText:
              p['structured_formatting']?['secondary_text'] as String? ?? '',
        );
      }).toList();
    } on TimeoutException {
      debugPrint('GooglePlaces: autocomplete timeout for query=$query');
      return const [];
    } on DioException catch (e) {
      debugPrint('GooglePlaces: autocomplete error: ${e.message}');
      return const [];
    } catch (e) {
      debugPrint('GooglePlaces: autocomplete error: $e');
      return const [];
    }
  }

  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? preferredName,
  }) async {
    const dartDefine = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
    final apiKey = dartDefine.trim().isNotEmpty
        ? dartDefine
        : (dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '');
    if (apiKey.isEmpty) return null;

    try {
      final response = await _dio.get(
        '$_baseUrl/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'name,geometry,address_components',
          'key': apiKey,
        },
      );

      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : json.decode(response.data.toString()) as Map<String, dynamic>;
      final status = body['status'] as String? ?? '';

      if (status != 'OK') {
        debugPrint('GooglePlaces: details status=$status for placeId=$placeId');
        return null;
      }

      final result = body['result'] as Map<String, dynamic>?;
      if (result == null) return null;

      final location = result['geometry']?['location'] as Map<String, dynamic>?;
      if (location == null) return null;

      final lat = (location['lat'] as num?)?.toDouble() ?? 0.0;
      final lng = (location['lng'] as num?)?.toDouble() ?? 0.0;

      String displayName;
      if (preferredName != null && preferredName.isNotEmpty) {
        displayName = preferredName;
      } else {
        String? locality;
        String? city;
        final components = result['address_components'] as List? ?? [];
        for (final c in components) {
          final types = c['types'] as List? ?? [];
          if (types.contains('locality')) {
            locality = c['long_name'] as String?;
          }
          if (types.contains('administrative_area_level_2')) {
            city = c['long_name'] as String?;
          }
        }
        displayName = result['name'] as String? ?? '';
        if (locality != null && city != null) {
          displayName = '$locality, $city';
        } else if (city != null) {
          displayName = city;
        } else if (locality != null) {
          displayName = locality;
        }
      }

      return (latitude: lat, longitude: lng, name: displayName);
    } on TimeoutException {
      debugPrint('GooglePlaces: details timeout for placeId=$placeId');
      return null;
    } on DioException catch (e) {
      debugPrint('GooglePlaces: details error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('GooglePlaces: details error: $e');
      return null;
    }
  }
}
