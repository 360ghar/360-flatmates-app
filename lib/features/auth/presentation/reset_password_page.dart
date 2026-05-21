import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flatmates_app/core/theme/app_radius.dart';
import 'package:flatmates_app/core/theme/app_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../auth_controller.dart';
import '../password_reset_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage>
    with CodeAutoFill {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  final _keyboardFocusNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _currentOtp = '';
  bool _isListening = false;

  String get _phone =>
      ref.read(pendingPhoneProvider) ?? '';

  static const _resendCooldownSeconds = 60;
  int _countdownSeconds = _resendCooldownSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startListeningForSms();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    SmsAutoFill().unregisterListener();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    for (final f in _keyboardFocusNodes) {
      f.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      _fillOtp(code!);
    }
  }

  Future<void> _startListeningForSms() async {
    try {
      await SmsAutoFill().listenForCode();
      if (mounted) {
        setState(() => _isListening = true);
      }
    } catch (e) {
      debugPrint(
          'ResetPasswordPage._startListeningForSms: SMS auto-fill unavailable: $e');
    }
  }

  void _startCountdown() {
    _countdownSeconds = _resendCooldownSeconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds <= 1) {
        setState(() => _countdownSeconds = 0);
        timer.cancel();
      } else {
        setState(() => _countdownSeconds--);
      }
    });
  }

  void _fillOtp(String otp) {
    _currentOtp = otp;
    for (var i = 0; i < 6; i++) {
      if (i < otp.length) {
        _otpControllers[i].text = otp[i];
      } else {
        _otpControllers[i].clear();
      }
    }
    if (otp.length == 6) {
      _focusNodes[5].unfocus();
    } else if (otp.length < 6) {
      _focusNodes[otp.length].requestFocus();
    }
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.length > 1) {
      final lastChar = value.substring(value.length - 1);
      _otpControllers[index].text = lastChar;
      value = lastChar;
    }
    final buffer = StringBuffer();
    for (var i = 0; i < 6; i++) {
      buffer.write(_otpControllers[i].text);
    }
    _currentOtp = buffer.toString();
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _onOtpDigitDeleted(int index) {
    if (_otpControllers[index].text.isEmpty && index > 0) {
      _otpControllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
    final buffer = StringBuffer();
    for (var i = 0; i < 6; i++) {
      buffer.write(_otpControllers[i].text);
    }
    _currentOtp = buffer.toString();
  }

  Future<void> _resendOtp() async {
    if (_countdownSeconds > 0) return;
    await ref.read(passwordResetControllerProvider.notifier).sendOtp(_phone);
    if (mounted) {
      final state = ref.read(passwordResetControllerProvider);
      if (state.step == PasswordResetStep.otpSent) {
        _startCountdown();
      }
    }
  }

  Future<void> _submit() async {
    if (_currentOtp.length != 6) return;
    if (_passwordController.text != _confirmPasswordController.text) return;
    if (_passwordController.text.length < 8) return;

    final success = await ref
        .read(passwordResetControllerProvider.notifier)
        .verifyOtpAndSetPassword(
          otp: _currentOtp,
          newPassword: _passwordController.text,
        );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).passwordResetSuccess)),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final resetState = ref.watch(passwordResetControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isVerifying = resetState.step == PasswordResetStep.verifying;

    return FlatmatesScreen(
      appBar: AppBar(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(locale.resetPasswordTitle,
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(locale.resetPasswordSubtitle(_phone),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              )),
          if (_isListening) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              locale.otpAutoReadHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.screen),

          // OTP digit row
          LayoutBuilder(
            builder: (context, constraints) {
              const digitCount = 6;
              const gapCount = digitCount - 1;
              const gap = AppSpacing.sm;
              const maxBoxWidth = AppSpacing.screen + AppSpacing.section;
              final boxWidth =
                  ((constraints.maxWidth - gap * gapCount) / digitCount)
                      .clamp(0, maxBoxWidth)
                      .toDouble();
              final fontSize = boxWidth >= AppSpacing.screen + AppSpacing.xl
                  ? AppTypography.h2Size
                  : AppTypography.h3SizeLarge;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(digitCount, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < gapCount ? gap : 0,
                    ),
                    child: SizedBox(
                      width: boxWidth,
                      height: boxWidth + AppSpacing.sm,
                      child: KeyboardListener(
                        focusNode: _keyboardFocusNodes[index],
                        onKeyEvent: (event) {
                          if (event.logicalKey.keyLabel == 'Backspace' ||
                              event.logicalKey.keyLabel == 'Delete') {
                            _onOtpDigitDeleted(index);
                          }
                        },
                        child: TextField(
                          key: Key('reset_otp_digit_$index'),
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: fontSize,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.mdBorder,
                              borderSide: BorderSide(
                                color: AppSemanticColors.line,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppRadius.mdBorder,
                              borderSide: BorderSide(
                                color: AppSemanticColors.accent,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: AppRadius.mdBorder,
                              borderSide: BorderSide(
                                color: AppSemanticColors.error,
                              ),
                            ),
                          ),
                          onChanged: (value) =>
                              _onOtpDigitChanged(index, value),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: AppSpacing.screen),

          // New password field
          FlatmatesCard(
            child: Column(
              children: [
                TextField(
                  key: const Key('reset_new_password_input'),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: locale.newPasswordLabel,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  key: const Key('reset_confirm_password_input'),
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: locale.confirmPasswordLabel,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                if (_passwordController.text.isNotEmpty &&
                    _confirmPasswordController.text.isNotEmpty &&
                    _passwordController.text != _confirmPasswordController.text) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    locale.passwordsDoNotMatch,
                    style: TextStyle(color: AppSemanticColors.error),
                  ),
                ],
                if (resetState.step == PasswordResetStep.error &&
                    resetState.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    resetState.errorMessage!,
                    style: TextStyle(color: AppSemanticColors.error),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.screen),

          // Resend OTP
          Center(
            child: _countdownSeconds > 0
                ? Text(
                    locale.resendOtpCountdown(_countdownSeconds),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                          theme.brightness),
                    ),
                  )
                : FlatmatesButton.tertiary(
                    label: locale.resendOtpCta,
                    onPressed: isVerifying ? null : _resendOtp,
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Reset password CTA
          FlatmatesButton(
            key: const Key('reset_password_submit'),
            label: locale.updatePasswordCta,
            fullWidth: true,
            onPressed: isVerifying ? null : _submit,
          ),
        ],
      ),
    );
  }
}
