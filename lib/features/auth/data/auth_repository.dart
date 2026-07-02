import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_token_storage.dart';
import '../domain/auth_state.dart';

/// Neutral result of `POST /api/v1/auth/identifier-status`.
@immutable
class IdentifierStatus {
  const IdentifierStatus({
    required this.exists,
    required this.verified,
    required this.hasPassword,
    required this.channel,
    required this.nextStep,
  });

  /// Whether an account already exists for the identifier.
  final bool exists;

  /// Whether the identifier (and therefore the account) is verified.
  final bool verified;

  /// Whether the account has a password set.
  final bool hasPassword;

  /// Whether the identifier is a phone or an email.
  final AuthChannel channel;

  /// Server-recommended next step: password (verified) or otp.
  final IdentifierNextStep nextStep;

  factory IdentifierStatus.fromJson(Map<String, dynamic> json) {
    return IdentifierStatus(
      exists: json['exists'] as bool? ?? false,
      verified: json['verified'] as bool? ?? false,
      hasPassword: json['has_password'] as bool? ?? false,
      channel: (json['channel'] as String?) == 'email'
          ? AuthChannel.email
          : AuthChannel.phone,
      nextStep: (json['next_step'] as String?) == 'password'
          ? IdentifierNextStep.password
          : IdentifierNextStep.otp,
    );
  }
}

enum IdentifierNextStep { password, otp }

/// Thrown when the user dismisses the native Apple sign-in sheet.
/// Callers should treat this as a silent no-op, not an error.
class AppleSignInCancelled implements Exception {
  const AppleSignInCancelled();
}

final class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required AuthTokenStorage tokenStorage,
    required AppConfig config,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage,
       _config = config;

  final ApiClient _apiClient;
  final AuthTokenStorage _tokenStorage;
  final AppConfig _config;
  Future<void>? _googleSignInInitializeFuture;
  String? _googleSignInInitializeKey;

  SupabaseClient get _supabase => Supabase.instance.client;

  Session? get currentSession => _supabase.auth.currentSession;
  String? get currentPhone => currentSession?.user.phone;
  String? get currentEmail => currentSession?.user.email;

  /// Whether the signed-in user already has a (verified) phone on file.
  bool get hasPhone {
    final user = currentSession?.user;
    if (user == null) return false;
    final phone = user.phone;
    return phone != null && phone.trim().isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Login state-machine
  // ---------------------------------------------------------------------------

  /// Calls the public `POST /api/v1/auth/identifier-status` endpoint to decide
  /// whether to route the user to a password screen, an OTP screen, or signup.
  Future<IdentifierStatus> checkIdentifierStatus(String identifier) async {
    final response = await _apiClient.post(
      FlatmatesEndpoints.identifierStatus,
      data: {'identifier': identifier},
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('Unexpected identifier-status response shape.');
    }
    return IdentifierStatus.fromJson(data);
  }

  /// Records the last-used auth method on the backend (best-effort, AUTH).
  Future<void> recordLastMethod(AuthMethod method) async {
    try {
      await _apiClient.post(
        FlatmatesEndpoints.lastMethod,
        data: {'method': method.wireValue},
      );
    } catch (e) {
      // Non-fatal: the user is already authenticated; remembering the method
      // is a convenience, not a gate.
      debugPrint('AuthRepository.recordLastMethod failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Google sign-in (native ID-token)
  // ---------------------------------------------------------------------------

  /// Redirect URL used by email OTP links. Google sign-in uses only the native
  /// ID-token flow and must not launch browser OAuth.
  static const emailRedirectUrl = String.fromEnvironment(
    'AUTH_REDIRECT_URL',
    defaultValue: 'com.the360ghar.flatmates360://login-callback',
  );
  static const _googleAuthScopes = <String>['email', 'profile'];

  /// Whether native Google sign-in (ID-token flow) is available.
  bool get isNativeGoogleAvailable =>
      _config.googleWebClientId.trim().isNotEmpty;

  /// Starts Google sign-in with the native device account picker and exchanges
  /// the returned ID token with Supabase. Browser OAuth is intentionally not
  /// used here.
  Future<void> signInWithGoogle() async {
    if (!isNativeGoogleAvailable) {
      throw StateError(
        'GOOGLE_WEB_CLIENT_ID is not configured; Google sign-in is unavailable.',
      );
    }
    await _signInWithGoogleNative();
  }

  /// Native Google Sign-In via the device account picker, exchanging the
  /// returned ID token for a Supabase session (`signInWithIdToken`).
  ///
  /// Mirrors the [signInWithPassword] postlude: persist the access token and
  /// validate the backend user via `GET /users/me`.
  Future<void> _signInWithGoogleNative() async {
    final webClientId = _config.googleWebClientId;
    final iosClientId = _config.googleIosClientId;
    if (webClientId.trim().isEmpty) {
      throw StateError(
        'GOOGLE_WEB_CLIENT_ID is not configured; Google sign-in is unavailable.',
      );
    }

    final signIn = await _initializedGoogleSignIn(
      webClientId: webClientId,
      iosClientId: iosClientId,
    );

    if (!signIn.supportsAuthenticate()) {
      throw StateError('Google sign-in is not supported on this platform.');
    }

    final account = await signIn.authenticate(scopeHint: _googleAuthScopes);
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google did not return an ID token.');
    }

    final accessToken = await _googleAccessTokenFor(account);

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
    final session = response.session ?? _supabase.auth.currentSession;
    if (session == null) {
      throw StateError('Session missing after Google sign in.');
    }
    await _tokenStorage.save(session.accessToken);
    await _apiClient.get(FlatmatesEndpoints.me);
  }

  Future<GoogleSignIn> _initializedGoogleSignIn({
    required String webClientId,
    required String iosClientId,
  }) async {
    final signIn = GoogleSignIn.instance;
    final serverClientId = webClientId.trim();
    final clientId = (Platform.isIOS && iosClientId.trim().isNotEmpty)
        ? iosClientId.trim()
        : null;
    final configKey = '$serverClientId|${clientId ?? ''}';
    final existingFuture = _googleSignInInitializeFuture;

    if (existingFuture != null) {
      if (_googleSignInInitializeKey != configKey) {
        throw StateError(
          'Google sign-in is already initialized with different client configuration.',
        );
      }
      await existingFuture;
      return signIn;
    }

    final initializeFuture = signIn.initialize(
      // serverClientId is the Web client id; Supabase validates the audience
      // against it. clientId is the iOS client id (ignored on Android).
      serverClientId: serverClientId,
      clientId: clientId,
    );
    _googleSignInInitializeFuture = initializeFuture;
    _googleSignInInitializeKey = configKey;

    try {
      await initializeFuture;
    } catch (e) {
      debugPrint('AuthRepository._initializedGoogleSignIn failed: $e');
      if (identical(_googleSignInInitializeFuture, initializeFuture)) {
        _googleSignInInitializeFuture = null;
        _googleSignInInitializeKey = null;
      }
      rethrow;
    }

    return signIn;
  }

  Future<String> _googleAccessTokenFor(GoogleSignInAccount account) async {
    final authorizationClient = account.authorizationClient;
    GoogleSignInClientAuthorization? authorization;
    try {
      authorization = await authorizationClient.authorizationForScopes(
        _googleAuthScopes,
      );
    } catch (e) {
      debugPrint(
        'AuthRepository.signInWithGoogle: silent scope auth failed: $e',
      );
    }

    authorization ??= await authorizationClient.authorizeScopes(
      _googleAuthScopes,
    );
    return authorization.accessToken;
  }

  // ---------------------------------------------------------------------------
  // Apple native ID-token sign-in (iOS)
  // ---------------------------------------------------------------------------

  /// Native Sign in with Apple, exchanging the returned identity token for a
  /// Supabase session (`signInWithIdToken`). Uses a nonce: the SHA-256 hash is
  /// embedded in Apple's token, and the raw nonce is validated by Supabase.
  ///
  /// Mirrors the [signInWithGoogle] postlude: persist the access token and
  /// validate the backend user via `GET /users/me`.
  Future<void> signInWithApple() async {
    final rawNonce = _supabase.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AppleSignInCancelled();
      }
      rethrow;
    }

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw StateError('Apple did not return an identity token.');
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
    final session = response.session ?? _supabase.auth.currentSession;
    if (session == null) {
      throw StateError('Session missing after Apple sign in.');
    }
    await _tokenStorage.save(session.accessToken);
    await _apiClient.get(FlatmatesEndpoints.me);
  }

  // ---------------------------------------------------------------------------
  // Phone OTP + password (existing)
  // ---------------------------------------------------------------------------

  /// Sends an SMS OTP. [shouldCreateUser] is `false` for the login/reset
  /// OTP-first paths (so an unknown/mistyped number is NOT silently created)
  /// and `true` only when signing up an unknown identifier.
  Future<void> requestOtp(String phone, {bool shouldCreateUser = false}) async {
    await _supabase.auth.signInWithOtp(
      phone: phone,
      shouldCreateUser: shouldCreateUser,
    );
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

  /// Password sign-in for the **email** channel (verified email that has a
  /// password set; `next_step == password` from `/auth/identifier-status`).
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final session = response.session ?? _supabase.auth.currentSession;
    if (session == null) {
      throw StateError('Session missing after sign in.');
    }
    await _tokenStorage.save(session.accessToken);
    await _apiClient.get(FlatmatesEndpoints.me);
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

  // ---------------------------------------------------------------------------
  // Email OTP (6-digit, OtpType.email)
  // ---------------------------------------------------------------------------

  /// Sends a 6-digit email OTP. [shouldCreateUser] is true for signup flows
  /// (unknown identifier) and false for re-verifying an existing account.
  Future<void> sendEmailOtp(
    String email, {
    bool shouldCreateUser = true,
  }) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: shouldCreateUser,
      emailRedirectTo: emailRedirectUrl,
    );
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.email,
    );
    final session = response.session ?? _supabase.auth.currentSession;
    if (session == null) {
      throw StateError('Session missing after email OTP verification.');
    }
    await _tokenStorage.save(session.accessToken);
    await _apiClient.get(FlatmatesEndpoints.me);
  }

  // ---------------------------------------------------------------------------
  // Post-Google add-phone (manual linking via phoneChange)
  // ---------------------------------------------------------------------------

  /// Step 1 of adding a phone to an already-authenticated (e.g. Google)
  /// account: requests an SMS OTP for the new number.
  Future<void> sendAddPhoneOtp(String phone) async {
    await _supabase.auth.updateUser(UserAttributes(phone: phone));
  }

  /// Step 2: verifies the SMS OTP for the phone being linked
  /// (`OtpType.phoneChange`).
  Future<void> verifyAddPhoneOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.phoneChange,
    );
    final session = response.session ?? _supabase.auth.currentSession;
    if (session != null) {
      await _tokenStorage.save(session.accessToken);
    }
    // Refresh the backend mirror so the new phone is reflected in /users/me.
    await _apiClient.get(FlatmatesEndpoints.me);
  }

  // ---------------------------------------------------------------------------
  // Set password after signup (skipped for Google)
  // ---------------------------------------------------------------------------

  /// Sets a password on the current account after an OTP-first signup.
  Future<void> setPasswordAfterSignup(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
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
    // The session is kept after the reset (stay signed in) — sync the backend
    // user mirror the same way the login OTP verify does.
    await _apiClient.get(FlatmatesEndpoints.me);
  }

  /// Email reset channel (decision 1: OTP for both channels). Sends a 6-digit
  /// email OTP without creating an account for an unknown address.
  Future<void> sendPasswordResetEmailOtp(String email) async {
    await _supabase.auth.signInWithOtp(email: email, shouldCreateUser: false);
  }

  Future<void> verifyPasswordResetEmailOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.email,
    );
    final session = response.session ?? _supabase.auth.currentSession;
    if (session == null) {
      throw StateError(
        'Session missing after password reset OTP verification.',
      );
    }
    await _tokenStorage.save(session.accessToken);
    // The session is kept after the reset (stay signed in) — sync the backend
    // user mirror the same way the login OTP verify does.
    await _apiClient.get(FlatmatesEndpoints.me);
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('AuthRepository.signOut: Google signOut skipped: $e');
    }
    await _supabase.auth.signOut();
    await _tokenStorage.clear();
  }

  Future<void> deleteAccount() async {
    await _apiClient.delete(FlatmatesEndpoints.deleteAccount);
    // The backend hard-deletes the Supabase auth user, so the local sign-out is
    // best-effort — a failure here must not flip a successful delete into a
    // user-facing error.
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('AuthRepository.deleteAccount: supabase signOut failed: $e');
    }
    await _tokenStorage.clear();
  }

  Future<void> changePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
