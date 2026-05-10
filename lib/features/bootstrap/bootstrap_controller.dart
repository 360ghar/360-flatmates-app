import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/endpoints.dart';
import '../../core/providers.dart';
import 'domain/bootstrap_models.dart';

export 'domain/bootstrap_models.dart';

class BootstrapController extends AsyncNotifier<BootstrapData?> {
  bool _isLoading = false;

  @override
  FutureOr<BootstrapData?> build() => null;

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    state = const AsyncValue.loading();
    try {
      state = await AsyncValue.guard(() async {
        final response = await ref
            .read(apiClientProvider)
            .get(FlatmatesEndpoints.bootstrap);
        final data = response.data;
        if (data == null || data is! Map) return null;
        return BootstrapData.fromJson(Map<String, dynamic>.from(data));
      });
    } finally {
      _isLoading = false;
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

final bootstrapControllerProvider =
    AsyncNotifierProvider<BootstrapController, BootstrapData?>(
      BootstrapController.new,
    );
