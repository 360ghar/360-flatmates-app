import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../../core/storage/app_preferences.dart';
import '../auth/auth_controller.dart';
import 'domain/bootstrap_models.dart';

export 'domain/bootstrap_models.dart';

class BootstrapController extends AsyncNotifier<BootstrapData?> {
  @override
  Future<BootstrapData?> build() async {
    // Bootstrap data is only meaningful for an authenticated user. Fetching it
    // while unauthenticated issues /bootstrap + /users/me/auth-state with no
    // token, which can clear a fresh session through the auth interceptor. Only
    // watch the boolean login state so this provider starts after login without
    // refetching when auth-stage/profile gates are updated from auth-state.
    final isLoggedIn = ref.watch(
      authControllerProvider.select((state) => state.isLoggedIn),
    );
    if (!isLoggedIn) return null;
    return _fetchBootstrapData();
  }

  Future<void> refresh() async {
    if (!ref.read(authControllerProvider).isLoggedIn) {
      state = const AsyncValue.data(null);
      return;
    }
    if (state.isLoading) {
      await future.catchError((Object _) => null);
      if (!ref.read(authControllerProvider).isLoggedIn) {
        state = const AsyncValue.data(null);
        return;
      }
    }
    // Retain the previous value while reloading so widgets watching
    // `valueOrNull` (e.g. the Discover page's profile/city) don't flicker to
    // null mid-refresh — and so the router does not bounce to /splash.
    final previous = state;
    state = const AsyncLoading<BootstrapData?>().copyWithPrevious(previous);
    final next = await AsyncValue.guard(() => _fetchBootstrapData());
    // Sign-out can win the race while this refresh was in flight — never
    // restore the previous account's bootstrap after clear().
    if (!ref.read(authControllerProvider).isLoggedIn) {
      state = const AsyncValue.data(null);
      return;
    }
    if (next.hasError && previous.valueOrNull != null) {
      // Soft-refresh failure: keep last good bootstrap so the user stays in
      // the app (post-create, pull-to-refresh, etc.).
      state = AsyncError<BootstrapData?>(
        next.error!,
        next.stackTrace ?? StackTrace.current,
      ).copyWithPrevious(previous);
      return;
    }
    state = next;
  }

  /// Re-fetches only `/users/me/auth-state` and updates the auth gate stage.
  ///
  /// Used after profile-completion saves when a full [refresh] may soft-fail
  /// (keeping the previous stage) even though the PUT succeeded. Throws on
  /// network/API failure so the caller can surface a real error.
  Future<void> refreshAuthStage() async {
    if (!ref.read(authControllerProvider).isLoggedIn) return;
    final client = ref.read(apiClientProvider);
    final critical = ApiClient.criticalPathOptions();
    final response = await client.get(
      FlatmatesEndpoints.authState,
      options: critical,
    );
    final authStateData = response.data;
    if (authStateData is! Map) {
      throw StateError('auth-state response was not a JSON object');
    }
    final stageMap = Map<String, dynamic>.from(authStateData);
    final stage = AuthStage.fromWire(stageMap['stage'] as String?);
    final profileId = ref
        .read(bootstrapControllerProvider)
        .valueOrNull
        ?.profile
        .id
        .toString();
    ref
        .read(authControllerProvider.notifier)
        .updateGateStage(
          _applyLocalProfileCompletionOverride(
            stage: stage,
            profileId: profileId,
          ),
          missingFields:
              (stageMap['missing_fields'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
        );
  }

  Future<BootstrapData?> _fetchBootstrapData() async {
    final client = ref.read(apiClientProvider);
    // Fail fast on cold start: if the API/DB is wedged, splash should show
    // retry within ~15s instead of sitting on the global 60s Dio timeout.
    final critical = ApiClient.criticalPathOptions();
    // Fetch bootstrap + auth-state in parallel.
    final results = await Future.wait([
      client.get(FlatmatesEndpoints.bootstrap, options: critical),
      client.get(FlatmatesEndpoints.authState, options: critical),
    ]);
    final bootstrapResponse = results[0];
    final authStateResponse = results[1];

    final data = bootstrapResponse.data;
    if (data == null || data is! Map) return null;

    // Update the AuthController's gate stage from the backend.
    final authStateData = authStateResponse.data;
    if (authStateData is Map) {
      final stageMap = Map<String, dynamic>.from(authStateData);
      final stage = AuthStage.fromWire(stageMap['stage'] as String?);
      final missingFields =
          (stageMap['missing_fields'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      final authController = ref.read(authControllerProvider.notifier);
      authController.updateGateStage(
        _applyLocalProfileCompletionOverride(
          stage: stage,
          profileId: _profileIdFromBootstrap(data),
        ),
        missingFields: missingFields,
      );
    }

    return BootstrapData.fromJson(Map<String, dynamic>.from(data));
  }

  /// Production `PUT /users/me` has been observed to return 200 with name/DOB
  /// in the body while never committing them. The profile-completion form
  /// records a per-user local override so the app is not hard-stuck on
  /// `/complete-profile` until the backend is fixed.
  AuthStage _applyLocalProfileCompletionOverride({
    required AuthStage stage,
    required String? profileId,
  }) {
    if (stage != AuthStage.profileCompletion) return stage;
    if (profileId == null || profileId.isEmpty) return stage;
    final localUserId = ref
        .read(appPreferencesProvider)
        .getString(PrefKeys.profileCompletionLocalUserId);
    if (localUserId == profileId) {
      return AuthStage.appOnboarding;
    }
    return stage;
  }

  static String? _profileIdFromBootstrap(Object data) {
    if (data is! Map) return null;
    final profile = data['profile'];
    if (profile is! Map) return null;
    final id = profile['id'];
    if (id == null) return null;
    return id.toString();
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

final bootstrapControllerProvider =
    AsyncNotifierProvider<BootstrapController, BootstrapData?>(
      BootstrapController.new,
    );
