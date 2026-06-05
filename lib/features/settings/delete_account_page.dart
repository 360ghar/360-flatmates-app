import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/constants.dart';
import '../../core/config/endpoints.dart';
import '../../core/providers.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../shared/presentation/components.dart';

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;

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
          Icon(
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
            onPressed:
                _isConfirmed && !_isSubmitting ? _handleRequest : null,
            destructive: true,
          ),
          const SizedBox(height: AppSpacing.md),
          FlatmatesButton.secondary(
            key: const Key('delete_account_cancel_button'),
            label: locale.cancelCta,
            fullWidth: true,
            onPressed: _isSubmitting ? null : () => context.pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRequest() async {
    if (!_isConfirmed || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.delete(FlatmatesEndpoints.deleteAccount);
      if (!mounted) return;

      final locale = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.deleteAccountRequestSent)),
      );
      await ref.read(authControllerProvider.notifier).signOut();
      if (!mounted) return;
      context.go('/enter-phone');
    } catch (_) {
      if (!mounted) return;
      _fallbackEmailDeletion();
    }
  }

  Future<void> _fallbackEmailDeletion() async {
    final locale = AppLocalizations.of(context);
    final registeredEmail =
        ref.read(bootstrapControllerProvider).valueOrNull?.profile.email ??
        'Not available';

    final body = locale.deleteAccountEmailBody(registeredEmail);
    final uri = Uri(
      scheme: 'mailto',
      path: kSupportEmail,
      queryParameters: {
        'subject': locale.deleteAccountEmailSubject,
        'body': body,
      },
    );

    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    if (!mounted) return;

    if (launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.deleteAccountRequestSent)),
      );
      context.go('/profile/settings');
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            locale.deleteAccountEmailFallback(
              kSupportEmail,
              locale.deleteAccountEmailSubject,
            ),
          ),
        ),
      );
    }
  }
}