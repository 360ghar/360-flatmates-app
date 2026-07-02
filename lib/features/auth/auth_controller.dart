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

  /// Whether the identifier resolved by the last [checkIdentifierStatus] call
  /// already has a password. Drives the mandatory set-password step after an
  /// OTP verify: an unknown identifier (signup) or a known-but-passwordless
  /// account must set a password before entering the app. Defaults to true so
  /// flows that bypass the state-machine never force a spurious step.
  bool _resolvedHasPassword = true;

  @override
  AuthState build() {
    _watchTokenClears();
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
            // Only treat a null token as a real logout when there is genuinely
            // no live session. A stale/async null can be buffered on this
            // broadcast stream (e.g. from an unauthenticated startup request
            // that cleared the session) and delivered AFTER a fresh login has
            // set `authenticated` — without the currentSession guard it would
            // clobber the just-authenticated state and bounce the user back to
            // login. A genuine sign-out clears the Supabase session first, so
            // currentSession is null there and the reset still proceeds.
            if (token == null &&
                state.isLoggedIn &&
                state.status != AuthStatus.submitting &&
                _repository.currentSession == null) {
              state = const AuthState(status: AuthStatus.unauthenticated);
            }
          },
          onError: (error) {
            if (state.status != AuthStatus.submitting &&
                _repository.currentSession == null) {
              state = const AuthState(status: AuthStatus.unauthenticated);
            }
          },
        );

    ref.onDispose(() {
      _tokenSubscription?.cancel();
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
        sessionAuthenticated: true,
      );
    } catch (e) {
      debugPrint('AuthController.checkSession failed: $e');
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(
        status: state.sessionAuthenticated
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        errorMessage: null,
      );
    }
  }

  /// Updates the auth gate stage from the backend's `/users/me/auth-state`.
  /// Called by [BootstrapController] after bootstrap data is fetched. The
  /// router reads [AuthState.authStage] to route profile-completion and
  /// onboarding screens.
  ///
  /// No-ops when the stage and missing fields are unchanged. Riverpod's
  /// `Notifier` notifies on every assignment regardless of value equality, so
  /// without this guard a repeated identical stage would re-emit and ripple
  /// through every auth-state listener on each bootstrap refresh.
  void updateGateStage(
    AuthStage stage, {
    List<String> missingFields = const [],
  }) {
    final next = state.copyWith(
      authStage: stage,
      missingProfileFields: missingFields,
    );
    if (next == state) return;
    state = next;
  }

  /// Returns a resolvable key for [resolveAuthError] in the presentation layer.
  ///
  /// Prefixes AppFailure labels with `failure:` so the UI can map them back
  /// to localized user messages. Maps Supabase [AuthException] (OTP errors)
  /// and [StateError] (missing session) to specific keys so the user sees a
  /// meaningful message instead of the generic "Something went wrong".
  ///
  /// Pass [authOp] to disambiguate Supabase [AuthException]s by operation:
  /// `'password'` (wrong password on sign-in) → `invalid_credentials`;
  /// otherwise (OTP verify) → `otp_invalid`.
  String _userSafeMessage(Object error, {String? authOp}) {
    if (error is AppFailure) {
      if (error is AuthExpiredFailure && error.serverMessage != null) {
        return 'failure:${error.label}|${error.serverMessage}';
      }
      if (error is ServerFailure && error.serverMessage != null) {
        return 'failure:server|${error.serverMessage}';
      }
      if (error is PermissionFailure && error.serverMessage != null) {
        return 'failure:${error.label}|${error.serverMessage}';
      }
      if (error is NotFoundFailure && error.serverMessage != null) {
        return 'failure:${error.label}|${error.serverMessage}';
      }
      if (error is ConflictFailure && error.serverMessage != null) {
        return 'failure:${error.label}|${error.serverMessage}';
      }
      if (error is RateLimitFailure && error.serverMessage != null) {
        return 'failure:${error.label}|${error.serverMessage}';
      }
      if (error is UnknownFailure && error.serverMessage != null) {
        return 'failure:${error.label}|${error.serverMessage}';
      }
      return 'failure:${error.label}';
    }
    if (error is AuthException) {
      if (error.statusCode == '429' || error.code == 'too_many_requests') {
        return 'failure:rate_limit';
      }
      // Password sign-in with bad credentials (Supabase "Invalid login
      // credentials") → tell the user the password is wrong, not that the
      // OTP/token is invalid.
      if (authOp == 'password') {
        return 'failure:invalid_credentials';
      }
      if (authOp == 'google') {
        debugPrint(
          'AuthController._userSafeMessage: $authOp auth failed: $error',
        );
        return 'failure:auth';
      }
      // OTP verify: token invalid / expired / already consumed.
      return 'failure:otp_invalid';
    }

    if (error is StateError) {
      final msg = error.message.toLowerCase();
      if (msg.contains('session missing') || msg.contains('no current user')) {
        return 'failure:auth_session_missing';
      }
      return 'failure:unknown';
    }
    if (authOp == 'google') {
      debugPrint(
        'AuthController._userSafeMessage: $authOp auth failed: $error',
      );
      return 'failure:auth';
    }
    debugPrint(
      'AuthController._userSafeMessage: unhandled ${error.runtimeType}: $error',
    );
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

  /// Starts Google sign-in through the native ID-token flow only.
  Future<bool> signInWithGoogle() async {
    clearError();
    state = state.copyWith(status: AuthStatus.submitting, errorMessage: null);
    try {
      await _repository.signInWithGoogle();
      await _completeGoogleSignIn();
      return true;
    } on GoogleSignInException catch (e) {
      // User dismissed the Google picker (the repository rethrows cancellation
      // instead of falling back) — treat as a benign cancel, no error banner.
      if (e.code == GoogleSignInExceptionCode.canceled) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: _userSafeMessage(e, authOp: 'google'),
        );
      }
      return false;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error, authOp: 'google'),
      );
      return false;
    }
  }

  /// Shared Google postlude: record `last_auth_method=google`, remember the
  /// skippable add-phone prompt for phone-less accounts, and mark authenticated.
  Future<void> _completeGoogleSignIn() async {
    await _rememberMethod(
      AuthMethod.google,
      identifier: _repository.currentEmail,
    );
    // Passwordless: prompt for a phone after the required backend gates pass.
    if (!_repository.hasPhone) {
      ref.read(addPhonePromptProvider.notifier).state = true;
    }
    state = AuthState(
      status: AuthStatus.authenticated,
      phone: _repository.currentPhone,
      sessionAuthenticated: true,
    );
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
      // Passwordless: prompt for a phone after the required backend gates pass.
      if (!_repository.hasPhone) {
        ref.read(addPhonePromptProvider.notifier).state = true;
      }
      state = AuthState(
        status: AuthStatus.authenticated,
        phone: _repository.currentPhone,
        sessionAuthenticated: true,
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
      state = AuthState(
        status: AuthStatus.authenticated,
        phone: phone,
        sessionAuthenticated: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error, authOp: 'password'),
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
        sessionAuthenticated: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error, authOp: 'password'),
        identifier: email,
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
          sessionAuthenticated: true,
        );
        return true;
      }
      await _rememberMethod(AuthMethod.phoneOtp, identifier: phone);
      state = AuthState(
        status: AuthStatus.authenticated,
        phone: phone,
        sessionAuthenticated: true,
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
          sessionAuthenticated: true,
        );
        return true;
      }
      await _rememberMethod(AuthMethod.emailOtp, identifier: email);
      state = AuthState(
        status: AuthStatus.authenticated,
        phone: _repository.currentPhone,
        sessionAuthenticated: true,
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
    state = state.copyWith(
      status: AuthStatus.submitting,
      phone: phone,
      sessionAuthenticated: true,
    );
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
    state = state.copyWith(
      status: AuthStatus.submitting,
      phone: phone,
      sessionAuthenticated: true,
    );
    try {
      await _repository.verifyAddPhoneOtp(phone: phone, otp: otp);
      ref.read(addPhonePromptProvider.notifier).state = false;
      state = AuthState(
        status: AuthStatus.authenticated,
        phone: phone,
        sessionAuthenticated: true,
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
    state = state.copyWith(
      status: AuthStatus.submitting,
      errorMessage: null,
      sessionAuthenticated: true,
    );
    try {
      await _repository.setPasswordAfterSignup(password);
      final method = channel == AuthChannel.email
          ? AuthMethod.emailPassword
          : AuthMethod.phonePassword;
      await _rememberMethod(method, identifier: identifier ?? phone);
      _resolvedHasPassword = true;
      state = AuthState(
        status: AuthStatus.authenticated,
        phone: phone,
        sessionAuthenticated: true,
      );
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

  /// Finishes a forgot-password reset while keeping the session created by
  /// the reset OTP verify: the OTP already proved identity, so the user stays
  /// signed in instead of re-entering the new password on the login screen.
  /// Records the password-based last_auth_method per channel and flips the
  /// router into the authenticated redirect chain.
  Future<void> completePasswordReset({
    required String identifier,
    required AuthChannel channel,
  }) async {
    final method = channel == AuthChannel.email
        ? AuthMethod.emailPassword
        : AuthMethod.phonePassword;
    await _rememberMethod(method, identifier: identifier);
    _resolvedHasPassword = true;
    state = AuthState(
      status: AuthStatus.authenticated,
      phone: _repository.currentPhone,
      sessionAuthenticated: true,
    );
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
