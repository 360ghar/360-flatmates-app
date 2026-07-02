import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/endpoints.dart';
import '../../core/providers.dart';
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
    if (state.isLoading) return;
    // Retain the previous value while reloading so widgets watching
    // `valueOrNull` (e.g. the Discover page's profile/city) don't flicker to
    // null mid-refresh. `isLoading` stays true for any spinner that needs it.
    state = const AsyncLoading<BootstrapData?>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchBootstrapData());
  }

  Future<BootstrapData?> _fetchBootstrapData() async {
    final client = ref.read(apiClientProvider);
    // Fetch bootstrap + auth-state in parallel.
    final results = await Future.wait([
      client.get(FlatmatesEndpoints.bootstrap),
      client.get(FlatmatesEndpoints.authState),
    ]);
    final bootstrapResponse = results[0];
    final authStateResponse = results[1];

    final data = bootstrapResponse.data;
    if (data == null || data is! Map) return null;

    // Update the AuthController's gate stage from the backend.
    final authStateData = authStateResponse.data;
    if (authStateData is Map) {
      final stageMap = Map<String, dynamic>.from(authStateData);
      final authController = ref.read(authControllerProvider.notifier);
      authController.updateGateStage(
        AuthStage.fromWire(stageMap['stage'] as String?),
        missingFields:
            (stageMap['missing_fields'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
    }

    return BootstrapData.fromJson(Map<String, dynamic>.from(data));
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

final bootstrapControllerProvider =
    AsyncNotifierProvider<BootstrapController, BootstrapData?>(
      BootstrapController.new,
    );
