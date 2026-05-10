import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({required this.phone, super.key});

  final String? phone;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late final TextEditingController _phoneController;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.phone ?? '+91');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        minimum: AppSpacing.horizontalScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.loginTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.screen),
            FlatmatesCard(
              child: Column(
                children: [
                  TextField(
                    key: const Key('login_phone_input'),
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: locale.phoneNumberLabel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    key: const Key('login_password_input'),
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: locale.passwordLabel,
                    ),
                  ),
                  if (auth.status == AuthStatus.error &&
                      auth.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      auth.errorMessage!,
                      style: TextStyle(color: AppSemanticColors.error),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            FlatmatesButton(
              key: const Key('login_submit_button'),
              label: locale.signInCta,
              fullWidth: true,
              onPressed: auth.status == AuthStatus.submitting
                  ? null
                  : () {
                      ref
                          .read(authControllerProvider.notifier)
                          .signInWithPassword(
                            phone: _phoneController.text.trim(),
                            password: _passwordController.text,
                          );
                    },
            ),
          ],
        ),
      ),
    );
  }
}
