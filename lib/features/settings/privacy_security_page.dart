import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/components.dart';

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);

    return Scaffold(
      appBar: FlatmatesHeader.backTitle(title: locale.privacySecurityLabel),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          children: [
            const SizedBox(height: AppSpacing.lg),
            FlatmatesCard(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FlatmatesMenuItem(
                    key: const Key('privacy_change_password_item'),
                    icon: Icons.lock_outline,
                    label: locale.changePasswordLabel,
                    onTap: () => context.push('/change-password'),
                  ),
                  const Divider(
                    height: 1,
                    indent: AppSpacing.xl * 3 + AppSpacing.sm,
                    endIndent: AppSpacing.lg,
                  ),
                  FlatmatesMenuItem(
                    key: const Key('privacy_blocked_users_item'),
                    icon: Icons.person_off_outlined,
                    label: locale.blockedUsersLabel,
                    onTap: () => context.push('/blocked-users'),
                  ),
                  const Divider(
                    height: 1,
                    indent: AppSpacing.xl * 3 + AppSpacing.sm,
                    endIndent: AppSpacing.lg,
                  ),
                  FlatmatesMenuItem(
                    key: const Key('privacy_policy_item'),
                    icon: Icons.privacy_tip_outlined,
                    label: locale.privacyPolicy,
                    onTap: () => context.push('/privacy-policy'),
                  ),
                  const Divider(
                    height: 1,
                    indent: AppSpacing.xl * 3 + AppSpacing.sm,
                    endIndent: AppSpacing.lg,
                  ),
                  FlatmatesMenuItem(
                    key: const Key('privacy_terms_item'),
                    icon: Icons.description_outlined,
                    label: locale.termsOfService,
                    onTap: () => context.push('/terms-of-service'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FlatmatesCard(
              padding: EdgeInsets.zero,
              child: FlatmatesMenuItem(
                key: const Key('privacy_delete_account_item'),
                icon: Icons.delete_forever_outlined,
                label: locale.deleteAccountCta,
                isDestructive: true,
                onTap: () => context.push('/delete-account'),
              ),
            ),
            const SizedBox(height: AppSpacing.screen),
          ],
        ),
      ),
    );
  }
}
