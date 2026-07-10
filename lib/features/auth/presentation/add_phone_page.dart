import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_auth/smart_auth.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../auth_controller.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';
import 'widgets/resend_countdown.dart';

final _codeSentProvider = StateProvider<bool>((ref) => false);
final _addPhoneOtpTextProvider = StateProvider.autoDispose<String>((ref) => '');

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
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  /// Suppresses auto-submit from [codeUpdated] while programmatically
  /// filling boxes — the sms_autofill package can fire with a stale code
  /// (BehaviorSubject replay) and should not auto-verify.
  bool _isSmsFilling = false;
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
    for (final c in _otpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void codeUpdated() {
    final value = code;
    if (value != null && value.length == 6) {
      _isSmsFilling = true;
      for (var i = 0; i < 6; i++) {
        _otpControllers[i].text = value[i];
      }
      _isSmsFilling = false;
      if (mounted) ref.read(_addPhoneOtpTextProvider.notifier).state = value;
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
      ref.read(_codeSentProvider.notifier).state = true;
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
    for (final controller in _otpControllers) {
      controller.clear();
    }
    ref.read(_addPhoneOtpTextProvider.notifier).state = '';
    final ok = await ref
        .read(authControllerProvider.notifier)
        .requestAddPhoneOtp(_phone);
    if (ok && mounted) {
      startResendCountdown();
    }
  }

  String get _currentOtp => _otpControllers.map((c) => c.text).join();

  Future<void> _verify([String? code]) async {
    // Suppress auto-verify while sms_autofill is programmatically filling
    // boxes — the code may be stale/cached from a previous SMS detection.
    if (_isSmsFilling) return;

    final otp = code ?? _currentOtp;
    if (otp.length != 6) return;
    if (!_phoneLooksValid) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .addAndVerifyPhone(phone: _phone, otp: otp);
    // On success the router redirect chain advances onboarding.
    if (!ok && mounted) {
      // Error surfaced via auth state below.
    }
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
    final codeSent = ref.watch(_codeSentProvider);
    final otpComplete = ref.watch(_addPhoneOtpTextProvider).length == 6;
    final canSubmit = !isBusy && (codeSent ? otpComplete : _phoneLooksValid);

    return FlatmatesScreen(
      appBar: AppBar(),
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
                    _OtpFieldRow(
                      controllers: _otpControllers,
                      onChanged: (otp) {
                        ref.read(_addPhoneOtpTextProvider.notifier).state = otp;
                        if (otp.length == 6) _verify(otp);
                      },
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
              Text(
                resolveAuthError(auth.errorMessage, locale),
                style: const TextStyle(color: AppSemanticColors.error),
              ),
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

class _OtpFieldRow extends StatefulWidget {
  const _OtpFieldRow({required this.controllers, required this.onChanged});

  final List<TextEditingController> controllers;
  final ValueChanged<String> onChanged;

  @override
  State<_OtpFieldRow> createState() => _OtpFieldRowState();
}

class _OtpFieldRowState extends State<_OtpFieldRow> {
  bool _isFilling = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: AppSpacing.xl,
          child: TextField(
            key: Key('add_phone_otp_$index'),
            controller: widget.controllers[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: index == 0 ? null : 1,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(index == 0 ? 6 : 1),
            ],
            autofillHints: index == 0
                ? const [AutofillHints.oneTimeCode]
                : null,
            decoration: const InputDecoration(
              counterText: '',
              border: OutlineInputBorder(borderRadius: AppRadius.mdBorder),
            ),
            onChanged: (value) {
              // Suppress re-entrant onChanged while distributing digits.
              if (_isFilling) return;

              // Handle multi-character paste/autofill on the first box.
              if (value.length > 1 && index == 0) {
                final digits = value.replaceAll(RegExp(r'\D'), '');
                _isFilling = true;
                for (var i = 0; i < 6; i++) {
                  if (i < digits.length) {
                    widget.controllers[i].text = digits[i];
                  } else {
                    widget.controllers[i].clear();
                  }
                }
                _isFilling = false;
                widget.onChanged(_currentOtp);
                return;
              }

              if (value.isNotEmpty && index < 5) {
                FocusScope.of(context).nextFocus();
              }
              widget.onChanged(_currentOtp);
            },
          ),
        );
      }),
    );
  }

  String get _currentOtp => widget.controllers.map((c) => c.text).join();
}
