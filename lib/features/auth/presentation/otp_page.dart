import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../auth_controller.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({required this.phone, super.key});

  final String phone;

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> with CodeAutoFill {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  final _keyboardFocusNodes = List.generate(6, (_) => FocusNode());
  String _currentOtp = '';
  bool _isListening = false;

  String get _phone => widget.phone.isNotEmpty
      ? widget.phone
      : (ref.read(pendingPhoneProvider) ?? '');

  // Resend countdown
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
    } catch (_) {
      // SMS auto-fill not available on this platform (e.g. iOS simulator).
      // The user will enter the OTP manually.
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
        setState(() {
          _countdownSeconds--;
        });
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
    // Move focus to the last filled field or unfocus if complete.
    if (otp.length == 6) {
      _focusNodes[5].unfocus();
      _submitOtp();
    } else if (otp.length < 6) {
      _focusNodes[otp.length].requestFocus();
    }
  }

  void _onOtpDigitChanged(int index, String value) {
    // If a digit was entered and it's more than one char, take only the last.
    if (value.length > 1) {
      final lastChar = value.substring(value.length - 1);
      _otpControllers[index].text = lastChar;
      value = lastChar;
    }

    // Build the full OTP string.
    final buffer = StringBuffer();
    for (var i = 0; i < 6; i++) {
      buffer.write(_otpControllers[i].text);
    }
    _currentOtp = buffer.toString();

    // Auto-advance focus.
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-submit when all 6 digits are filled.
    if (_currentOtp.length == 6) {
      _focusNodes[5].unfocus();
      _submitOtp();
    }
  }

  void _onOtpDigitDeleted(int index) {
    if (_otpControllers[index].text.isEmpty && index > 0) {
      _otpControllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
    // Rebuild current otp.
    final buffer = StringBuffer();
    for (var i = 0; i < 6; i++) {
      buffer.write(_otpControllers[i].text);
    }
    _currentOtp = buffer.toString();
  }

  void _submitOtp() {
    if (_currentOtp.length != 6) return;
    final auth = ref.read(authControllerProvider);
    if (auth.status == AuthStatus.submitting) return;
    ref
        .read(authControllerProvider.notifier)
        .verifyOtp(phone: _phone, otp: _currentOtp);
  }

  Future<void> _resendOtp() async {
    if (_countdownSeconds > 0) return;
    final notifier = ref.read(authControllerProvider.notifier);
    await notifier.requestOtp(_phone);
    if (mounted) {
      final auth = ref.read(authControllerProvider);
      if (auth.status != AuthStatus.error) {
        _startCountdown();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isSuccess = auth.status == AuthStatus.authenticated;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        minimum: AppSpacing.horizontalScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.otpTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(locale.otpSubtitle(_phone)),
            if (_isListening) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                locale.otpAutoReadHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                ),
              ),
            ],
            if (isSuccess) ...[
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: FlatmatesTrustBadge(
                  label: locale.phoneVerifiedLabel,
                  variant: FlatmatesTrustBadgeVariant.verified,
                  compact: true,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.screen),
            // 6-digit OTP input — larger centered boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < 5 ? AppSpacing.sm : 0,
                  ),
                  child: SizedBox(
                    width: 52,
                    height: 60,
                    child: KeyboardListener(
                      focusNode: _keyboardFocusNodes[index],
                      onKeyEvent: (event) {
                        if (event.logicalKey.keyLabel == 'Backspace' ||
                            event.logicalKey.keyLabel == 'Delete') {
                          _onOtpDigitDeleted(index);
                        }
                      },
                      child: TextField(
                        key: Key('otp_digit_$index'),
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
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
                        onChanged: (value) => _onOtpDigitChanged(index, value),
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (auth.status == AuthStatus.error &&
                auth.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                auth.errorMessage!,
                style: TextStyle(color: AppSemanticColors.error),
              ),
            ],
            const Spacer(),
            // Resend OTP button with countdown.
            Center(
              child: _countdownSeconds > 0
                  ? Text(
                      locale.resendOtpCountdown(_countdownSeconds),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppSemanticColors.textSecondaryFor(
                          theme.brightness,
                        ),
                      ),
                    )
                  : FlatmatesButton.tertiary(
                      label: locale.resendOtpCta,
                      onPressed: auth.status == AuthStatus.submitting
                          ? null
                          : _resendOtp,
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Verify button.
            FlatmatesButton(
              key: const Key('otp_submit_button'),
              label: locale.verifyOtpCta,
              fullWidth: true,
              onPressed: auth.status == AuthStatus.submitting
                  ? null
                  : _submitOtp,
            ),
          ],
        ),
      ),
    );
  }
}
