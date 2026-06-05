import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  SupabaseClient get _supabase => Supabase.instance.client;

  Session? get currentSession => _supabase.auth.currentSession;
  String? get currentPhone => currentSession?.user.phone;

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
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw StateError('Google Sign-In was cancelled.');
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      await _googleSignIn.disconnect();
      throw StateError(
        'Failed to get Google ID token. '
        'Ensure the web client ID is configured for this app.',
      );
    }

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );

    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw StateError('Session missing after Google sign in.');
    }
    await _tokenStorage.save(session.accessToken);
    await _apiClient.get(FlatmatesEndpoints.me);
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
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
    await _tokenStorage.clear();
  }

  Future<void> changePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
