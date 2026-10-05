import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/core/location/location_data.dart';
import 'package:flatmates_app/features/location/application/location_controller.dart';

/// A [LocationController] whose GPS path always fails (no geolocator plugin in
/// tests) and whose IP lookup result is scripted by the test.
class _ScriptedLocationController extends LocationController {
  LocationData? ipResult;

  @override
  Future<LocationData?> getIpLocation() async => ipResult;
}

ProviderContainer _container(_ScriptedLocationController controller) {
  final container = ProviderContainer(
    overrides: [locationControllerProvider.overrideWith(() => controller)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  const fallback = LocationData(
    name: 'Bengaluru, Karnataka',
    latitude: 12.9716,
    longitude: 77.5946,
  );

  group('LocationController.getCurrentLocation', () {
    test('a successful IP fallback clears an earlier detection error', () async {
      final controller = _ScriptedLocationController();
      final container = _container(controller);
      final notifier = container.read(locationControllerProvider.notifier);

      // First detection: GPS fails and the IP lookup fails too → error.
      await notifier.getCurrentLocation();
      final failed = container.read(locationControllerProvider);
      expect(failed.error, LocationError.couldNotDetect);
      expect(failed.selectedLocation, isNull);
      expect(failed.isLoading, isFalse);

      // A later detection succeeds through the IP fallback.
      controller.ipResult = fallback;
      await notifier.getCurrentLocation(forceRefresh: true);

      final recovered = container.read(locationControllerProvider);
      expect(
        recovered.error,
        isNull,
        reason:
            'a usable fallback location is not a detection error; MapViewPage '
            'branches on `error` to decide between recentring and toasting',
      );
      expect(recovered.selectedLocation, fallback);
      expect(recovered.currentAddress, fallback.name);
      expect(recovered.isLoading, isFalse);
    });

    test('a failed retry keeps the error set', () async {
      final controller = _ScriptedLocationController();
      final container = _container(controller);
      final notifier = container.read(locationControllerProvider.notifier);

      await notifier.getCurrentLocation();
      expect(
        container.read(locationControllerProvider).error,
        LocationError.couldNotDetect,
      );

      // Still no GPS fix and still no IP answer: the error must survive.
      await notifier.getCurrentLocation(forceRefresh: true);
      expect(
        container.read(locationControllerProvider).error,
        LocationError.couldNotDetect,
      );
    });
  });
}
