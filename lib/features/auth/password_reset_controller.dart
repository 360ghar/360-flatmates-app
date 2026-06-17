import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../core/errors/app_failure.dart';
import '../../core/errors/error_presenter.dart';
import 'auth_controller.dart';
import 'data/auth_repository.dart';

enum PasswordResetStep { idle, sendingOtp, otpSent, verifying, success, error }

class PasswordResetState {
  final PasswordResetStep step;

  /// The identifier (phone or email) the reset OTP was sent to.
  final String? identifier;

  /// Whether the reset is running over the phone (SMS) or email channel.
  final AuthChannel channel;
  final AppFailure? failure;

  const PasswordResetState({
    this.step = PasswordResetStep.idle,
    this.identifier,
    this.channel = AuthChannel.phone,
    this.failure,
  });

  /// Back-compat alias used by the phone reset UI.
  String? get phone => identifier;

  PasswordResetState copyWith({
    PasswordResetStep? step,
    String? identifier,
    AuthChannel? channel,
    AppFailure? failure,
    bool clearFailure = false,
  }) => PasswordResetState(
    step: step ?? this.step,
    identifier: identifier ?? this.identifier,
    channel: channel ?? this.channel,
    failure: clearFailure ? null : (failure ?? this.failure),
  );
}

class PasswordResetController extends Notifier<PasswordResetState> {
  @override
  PasswordResetState build() => const PasswordResetState();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  void clearError() {
    if (state.step == PasswordResetStep.error) {
      state = state.copyWith(
        step: PasswordResetStep.otpSent,
        clearFailure: true,
      );
    }
  }

  /// Sends a reset OTP. Auto-detects the channel from the identifier (an `@`
  /// means email; otherwise phone) — decision 1: OTP for both channels.
  Future<void> sendOtp(String identifier) async {
    final channel = identifier.contains('@')
        ? AuthChannel.email
        : AuthChannel.phone;
    state = PasswordResetState(
      step: PasswordResetStep.sendingOtp,
      identifier: identifier,
      channel: channel,
    );
    try {
      if (channel == AuthChannel.email) {
        await _repository.sendPasswordResetEmailOtp(identifier);
      } else {
        await _repository.sendPasswordResetOtp(identifier);
      }
      state = PasswordResetState(
        step: PasswordResetStep.otpSent,
        identifier: identifier,
        channel: channel,
      );
    } catch (e, st) {
      final failure = _toFailure(e, st);
      debugPrint('PasswordResetController.sendOtp failed: ${failure.label}');
      state = PasswordResetState(
        step: PasswordResetStep.error,
        identifier: identifier,
        channel: channel,
        failure: failure,
      );
    }
  }

  Future<bool> verifyOtpAndSetPassword({
    required String otp,
    required String newPassword,
  }) async {
    final identifier = state.identifier;
    if (identifier == null) return false;

    state = state.copyWith(step: PasswordResetStep.verifying);
    try {
      if (state.channel == AuthChannel.email) {
        await _repository.verifyPasswordResetEmailOtp(
          email: identifier,
          otp: otp,
        );
      } else {
        await _repository.verifyPasswordResetOtp(phone: identifier, otp: otp);
      }
      await _repository.changePassword(newPassword);
      // The reset OTP already proved identity and created a session — keep
      // the user signed in and hand over to the authenticated redirect chain.
      await ref
          .read(authControllerProvider.notifier)
          .completePasswordReset(
            identifier: identifier,
            channel: state.channel,
          );
      state = state.copyWith(step: PasswordResetStep.success);
      return true;
    } catch (e, st) {
      final failure = _toFailure(e, st);
      debugPrint(
        'PasswordResetController.verifyOtpAndSetPassword failed: ${failure.label}',
      );
      // Clean up the temporary session if it was created
      try {
        await _repository.signOut();
      } catch (cleanupErr) {
        debugPrint(
          'PasswordResetController.verifyOtpAndSetPassword signOut cleanup failed: $cleanupErr',
        );
      }
      state = state.copyWith(step: PasswordResetStep.error, failure: failure);
      return false;
    }
  }

  AppFailure _toFailure(Object e, StackTrace st) {
    if (e is AppFailure) return e;
    if (e is DioException) return ErrorPresenter.fromDio(e, st);
    // Reset OTP send/verify goes through Supabase, which throws AuthException
    // (not DioException). Map the common cases to typed failures so the user
    // sees a meaningful message instead of the generic "Something went wrong".
    if (e is AuthException) {
      if (e.statusCode == '429' || e.code == 'too_many_requests') {
        return RateLimitFailure(underlyingError: e, stackTrace: st);
      }
      return ValidationFailure(underlyingError: e, stackTrace: st);
    }
    return UnknownFailure(underlyingError: e, stackTrace: st);
  }
}

final passwordResetControllerProvider =
    NotifierProvider<PasswordResetController, PasswordResetState>(
      PasswordResetController.new,
    );
