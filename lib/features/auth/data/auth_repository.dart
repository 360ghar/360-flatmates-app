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

  SupabaseClient get _supabase => Supabase.instance.client;

  Session? get currentSession => _supabase.auth.currentSession;
  String? get currentPhone => currentSession?.user.phone;
  String? get currentEmail => currentSession?.user.email;

  /// Emits whenever Supabase signs a user in (`signedIn` / `tokenRefreshed`
  /// with a session). Used to detect the session that arrives asynchronously
  /// from the Google OAuth redirect callback, which supabase_flutter
  /// auto-exchanges. Kept as a plain bool stream to avoid leaking the gotrue
  /// `AuthState` type (which collides with the app's domain `AuthState`).
  Stream<bool> get onSignedIn => _supabase.auth.onAuthStateChange
      .where(
        (state) =>
            state.session != null &&
            (state.event == AuthChangeEvent.signedIn ||
                state.event == AuthChangeEvent.tokenRefreshed),
      )
      .map((_) => true);

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
  // Google sign-in (native ID-token when configured, else OAuth redirect)
  // ---------------------------------------------------------------------------

  /// Deep link the Google OAuth redirect returns to. Must be in Supabase's
  /// Redirect URL allowlist and registered as an OS URL scheme.
  ///
  /// Override via the `AUTH_REDIRECT_URL` env var when running in a non-standard
  /// environment (e.g. a custom deep link scheme for testing).
  static const googleRedirectUrl = String.fromEnvironment(
    'AUTH_REDIRECT_URL',
    defaultValue: 'com.the360ghar.flatmates360://login-callback',
  );

  /// Whether native Google sign-in (ID-token flow) is available. When false,
  /// [signInWithGoogle] falls back to the OAuth redirect flow using the
  /// already-enabled Supabase Google provider.
  bool get isNativeGoogleAvailable =>
      _config.googleWebClientId.trim().isNotEmpty;

  /// Starts Google sign-in.
  ///
  /// Returns `true` when the native ID-token flow completed synchronously
  /// (token persisted + `/users/me` validated). Returns `false` when the OAuth
  /// **redirect** flow was launched instead — the session then arrives
  /// asynchronously via the deep-link callback (supabase_flutter
  /// auto-exchanges the `?code=`) and the caller finishes via
  /// [completeOAuthSession].
  ///
  /// Resilient native→redirect fallback: when a Web client id is configured we
  /// attempt the native flow, but native OAuth clients + SHA fingerprints may
  /// not be provisioned yet (the native call then throws). On any **non
  /// user-cancellation** error we automatically fall back to the redirect flow
  /// so Google sign-in works today and silently upgrades to native once the
  /// clients are provisioned. A genuine user cancellation is **not** swallowed
  /// — it rethrows so the UI can treat it as a cancel, not an error.
  Future<bool> signInWithGoogle() async {
    if (!isNativeGoogleAvailable) {
      await _launchGoogleRedirect();
      return false;
    }
    try {
      await _signInWithGoogleNative();
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        rethrow; // User dismissed the picker — do not fall back.
      }
      debugPrint(
        'AuthRepository.signInWithGoogle: native failed (${e.code}); '
        'falling back to OAuth redirect.',
      );
      await _launchGoogleRedirect();
      return false;
    } catch (e) {
      // Misconfiguration (missing SHA / unprovisioned client / plugin error) —
      // fall back to the redirect flow rather than failing the sign-in.
      debugPrint(
        'AuthRepository.signInWithGoogle: native error ($e); '
        'falling back to OAuth redirect.',
      );
      await _launchGoogleRedirect();
      return false;
    }
  }

  /// Launches the Google OAuth redirect flow in an external browser.
  Future<void> _launchGoogleRedirect() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: googleRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  /// Completes the postlude after the OAuth redirect produced a session
  /// (supabase_flutter auto-exchanges the `?code=` from the callback URI).
  /// Mirrors the native postlude: persist the access token + validate `/me`.
  Future<void> completeOAuthSession() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw StateError('Session missing after OAuth redirect.');
    }
    await _tokenStorage.save(session.accessToken);
    await _apiClient.get(FlatmatesEndpoints.me);
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

    final signIn = GoogleSignIn.instance;
    await signIn.initialize(
      // serverClientId is the Web client id; Supabase validates the audience
      // against it. clientId is the iOS client id (ignored on Android).
      serverClientId: webClientId,
      clientId: (Platform.isIOS && iosClientId.trim().isNotEmpty)
          ? iosClientId
          : null,
    );

    if (!signIn.supportsAuthenticate()) {
      throw StateError('Google sign-in is not supported on this platform.');
    }

    final account = await signIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google did not return an ID token.');
    }

    // Best-effort silent access-token retrieval; not required for the
    // ID-token flow but improves Supabase provider-token availability.
    String? accessToken;
    try {
      final authorization = await account.authorizationClient
          .authorizationForScopes(const ['email', 'profile']);
      accessToken = authorization?.accessToken;
    } catch (e) {
      debugPrint('AuthRepository.signInWithGoogle: scope auth skipped: $e');
    }

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
      emailRedirectTo: googleRedirectUrl,
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
    await _supabase.auth.signOut();
    await _tokenStorage.clear();
  }

  Future<void> changePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
