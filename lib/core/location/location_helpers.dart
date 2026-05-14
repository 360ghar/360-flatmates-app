import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../features/bootstrap/catalog_helpers.dart';
import 'geo_utils.dart';
export 'geo_utils.dart';

const kMaxMatchDistanceKm = 150.0;
const kLocationTimeout = Duration(seconds: 20);

enum LocationDetectResult {
  success,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  noMatch,
  error,
}

Future<
  ({LocationDetectResult result, CatalogOption? city, String? errorDetail})
>
detectCurrentLocation({required List<CatalogOption> catalogCities}) async {
  debugPrint('LocationHelpers: starting detection...');
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  debugPrint('LocationHelpers: serviceEnabled=$serviceEnabled');
  if (!serviceEnabled) {
    return (
      result: LocationDetectResult.serviceDisabled,
      city: null,
      errorDetail: null,
    );
  }

  var permission = await Geolocator.checkPermission();
  debugPrint('LocationHelpers: initialPermission=$permission');
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    debugPrint('LocationHelpers: afterRequestPermission=$permission');
  }
  if (permission == LocationPermission.denied) {
    return (
      result: LocationDetectResult.permissionDenied,
      city: null,
      errorDetail: null,
    );
  }
  if (permission == LocationPermission.deniedForever) {
    return (
      result: LocationDetectResult.permissionDeniedForever,
      city: null,
      errorDetail: null,
    );
  }

  Position position;
  try {
    debugPrint('LocationHelpers: requesting position...');
    position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    ).timeout(kLocationTimeout);
    debugPrint(
      'LocationHelpers: got position ${position.latitude}, ${position.longitude}',
    );
  } catch (e) {
    debugPrint('LocationHelpers: position error: $e');
    return (
      result: LocationDetectResult.error,
      city: null,
      errorDetail: e.toString(),
    );
  }

  final cities = resolveCities(catalogCities);
  debugPrint('LocationHelpers: using ${cities.length} catalog cities');

  CatalogOption? closest;
  double minDist = double.infinity;
  for (final city in cities) {
    final lat = (city.meta['latitude'] as num?)?.toDouble();
    final lng = (city.meta['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) continue;
    final d = haversineKm(position.latitude, position.longitude, lat, lng);
    if (d < minDist) {
      minDist = d;
      closest = city;
    }
  }
  debugPrint(
    'LocationHelpers: haversine closest=${closest?.label}, dist=${minDist.toStringAsFixed(1)}km',
  );
  if (closest != null && minDist <= kMaxMatchDistanceKm) {
    return (
      result: LocationDetectResult.success,
      city: closest,
      errorDetail: null,
    );
  }

  closest = null;
  try {
    debugPrint('LocationHelpers: trying geocoding fallback...');
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isNotEmpty) {
      final locality = placemarks.first.locality?.toLowerCase() ?? '';
      final adminArea =
          placemarks.first.administrativeArea?.toLowerCase() ?? '';
      debugPrint(
        'LocationHelpers: geocoding locality=$locality, adminArea=$adminArea',
      );
      for (final city in cities) {
        final label = city.label.toLowerCase();
        if (_matchesLocation(
          label,
          city.meta['aliases'],
          locality,
          adminArea,
        )) {
          closest = city;
          break;
        }
      }
    }
  } catch (e) {
    debugPrint('LocationHelpers: geocoding fallback failed: $e');
  }

  if (closest != null) {
    debugPrint('LocationHelpers: geocoding matched ${closest.label}');
    return (
      result: LocationDetectResult.success,
      city: closest,
      errorDetail: null,
    );
  }

  debugPrint('LocationHelpers: no match found');
  return (result: LocationDetectResult.noMatch, city: null, errorDetail: null);
}

List<CatalogOption> resolveCities(List<CatalogOption> catalogCities) {
  return catalogCities;
}

bool _matchesLocation(
  String label,
  dynamic aliases,
  String locality,
  String adminArea,
) {
  if (_containsEither(locality, label) || _containsEither(adminArea, label)) {
    return true;
  }
  if (aliases is List) {
    for (final alias in aliases) {
      final a = alias.toString().toLowerCase();
      if (_containsEither(locality, a) || _containsEither(adminArea, a)) {
        return true;
      }
    }
  }
  return false;
}

bool _containsEither(String value, String candidate) {
  if (value.isEmpty || candidate.isEmpty) return false;
  return value.contains(candidate) || candidate.contains(value);
}

bool cityMatchesQuery(CatalogOption city, String query) {
  final q = query.toLowerCase();
  if (city.label.toLowerCase().contains(q)) return true;
  final aliases = city.meta['aliases'];
  if (aliases is List) {
    for (final alias in aliases) {
      if (alias.toString().toLowerCase().contains(q)) return true;
    }
  }
  return false;
}
