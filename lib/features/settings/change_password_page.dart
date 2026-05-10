import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../shared/presentation/flatmates_card.dart';
import '../shared/presentation/flatmates_header.dart';
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

  static final _uppercaseRegex = RegExp(r'[A-Z]');
  static final _numberRegex = RegExp(r'[0-9]');

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _uppercaseRegex.hasMatch(_passwordController.text);
  bool get _hasNumber => _numberRegex.hasMatch(_passwordController.text);

  Future<void> _submit() async {
    final locale = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(_passwordController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.passwordUpdated)));
      Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.passwordUpdateFailed)));
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
                  child: Icon(
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
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if ((value ?? '').length < 8) {
                          return locale.passwordMinLength;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Password rules checklist
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PasswordRuleItem(
                          passed: _hasMinLength,
                          label: locale.passwordRuleMinLength,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _PasswordRuleItem(
                          passed: _hasUppercase,
                          label: locale.passwordRuleUppercase,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _PasswordRuleItem(
                          passed: _hasNumber,
                          label: locale.passwordRuleNumber,
                        ),
                      ],
                    ),
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
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
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
              const SizedBox(height: AppSpacing.section),

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

/// Single password rule check item with green/red indicator.
class _PasswordRuleItem extends StatelessWidget {
  const _PasswordRuleItem({required this.passed, required this.label});

  final bool passed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.close,
          size: 18,
          color: passed ? AppSemanticColors.success : AppSemanticColors.error,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: passed
                ? AppSemanticColors.success
                : AppSemanticColors.textSecondaryFor(theme.brightness),
            fontWeight: passed ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
