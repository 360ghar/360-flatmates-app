import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:smart_auth/smart_auth.dart';

import '../auth_controller.dart';
import '../data/auth_repository.dart' show IdentifierNextStep;
import '../last_auth_method.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';
import 'widgets/terms_checkbox.dart';

class EnterPhonePage extends ConsumerStatefulWidget {
  const EnterPhonePage({super.key});

  @override
  ConsumerState<EnterPhonePage> createState() => _EnterPhonePageState();
}

class _EnterPhonePageState extends ConsumerState<EnterPhonePage> {
  final _controller = TextEditingController();
  final _identifierFocusNode = FocusNode();
  final _smartAuth = SmartAuth.instance;
  bool _termsAccepted = false;
  bool _isSubmitting = false;
  bool _phoneHintShown = false;

  bool get _looksLikeEmail => _controller.text.contains('@');

  @override
  void initState() {
    super.initState();
    // Prefill the identifier handed over by the login page's "No account?"
    // link so the user doesn't retype it for the OTP-first signup flow.
    final pending = ref.read(pendingPhoneProvider);
    if (pending != null && pending.trim().isNotEmpty) {
      _controller.text = pending.trim();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _identifierFocusNode.dispose();
    super.dispose();
  }

  /// On Android, offer the SIM-based phone-number hint picker so the user can
  /// fill the identifier field with one tap (no permission required). Shown at
  /// most once per page session — the picker is a system activity that
  /// dismisses the keyboard, so re-launching it on every tap would make manual
  /// entry impossible.
  Future<void> _requestPhoneHint() async {
    if (!Platform.isAndroid) return;
    if (_phoneHintShown || _controller.text.isNotEmpty) return;
    _phoneHintShown = true;
    try {
      final res = await _smartAuth.requestPhoneNumberHint();
      final phone = res.data;
      if (phone != null && phone.trim().isNotEmpty && mounted) {
        _controller.text = phone.trim();
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
      }
    } catch (_) {
      debugPrint('EnterPhonePage._requestPhoneHint: hint unavailable');
    } finally {
      // The picker activity hides the keyboard but the node keeps Flutter
      // focus, so requestFocus() alone is a no-op — explicitly re-show the
      // keyboard so the user can edit the filled number or type a custom
      // identifier.
      if (mounted) {
        _identifierFocusNode.requestFocus();
        await SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    }
  }

  Future<void> _onContinue() async {
    if (_isSubmitting) return;
    String identifier = _controller.text.trim();
    if (identifier.isEmpty) return;

    // Normalize phone numbers to include the country code
    if (!identifier.contains('@')) {
      String digits = identifier.replaceAll(RegExp(r'\D'), '');
      if (digits.length == 11 && digits.startsWith('0')) {
        digits = digits.substring(1);
      } else if (digits.startsWith('0')) {
        digits = digits.replaceFirst(RegExp(r'^0+'), '');
      }
      if (digits.length == 10) {
        identifier = '+91$digits';
      } else if (digits.length == 12 && digits.startsWith('91')) {
        identifier = '+$digits';
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final notifier = ref.read(authControllerProvider.notifier);
      final status = await notifier.checkIdentifierStatus(identifier);
      if (status == null || !mounted) return;

      ref.read(pendingPhoneProvider.notifier).state = identifier;

      final encodedIdentifier = Uri.encodeComponent(identifier);
      if (status.channel == AuthChannel.email) {
        // Consume next_step: a verified email that has a password logs in with
        // the password screen; everything else is OTP-first.
        if (status.nextStep == IdentifierNextStep.password) {
          unawaited(context.push('/login?email=$encodedIdentifier'));
          return;
        }
        // OTP-first for verified-passwordless and unknown (signup) emails.
        // Unverified existing accounts also allow creation: some GoTrue
        // versions reject a login-only OTP for unconfirmed accounts, and
        // shouldCreateUser=true never duplicates an existing account.
        final sent = await notifier.sendEmailOtp(
          identifier,
          isSignup: !status.exists || !status.verified,
        );
        if (sent && mounted) {
          unawaited(context.push('/otp?email=$encodedIdentifier'));
        }
        return;
      }

      // Phone channel.
      if (status.nextStep == IdentifierNextStep.password) {
        // Existing verified account with a password → password login.
        unawaited(context.push('/login?phone=$encodedIdentifier'));
      } else if (status.exists) {
        // Existing but passwordless/unverified account → OTP-first login.
        // Allow creation for unverified accounts: some GoTrue versions reject
        // a login-only OTP for unconfirmed accounts; an existing account is
        // never duplicated by shouldCreateUser=true.
        await notifier.requestOtp(
          identifier,
          shouldCreateUser: !status.verified,
        );
        if (mounted &&
            ref.read(authControllerProvider).status != AuthStatus.error) {
          unawaited(context.push('/otp?phone=$encodedIdentifier'));
        }
      } else {
        // Unknown → OTP-first signup.
        await notifier.requestOtp(identifier, shouldCreateUser: true);
        if (mounted &&
            ref.read(authControllerProvider).status != AuthStatus.error) {
          unawaited(context.push('/otp?phone=$encodedIdentifier'));
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _onGoogle() async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle();
    // On success the router redirect chain takes over (incl. /add-phone).
    if (!ok && mounted) {
      // Error surfaced via auth state below.
    }
  }

  Future<void> _onApple() async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signInWithApple();
    // On success the router redirect chain takes over (incl. /add-phone).
    if (!ok && mounted) {
      // Error surfaced via auth state below.
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final lastMethod = ref.watch(lastAuthMethodProvider);
    final isBusy = auth.status == AuthStatus.submitting || _isSubmitting;

    return FlatmatesScreen(
      appBar: AppBar(),
      scrollable: true,
      body: AutofillGroup(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.authEntryTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(locale.authEntrySubtitle),
            if (lastMethod != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                locale.lastUsedMethodHint(_methodLabel(lastMethod.method)),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.screen),
            FlatmatesButton.google(
              key: const Key('auth_google_button'),
              label: locale.continueWithGoogleCta,
              fullWidth: true,
              onPressed: (isBusy || !_termsAccepted) ? null : _onGoogle,
            ),
            // Sign in with Apple — iOS only, as prominent as Google. Apple
            // requires it on iOS apps that offer Google sign-in.
            if (Platform.isIOS) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 52,
                child: AbsorbPointer(
                  absorbing: isBusy || !_termsAccepted,
                  child: Opacity(
                    opacity: (isBusy || !_termsAccepted) ? 0.5 : 1,
                    child: SignInWithAppleButton(
                      key: const Key('auth_apple_button'),
                      onPressed: _onApple,
                      style: theme.brightness == Brightness.dark
                          ? SignInWithAppleButtonStyle.white
                          : SignInWithAppleButtonStyle.black,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    locale.authDividerOr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FlatmatesCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const Key('enter_phone_input'),
                    controller: _controller,
                    focusNode: _identifierFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: _looksLikeEmail
                        ? const [AutofillHints.email]
                        : const [
                            AutofillHints.telephoneNumber,
                            AutofillHints.email,
                          ],
                    onChanged: (_) => setState(() {}),
                    onTap: _requestPhoneHint,
                    onSubmitted: (_) =>
                        (isBusy || !_termsAccepted) ? null : _onContinue(),
                    decoration: InputDecoration(
                      labelText: locale.identifierLabel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      FlatmatesTrustBadge(
                        label: locale.yourNumberIsPrivate,
                        variant: FlatmatesTrustBadgeVariant.privacy,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TermsCheckbox(
                    accepted: _termsAccepted,
                    onChanged: (v) => setState(() => _termsAccepted = v),
                    locale: locale,
                    theme: theme,
                  ),
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
              key: const Key('enter_phone_continue_cta'),
              label: locale.continueCta,
              fullWidth: true,
              onPressed: (isBusy || !_termsAccepted) ? null : _onContinue,
            ),
          ],
        ),
      ),
    );
  }

  String _methodLabel(AuthMethod method) {
    switch (method) {
      case AuthMethod.google:
        return 'Google';
      case AuthMethod.apple:
        return 'Apple';
      case AuthMethod.emailPassword:
      case AuthMethod.emailOtp:
        return 'email';
      case AuthMethod.phonePassword:
      case AuthMethod.phoneOtp:
        return 'phone';
    }
  }
}
