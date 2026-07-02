import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../shared/presentation/components.dart';

/// Tracks whether the account deletion request is in flight.
final _deletingProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Tracks whether the user has typed the confirmation word ("DELETE").
final _confirmedProvider = StateProvider.autoDispose<bool>((ref) => false);

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  final _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset the page-scoped flags so stale state from a prior visit (e.g. a
    // confirmed-but-cancelled attempt) never leaks into a fresh visit.
    ref.read(_confirmedProvider.notifier).state = false;
    ref.read(_deletingProvider.notifier).state = false;
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDeleting = ref.watch(_deletingProvider);
    final isConfirmed = ref.watch(_confirmedProvider);

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
            key: const Key('delete_account_confirm_field'),
            controller: _confirmController,
            enabled: !isDeleting,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              final confirmed = value.trim().toUpperCase() == 'DELETE';
              ref.read(_confirmedProvider.notifier).state = confirmed;
            },
            decoration: InputDecoration(
              hintText: locale.deleteAccountConfirmHint,
              border: const OutlineInputBorder(
                borderRadius: AppRadius.smBorder,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.smBorder,
                borderSide: BorderSide(
                  color: AppSemanticColors.line.withValues(alpha: 0.35),
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: AppRadius.smBorder,
                borderSide: BorderSide(color: AppSemanticColors.accent),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          FlatmatesButton.secondary(
            key: const Key('delete_account_confirm_button'),
            label: isDeleting
                ? locale.deleteAccountInProgress
                : locale.deleteAccountButton,
            fullWidth: true,
            onPressed: isConfirmed && !isDeleting ? _handleDelete : null,
            destructive: true,
          ),
          const SizedBox(height: AppSpacing.md),
          FlatmatesButton.secondary(
            key: const Key('delete_account_cancel_button'),
            label: locale.cancelCta,
            fullWidth: true,
            onPressed: isDeleting ? null : () => context.pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete() async {
    final locale = AppLocalizations.of(context);
    if (!ref.read(_confirmedProvider) || ref.read(_deletingProvider)) return;

    // Final irreversible-action confirmation dialog.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(locale.deleteAccountTitle),
        content: Text(locale.deleteAccountDialogBody),
        actions: [
          TextButton(
            key: const Key('delete_account_dialog_cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(locale.cancelCta),
          ),
          TextButton(
            key: const Key('delete_account_dialog_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppSemanticColors.error,
            ),
            child: Text(locale.deleteAccountButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    ref.read(_deletingProvider.notifier).state = true;

    final success = await ref
        .read(authControllerProvider.notifier)
        .deleteAccount();

    if (!mounted) return;

    if (success) {
      context.go('/enter-phone');
    } else {
      ref.read(_deletingProvider.notifier).state = false;
      FlatmatesToast.error(context, locale.deleteAccountFailed);
    }
  }
}
