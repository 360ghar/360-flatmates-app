import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/endpoints.dart';
import '../../core/providers.dart';
import 'domain/bootstrap_models.dart';

export 'domain/bootstrap_models.dart';

class BootstrapController extends AsyncNotifier<BootstrapData?> {
  @override
  Future<BootstrapData?> build() async {
    return _fetchBootstrapData();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchBootstrapData());
  }

  Future<BootstrapData?> _fetchBootstrapData() async {
    final response = await ref
        .read(apiClientProvider)
        .get(FlatmatesEndpoints.bootstrap);
    final data = response.data;
    if (data == null || data is! Map) return null;
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
