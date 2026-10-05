import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_config/patch_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../shared/presentation/components.dart';
import '../shared/presentation/profile_sections.dart';

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
                _GroupLabel(label: locale.settingsGroupAccount),
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
                      const _MenuDivider(),
                      FlatmatesMenuItem(
                        icon: Icons.lock_outline,
                        label: locale.changePasswordLabel,
                        onTap: () => context.push('/change-password'),
                      ),
                      const _MenuDivider(),
                      FlatmatesMenuItem(
                        key: const Key('settings_privacy_security_item'),
                        icon: Icons.shield_outlined,
                        label: locale.privacySecurityLabel,
                        onTap: () => context.push('/privacy-security'),
                      ),
                      const _MenuDivider(),
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

                const SizedBox(height: AppSpacing.lg),

                // App group
                _GroupLabel(label: locale.settingsGroupApp),
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

                const SizedBox(height: AppSpacing.lg),

                // Legal group
                _GroupLabel(label: locale.settingsGroupLegal),
                FlatmatesCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlatmatesMenuItem(
                        icon: Icons.info_outline,
                        label: locale.aboutLabel,
                        onTap: () => _showAboutDialog(context, ref),
                      ),
                      const _MenuDivider(),
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

  Future<void> _showAboutDialog(BuildContext context, WidgetRef ref) async {
    final locale = AppLocalizations.of(context);
    final packageInfo = await PackageInfo.fromPlatform();
    // Null on the base release and on any non-Shorebird build.
    final patchNumber = await ref
        .read(patchServiceProvider)
        .currentPatchNumber();
    if (!context.mounted) return;
    final build = '${packageInfo.version}+${packageInfo.buildNumber}';
    final version = patchNumber == null
        ? build
        : '$build (${locale.patchLabel(patchNumber)})';
    await FlatmatesDialog.custom<void>(
      context,
      title: locale.appName,
      body: (ctx, _) => Text(
        locale.appVersionLabel(version),
        style: Theme.of(ctx).textTheme.bodyLarge,
      ),
      actions: (ctx, _, close) => [
        FlatmatesButton.tertiary(
          key: const Key('about_licenses_button'),
          label: MaterialLocalizations.of(ctx).viewLicensesButtonLabel,
          onPressed: () {
            close();
            showLicensePage(
              context: context,
              applicationName: locale.appName,
              applicationVersion: version,
            );
          },
        ),
        FlatmatesButton(label: locale.closeCta, onPressed: close),
      ],
    );
  }

  void _openTermsOfService(BuildContext context) {
    context.push('/terms-of-service');
  }

  Future<void> _confirmAndLogout(BuildContext context, WidgetRef ref) async {
    final locale = AppLocalizations.of(context);
    final confirmed = await FlatmatesDialog.confirm(
      context,
      title: locale.logoutCta,
      cancelLabel: locale.cancelCta,
      confirmLabel: locale.logoutCta,
      destructive: true,
      cancelKey: const Key('logout_dialog_cancel'),
      confirmKey: const Key('logout_dialog_confirm'),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(authControllerProvider.notifier).signOut();
  }
}

/// Label above a settings group, aligned with the card edge.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: SectionHeader(label: label),
  );
}

/// Divider between menu rows, aligned with the row labels.
class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: FlatmatesMenuItem.labelInset(),
    endIndent: AppSpacing.base,
  );
}
