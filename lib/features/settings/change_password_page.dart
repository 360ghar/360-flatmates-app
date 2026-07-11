import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../auth/presentation/widgets/password_policy.dart';
import '../shared/presentation/flatmates_card.dart';
import '../shared/presentation/flatmates_header.dart';
import '../shared/presentation/flatmates_toast.dart';
import '../shared/presentation/flatmates_ui.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final locale = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(_passwordController.text);
      if (!mounted) return;
      FlatmatesToast.success(context, locale.passwordUpdated);
      unawaited(Navigator.of(context).maybePop());
    } catch (error) {
      if (!mounted) return;
      final msg = error is AppFailure
          ? error.userMessage(locale.toUserMessageL10n())
          : locale.passwordUpdateFailed;
      FlatmatesToast.error(context, msg);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);

    return Scaffold(
      appBar: FlatmatesHeader.backTitle(title: locale.changePasswordLabel),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              // Lock icon
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppSemanticColors.accent.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 32,
                    color: AppSemanticColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Form wrapped in FlatmatesCard
              FlatmatesCard(
                child: Column(
                  children: [
                    // New password field with visibility toggle
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: locale.newPasswordLabel,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscureNewPassword = !_obscureNewPassword,
                          ),
                          tooltip: locale.togglePasswordVisibility,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) =>
                          PasswordPolicy.validate(value ?? '', locale),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Password rules checklist (shared policy)
                    PasswordRulesChecklist(password: _passwordController.text),
                    const SizedBox(height: AppSpacing.lg),

                    // Confirm password field with visibility toggle
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: locale.confirmPasswordLabel,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                          tooltip: locale.togglePasswordVisibility,
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return locale.passwordsDoNotMatch;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // CTA
              FlatmatesButton(
                label: locale.updatePasswordCta,
                fullWidth: true,
                onPressed: _saving ? null : _submit,
                icon: _saving ? null : Icons.lock_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
