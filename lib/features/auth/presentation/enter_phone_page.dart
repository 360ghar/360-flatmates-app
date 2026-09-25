import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:smart_auth/smart_auth.dart';

import '../auth_controller.dart';
import '../identifier.dart';
import '../last_auth_method.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';
import '../../shared/presentation/paper/paper_scene.dart';
import 'widgets/terms_checkbox.dart';

class EnterPhonePage extends ConsumerStatefulWidget {
  const EnterPhonePage({super.key});

  @override
  ConsumerState<EnterPhonePage> createState() => _EnterPhonePageState();
}

class _EnterPhonePageState extends ConsumerState<EnterPhonePage> {
  final _controller = TextEditingController();

  /// Drives the scene parallax as the form scrolls.
  final _scroll = ScrollController();
  final _identifierFocusNode = FocusNode();
  final _smartAuth = SmartAuth.instance;
  bool _phoneHintShown = false;

  /// Terms start accepted; the checkbox gates every sign-in action.
  bool _termsAccepted = true;

  /// Closes the async gap between the identifier check and the follow-up
  /// OTP request, so the CTA stays disabled across both steps.
  bool _isSubmitting = false;

  bool get _looksLikeEmail => looksLikeEmail(_controller.text);

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
    _scroll.dispose();
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
    // Phone numbers are normalized to E.164 by the shared identifier rules.
    final identifier = normalizeIdentifier(_controller.text);
    if (identifier.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .startIdentifierFlow(identifier);
      if (!mounted) return;
      final locale = AppLocalizations.of(context);
      final route = result.route;
      if (route == null) {
        final err = ref.read(authControllerProvider).errorMessage;
        if (err != null && err.isNotEmpty) {
          FlatmatesToast.error(context, resolveAuthError(err, locale));
        }
        return;
      }
      if (result.unverified) {
        FlatmatesToast.info(context, locale.unverifiedAccountHint);
      }
      unawaited(context.push(route));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // On success the router redirect chain takes over (incl. /add-phone); an
  // error shows from the auth state.
  void _onGoogle() =>
      unawaited(ref.read(authControllerProvider.notifier).signInWithGoogle());

  void _onApple() =>
      unawaited(ref.read(authControllerProvider.notifier).signInWithApple());

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final lastMethod = ref.watch(lastAuthMethodProvider);
    final termsAccepted = _termsAccepted;
    final isBusy = auth.status == AuthStatus.submitting || _isSubmitting;

    // Root auth entry — no top chrome; title lives in the body.
    // The neighbourhood scene owns the top of the first screen; the form
    // sits below it on the page.
    return FlatmatesScreen(
      scrollable: true,
      scrollController: _scroll,
      useSafeArea: false,
      padding: EdgeInsets.zero,
      backgroundColor: AppSemanticColors.paper1For(theme.brightness),
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PaperSceneHeader(parallax: _scroll),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.base,
                AppSpacing.screen,
                AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale.authEntryTitle,
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(locale.authEntrySubtitle),
                  if (lastMethod != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      locale.lastUsedMethodHint(
                        _methodLabel(lastMethod.method, locale),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppSemanticColors.textSecondaryFor(
                          theme.brightness,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.screen),
                  FlatmatesButton.google(
                    key: const Key('auth_google_button'),
                    label: locale.continueWithGoogleCta,
                    fullWidth: true,
                    onPressed: (isBusy || !termsAccepted) ? null : _onGoogle,
                  ),
                  // Sign in with Apple — iOS only, as prominent as Google. Apple
                  // requires it on iOS apps that offer Google sign-in.
                  if (Platform.isIOS) ...[
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 48,
                      child: AbsorbPointer(
                        absorbing: isBusy || !termsAccepted,
                        child: Opacity(
                          opacity: (isBusy || !termsAccepted) ? 0.5 : 1,
                          // The package button has a fixed height (48, the
                          // same as Google); keep its label inside it at
                          // large text sizes.
                          child: MediaQuery.withClampedTextScaling(
                            maxScaleFactor: 1.3,
                            child: SignInWithAppleButton(
                              key: const Key('auth_apple_button'),
                              height: 48,
                              borderRadius: AppRadius.mdBorder,
                              onPressed: _onApple,
                              style: theme.brightness == Brightness.dark
                                  ? SignInWithAppleButtonStyle.white
                                  : SignInWithAppleButtonStyle.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.base),
                  // Spacing, not rules, separates the two sign-in routes.
                  Center(
                    child: Text(
                      locale.authDividerOr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppSemanticColors.textSecondaryFor(
                          theme.brightness,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
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
                          // Rebuild so autofill hints track email vs phone.
                          onChanged: (_) => setState(() {}),
                          onTap: _requestPhoneHint,
                          onSubmitted: (_) =>
                              (isBusy || !termsAccepted) ? null : _onContinue(),
                          decoration: InputDecoration(
                            labelText: locale.identifierLabel,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FlatmatesTrustBadge(
                          label: locale.yourNumberIsPrivate,
                          variant: FlatmatesTrustBadgeVariant.privacy,
                          compact: true,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TermsCheckbox(
                          accepted: termsAccepted,
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
                    FlatmatesInlineError(
                      resolveAuthError(auth.errorMessage, locale),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.screen),
                  FlatmatesButton(
                    key: const Key('enter_phone_continue_cta'),
                    label: locale.continueCta,
                    fullWidth: true,
                    onPressed: (isBusy || !termsAccepted) ? null : _onContinue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _methodLabel(AuthMethod method, AppLocalizations locale) {
    switch (method) {
      case AuthMethod.google:
        return locale.authMethodGoogle;
      case AuthMethod.apple:
        return locale.authMethodApple;
      case AuthMethod.emailPassword:
      case AuthMethod.emailOtp:
        return locale.authMethodEmail;
      case AuthMethod.phonePassword:
      case AuthMethod.phoneOtp:
        return locale.authMethodPhone;
    }
  }
}
