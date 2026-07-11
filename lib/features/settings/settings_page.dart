import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../shared/presentation/components.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);

    final theme = Theme.of(context);
    final listHubBg = AppSemanticColors.secondarySurfaceFor(theme.brightness);

    return FlatmatesScreen(
      backgroundColor: listHubBg,
      appBar: FlatmatesHeader.backTitle(title: locale.settingsTitle),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.md,
              ),
              children: [
                // Account group
                _SectionHeader(label: locale.settingsGroupAccount),
                FlatmatesCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlatmatesMenuItem(
                        icon: Icons.person_outline,
                        label: locale.editProfileCta,
                        onTap: () => context.push('/profile/edit'),
                      ),
                      const Divider(
                        height: 1,
                        indent: AppSpacing.xl * 3 + AppSpacing.sm,
                        endIndent: AppSpacing.lg,
                      ),
                      FlatmatesMenuItem(
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
                        key: const Key('settings_privacy_security_item'),
                        icon: Icons.shield_outlined,
                        label: locale.privacySecurityLabel,
                        onTap: () => context.push('/privacy-security'),
                      ),
                      const Divider(
                        height: 1,
                        indent: AppSpacing.xl * 3 + AppSpacing.sm,
                        endIndent: AppSpacing.lg,
                      ),
                      FlatmatesMenuItem(
                        key: const Key('delete_account_menu_item'),
                        icon: Icons.delete_forever_outlined,
                        label: locale.deleteAccountCta,
                        isDestructive: true,
                        onTap: () => context.push('/delete-account'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // App group
                _SectionHeader(label: locale.settingsGroupApp),
                FlatmatesCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlatmatesMenuItem(
                        icon: Icons.person_off_outlined,
                        label: locale.blockedUsersLabel,
                        onTap: () => context.push('/blocked-users'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Legal group
                _SectionHeader(label: locale.settingsGroupLegal),
                FlatmatesCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlatmatesMenuItem(
                        icon: Icons.info_outline,
                        label: locale.aboutLabel,
                        onTap: () => _showAboutDialog(context),
                      ),
                      const Divider(
                        height: 1,
                        indent: AppSpacing.xl * 3 + AppSpacing.sm,
                        endIndent: AppSpacing.lg,
                      ),
                      FlatmatesMenuItem(
                        icon: Icons.description_outlined,
                        label: locale.termsAndConditionsLabel,
                        onTap: () => _openTermsOfService(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Standalone Logout
                FlatmatesButton.tertiary(
                  key: const Key('logout_button'),
                  label: locale.logoutCta,
                  destructive: true,
                  onPressed: () => _confirmAndLogout(context, ref),
                ),

                const SizedBox(height: AppSpacing.screen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    final locale = AppLocalizations.of(context);
    final packageInfo = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: locale.appName,
      applicationVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
      applicationIcon: const FlutterLogo(size: 32),
    );
  }

  void _openTermsOfService(BuildContext context) {
    context.push('/terms-of-service');
  }

  Future<void> _confirmAndLogout(BuildContext context, WidgetRef ref) async {
    final locale = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.logoutCta),
        actions: [
          TextButton(
            key: const Key('logout_dialog_cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(locale.cancelCta),
          ),
          TextButton(
            key: const Key('logout_dialog_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppSemanticColors.error,
            ),
            child: Text(locale.logoutCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(authControllerProvider.notifier).signOut();
  }
}

/// Section group header with a divider line above and bold label.
/// Matches DESIGN.md Screen 19 group pattern.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
            ),
          ),
        ],
      ),
    );
  }
}
