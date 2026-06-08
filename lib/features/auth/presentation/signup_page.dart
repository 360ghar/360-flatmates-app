import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_controller.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';
import 'widgets/password_policy.dart';
import 'widgets/terms_checkbox.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({required this.phone, super.key});

  final String? phone;

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  late final TextEditingController _phoneController;
  final _passwordController = TextEditingController();
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.phone ?? '+91');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return FlatmatesScreen(
      appBar: AppBar(),
      scrollable: true,
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.signupTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.screen),
            FlatmatesCard(
              child: Column(
                children: [
                  TextField(
                    key: const Key('signup_name_input'),
                    controller: _nameController,
                    autofillHints: const [AutofillHints.name],
                    decoration: InputDecoration(
                      labelText: locale.fullNameLabel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    key: const Key('signup_email_input'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(labelText: locale.emailLabel),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    key: const Key('signup_phone_input'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    decoration: InputDecoration(
                      labelText: locale.phoneNumberLabel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    key: const Key('signup_password_input'),
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: locale.passwordLabel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PasswordRulesChecklist(password: _passwordController.text),
                  const SizedBox(height: AppSpacing.lg),
                  TermsCheckbox(
                    accepted: _termsAccepted,
                    onChanged: (v) => setState(() => _termsAccepted = v),
                    locale: locale,
                    theme: theme,
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
            const SizedBox(height: AppSpacing.screen),
            FlatmatesButton(
              key: const Key('signup_submit_button'),
              label: locale.createAccountCta,
              fullWidth: true,
              onPressed:
                  auth.status == AuthStatus.submitting ||
                      !_termsAccepted ||
                      !PasswordPolicy.isValid(_passwordController.text)
                  ? null
                  : () {
                      ref
                          .read(authControllerProvider.notifier)
                          .signUpWithPassword(
                            fullName: _nameController.text.trim(),
                            phone: _phoneController.text.trim(),
                            password: _passwordController.text,
                            email: _emailController.text.trim(),
                          );
                    },
            ),
          ],
        ),
      ),
    );
  }
}
