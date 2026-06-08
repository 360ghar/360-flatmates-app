import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../shared/presentation/components.dart';

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  final _confirmController = TextEditingController();
  bool _isDeleting = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isConfirmed =>
      _confirmController.text.trim().toUpperCase() == 'DELETE';

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return FlatmatesScreen(
      appBar: FlatmatesHeader.backTitle(
        title: locale.deleteAccountTitle,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 56,
            color: AppSemanticColors.error,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            locale.deleteAccountTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            locale.deleteAccountWarning,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.section),
          Text(
            locale.deleteAccountConfirmLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _confirmController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: locale.deleteAccountConfirmHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide(
                  color: AppSemanticColors.line.withValues(alpha: 0.35),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: AppSemanticColors.accent),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          FlatmatesButton.secondary(
            key: const Key('delete_account_confirm_button'),
            label: locale.deleteAccountButton,
            fullWidth: true,
            onPressed: _isConfirmed && !_isDeleting ? _handleDelete : null,
            destructive: true,
          ),
          const SizedBox(height: AppSpacing.md),
          FlatmatesButton.secondary(
            key: const Key('delete_account_cancel_button'),
            label: locale.cancelCta,
            fullWidth: true,
            onPressed: _isDeleting ? null : () => context.pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete() async {
    if (!_isConfirmed || _isDeleting) return;
    setState(() => _isDeleting = true);

    final success = await ref
        .read(authControllerProvider.notifier)
        .deleteAccount();

    if (!mounted) return;

    if (success) {
      context.go('/enter-phone');
    } else {
      final locale = AppLocalizations.of(context);
      setState(() => _isDeleting = false);
      FlatmatesToast.error(context, locale.deleteAccountFailed);
    }
  }
}
