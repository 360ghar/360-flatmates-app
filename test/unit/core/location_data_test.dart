import 'package:flatmates_app/core/location/location_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LocationData at(double lat, double lng) =>
      LocationData(name: 'x', latitude: lat, longitude: lng);

  test('hasCoordinates is false for 0,0 and non-finite values', () {
    expect(at(12.97, 77.59).hasCoordinates, isTrue);
    expect(at(0, 77.59).hasCoordinates, isTrue);
    expect(at(0, 0).hasCoordinates, isFalse);
    expect(at(double.nan, 77.59).hasCoordinates, isFalse);
    expect(at(12.97, double.infinity).hasCoordinates, isFalse);
  });
}
