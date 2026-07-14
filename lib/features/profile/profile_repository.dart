import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/endpoints.dart';
import '../../core/providers.dart';
import '../bootstrap/bootstrap_controller.dart';

class ProfileRepository {
  const ProfileRepository(this._ref);

  final Ref _ref;

  Future<FlatmatesProfileModel> updateProfile({
    required Map<String, dynamic> payload,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .put(FlatmatesEndpoints.flatmatesProfile, data: payload);
    final responseData = response.data;
    return FlatmatesProfileModel.fromJson(
      Map<String, dynamic>.from(responseData is Map ? responseData : const {}),
    );
  }

  Future<FlatmatesProfileModel> fetchProfile() async {
    final response = await _ref
        .read(apiClientProvider)
        .get(FlatmatesEndpoints.flatmatesProfile);
    final responseData = response.data;
    return FlatmatesProfileModel.fromJson(
      Map<String, dynamic>.from(responseData is Map ? responseData : const {}),
    );
  }

  Future<void> completeFlatmatesOnboarding() async {
    await _ref
        .read(apiClientProvider)
        .post(FlatmatesEndpoints.completeFlatmatesOnboarding);
  }

  /// Updates core user fields via `PUT /users/me` (the general user update
  /// endpoint). Use this for fields that live on the `User` model itself —
  /// notably `full_name` and `date_of_birth` — which the profile_completion
  /// auth gate checks. The flatmates-specific [updateProfile] endpoint does
  /// not support `date_of_birth`.
  Future<void> updateUser({required Map<String, dynamic> payload}) async {
    await _ref
        .read(apiClientProvider)
        .put(FlatmatesEndpoints.me, data: payload);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref),
);
