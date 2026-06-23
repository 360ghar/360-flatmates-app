import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../shared/presentation/components.dart';

final _confirmTextProvider = StateProvider<String>((ref) => '');
final _isDeletingProvider = StateProvider<bool>((ref) => false);

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool _isConfirmed(String text) =>
      text.trim().toUpperCase() == 'DELETE';

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final confirmText = ref.watch(_confirmTextProvider);
    final isDeleting = ref.watch(_isDeletingProvider);
    final isConfirmed = _isConfirmed(confirmText);

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
            onChanged: (value) =>
                ref.read(_confirmTextProvider.notifier).state = value,
            decoration: InputDecoration(
              hintText: locale.deleteAccountConfirmHint,
              border: OutlineInputBorder(
                borderRadius: AppRadius.smBorder,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.smBorder,
                borderSide: BorderSide(
                  color: AppSemanticColors.line.withValues(alpha: 0.35),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.smBorder,
                borderSide: const BorderSide(color: AppSemanticColors.accent),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          FlatmatesButton.secondary(
            key: const Key('delete_account_confirm_button'),
            label: locale.deleteAccountButton,
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
    final confirmText = ref.read(_confirmTextProvider);
    if (!_isConfirmed(confirmText) || ref.read(_isDeletingProvider)) return;
    ref.read(_isDeletingProvider.notifier).state = true;

    final success = await ref
        .read(authControllerProvider.notifier)
        .deleteAccount();

    if (!mounted) return;

    if (success) {
      context.go('/enter-phone');
    } else {
      final locale = AppLocalizations.of(context);
      ref.read(_isDeletingProvider.notifier).state = false;
      FlatmatesToast.error(context, locale.deleteAccountFailed);
    }
  }
}
