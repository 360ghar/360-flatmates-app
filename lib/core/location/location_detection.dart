import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../features/bootstrap/catalog_helpers.dart';
import '../../features/shared/presentation/flatmates_toast.dart';
import '../../l10n/gen/app_localizations.dart';
import 'location_data.dart';
import 'location_helpers.dart';

/// Runs the full "detect current location → match to a catalog city" flow and
/// reports every non-success outcome to the user.
///
/// This owns the Geolocator ladder + the whole result switch that used to be
/// copy-pasted across the location-search, change-location and onboarding
/// location screens. Each caller keeps only its own success handler (branching
/// on [LocationDetectResult.success] and using the returned `city`) plus its
/// own in-flight spinner state.
///
/// Reporting goes through [FlatmatesToast], except for the two outcomes that
/// offer a settings shortcut (service disabled / permission denied forever):
/// [FlatmatesToast] cannot carry a [SnackBarAction], so those keep a snackbar
/// with an action to preserve the jump-to-settings affordance.
Future<
  ({LocationDetectResult result, CatalogOption? city, String? errorDetail})
>
detectAndReportLocation(
  BuildContext context, {
  required List<CatalogOption> catalogCities,
}) async {
  ({LocationDetectResult result, CatalogOption? city, String? errorDetail})
  detection;
  try {
    detection = await detectCurrentLocation(catalogCities: catalogCities);
  } catch (e) {
    debugPrint('detectAndReportLocation unhandled: $e');
    detection = (
      result: LocationDetectResult.error,
      city: null,
      errorDetail: e.toString(),
    );
  }
  if (!context.mounted) return detection;

  final locale = AppLocalizations.of(context);
  switch (detection.result) {
    case LocationDetectResult.success:
      // Caller handles the matched city.
      break;
    case LocationDetectResult.serviceDisabled:
      _reportServiceDisabled(context, locale);
    case LocationDetectResult.permissionDenied:
      FlatmatesToast.info(context, locale.locationPermissionRequired);
    case LocationDetectResult.permissionDeniedForever:
      _reportPermissionDeniedForever(context, locale);
    case LocationDetectResult.noMatch:
      FlatmatesToast.info(context, locale.locationNoMatchFound);
    case LocationDetectResult.error:
      debugPrint('detectAndReportLocation error: ${detection.errorDetail}');
      FlatmatesToast.error(context, locale.locationDetectionFailed);
  }
  return detection;
}

/// Runs the Geolocator permission/service ladder, fetches the raw current
/// position and reverse-geocodes a human-readable name for it.
///
/// Unlike [detectAndReportLocation], this does NOT require the position to
/// match a catalog city — it is for surfaces (the map location picker) that
/// accept an arbitrary lat/lng. Failures are reported through [FlatmatesToast]
/// (or a snackbar with an action for the two settings-shortcut cases); returns
/// `null` when no position could be obtained, already reported.
Future<LocationData?> resolveRawPosition(BuildContext context) async {
  final locale = AppLocalizations.of(context);

  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!context.mounted) return null;
  if (!serviceEnabled) {
    _reportServiceDisabled(context, locale);
    return null;
  }

  var permission = await Geolocator.checkPermission();
  if (!context.mounted) return null;
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (!context.mounted) return null;
  }
  if (permission == LocationPermission.denied) {
    FlatmatesToast.info(context, locale.locationPermissionRequired);
    return null;
  }
  if (permission == LocationPermission.deniedForever) {
    _reportPermissionDeniedForever(context, locale);
    return null;
  }

  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: kLocationTimeout,
      ),
    );
    if (!context.mounted) return null;

    String locationName = locale.currentLocationLabel;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[
          if (place.locality?.isNotEmpty ?? false) place.locality!,
          if (place.administrativeArea?.isNotEmpty ?? false)
            place.administrativeArea!,
        ];
        if (parts.isNotEmpty) locationName = parts.join(', ');
      }
    } catch (e) {
      debugPrint('resolveRawPosition geocoding failed: $e');
    }
    if (!context.mounted) return null;
    return LocationData(
      name: locationName,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  } catch (e) {
    debugPrint('resolveRawPosition failed: $e');
    if (context.mounted) {
      FlatmatesToast.error(context, locale.locationDetectionFailed);
    }
    return null;
  }
}

void _reportServiceDisabled(BuildContext context, AppLocalizations locale) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(locale.locationServicesDisabled),
      action: SnackBarAction(
        label: locale.locationServicesDisabledAction,
        onPressed: Geolocator.openLocationSettings,
      ),
      duration: const Duration(seconds: 5),
    ),
  );
}

void _reportPermissionDeniedForever(
  BuildContext context,
  AppLocalizations locale,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(locale.locationPermissionDeniedForever),
      action: SnackBarAction(
        label: locale.locationOpenAppSettings,
        onPressed: Geolocator.openAppSettings,
      ),
      duration: const Duration(seconds: 5),
    ),
  );
}
