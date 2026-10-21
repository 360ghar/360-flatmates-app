import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/core/location/location_data.dart';
import 'package:flatmates_app/features/location/application/location_controller.dart';

/// A [LocationController] whose GPS path always fails (no geolocator plugin in
/// tests) and whose IP lookup result is scripted by the test.
class _ScriptedLocationController extends LocationController {
  LocationData? ipResult;

  /// When set, the IP lookup waits for it, so a test can hold a detection open.
  Completer<void>? gate;
  int ipCalls = 0;

  @override
  Future<LocationData?> getIpLocation() async {
    ipCalls++;
    await gate?.future;
    return ipResult;
  }
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

    test('a concurrent call joins the running detection', () async {
      final controller = _ScriptedLocationController()
        ..ipResult = fallback
        ..gate = Completer<void>();
      final container = _container(controller);
      final notifier = container.read(locationControllerProvider.notifier);

      final first = notifier.getCurrentLocation();
      final second = notifier.getCurrentLocation();
      var secondDone = false;
      unawaited(second.then((_) => secondDone = true));
      await Future<void>.delayed(Duration.zero);
      expect(secondDone, isFalse, reason: 'the detection is still running');

      controller.gate!.complete();
      await Future.wait([first, second]);

      expect(controller.ipCalls, 1, reason: 'one detection, not two');
      expect(container.read(locationControllerProvider).ipLocation, fallback);
    });

    test('a 0,0 IP result is a failed detection', () async {
      final controller = _ScriptedLocationController()
        ..ipResult = const LocationData(name: '', latitude: 0, longitude: 0);
      final container = _container(controller);

      await container
          .read(locationControllerProvider.notifier)
          .getCurrentLocation();

      final state = container.read(locationControllerProvider);
      expect(state.error, LocationError.couldNotDetect);
      expect(state.ipLocation, isNull);
    });

    test('the IP fix is kept apart from a manually chosen city', () async {
      const manual = LocationData(
        name: 'Pune',
        latitude: 18.5204,
        longitude: 73.8567,
      );
      final controller = _ScriptedLocationController()..ipResult = fallback;
      final container = _container(controller);
      final notifier = container.read(locationControllerProvider.notifier);

      notifier.selectLocation(manual);
      await notifier.getCurrentLocation();

      final state = container.read(locationControllerProvider);
      expect(state.selectedLocation, manual);
      expect(state.ipLocation, fallback);
    });
  });
}
