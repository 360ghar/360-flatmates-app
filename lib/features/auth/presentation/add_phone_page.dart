import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_auth/smart_auth.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../auth_controller.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';
import 'widgets/resend_countdown.dart';

/// Skippable post-Google step that lets a phone-less account add and verify a
/// phone number. Skipping keeps `last_auth_method = google` and continues the
/// onboarding chain.
class AddPhonePage extends ConsumerStatefulWidget {
  const AddPhonePage({super.key});

  @override
  ConsumerState<AddPhonePage> createState() => _AddPhonePageState();
}

class _AddPhonePageState extends ConsumerState<AddPhonePage>
    with CodeAutoFill, ResendCountdownMixin {
  final _phoneController = TextEditingController(text: '+91');
  final _phoneFocusNode = FocusNode();
  final _smartAuth = SmartAuth.instance;
  bool _phoneHintShown = false;
  final _otpKey = GlobalKey<FlatmatesOtpInputState>();
  bool _codeSent = false;
  String _otpText = '';
  bool _smsListening = false;

  String get _phone => _phoneController.text.trim();

  bool get _phoneLooksValid {
    final digits = _phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 15 && _phone != '+91';
  }

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    cancelResendCountdown();
    if (_smsListening) {
      SmsAutoFill().unregisterListener();
      _smsListening = false;
    }
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  void codeUpdated() {
    final value = code;
    if (value != null && value.length == 6) {
      // Fill the boxes but do not auto-verify: sms_autofill can replay a
      // stale code from an earlier SMS.
      _otpKey.currentState?.silentFillOtp(value);
      if (mounted) setState(() => _otpText = value);
    }
  }

  /// Shown at most once per page session — the picker is a system activity
  /// that dismisses the keyboard, so re-launching it on every tap would make
  /// manual entry impossible. The '+91' prefill counts as an empty field.
  Future<void> _requestPhoneHint() async {
    if (!Platform.isAndroid) return;
    if (_phoneHintShown || _phone.length > '+91'.length) return;
    _phoneHintShown = true;
    try {
      final res = await _smartAuth.requestPhoneNumberHint();
      if (res.data != null && res.data!.trim().isNotEmpty && mounted) {
        _phoneController.text = res.data!.trim();
        _phoneController.selection = TextSelection.collapsed(
          offset: _phoneController.text.length,
        );
      }
    } catch (_) {
      debugPrint('AddPhonePage._requestPhoneHint: SIM hint unavailable');
    } finally {
      // The picker activity hides the keyboard but the node keeps Flutter
      // focus, so requestFocus() alone is a no-op — explicitly re-show the
      // keyboard so the user can edit the filled number or type one manually.
      if (mounted) {
        _phoneFocusNode.requestFocus();
        await SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    }
  }

  Future<void> _sendCode() async {
    if (!_phoneLooksValid) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .requestAddPhoneOtp(_phone);
    if (ok && mounted) {
      setState(() => _codeSent = true);
      // Start the shared 30s resend cooldown once the SMS is sent.
      startResendCountdown();
      try {
        await SmsAutoFill().listenForCode();
        if (mounted) _smsListening = true;
      } catch (_) {
        debugPrint('AddPhonePage._sendCode: SMS auto-fill unavailable');
      }
    }
  }

  /// Resends the SMS OTP and restarts the 30s cooldown (enabled only at 0).
  Future<void> _resendCode() async {
    if (!canResend) return;
    if (!_phoneLooksValid) return;
    _otpKey.currentState?.silentFillOtp('');
    setState(() => _otpText = '');
    final ok = await ref
        .read(authControllerProvider.notifier)
        .requestAddPhoneOtp(_phone);
    if (ok && mounted) {
      startResendCountdown();
    }
  }

  /// On success the router redirect chain advances onboarding; an error
  /// shows from the auth state.
  Future<void> _verify([String? code]) async {
    final otp = code ?? _otpText;
    if (otp.length != 6) return;
    if (!_phoneLooksValid) return;
    await ref
        .read(authControllerProvider.notifier)
        .addAndVerifyPhone(phone: _phone, otp: otp);
  }

  void _skip() {
    ref.read(authControllerProvider.notifier).skipAddPhone();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final isBusy = auth.status == AuthStatus.submitting;
    final codeSent = _codeSent;
    final otpComplete = _otpText.length == 6;
    final canSubmit = !isBusy && (codeSent ? otpComplete : _phoneLooksValid);

    // Reached by redirect, so there is nothing to pop: Skip is the way out.
    return FlatmatesScreen(
      appBar: const FlatmatesHeader.titleOnly(title: ''),
      scrollable: true,
      body: AutofillGroup(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.addPhoneTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(locale.addPhoneSubtitle),
            const SizedBox(height: AppSpacing.screen),
            FlatmatesCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const Key('add_phone_input'),
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    enabled: !codeSent,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    onTap: _requestPhoneHint,
                    decoration: InputDecoration(
                      labelText: locale.phoneNumberLabel,
                    ),
                  ),
                  if (codeSent) ...[
                    const SizedBox(height: AppSpacing.lg),
                    FlatmatesOtpInput(
                      key: _otpKey,
                      keyPrefix: 'add_phone_otp',
                      onChanged: (otp) => setState(() => _otpText = otp),
                      onCompleted: _verify,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Resend OTP with shared 30s countdown.
                    Center(
                      child: !canResend
                          ? Text(
                              locale.resendOtpCountdown(resendSecondsRemaining),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppSemanticColors.textSecondaryFor(
                                  theme.brightness,
                                ),
                              ),
                            )
                          : FlatmatesButton.tertiary(
                              key: const Key('add_phone_resend_cta'),
                              label: locale.resendOtpCta,
                              onPressed: isBusy ? null : _resendCode,
                            ),
                    ),
                  ],
                ],
              ),
            ),
            if (auth.status == AuthStatus.error &&
                auth.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              FlatmatesInlineError(resolveAuthError(auth.errorMessage, locale)),
            ],
            const SizedBox(height: AppSpacing.screen),
            FlatmatesButton(
              key: const Key('add_phone_primary_cta'),
              label: codeSent ? locale.verifyOtpCta : locale.addPhoneCta,
              fullWidth: true,
              onPressed: canSubmit
                  ? (codeSent ? () => _verify() : _sendCode)
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: FlatmatesButton.tertiary(
                key: const Key('add_phone_skip_cta'),
                label: locale.skipCta,
                onPressed: isBusy ? null : _skip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
