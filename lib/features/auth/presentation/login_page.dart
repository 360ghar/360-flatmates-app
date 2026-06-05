import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  bool _obscurePassword = true;

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

    return FlatmatesScreen(
      appBar: AppBar(),
      scrollable: true,
      body: Column(
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
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: locale.phoneNumberLabel,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  key: const Key('login_password_input'),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: locale.passwordLabel,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
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
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FlatmatesButton.tertiary(
              label: locale.forgotPasswordCta,
              onPressed: () {
                final phone = _phoneController.text.trim();
                ref.read(pendingPhoneProvider.notifier).state = phone;
                context.push('/forgot-password?phone=$phone');
              },
            ),
          ),
          const SizedBox(height: AppSpacing.screen),
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
          const SizedBox(height: AppSpacing.md),
          FlatmatesGoogleSignInButton(
            key: const Key('login_google_signin_button'),
            label: locale.signInWithGoogleCta,
            isLoading: auth.status == AuthStatus.submitting,
            onPressed: () {
              ref.read(authControllerProvider.notifier).signInWithGoogle();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: FlatmatesButton.tertiary(
              label: locale.noAccountCta,
              onPressed: () {
                final phone = _phoneController.text.trim();
                ref.read(pendingPhoneProvider.notifier).state = phone;
                context.push('/signup?phone=$phone');
              },
            ),
          ),
        ],
      ),
    );
  }
}


