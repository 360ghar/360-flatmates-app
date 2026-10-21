import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/onboarding/application/profile_completion_controller.dart';
import 'package:flatmates_app/features/onboarding/onboarding_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/recording_api.dart';
import '../helpers/test_helpers.dart';
import 'api_fixtures.dart';
import 'contract_checks.dart';

/// The profile writes of the onboarding and profile-completion flows are
/// checked against the bodies the backend declares: `PUT /flatmates/profile`
/// and `PUT /users/me` reject an undeclared key (422), and an enum field takes
/// its wire values only.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  Future<RecordingApi> api() async {
    final prefs = await testAppPreferences;
    return RecordingApi(
      (options) {
        if (options.path == '/flatmates/profile') {
          return ok(apiFixture('bootstrap', 'profile'));
        }
        if (options.path == '/users/me') {
          return ok(apiFixture('bootstrap', 'self_user'));
        }
        return ok(<String, dynamic>{'id': 7});
      },
      overrides: [
        appPreferencesProvider.overrideWithValue(prefs),
        authControllerProvider.overrideWith(() => FakeAuthController()),
        bootstrapControllerProvider.overrideWith(
          () => FakeBootstrapController(),
        ),
      ],
    );
  }

  test(
    'the onboarding submit sends only keys FlatmatesProfileUpdate declares',
    () async {
      final recorder = await api();
      final controller = recorder.container.read(
        onboardingControllerProvider.notifier,
      );
      await controller.setMode('room_poster');
      await controller.setBasicInfo({
        'full_name': 'Asha Verma',
        'age': 29,
        'profession': 'Engineer',
        'city': 'Bengaluru',
        'locality': 'Koramangala',
      });
      await controller.setPhotoUrls(['https://cdn.example.com/asha.jpg']);
      await controller.setLifestyleAnswers({
        'sleep_schedule': 'early_bird',
        'cleanliness': 'tidy',
        'food_habits': 'vegetarian',
        'smoking': 'never',
        'drinking': 'occasionally',
        'guests_policy': 'occasional_ok',
        'work_style': 'wfh',
      });
      await controller.setBudgetTimeline({
        'budget_min': 15000.0,
        'budget_max': 30000.0,
        'move_in_timeline': 'within_1_month',
      });
      await controller.setPreferences({'gender_preference': 'female'});
      await controller.submitNonNegotiables(['no_smoking']);

      final puts = recorder.to('PUT', '/flatmates/profile');
      expect(puts, hasLength(1));
      final body = Map<String, dynamic>.from(puts.single.data as Map);
      expectBodyMatchesContract(body, 'FlatmatesProfileUpdate');
      // The account fields are not profile fields.
      expect(body.containsKey('email'), isFalse);
      expect(body.containsKey('phone'), isFalse);
      expect(body['mode'], 'room_poster');
      expect(body['profile_image_url'], 'https://cdn.example.com/asha.jpg');
      expect(body['sleep_schedule'], 'early_bird');

      // The completion call names the app.
      expect(
        recorder.requests.any(
          (r) =>
              r.method == 'POST' &&
              r.path == '/users/me/onboarding?app=flatmates',
        ),
        isTrue,
      );
    },
  );

  test('the profile completion sends only keys UserUpdate declares', () async {
    final recorder = await api();

    await recorder.container
        .read(profileCompletionControllerProvider)
        .submit(
          trimmedName: 'Asha Verma',
          dob: DateTime(1996, 4, 12),
          needsName: true,
          needsDob: true,
        );

    final user = recorder.to('PUT', '/users/me');
    expect(user, hasLength(1));
    final userBody = Map<String, dynamic>.from(user.single.data as Map);
    expectBodyMatchesContract(userBody, 'UserUpdate');
    // A date-only field is YYYY-MM-DD, never a datetime.
    expect(userBody['date_of_birth'], '1996-04-12');

    final profile = recorder.to('PUT', '/flatmates/profile');
    expect(profile, isNotEmpty);
    for (final request in profile) {
      expectBodyMatchesContract(
        Map<String, dynamic>.from(request.data as Map),
        'FlatmatesProfileUpdate',
      );
    }
  });
}
