import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../auth_controller.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';
import 'widgets/resend_countdown.dart';

final _otpTextProvider = StateProvider.autoDispose<String>((ref) => '');

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({this.phone = '', this.email, super.key});

  final String phone;

  /// When set, this is an **email** OTP screen (6-digit `OtpType.email`).
  final String? email;

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage>
    with CodeAutoFill, ResendCountdownMixin {
  final _otpKey = GlobalKey<FlatmatesOtpInputState>();
  bool _isListening = false;

  /// Local guard to prevent re-entrant submissions from dual autofill sources
  /// (sms_autofill + AutofillHints.oneTimeCode). The Riverpod `auth.status`
  /// check alone has an async gap; this flag closes it.
  bool _isSubmitting = false;

  bool get _isEmail => widget.email != null && widget.email!.trim().isNotEmpty;

  String get _email => widget.email?.trim() ?? '';

  String get _phone => widget.phone.isNotEmpty
      ? widget.phone
      : (ref.read(pendingPhoneProvider) ?? '');

  String _watchedPhone(WidgetRef ref) => widget.phone.isNotEmpty
      ? widget.phone
      : (ref.watch(pendingPhoneProvider) ?? '');

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
    super.dispose();
  }

  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      // Fill the OTP boxes but do NOT auto-submit. The sms_autofill package
      // can fire with a stale/cached code from a previous SMS detection
      // (BehaviorSubject replay); auto-submitting it would produce a
      // spurious "Invalid or expired" error.
      _otpKey.currentState?.silentFillOtp(code!);
      if (mounted) ref.read(_otpTextProvider.notifier).state = code!;
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
        'OtpPage._startListeningForSms: SMS auto-fill unavailable: $e',
      );
    }
  }

  void _submitOtp() {
    if (_isSubmitting) return;
    final auth = ref.read(authControllerProvider);
    final otp = _otpKey.currentState?.otp ?? '';
    if (otp.length != 6) return;
    if (auth.status == AuthStatus.submitting ||
        auth.status == AuthStatus.authenticated) {
      return;
    }
    _isSubmitting = true;
    final notifier = ref.read(authControllerProvider.notifier);
    if (_isEmail) {
      notifier.verifyEmailOtp(email: _email, otp: otp);
    } else {
      notifier.verifyOtp(phone: _phone, otp: otp);
    }
  }

  Future<void> _resendOtp() async {
    if (!canResend) return;
    _otpKey.currentState?.silentFillOtp('');
    ref.read(_otpTextProvider.notifier).state = '';
    final notifier = ref.read(authControllerProvider.notifier);
    // Default resend to login mode unless the identifier is explicitly
    // unverified. A null/unknown verified state should not opt into signup,
    // which could fail on GoTrue versions that reject create-user for existing
    // identifiers.
    final isSignup =
        ref.read(authControllerProvider).identifierVerified == false;
    if (_isEmail) {
      await notifier.sendEmailOtp(_email, isSignup: isSignup);
    } else {
      await notifier.requestOtp(_phone, shouldCreateUser: isSignup);
    }
    if (mounted) {
      final auth = ref.read(authControllerProvider);
      if (auth.status != AuthStatus.error) {
        startResendCountdown();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    // Reset the local submit guard when the auth state leaves the submitting
    // state (success or error) so the user can retry.
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.status == AuthStatus.submitting &&
          next.status != AuthStatus.submitting) {
        _isSubmitting = false;
      }
    });
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isSuccess = auth.status == AuthStatus.authenticated;
    final otpComplete = ref.watch(_otpTextProvider).length == 6;
    final canSubmit =
        otpComplete && auth.status != AuthStatus.submitting && !isSuccess;

    return FlatmatesScreen(
      appBar: AppBar(),
      scrollable: true,
      body: AutofillGroup(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.otpTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(locale.otpSubtitle(_isEmail ? _email : _watchedPhone(ref))),
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
                  compact: true,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.screen),
            FlatmatesOtpInput(
              key: _otpKey,
              onChanged: (otp) =>
                  ref.read(_otpTextProvider.notifier).state = otp,
              onCompleted: (_) => _submitOtp(),
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
                      onPressed: auth.status == AuthStatus.submitting
                          ? null
                          : _resendOtp,
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FlatmatesButton(
              key: const Key('otp_submit_button'),
              label: locale.verifyOtpCta,
              fullWidth: true,
              onPressed: canSubmit ? _submitOtp : null,
            ),
          ],
        ),
      ),
    );
  }
}
