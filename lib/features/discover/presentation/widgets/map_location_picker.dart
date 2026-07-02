import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/debouncer.dart';
import '../../../bootstrap/bootstrap_controller.dart';
import '../../../location/application/location_controller.dart';
import '../../../location/presentation/location_picker_modal.dart';
import '../../application/discover_feed_controller.dart';
import '../../application/map_listings_controller.dart';
import '../../discover_repository.dart';

/// Opens the location picker modal pre-filled from the current map filters
/// and profile, wiring radius and location changes back into
/// [mapListingsProvider]. Radius-only changes are debounced via [debouncer].
void showMapLocationPicker(
  BuildContext context,
  WidgetRef ref, {
  required ActionDebouncer debouncer,
}) {
  final mapState = ref.read(mapListingsProvider);
  final selectedLocation = ref
      .read(locationControllerProvider)
      .selectedLocation;
  final profile = ref.read(bootstrapControllerProvider).valueOrNull?.profile;

  final locality = profile?.locality?.trim();
  final city = profile?.city?.trim();
  final profileLocation = [
    if (locality != null && locality.isNotEmpty) locality,
    if (city != null && city.isNotEmpty) city,
  ].join(', ');
  final selectedDisplayText = selectedLocation?.displayText ?? '';
  final currentLocation = selectedDisplayText.isNotEmpty
      ? selectedDisplayText
      : profileLocation;
  final currentRadiusKm =
      mapState.filters.radiusKm ??
      MapListingsController.defaultLocationRadiusKm;

  var selectedRadiusKm = currentRadiusKm;
  var didSelectLocation = false;

  showLocationPickerModal(
    context,
    currentLocationName: currentLocation,
    currentRadius: currentRadiusKm,
    onRadiusChanged: (radiusKm) {
      selectedRadiusKm = radiusKm;
      debouncer.run(() {
        if (!context.mounted || didSelectLocation) return;
        final activeLocation = ref
            .read(locationControllerProvider)
            .selectedLocation;
        if (activeLocation == null) return;
        ref
            .read(mapListingsProvider.notifier)
            .updateLocationFilter(
              latitude: activeLocation.latitude,
              longitude: activeLocation.longitude,
              radiusKm: radiusKm,
            );
        ref
            .read(discoverFeedControllerProvider.notifier)
            .updateLocationFilter(
              latitude: activeLocation.latitude,
              longitude: activeLocation.longitude,
              radiusKm: radiusKm,
            );
      });
    },
    onLocationSelected: (location) {
      didSelectLocation = true;
      unawaited(
        ref
            .read(locationControllerProvider.notifier)
            .selectAndPersistLocation(location),
      );
      final mapController = ref.read(mapListingsProvider.notifier);
      final feedController = ref.read(discoverFeedControllerProvider.notifier);
      if (location.latitude.isFinite && location.longitude.isFinite) {
        mapController.updateLocationFilter(
          latitude: location.latitude,
          longitude: location.longitude,
          radiusKm: selectedRadiusKm,
        );
        feedController.updateLocationFilter(
          latitude: location.latitude,
          longitude: location.longitude,
          radiusKm: selectedRadiusKm,
        );
      } else {
        mapController.updateTextLocationFilter(location: location.name);
        feedController.updateTextLocationFilter(location: location.name);
      }
      ref.invalidate(discoverListingsProvider);
    },
  );
}
