import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth_controller.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({this.phone, this.email, super.key});

  final String? phone;

  /// When set, this is an **email** password login (verified email that has a
  /// password set; `next_step == password`).
  final String? email;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late final TextEditingController _identifierController;
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool get _isEmail => widget.email != null && widget.email!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController(
      text: _isEmail ? widget.email : (widget.phone ?? '+91'),
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final notifier = ref.read(authControllerProvider.notifier);
    final identifier = _identifierController.text.trim();
    if (_isEmail) {
      notifier.signInWithEmailPassword(
        email: identifier,
        password: _passwordController.text,
      );
    } else {
      notifier.signInWithPassword(
        phone: identifier,
        password: _passwordController.text,
      );
    }
  }

  void _onForgotPassword() {
    final identifier = _identifierController.text.trim();
    if (!_isEmail) ref.read(pendingPhoneProvider.notifier).set(identifier);
    final route = Uri(
      path: '/forgot-password',
      queryParameters: {_isEmail ? 'email' : 'phone': identifier},
    ).toString();
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return FlatmatesScreen(
      appBar: const FlatmatesHeader.backTitle(title: ''),
      scrollable: true,
      body: AutofillGroup(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.loginTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.screen),
            FlatmatesCard(
              child: Column(
                children: [
                  TextField(
                    key: const Key('login_phone_input'),
                    controller: _identifierController,
                    keyboardType: _isEmail
                        ? TextInputType.emailAddress
                        : TextInputType.phone,
                    autofillHints: _isEmail
                        ? const [AutofillHints.email]
                        : const [AutofillHints.telephoneNumber],
                    decoration: InputDecoration(
                      labelText: _isEmail
                          ? locale.emailLabel
                          : locale.phoneNumberLabel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    key: const Key('login_password_input'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) =>
                        auth.status == AuthStatus.submitting ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: locale.passwordLabel,
                      suffixIcon: IconButton(
                        key: const Key('login_password_visibility_toggle'),
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
                  if (auth.status == AuthStatus.error &&
                      auth.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      resolveAuthError(auth.errorMessage, locale),
                      style: const TextStyle(color: AppSemanticColors.error),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: FlatmatesButton.tertiary(
                label: locale.forgotPasswordCta,
                onPressed: _onForgotPassword,
              ),
            ),
            const SizedBox(height: AppSpacing.screen),
            FlatmatesButton(
              key: const Key('login_submit_button'),
              label: locale.signInCta,
              fullWidth: true,
              onPressed: auth.status == AuthStatus.submitting ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: FlatmatesButton.tertiary(
                label: locale.noAccountCta,
                onPressed: () {
                  // Signup is unified into the OTP-first entry flow: verify
                  // the identifier first, then the mandatory set-password
                  // step creates the credential.
                  final identifier = _identifierController.text.trim();
                  ref.read(pendingPhoneProvider.notifier).set(identifier);
                  context.go('/enter-phone');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
