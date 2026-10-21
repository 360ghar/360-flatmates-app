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
  bool _isConfirmed = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return FlatmatesScreen(
      appBar: FlatmatesHeader.backTitle(title: locale.deleteAccountTitle),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.lg,
        ),
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: AppSemanticColors.dangerFor(theme.brightness),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            locale.deleteAccountTitle,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            locale.deleteAccountWarning,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            locale.deleteAccountConfirmLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const Key('delete_account_confirm_field'),
            controller: _confirmController,
            enabled: !_isDeleting,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              final confirmed = value.trim().toUpperCase() == 'DELETE';
              if (confirmed != _isConfirmed) {
                setState(() => _isConfirmed = confirmed);
              }
            },
            decoration: InputDecoration(
              hintText: locale.deleteAccountConfirmHint,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FlatmatesButton.secondary(
            key: const Key('delete_account_confirm_button'),
            label: _isDeleting
                ? locale.deleteAccountInProgress
                : locale.deleteAccountButton,
            fullWidth: true,
            onPressed: _isConfirmed && !_isDeleting ? _handleDelete : null,
            destructive: true,
          ),
          const SizedBox(height: AppSpacing.md),
          FlatmatesButton.tertiary(
            key: const Key('delete_account_cancel_button'),
            label: locale.cancelCta,
            onPressed: _isDeleting ? null : () => context.pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete() async {
    final locale = AppLocalizations.of(context);
    if (!_isConfirmed || _isDeleting) return;

    // Final irreversible-action confirmation dialog.
    final confirmed = await FlatmatesDialog.confirm(
      context,
      title: locale.deleteAccountTitle,
      message: locale.deleteAccountDialogBody,
      cancelLabel: locale.cancelCta,
      confirmLabel: locale.deleteAccountButton,
      destructive: true,
      cancelKey: const Key('delete_account_dialog_cancel'),
      confirmKey: const Key('delete_account_dialog_confirm'),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isDeleting = true);

    final success = await ref
        .read(authControllerProvider.notifier)
        .deleteAccount();

    if (!mounted) return;

    if (success) {
      context.go('/enter-phone');
    } else {
      setState(() => _isDeleting = false);
      // deleteAccount() returns a bool and never populates a per-call error
      // message; show the delete-failure copy directly. Reading auth.errorMessage
      // here would surface a stale key left by an unrelated prior auth attempt.
      FlatmatesToast.error(context, locale.deleteAccountFailed);
    }
  }
}
