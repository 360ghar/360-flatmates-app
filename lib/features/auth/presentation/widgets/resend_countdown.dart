import 'dart:async';

import 'package:flutter/widgets.dart';

/// Shared 30-second resend-OTP countdown used by every OTP step
/// (phone OTP, email OTP, add-phone). Mix into a [State] and call
/// [startResendCountdown] right after an OTP is sent. While
/// [canResend] is false, the UI shows [resendSecondsRemaining] and keeps
/// the Resend control disabled; it enables once the countdown hits 0.
mixin ResendCountdownMixin<T extends StatefulWidget> on State<T> {
  /// Standard resend cooldown applied across all OTP modes.
  static const resendCooldownSeconds = 30;

  Timer? _resendTimer;
  int _resendSecondsRemaining = resendCooldownSeconds;

  /// Seconds left before the user may resend; 0 once the cooldown elapses.
  int get resendSecondsRemaining => _resendSecondsRemaining;

  /// Whether the Resend control should be enabled.
  bool get canResend => _resendSecondsRemaining <= 0;

  /// (Re)starts the 30s countdown. Call after each successful OTP send.
  void startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsRemaining = resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsRemaining <= 1) {
        setState(() => _resendSecondsRemaining = 0);
        timer.cancel();
      } else {
        setState(() => _resendSecondsRemaining--);
      }
    });
  }

  /// Cancels the countdown. Safe to call from `dispose`.
  void cancelResendCountdown() {
    _resendTimer?.cancel();
    _resendTimer = null;
  }
}
