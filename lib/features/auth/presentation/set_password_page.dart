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
  bool _obscurePassword = true;
  String? _localError;
  String _passwordText = '';
  String _confirmText = '';

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
      setState(() => _localError = policyError);
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _localError = locale.passwordsDoNotMatch);
      return;
    }
    setState(() => _localError = null);
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
    final passwordsMatch = _passwordText == _confirmText;
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
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      onChanged: (value) =>
                          setState(() => _passwordText = value),
                      decoration: InputDecoration(
                        labelText: locale.passwordLabel,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          tooltip: locale.togglePasswordVisibility,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PasswordRulesChecklist(password: _passwordText),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      key: const Key('set_password_confirm_input'),
                      controller: _confirmController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      onChanged: (value) =>
                          setState(() => _confirmText = value),
                      onSubmitted: (_) => isBusy ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: locale.confirmPasswordLabel,
                      ),
                    ),
                    if (_passwordText.isNotEmpty &&
                        _confirmText.isNotEmpty &&
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
              if (_localError != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _localError!,
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
                        !PasswordPolicy.isValid(_passwordText) ||
                        !passwordsMatch ||
                        _confirmText.isEmpty
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
