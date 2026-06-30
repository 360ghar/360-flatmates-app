import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

enum AuthStatus {
  checking,
  unauthenticated,
  authenticated,
  submitting,
  otpSent,
  error,
}

/// The channel an identifier resolves to in the auth state-machine.
enum AuthChannel { phone, email }

/// The centralized auth gate stage returned by the backend
/// `GET /users/me/auth-state`.  Clients route the user to the screen
/// corresponding to the first incomplete gate.
enum AuthStage {
  unknown,
  identifierVerification,
  passwordSetup,
  profileCompletion,
  appOnboarding,
  active;

  /// Parse from the backend wire value.
  static AuthStage fromWire(String? value) {
    switch (value) {
      case 'identifier_verification':
        return AuthStage.identifierVerification;
      case 'password_setup':
        return AuthStage.passwordSetup;
      case 'profile_completion':
        return AuthStage.profileCompletion;
      case 'app_onboarding':
        return AuthStage.appOnboarding;
      case 'active':
        return AuthStage.active;
      default:
        return AuthStage.unknown;
    }
  }
}

/// The auth method last used by the user, mirrored to the backend via
/// `POST /api/v1/auth/last-method` and remembered locally to pre-select it.
enum AuthMethod {
  google,
  apple,
  emailPassword,
  phonePassword,
  phoneOtp,
  emailOtp,
}

extension AuthMethodWire on AuthMethod {
  /// Backend wire value for `POST /api/v1/auth/last-method`.
  String get wireValue {
    switch (this) {
      case AuthMethod.google:
        return 'google';
      case AuthMethod.apple:
        return 'apple';
      case AuthMethod.emailPassword:
        return 'email_password';
      case AuthMethod.phonePassword:
        return 'phone_password';
      case AuthMethod.phoneOtp:
        return 'phone_otp';
      case AuthMethod.emailOtp:
        return 'email_otp';
    }
  }

  static AuthMethod? fromWire(String? value) {
    switch (value) {
      case 'google':
        return AuthMethod.google;
      case 'apple':
        return AuthMethod.apple;
      case 'email_password':
        return AuthMethod.emailPassword;
      case 'phone_password':
        return AuthMethod.phonePassword;
      case 'phone_otp':
        return AuthMethod.phoneOtp;
      case 'email_otp':
        return AuthMethod.emailOtp;
      default:
        return null;
    }
  }
}

@Freezed()
class AuthState with _$AuthState {
  const AuthState._();

  const factory AuthState({
    required AuthStatus status,
    String? phone,
    String? errorMessage,

    /// The raw identifier (phone or email) the user is currently working with.
    String? identifier,

    /// Whether the resolved identifier is already verified (drives the
    /// password-vs-OTP branch in the login state-machine).
    bool? identifierVerified,

    /// Whether the resolved identifier maps to a phone or email channel.
    AuthChannel? channel,

    /// Set after a successful email/phone OTP verify when the account has no
    /// password yet. While true, the router forces the mandatory
    /// (non-skippable) `/set-password` step before entering the app. Cleared
    /// once a password is set. Never set for Google/Apple (passwordless).
    @Default(false) bool needsPassword,

    /// The current auth gate stage returned by the backend
    /// `/users/me/auth-state`.  Drives the redirect chain for profile
    /// completion and onboarding. Defaults to [AuthStage.unknown] so protected
    /// routes fail closed until the first successful fetch completes.
    @Default(AuthStage.unknown) AuthStage authStage,

    /// True when the Supabase/API session is authenticated even if the UI is
    /// currently performing a submit step such as add-phone or set-password.
    @Default(false) bool sessionAuthenticated,

    /// Profile fields still missing (reported by the backend when
    /// `authStage == AuthStage.profileCompletion`).
    @Default([]) List<String> missingProfileFields,
  }) = _AuthState;

  bool get isLoggedIn =>
      sessionAuthenticated || status == AuthStatus.authenticated;
}
