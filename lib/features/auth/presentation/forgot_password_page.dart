import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth_controller.dart';
import '../password_reset_controller.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({this.phone, this.email, super.key});

  final String? phone;
  final String? email;

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  late final TextEditingController _controller;

  bool get _isEmail => widget.email != null && widget.email!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _isEmail ? widget.email : (widget.phone ?? '+91'),
    );
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
      appBar: const FlatmatesHeader.backTitle(title: ''),
      scrollable: true,
      body: AutofillGroup(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.forgotPasswordTitle,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              locale.forgotPasswordSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
            const SizedBox(height: AppSpacing.screen),
            FlatmatesCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const Key('forgot_password_phone_input'),
                    controller: _controller,
                    keyboardType: _isEmail
                        ? TextInputType.emailAddress
                        : TextInputType.phone,
                    autofillHints: _isEmail
                        ? const [AutofillHints.email]
                        : const [AutofillHints.telephoneNumber],
                    decoration: InputDecoration(
                      labelText: _isEmail
                          ? locale.emailLabel
                          : locale.identifierLabel,
                    ),
                  ),
                  if (resetState.step == PasswordResetStep.error &&
                      resetState.failure != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      resetState.failure!.userMessage(
                        locale.toUserMessageL10n(),
                      ),
                      style: const TextStyle(color: AppSemanticColors.error),
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
                      final identifier = _controller.text.trim();
                      await ref
                          .read(passwordResetControllerProvider.notifier)
                          .sendOtp(identifier);
                      if (!context.mounted) return;
                      final state = ref.read(passwordResetControllerProvider);
                      if (state.step == PasswordResetStep.otpSent) {
                        // Prefer controller-normalized E.164 / email so the
                        // reset page and pending-phone match what the OTP
                        // was actually sent to.
                        final normalized = state.identifier ?? identifier;
                        final isEmail = state.channel == AuthChannel.email;
                        if (!isEmail) {
                          ref
                              .read(pendingPhoneProvider.notifier)
                              .set(normalized);
                        }
                        final query = Uri(
                          path: '/reset-password',
                          queryParameters: {
                            isEmail ? 'email' : 'phone': normalized,
                          },
                        ).toString();
                        unawaited(context.push(query));
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
      ),
    );
  }
}
