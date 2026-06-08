import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'network/api_client.dart';
import 'network/auth_token_provider.dart';
import 'storage/app_preferences.dart';
import 'storage/auth_token_storage.dart';
import 'storage/onboarding_draft_storage.dart';
import 'storage/secure_kv_store.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('AppConfig override is required'),
);

final appPreferencesProvider = Provider<AppPreferences>(
  (ref) => throw UnimplementedError('AppPreferences override is required'),
);

final secureStoreProvider = Provider<SecureKvStore>(
  (ref) => throw UnimplementedError('SecureKvStore override is required'),
);

final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  final storage = AuthTokenStorage(ref.watch(secureStoreProvider));
  ref.onDispose(() => storage.dispose());
  return storage;
});

final authTokenProviderProvider = Provider<AuthTokenProvider>(
  (ref) => RefreshingAuthTokenProvider(ref.watch(authTokenStorageProvider)),
);

final onboardingDraftStorageProvider = Provider<OnboardingDraftStorage>((ref) {
  return OnboardingDraftStorage(ref.watch(appPreferencesProvider));
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
    tokenProvider: ref.watch(authTokenProviderProvider),
  ),
);
