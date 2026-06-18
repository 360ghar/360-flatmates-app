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

final _savingProvider = StateProvider<bool>((ref) => false);
final _obscureNewPasswordProvider = StateProvider<bool>((ref) => true);
final _obscureConfirmPasswordProvider = StateProvider<bool>((ref) => true);
final _buildTriggerProvider = StateProvider<int>((ref) => 0);

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // These are top-level (shared) StateProviders. Reset them on every fresh
    // visit so an interrupted save can't leave the submit button permanently
    // disabled, and obscure toggles start in the secure default state.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(_savingProvider.notifier).state = false;
      ref.read(_obscureNewPasswordProvider.notifier).state = true;
      ref.read(_obscureConfirmPasswordProvider.notifier).state = true;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final locale = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(_savingProvider.notifier).state = true;
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
        ref.read(_savingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    ref.watch(_buildTriggerProvider);

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
                      obscureText: ref.watch(_obscureNewPasswordProvider),
                      decoration: InputDecoration(
                        labelText: locale.newPasswordLabel,
                        suffixIcon: IconButton(
                          icon: Icon(
                            ref.watch(_obscureNewPasswordProvider)
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            final notifier = ref.read(
                              _obscureNewPasswordProvider.notifier,
                            );
                            notifier.state = !notifier.state;
                          },
                          tooltip: 'Toggle password visibility',
                        ),
                      ),
                      onChanged: (_) =>
                          ref.read(_buildTriggerProvider.notifier).state++,
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
                      obscureText: ref.watch(_obscureConfirmPasswordProvider),
                      decoration: InputDecoration(
                        labelText: locale.confirmPasswordLabel,
                        suffixIcon: IconButton(
                          icon: Icon(
                            ref.watch(_obscureConfirmPasswordProvider)
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            final notifier = ref.read(
                              _obscureConfirmPasswordProvider.notifier,
                            );
                            notifier.state = !notifier.state;
                          },
                          tooltip: 'Toggle password visibility',
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
                onPressed: ref.watch(_savingProvider) ? null : _submit,
                icon: ref.watch(_savingProvider) ? null : Icons.lock_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
