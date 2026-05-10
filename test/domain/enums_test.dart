import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/domain/enums.dart';

void main() {
  group('Enum roundtrips', () {
    test('UserMode roundtrip', () {
      for (final value in UserMode.values) {
        expect(UserMode.fromApi(value.toApi()), value);
      }
    });
    test('SharingType roundtrip', () {
      for (final value in SharingType.values) {
        expect(SharingType.fromApi(value.toApi()), value);
      }
    });
    test('GenderPreference roundtrip', () {
      for (final value in GenderPreference.values) {
        expect(GenderPreference.fromApi(value.toApi()), value);
      }
    });
    test('VisitStatus roundtrip', () {
      for (final value in VisitStatus.values) {
        expect(VisitStatus.fromApi(value.toApi()), value);
      }
    });
    test('TimeSlot roundtrip', () {
      for (final value in TimeSlot.values) {
        expect(TimeSlot.fromApi(value.toApi()), value);
      }
    });
    test('TimeSlot.hour returns correct int', () {
      expect(TimeSlot.morning.hour, 10);
      expect(TimeSlot.afternoon.hour, 15);
      expect(TimeSlot.evening.hour, 18);
    });
    test('FoodHabits roundtrip', () {
      for (final value in FoodHabits.values) {
        expect(FoodHabits.fromApi(value.toApi()), value);
      }
    });
    test('UserMode.fromApi handles unknown gracefully', () {
      expect(UserMode.fromApi('unknown'), UserMode.coHunter);
    });
  });
}
