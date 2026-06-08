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
  }) = _AuthState;

  bool get isLoggedIn => status == AuthStatus.authenticated;
}
