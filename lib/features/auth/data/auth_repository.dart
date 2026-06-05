import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_token_storage.dart';

final class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required AuthTokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final AuthTokenStorage _tokenStorage;

  SupabaseClient get _supabase => Supabase.instance.client;

  Session? get currentSession => _supabase.auth.currentSession;
  String? get currentPhone => currentSession?.user.phone;

  static const _supabaseRedirectUrl =
      'io.supabase.flutter://pezjtoivkrmepydqminz/auth-callback';

  Future<void> requestOtp(String phone) async {
    await _supabase.auth.signInWithOtp(phone: phone);
  }

  Future<void> signInWithPassword({
    required String phone,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      phone: phone,
      password: password,
    );
    final session = response.session ?? _supabase.auth.currentSession;
    if (session == null) {
      throw StateError('Session missing after sign in.');
    }
    await _tokenStorage.save(session.accessToken);
    await _apiClient.get(FlatmatesEndpoints.me);
  }

  Future<void> signInWithGoogle() async {
    final completer = Completer<void>();
    StreamSubscription? authSub;

    authSub = _supabase.auth.onAuthStateChange.listen((data) {
      if (data.session != null && !completer.isCompleted) {
        completer.complete();
      }
    });

    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _supabaseRedirectUrl,
      );

      await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw TimeoutException(
          'Google Sign-In timed out. Please try again.',
        ),
      );

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw StateError('Session missing after Google sign in.');
      }
      await _tokenStorage.save(session.accessToken);
      await _apiClient.get(FlatmatesEndpoints.me);
    } finally {
      await authSub.cancel();
    }
  }

  Future<void> signUpWithPassword({
    required String fullName,
    required String phone,
    required String password,
    String? email,
  }) async {
    final response = await _supabase.auth.signUp(
      phone: phone,
      password: password,
      data: {
        'full_name': fullName,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      },
    );
    final session = response.session ?? _supabase.auth.currentSession;
    if (session != null) {
      await _tokenStorage.save(session.accessToken);
      await _apiClient.get(FlatmatesEndpoints.me);
    }
  }

  Future<void> verifyOtp({required String phone, required String otp}) async {
    final response = await _supabase.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );
    final session = response.session ?? _supabase.auth.currentSession;
    if (session == null) {
      throw StateError('Session missing after OTP verification.');
    }
    await _tokenStorage.save(session.accessToken);
    await _apiClient.get(FlatmatesEndpoints.me);
  }

  Future<void> sendPasswordResetOtp(String phone) async {
    await _supabase.auth.signInWithOtp(phone: phone, shouldCreateUser: false);
  }

  Future<void> verifyPasswordResetOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );
    final session = response.session ?? _supabase.auth.currentSession;
    if (session == null) {
      throw StateError(
        'Session missing after password reset OTP verification.',
      );
    }
    await _tokenStorage.save(session.accessToken);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _tokenStorage.clear();
  }

  Future<void> changePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
