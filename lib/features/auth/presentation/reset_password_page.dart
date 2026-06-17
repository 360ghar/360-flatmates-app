import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../auth_controller.dart';
import '../password_reset_controller.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';
import 'widgets/password_policy.dart';
import 'widgets/resend_countdown.dart';

final _obscurePasswordProvider = StateProvider.autoDispose<bool>((ref) => true);
final _obscureConfirmProvider = StateProvider.autoDispose<bool>((ref) => true);
final _isListeningProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Mirror the password / confirm field text so the rules checklist, the
/// "passwords don't match" warning, and the submit-button enabled state all
/// rebuild on each keystroke without a `setState` in this
/// ConsumerStatefulWidget.
final _passwordTextProvider = StateProvider.autoDispose<String>((ref) => '');
final _confirmTextProvider = StateProvider.autoDispose<String>((ref) => '');

/// True once all 6 OTP digits are entered (driven by the OTP input's
/// onCompleted), so the submit button reflects OTP readiness too.
final _otpCompleteProvider = StateProvider.autoDispose<bool>((ref) => false);

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage>
    with CodeAutoFill, ResendCountdownMixin {
  final _otpKey = GlobalKey<FlatmatesOtpInputState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  /// Local guard to prevent re-entrant submissions from dual autofill sources.
  bool _isSubmitting = false;

  /// The identifier (phone or email) the reset OTP was sent to, sourced from
  /// the controller (set by [ForgotPasswordPage]).
  String get _identifier =>
      ref.read(passwordResetControllerProvider).identifier ??
      ref.read(pendingPhoneProvider) ??
      '';

  String _watchedIdentifier(WidgetRef ref) =>
      ref.watch(passwordResetControllerProvider).identifier ??
      ref.watch(pendingPhoneProvider) ??
      '';

  bool get _isEmail =>
      ref.read(passwordResetControllerProvider).channel == AuthChannel.email;

  @override
  void initState() {
    super.initState();
    if (!_isEmail) {
      _startListeningForSms();
    }
    startResendCountdown();
  }

  @override
  void dispose() {
    cancelResendCountdown();
    SmsAutoFill().unregisterListener();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      // Fill the OTP boxes but do NOT auto-submit. The sms_autofill package
      // can fire with a stale/cached code from a previous SMS detection.
      _otpKey.currentState?.silentFillOtp(code!);
      // silentFillOtp deliberately skips onCompleted; mark complete here so
      // the (manually triggered) submit button enables after autofill.
      if (mounted) ref.read(_otpCompleteProvider.notifier).state = true;
    }
  }

  Future<void> _startListeningForSms() async {
    try {
      await SmsAutoFill().listenForCode();
      if (mounted) {
        ref.read(_isListeningProvider.notifier).state = true;
      }
    } catch (e) {
      debugPrint(
        'ResetPasswordPage._startListeningForSms: SMS auto-fill unavailable: $e',
      );
    }
  }

  Future<void> _resendOtp() async {
    if (!canResend) return;
    await ref
        .read(passwordResetControllerProvider.notifier)
        .sendOtp(_identifier);
    if (mounted) {
      final state = ref.read(passwordResetControllerProvider);
      if (state.step == PasswordResetStep.otpSent) {
        startResendCountdown();
      }
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final currentOtp = _otpKey.currentState?.otp ?? '';
    if (currentOtp.length != 6) return;
    if (_passwordController.text != _confirmPasswordController.text) return;
    if (!PasswordPolicy.isValid(_passwordController.text)) return;

    _isSubmitting = true;
    bool success;
    try {
      success = await ref
          .read(passwordResetControllerProvider.notifier)
          .verifyOtpAndSetPassword(
            otp: currentOtp,
            newPassword: _passwordController.text,
          );
    } finally {
      _isSubmitting = false;
    }
    if (!mounted) return;
    if (success) {
      FlatmatesToast.success(
        context,
        AppLocalizations.of(context).passwordResetSuccess,
      );
      // The reset kept the OTP-verified session — go straight into the app;
      // the router redirect chain corrects to /splash or /onboarding.
      context.go('/discover');
    }
  }

  @override
  Widget build(BuildContext context) {
    final resetState = ref.watch(passwordResetControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isVerifying = resetState.step == PasswordResetStep.verifying;
    final identifier = _watchedIdentifier(ref);
    final isListening = ref.watch(_isListeningProvider);
    final passwordText = ref.watch(_passwordTextProvider);
    final confirmText = ref.watch(_confirmTextProvider);
    final passwordsMatch = passwordText == confirmText;
    final otpComplete = ref.watch(_otpCompleteProvider);
    final canSubmit =
        otpComplete &&
        PasswordPolicy.isValid(passwordText) &&
        passwordsMatch &&
        !isVerifying;

    return FlatmatesScreen(
      appBar: AppBar(),
      scrollable: true,
      body: AutofillGroup(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.resetPasswordTitle,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              locale.resetPasswordSubtitle(identifier),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
            if (isListening) ...[
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
            FlatmatesOtpInput(
              key: _otpKey,
              keyPrefix: 'reset_otp',
              onCompleted: (_) =>
                  ref.read(_otpCompleteProvider.notifier).state = true,
            ),
            const SizedBox(height: AppSpacing.screen),

            // New password field
            FlatmatesCard(
              child: Column(
                children: [
                  TextField(
                    key: const Key('reset_new_password_input'),
                    controller: _passwordController,
                    obscureText: ref.watch(_obscurePasswordProvider),
                    autofillHints: const [AutofillHints.newPassword],
                    onChanged: (value) =>
                        ref.read(_passwordTextProvider.notifier).state = value,
                    decoration: InputDecoration(
                      labelText: locale.newPasswordLabel,
                      suffixIcon: IconButton(
                        icon: Icon(
                          ref.watch(_obscurePasswordProvider)
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          final notifier = ref.read(
                            _obscurePasswordProvider.notifier,
                          );
                          notifier.state = !notifier.state;
                        },
                        tooltip: locale.togglePasswordVisibility,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Live policy checklist so the user understands why the
                  // submit button stays disabled (parity with set-password).
                  PasswordRulesChecklist(password: passwordText),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    key: const Key('reset_confirm_password_input'),
                    controller: _confirmPasswordController,
                    obscureText: ref.watch(_obscureConfirmProvider),
                    autofillHints: const [AutofillHints.newPassword],
                    onChanged: (value) =>
                        ref.read(_confirmTextProvider.notifier).state = value,
                    decoration: InputDecoration(
                      labelText: locale.confirmPasswordLabel,
                      suffixIcon: IconButton(
                        icon: Icon(
                          ref.watch(_obscureConfirmProvider)
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          final notifier = ref.read(
                            _obscureConfirmProvider.notifier,
                          );
                          notifier.state = !notifier.state;
                        },
                        tooltip: locale.togglePasswordVisibility,
                      ),
                    ),
                  ),
                  if (passwordText.isNotEmpty &&
                      confirmText.isNotEmpty &&
                      !passwordsMatch) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      locale.passwordsDoNotMatch,
                      style: const TextStyle(color: AppSemanticColors.error),
                    ),
                  ],
                  if (resetState.step == PasswordResetStep.error &&
                      resetState.failure != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      resetState.failure!.userMessage(
                        locale.toUserMessageL10n(),
                      ),
                      style: const TextStyle(color: AppSemanticColors.error),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.screen),

            // Resend OTP
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
              // Gate on a valid + matching password so the button reflects
              // why a tap would no-op, instead of silently doing nothing.
              onPressed: canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
