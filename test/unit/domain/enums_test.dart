import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/core/domain/enums.dart';

void main() {
  group('UserMode', () {
    test('roundtrip: toApi → fromApi preserves value', () {
      for (final mode in UserMode.values) {
        expect(UserMode.fromApi(mode.toApi()), mode);
      }
    });

    test('fromApi handles unknown gracefully (defaults to coHunter)', () {
      expect(UserMode.fromApi('unknown_mode'), UserMode.coHunter);
    });

    test('fromApi handles empty string gracefully', () {
      expect(UserMode.fromApi(''), UserMode.coHunter);
    });

    test('label is non-empty for each mode', () {
      for (final mode in UserMode.values) {
        expect(mode.label, isNotEmpty);
      }
    });
  });

  group('SharingType', () {
    test('roundtrip: toApi → fromApi preserves value', () {
      for (final type in SharingType.values) {
        expect(SharingType.fromApi(type.toApi()), type);
      }
    });

    test('fromApi handles unknown gracefully (defaults to privateRoom)', () {
      expect(SharingType.fromApi('unknown'), SharingType.privateRoom);
    });
  });

  group('GenderPreference', () {
    test('roundtrip: toApi → fromApi preserves value', () {
      for (final pref in GenderPreference.values) {
        expect(GenderPreference.fromApi(pref.toApi()), pref);
      }
    });

    test('fromApi handles unknown gracefully (defaults to any)', () {
      expect(GenderPreference.fromApi('unknown'), GenderPreference.any);
    });
  });

  group('VisitStatus', () {
    test('roundtrip: toApi → fromApi preserves value', () {
      for (final status in VisitStatus.values) {
        expect(VisitStatus.fromApi(status.toApi()), status);
      }
    });

    test('fromApi handles unknown gracefully (defaults to requested)', () {
      expect(VisitStatus.fromApi('unknown'), VisitStatus.requested);
    });
  });

  group('TimeSlot', () {
    test('roundtrip: toApi → fromApi preserves value', () {
      for (final slot in TimeSlot.values) {
        expect(TimeSlot.fromApi(slot.toApi()), slot);
      }
    });

    test('fromApi handles unknown gracefully (defaults to afternoon)', () {
      expect(TimeSlot.fromApi('unknown'), TimeSlot.afternoon);
    });

    test('morning.hour returns 10', () {
      expect(TimeSlot.morning.hour, 10);
    });

    test('afternoon.hour returns 15', () {
      expect(TimeSlot.afternoon.hour, 15);
    });

    test('evening.hour returns 18', () {
      expect(TimeSlot.evening.hour, 18);
    });
  });

  group('FoodHabits', () {
    test('roundtrip: toApi → fromApi preserves value', () {
      for (final habit in FoodHabits.values) {
        expect(FoodHabits.fromApi(habit.toApi()), habit);
      }
    });

    test('fromApi handles unknown gracefully (defaults to noPreference)', () {
      expect(FoodHabits.fromApi('unknown'), FoodHabits.noPreference);
    });
  });

  group('ListingModerationStatus', () {
    test('roundtrip: toApi → fromApi preserves value', () {
      for (final status in ListingModerationStatus.values) {
        expect(ListingModerationStatus.fromApi(status.toApi()), status);
      }
    });
  });

  group('ProfileStatus', () {
    test('roundtrip: toApi → fromApi preserves value', () {
      for (final status in ProfileStatus.values) {
        expect(ProfileStatus.fromApi(status.toApi()), status);
      }
    });
  });

  group('SwipeAction', () {
    test('roundtrip: toApi → fromApi preserves value', () {
      for (final action in SwipeAction.values) {
        expect(SwipeAction.fromApi(action.toApi()), action);
      }
    });
  });

  group('SmokingPreference', () {
    test('roundtrip: toApi → fromApi preserves value', () {
      for (final pref in SmokingPreference.values) {
        expect(SmokingPreference.fromApi(pref.toApi()), pref);
      }
    });
  });

  group('PetPreference', () {
    test('roundtrip: toApi → fromApi preserves value', () {
      for (final pref in PetPreference.values) {
        expect(PetPreference.fromApi(pref.toApi()), pref);
      }
    });
  });
}
