import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import 'data/auth_repository.dart';

enum PasswordResetStep { idle, sendingOtp, otpSent, verifying, success, error }

class PasswordResetState {
  final PasswordResetStep step;
  final String? phone;
  final String? errorMessage;

  const PasswordResetState({
    this.step = PasswordResetStep.idle,
    this.phone,
    this.errorMessage,
  });

  PasswordResetState copyWith({
    PasswordResetStep? step,
    String? phone,
    String? errorMessage,
  }) =>
      PasswordResetState(
        step: step ?? this.step,
        phone: phone ?? this.phone,
        errorMessage: errorMessage,
      );
}

class PasswordResetController extends Notifier<PasswordResetState> {
  @override
  PasswordResetState build() => const PasswordResetState();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  void clearError() {
    if (state.step == PasswordResetStep.error) {
      state = state.copyWith(step: PasswordResetStep.otpSent);
    }
  }

  Future<void> sendOtp(String phone) async {
    state = PasswordResetState(
      step: PasswordResetStep.sendingOtp,
      phone: phone,
    );
    try {
      await _repository.sendPasswordResetOtp(phone);
      state = PasswordResetState(
        step: PasswordResetStep.otpSent,
        phone: phone,
      );
    } catch (e) {
      debugPrint('PasswordResetController.sendOtp failed: $e');
      state = PasswordResetState(
        step: PasswordResetStep.error,
        phone: phone,
        errorMessage: e is Exception ? e.toString() : 'Something went wrong',
      );
    }
  }

  Future<bool> verifyOtpAndSetPassword({
    required String otp,
    required String newPassword,
  }) async {
    final phone = state.phone;
    if (phone == null) return false;

    state = state.copyWith(step: PasswordResetStep.verifying);
    try {
      await _repository.verifyPasswordResetOtp(phone: phone, otp: otp);
      await _repository.changePassword(newPassword);
      // Sign out the temporary session created by OTP verification
      await _repository.signOut();
      state = state.copyWith(step: PasswordResetStep.success);
      return true;
    } catch (e) {
      debugPrint('PasswordResetController.verifyOtpAndSetPassword failed: $e');
      // Clean up the temporary session if it was created
      try {
        await _repository.signOut();
      } catch (_) {}
      state = state.copyWith(
        step: PasswordResetStep.error,
        errorMessage: e is Exception ? e.toString() : 'Something went wrong',
      );
      return false;
    }
  }
}

final passwordResetControllerProvider =
    NotifierProvider<PasswordResetController, PasswordResetState>(
  PasswordResetController.new,
);
