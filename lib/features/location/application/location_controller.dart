import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/google_places_service.dart';
import '../../../core/location/location_data.dart';
import '../../../core/location/place_suggestion.dart';

class LocationState {
  final Position? currentPosition;
  final String? currentAddress;
  final bool isLoading;
  final String? error;
  final LocationData? selectedLocation;

  const LocationState({
    this.currentPosition,
    this.currentAddress,
    this.isLoading = false,
    this.error,
    this.selectedLocation,
  });

  LocationState copyWith({
    Position? currentPosition,
    String? currentAddress,
    bool? isLoading,
    String? error,
    LocationData? selectedLocation,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      currentAddress: currentAddress ?? this.currentAddress,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedLocation: selectedLocation ?? this.selectedLocation,
    );
  }
}

final locationControllerProvider =
    NotifierProvider<LocationController, LocationState>(
  LocationController.new,
);

class LocationController extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState();

  Future<void> getCurrentLocation({bool forceRefresh = false}) async {
    if (state.isLoading) return;
    if (!forceRefresh && state.currentPosition != null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _fallbackToIpLocation();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _fallbackToIpLocation();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(const Duration(seconds: 20));

      final address = await _reverseGeocode(
        position.latitude,
        position.longitude,
      );

      state = state.copyWith(
        currentPosition: position,
        currentAddress: address,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('LocationController: GPS failed, falling back to IP: $e');
      await _fallbackToIpLocation();
    }
  }

  Future<void> _fallbackToIpLocation() async {
    try {
      final ipData = await getIpLocation();
      if (ipData != null) {
        final address = await _reverseGeocode(
          ipData.latitude,
          ipData.longitude,
        );
        state = state.copyWith(
          isLoading: false,
          currentAddress: address ?? ipData.name,
          selectedLocation: state.selectedLocation ?? ipData,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not detect location',
        );
      }
    } catch (e) {
      debugPrint('LocationController: IP location failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Could not detect location',
      );
    }
  }

  Future<LocationData?> getIpLocation() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://ipapi.co/json/',
        options: Options(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final data = response.data as Map<String, dynamic>;
      final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
      final city = data['city'] as String? ?? '';
      final region = data['region'] as String? ?? '';
      final name = city.isNotEmpty ? '$city, $region' : region;

      return LocationData(
        name: name,
        latitude: lat,
        longitude: lng,
      );
    } catch (e) {
      debugPrint('LocationController: IP location error: $e');
      return null;
    }
  }

  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    return _reverseGeocode(lat, lng);
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final parts = <String>[
        if (place.name != null && place.name!.isNotEmpty) place.name!,
        if (place.locality != null && place.locality!.isNotEmpty) place.locality!,
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty)
          place.administrativeArea!,
      ];
      return parts.isNotEmpty ? parts.join(', ') : place.toString();
    } catch (e) {
      debugPrint('LocationController: reverse geocode error: $e');
      return null;
    }
  }

  Future<List<PlaceSuggestion>> getPlaceSuggestions(
    String query, {
    LatLng? currentLocation,
  }) async {
    final service = ref.read(googlePlacesServiceProvider);
    return service.getPlaceSuggestions(query, currentLocation: currentLocation);
  }

  Future<({double latitude, double longitude, String name})?> getPlaceDetails(
    String placeId, {
    String? preferredName,
  }) async {
    final service = ref.read(googlePlacesServiceProvider);
    return service.getPlaceDetails(placeId, preferredName: preferredName);
  }

  void selectLocation(LocationData location) {
    state = state.copyWith(selectedLocation: location);
  }

  Future<void> useCurrentLocation() async {
    await getCurrentLocation(forceRefresh: true);
    final pos = state.currentPosition;
    if (pos != null) {
      final address = state.currentAddress ?? '';
      selectLocation(LocationData(
        name: address,
        latitude: pos.latitude,
        longitude: pos.longitude,
      ));
    }
  }

  String formatDistance(double km) {
    if (km < 1) {
      final meters = (km * 1000).round();
      return '${meters}m';
    }
    return '${km.toStringAsFixed(1)}km';
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
