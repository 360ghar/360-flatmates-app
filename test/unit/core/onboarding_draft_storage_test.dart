import 'dart:convert';

import 'package:flatmates_app/core/storage/app_preferences.dart';
import 'package:flatmates_app/core/storage/onboarding_draft_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await AppPreferences.create();
  });

  OnboardingDraftStorage storeFor(String? account) =>
      OnboardingDraftStorage(prefs, accountId: () => account);

  test('a draft comes back for the account that wrote it', () async {
    await storeFor('user-a').save({'step': 'basicInfo', 'full_name': 'Asha'});

    expect(storeFor('user-a').load(), {
      'step': 'basicInfo',
      'full_name': 'Asha',
    });
  });

  test('another account, or no account, never reads the draft', () async {
    await storeFor('user-a').save({'full_name': 'Asha'});

    expect(storeFor('user-b').load(), isNull);
    expect(storeFor(null).load(), isNull);
  });

  test('a draft of another schema version is dropped, never read', () async {
    await prefs.setString(
      PrefKeys.onboardingDraft,
      jsonEncode({
        'v': OnboardingDraftStorage.schemaVersion + 1,
        'account': 'user-a',
        'data': {'full_name': 'Asha'},
      }),
    );

    expect(storeFor('user-a').load(), isNull);
  });

  test('a draft an earlier build wrote (no version) is dropped', () async {
    await prefs.setString(
      PrefKeys.onboardingDraft,
      jsonEncode({'step': 'basicInfo', 'full_name': 'Asha'}),
    );

    expect(storeFor('user-a').load(), isNull);
  });

  test('clear removes the draft', () async {
    final store = storeFor('user-a');
    await store.save({'full_name': 'Asha'});
    await store.clear();

    expect(prefs.containsKey(PrefKeys.onboardingDraft), isFalse);
    expect(store.load(), isNull);
  });
}
