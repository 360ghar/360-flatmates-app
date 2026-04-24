import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../auth_controller.dart';
import '../../../l10n/gen/app_localizations.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({required this.phone, super.key});

  final String phone;

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> with CodeAutoFill {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  String _currentOtp = '';
  bool _isListening = false;

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
      SmsAutoFill().listenForCode;
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
      setState(() {
        _countdownSeconds--;
      });
      if (_countdownSeconds <= 0) {
        timer.cancel();
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
    ref.read(authControllerProvider.notifier).verifyOtp(
          phone: widget.phone,
          otp: _currentOtp,
        );
  }

  void _resendOtp() {
    if (_countdownSeconds > 0) return;
    ref.read(authControllerProvider.notifier).requestOtp(widget.phone);
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.otpTitle,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(locale.otpSubtitle(widget.phone)),
            if (_isListening) ...[
              const SizedBox(height: 8),
              Text(
                locale.otpAutoReadHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 24),
            // 6-digit OTP input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 48,
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      // Handle backspace to move focus backward.
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
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) => _onOtpDigitChanged(index, value),
                    ),
                  ),
                );
              }),
            ),
            if (auth.status == AuthStatus.error &&
                auth.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const Spacer(),
            // Resend OTP button with countdown.
            Center(
              child: _countdownSeconds > 0
                  ? Text(
                      locale.resendOtpCountdown(_countdownSeconds),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : TextButton(
                      onPressed: auth.status == AuthStatus.submitting
                          ? null
                          : _resendOtp,
                      child: Text(locale.resendOtpCta),
                    ),
            ),
            const SizedBox(height: 16),
            // Verify button.
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('otp_submit_button'),
                onPressed: auth.status == AuthStatus.submitting
                    ? null
                    : _submitOtp,
                child: auth.status == AuthStatus.submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(locale.verifyOtpCta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
