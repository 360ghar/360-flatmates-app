import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart'
    show GoogleSignInException, GoogleSignInExceptionCode;
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../core/errors/app_failure.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/providers.dart';
import 'data/auth_repository.dart';
import 'domain/auth_state.dart';
import 'last_auth_method.dart';

export 'domain/auth_state.dart';

final pendingPhoneProvider = StateProvider<String?>((ref) => null);

/// One-shot signal that a freshly signed-in Google account has no phone yet,
/// so the router should route into the skippable `/add-phone` step. Cleared
/// when the user adds a phone or skips.
final addPhonePromptProvider = StateProvider<bool>((ref) => false);

class AuthController extends Notifier<AuthState> {
  StreamSubscription<String?>? _tokenSubscription;
  StreamSubscription<bool>? _signedInSubscription;

  /// Whether the identifier resolved by the last [checkIdentifierStatus] call
  /// already has a password. Drives the mandatory set-password step after an
  /// OTP verify: an unknown identifier (signup) or a known-but-passwordless
  /// account must set a password before entering the app. Defaults to true so
  /// flows that bypass the state-machine never force a spurious step.
  bool _resolvedHasPassword = true;

  /// True while waiting for the Google OAuth redirect callback to deliver a
  /// session (redirect flow only; native flow completes synchronously).
  bool _pendingGoogleRedirect = false;

  @override
  AuthState build() {
    _watchTokenClears();
    _watchSignedIn();
    Future<void>.microtask(checkSession);
    return const AuthState(status: AuthStatus.checking);
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);
  LastAuthMethodStore get _lastMethod => ref.read(lastAuthMethodStoreProvider);

  void _watchTokenClears() {
    _tokenSubscription = ref
        .read(authTokenStorageProvider)
        .changes
        .listen(
          (token) {
            if (token == null &&
                state.isLoggedIn &&
                state.status != AuthStatus.submitting) {
              state = const AuthState(status: AuthStatus.unauthenticated);
            }
          },
          onError: (error) {
            if (state.status != AuthStatus.submitting) {
              state = const AuthState(status: AuthStatus.unauthenticated);
            }
          },
        );

    ref.onDispose(() {
      _tokenSubscription?.cancel();
    });
  }

  /// Listens for Supabase sign-in events so the Google OAuth **redirect**
  /// callback (auto-exchanged by supabase_flutter via the deep link) finishes
  /// the postlude even though it arrives outside the [signInWithGoogle] call.
  void _watchSignedIn() {
    _signedInSubscription = _repository.onSignedIn.listen((_) {
      if (_pendingGoogleRedirect) {
        unawaited(_onSupabaseSignedIn());
      }
    });
    ref.onDispose(() {
      _signedInSubscription?.cancel();
    });
  }

  Future<void> checkSession() async {
    try {
      final session = _repository.currentSession;
      if (session == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      state = AuthState(
        status: AuthStatus.authenticated,
        phone: _repository.currentPhone,
      );
    } catch (e) {
      debugPrint('AuthController.checkSession failed: $e');
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: null,
      );
    }
  }

  /// Returns a resolvable key for [resolveAuthError] in the presentation layer.
  ///
  /// Prefixes AppFailure labels with `failure:` so the UI can map them back
  /// to localized user messages. Maps Supabase [AuthException] (OTP errors)
  /// and [StateError] (missing session) to specific keys so the user sees a
  /// meaningful message instead of the generic "Something went wrong".
  String _userSafeMessage(Object error) {
    if (error is AppFailure) {
      if (error is AuthExpiredFailure && error.serverMessage != null) return 'failure:${error.label}|${error.serverMessage}';
      if (error is ServerFailure && error.serverMessage != null) return 'failure:server|${error.serverMessage}';
      if (error is PermissionFailure && error.serverMessage != null) return 'failure:${error.label}|${error.serverMessage}';
      if (error is NotFoundFailure && error.serverMessage != null) return 'failure:${error.label}|${error.serverMessage}';
      if (error is ConflictFailure && error.serverMessage != null) return 'failure:${error.label}|${error.serverMessage}';
      if (error is RateLimitFailure && error.serverMessage != null) return 'failure:${error.label}|${error.serverMessage}';
      if (error is UnknownFailure && error.serverMessage != null) return 'failure:${error.label}|${error.serverMessage}';
      return 'failure:${error.label}';
    }
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      // Supabase OTP errors: expired, invalid, already used, rate limited.
      if (msg.contains('rate') || msg.contains('limit') || msg.contains('seconds') || msg.contains('security purposes')) {
        return 'failure:rate_limit';
      }
      // Token invalid / expired / already consumed → treat as invalid OTP.
      return 'failure:otp_invalid';
    }
    if (error is StateError) {
      // Typically "Session missing after OTP verification."
      return 'failure:auth_session_missing';
    }
    debugPrint('AuthController._userSafeMessage: unhandled ${error.runtimeType}: $error');
    return 'failure:unknown';
  }

  /// Records the last-used method locally and mirrors it to the backend.
  Future<void> _rememberMethod(AuthMethod method, {String? identifier}) async {
    await _lastMethod.write(method, identifier: identifier);
    await _repository.recordLastMethod(method);
  }

  // ---------------------------------------------------------------------------
  // State-machine: identifier → status
  // ---------------------------------------------------------------------------

  /// Resolves the identifier against `POST /auth/identifier-status`. Sets the
  /// resolved [AuthChannel] / verified flag on the state and returns the
  /// status so the UI can branch to login / otp / signup. Returns null on
  /// failure (state is set to error).
  Future<IdentifierStatus?> checkIdentifierStatus(String identifier) async {
    clearError();
    state = state.copyWith(
      status: AuthStatus.submitting,
      identifier: identifier,
      errorMessage: null,
    );
    try {
      final status = await _repository.checkIdentifierStatus(identifier);
      // Unknown identifier (signup) has no password; a known account reports
      // its own has_password. Remembered so the post-OTP step can be forced.
      _resolvedHasPassword = status.exists && status.hasPassword;
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        identifier: identifier,
        channel: status.channel,
        identifierVerified: status.verified,
        phone: status.channel == AuthChannel.phone ? identifier : state.phone,
      );
      return status;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
        identifier: identifier,
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Google
  // ---------------------------------------------------------------------------

  /// Starts Google sign-in. Native ID-token flow completes synchronously;
  /// the OAuth **redirect** flow returns here after launching the browser and
  /// is finished by [_completeGoogleSignIn] when the deep-link callback's
  /// session arrives (see the auth-state-change listener).
  Future<bool> signInWithGoogle() async {
    clearError();
    state = state.copyWith(status: AuthStatus.submitting, errorMessage: null);
    try {
      final completed = await _repository.signInWithGoogle();
      if (!completed) {
        // Redirect flow launched — wait for the deep-link callback to deliver
        // a session, which the onAuthStateChange listener finishes. Keep the
        // submitting state so the UI shows progress.
        _pendingGoogleRedirect = true;
        return true;
      }
      await _completeGoogleSignIn();
      return true;
    } on GoogleSignInException catch (e) {
      // User dismissed the Google picker (the repository rethrows cancellation
      // instead of falling back) — treat as a benign cancel, no error banner.
      _pendingGoogleRedirect = false;
      if (e.code == GoogleSignInExceptionCode.canceled) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: _userSafeMessage(e),
        );
      }
      return false;
    } catch (error) {
      _pendingGoogleRedirect = false;
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
      );
      return false;
    }
  }

  /// Shared Google postlude: record `last_auth_method=google`, gate the
  /// skippable add-phone step for phone-less accounts, and mark authenticated.
  Future<void> _completeGoogleSignIn() async {
    await _rememberMethod(
      AuthMethod.google,
      identifier: _repository.currentEmail,
    );
    // Passwordless: prompt for a phone if the account doesn't have one yet.
    if (!_repository.hasPhone) {
      ref.read(addPhonePromptProvider.notifier).state = true;
    }
    state = AuthState(
      status: AuthStatus.authenticated,
      phone: _repository.currentPhone,
    );
  }

  /// Handles the session delivered by the Google OAuth **redirect** callback.
  /// supabase_flutter auto-exchanges the `?code=` from the callback deep link
  /// and emits a `signedIn` event; this finishes the postlude exactly once.
  Future<void> _onSupabaseSignedIn() async {
    if (!_pendingGoogleRedirect) return;
    _pendingGoogleRedirect = false;
    try {
      await _repository.completeOAuthSession();
      await _completeGoogleSignIn();
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Apple (iOS)
  // ---------------------------------------------------------------------------

  Future<bool> signInWithApple() async {
    clearError();
    state = state.copyWith(status: AuthStatus.submitting, errorMessage: null);
    try {
      await _repository.signInWithApple();
      await _rememberMethod(
        AuthMethod.apple,
        identifier: _repository.currentEmail,
      );
      // Passwordless: prompt for a phone if the account doesn't have one yet.
      if (!_repository.hasPhone) {
        ref.read(addPhonePromptProvider.notifier).state = true;
      }
      state = AuthState(
        status: AuthStatus.authenticated,
        phone: _repository.currentPhone,
      );
      return true;
    } on AppleSignInCancelled {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: null,
      );
      return false;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Phone OTP + password
  // ---------------------------------------------------------------------------

  /// Sends an SMS OTP. [shouldCreateUser] is `false` for the login/resend
  /// path (default) so a mistyped number isn't silently registered; signup
  /// passes `true`.
  Future<void> requestOtp(String phone, {bool shouldCreateUser = false}) async {
    clearError();
    state = state.copyWith(status: AuthStatus.submitting, phone: phone);
    try {
      await _repository.requestOtp(phone, shouldCreateUser: shouldCreateUser);
      state = state.copyWith(
        status: AuthStatus.otpSent,
        phone: phone,
        channel: AuthChannel.phone,
        identifier: phone,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
        phone: phone,
      );
    }
  }

  Future<bool> signInWithPassword({
    required String phone,
    required String password,
  }) async {
    clearError();
    state = state.copyWith(status: AuthStatus.submitting, phone: phone);
    try {
      await _repository.signInWithPassword(phone: phone, password: password);
      await _rememberMethod(AuthMethod.phonePassword, identifier: phone);
      state = AuthState(status: AuthStatus.authenticated, phone: phone);
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
        phone: phone,
      );
      return false;
    }
  }

  /// Password login for the **email** channel (verified email with a password;
  /// `next_step == password`). Records `last_auth_method = email_password`.
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    clearError();
    state = state.copyWith(
      status: AuthStatus.submitting,
      identifier: email,
      channel: AuthChannel.email,
    );
    try {
      await _repository.signInWithEmailPassword(
        email: email,
        password: password,
      );
      await _rememberMethod(AuthMethod.emailPassword, identifier: email);
      state = AuthState(
        status: AuthStatus.authenticated,
        phone: _repository.currentPhone,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
        identifier: email,
      );
      return false;
    }
  }

  Future<bool> signUpWithPassword({
    required String fullName,
    required String phone,
    required String password,
    String? email,
  }) async {
    clearError();
    state = state.copyWith(status: AuthStatus.submitting, phone: phone);
    try {
      await _repository.signUpWithPassword(
        fullName: fullName,
        phone: phone,
        password: password,
        email: email,
      );
      await _rememberMethod(AuthMethod.phonePassword, identifier: phone);
      state = AuthState(status: AuthStatus.authenticated, phone: phone);
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
        phone: phone,
      );
      return false;
    }
  }

  Future<bool> verifyOtp({required String phone, required String otp}) async {
    clearError();
    state = state.copyWith(status: AuthStatus.submitting, phone: phone);
    try {
      await _repository.verifyOtp(phone: phone, otp: otp);
      if (!_resolvedHasPassword) {
        // Requirement 6: passwordless OTP account must set a password before
        // entering the app. Defer last_auth_method until the password is set.
        state = AuthState(
          status: AuthStatus.authenticated,
          phone: phone,
          channel: AuthChannel.phone,
          identifier: phone,
          needsPassword: true,
        );
        return true;
      }
      await _rememberMethod(AuthMethod.phoneOtp, identifier: phone);
      state = AuthState(status: AuthStatus.authenticated, phone: phone);
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
        phone: phone,
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Email OTP
  // ---------------------------------------------------------------------------

  /// Sends a 6-digit email OTP. [isSignup] controls whether the user may be
  /// created (unknown identifier) or must already exist (re-verification).
  Future<bool> sendEmailOtp(String email, {bool isSignup = true}) async {
    clearError();
    state = state.copyWith(
      status: AuthStatus.submitting,
      identifier: email,
      channel: AuthChannel.email,
    );
    try {
      await _repository.sendEmailOtp(email, shouldCreateUser: isSignup);
      state = state.copyWith(
        status: AuthStatus.otpSent,
        identifier: email,
        channel: AuthChannel.email,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
        identifier: email,
      );
      return false;
    }
  }

  Future<bool> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    clearError();
    state = state.copyWith(
      status: AuthStatus.submitting,
      identifier: email,
      channel: AuthChannel.email,
    );
    try {
      await _repository.verifyEmailOtp(email: email, otp: otp);
      if (!_resolvedHasPassword) {
        // Requirement 6: passwordless OTP account must set a password before
        // entering the app. Defer last_auth_method until the password is set.
        state = AuthState(
          status: AuthStatus.authenticated,
          phone: _repository.currentPhone,
          channel: AuthChannel.email,
          identifier: email,
          needsPassword: true,
        );
        return true;
      }
      await _rememberMethod(AuthMethod.emailOtp, identifier: email);
      state = AuthState(
        status: AuthStatus.authenticated,
        phone: _repository.currentPhone,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
        identifier: email,
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Post-Google add-phone
  // ---------------------------------------------------------------------------

  /// Requests an SMS OTP for a phone being added to the current account.
  Future<bool> requestAddPhoneOtp(String phone) async {
    clearError();
    state = state.copyWith(status: AuthStatus.submitting, phone: phone);
    try {
      await _repository.sendAddPhoneOtp(phone);
      state = state.copyWith(
        status: AuthStatus.otpSent,
        phone: phone,
        channel: AuthChannel.phone,
        identifier: phone,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
        phone: phone,
      );
      return false;
    }
  }

  /// Verifies the add-phone OTP and links the phone to the current account.
  Future<bool> addAndVerifyPhone({
    required String phone,
    required String otp,
  }) async {
    clearError();
    state = state.copyWith(status: AuthStatus.submitting, phone: phone);
    try {
      await _repository.verifyAddPhoneOtp(phone: phone, otp: otp);
      ref.read(addPhonePromptProvider.notifier).state = false;
      state = AuthState(status: AuthStatus.authenticated, phone: phone);
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
        phone: phone,
      );
      return false;
    }
  }

  /// Skips the post-Google add-phone step; keeps `last_auth_method = google`.
  void skipAddPhone() {
    ref.read(addPhonePromptProvider.notifier).state = false;
  }

  // ---------------------------------------------------------------------------
  // Set password after OTP (mandatory; skipped only for Google/Apple)
  // ---------------------------------------------------------------------------

  /// Sets a password on the current account, satisfying the mandatory
  /// post-OTP set-password step (requirement 6). Records the password-based
  /// last_auth_method per channel and clears [AuthState.needsPassword].
  Future<bool> setPasswordAfterSignup(String password) async {
    clearError();
    final channel = state.channel;
    final identifier = state.identifier;
    final phone = state.phone;
    state = state.copyWith(status: AuthStatus.submitting, errorMessage: null);
    try {
      await _repository.setPasswordAfterSignup(password);
      final method = channel == AuthChannel.email
          ? AuthMethod.emailPassword
          : AuthMethod.phonePassword;
      await _rememberMethod(method, identifier: identifier ?? phone);
      _resolvedHasPassword = true;
      state = AuthState(status: AuthStatus.authenticated, phone: phone);
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
        // Preserve the gate so the user can retry the mandatory step.
        needsPassword: true,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await ref.read(notificationServiceProvider).clearToken();
    } catch (e) {
      debugPrint('AuthController.signOut: clearToken failed: $e');
    }
    try {
      await _repository.signOut();
    } catch (e) {
      debugPrint('AuthController.signOut: repository.signOut failed: $e');
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> deleteAccount() async {
    try {
      await ref.read(notificationServiceProvider).clearToken();
    } catch (e) {
      debugPrint('AuthController.deleteAccount: clearToken failed: $e');
    }
    try {
      await _repository.deleteAccount();
      state = const AuthState(status: AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      debugPrint('AuthController.deleteAccount: failed: $e');
      return false;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(authTokenStorageProvider),
    config: ref.watch(appConfigProvider),
  ),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
