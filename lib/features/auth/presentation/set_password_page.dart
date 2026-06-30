import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_controller.dart';
import '../last_auth_method.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';
import 'widgets/password_policy.dart';

final _obscurePasswordProvider = StateProvider.autoDispose<bool>((ref) => true);
final _localErrorProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Mirrors the password field text so the live rules checklist and the
/// submit-button enabled state rebuild on each keystroke without a `setState`
/// in this ConsumerStatefulWidget.
final _passwordTextProvider = StateProvider.autoDispose<String>((ref) => '');
final _confirmTextProvider = StateProvider.autoDispose<String>((ref) => '');

/// Mandatory (non-skippable) set-password step shown after an email/phone OTP
/// verify when the account has no password yet (requirement 6). The router
/// gates this screen — it cannot be popped or bypassed; completing it records
/// the password-based last_auth_method and lets the user into the app.
class SetPasswordPage extends ConsumerStatefulWidget {
  const SetPasswordPage({super.key});

  @override
  ConsumerState<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends ConsumerState<SetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final locale = AppLocalizations.of(context);
    final password = _passwordController.text;
    final policyError = PasswordPolicy.validate(password, locale);
    if (policyError != null) {
      ref.read(_localErrorProvider.notifier).state = policyError;
      return;
    }
    if (password != _confirmController.text) {
      ref.read(_localErrorProvider.notifier).state = locale.passwordsDoNotMatch;
      return;
    }
    ref.read(_localErrorProvider.notifier).state = null;
    await ref
        .read(authControllerProvider.notifier)
        .setPasswordAfterSignup(password);
    // On success the router redirect chain advances (needsPassword cleared).
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final passwordText = ref.watch(_passwordTextProvider);
    final confirmText = ref.watch(_confirmTextProvider);
    final passwordsMatch = passwordText == confirmText;
    final isBusy = auth.status == AuthStatus.submitting;
    // The phone/email this password is being set for (masked for display).
    final identifier = auth.identifier ?? auth.phone;
    final maskedIdentifier = (identifier != null && identifier.isNotEmpty)
        ? maskIdentifier(identifier)
        : null;

    return PopScope(
      // Mandatory step — disallow dismissing via the system back gesture.
      canPop: false,
      child: FlatmatesScreen(
        scrollable: true,
        body: AutofillGroup(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.setPasswordTitle,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(locale.setPasswordSubtitle),
              if (maskedIdentifier != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  maskedIdentifier,
                  key: const Key('set_password_identifier'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.screen),
              FlatmatesCard(
                child: Column(
                  children: [
                    TextField(
                      key: const Key('set_password_input'),
                      controller: _passwordController,
                      obscureText: ref.watch(_obscurePasswordProvider),
                      autofillHints: const [AutofillHints.newPassword],
                      onChanged: (value) =>
                          ref.read(_passwordTextProvider.notifier).state =
                              value,
                      decoration: InputDecoration(
                        labelText: locale.passwordLabel,
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
                    PasswordRulesChecklist(password: passwordText),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      key: const Key('set_password_confirm_input'),
                      controller: _confirmController,
                      obscureText: ref.watch(_obscurePasswordProvider),
                      autofillHints: const [AutofillHints.newPassword],
                      onChanged: (value) =>
                          ref.read(_confirmTextProvider.notifier).state = value,
                      onSubmitted: (_) => isBusy ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: locale.confirmPasswordLabel,
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
                  ],
                ),
              ),
              if (ref.watch(_localErrorProvider) != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  ref.watch(_localErrorProvider)!,
                  style: const TextStyle(color: AppSemanticColors.error),
                ),
              ],
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
                key: const Key('set_password_submit_button'),
                label: locale.commonSave,
                fullWidth: true,
                onPressed:
                    isBusy ||
                        !PasswordPolicy.isValid(passwordText) ||
                        !passwordsMatch ||
                        confirmText.isEmpty
                    ? null
                    : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
