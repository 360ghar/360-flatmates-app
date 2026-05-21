import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth_controller.dart';
import '../password_reset_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({this.phone, super.key});

  final String? phone;

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.phone ?? '+91');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resetState = ref.watch(passwordResetControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isSubmitting = resetState.step == PasswordResetStep.sendingOtp;

    return FlatmatesScreen(
      appBar: AppBar(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(locale.forgotPasswordTitle,
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(locale.forgotPasswordSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              )),
          const SizedBox(height: AppSpacing.screen),
          FlatmatesCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: const Key('forgot_password_phone_input'),
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: locale.phoneNumberLabel,
                  ),
                ),
                if (resetState.step == PasswordResetStep.error &&
                    resetState.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    resetState.errorMessage!,
                    style: TextStyle(color: AppSemanticColors.error),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.screen),
          FlatmatesButton(
            key: const Key('forgot_password_send_otp'),
            label: locale.sendOtpCta,
            fullWidth: true,
            onPressed: isSubmitting
                ? null
                : () async {
                    final phone = _controller.text.trim();
                    await ref
                        .read(passwordResetControllerProvider.notifier)
                        .sendOtp(phone);
                    if (!context.mounted) return;
                    final state =
                        ref.read(passwordResetControllerProvider);
                    if (state.step == PasswordResetStep.otpSent) {
                      ref.read(pendingPhoneProvider.notifier).state = phone;
                      context.push('/reset-password');
                    }
                  },
          ),
          const SizedBox(height: AppSpacing.md),
          FlatmatesButton.tertiary(
            label: locale.backCta,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
