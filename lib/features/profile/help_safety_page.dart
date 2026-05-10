import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_card.dart';
import '../shared/presentation/flatmates_header.dart';
import '../shared/presentation/flatmates_trust_badge.dart';
import '../shared/presentation/flatmates_ui.dart';

class HelpSafetyPage extends StatelessWidget {
  const HelpSafetyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: FlatmatesHeader.backTitle(title: locale.helpSafetyTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          children: [
            const SizedBox(height: AppSpacing.lg),
            FlatmatesCard.elevated(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppSemanticColors.accent.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      Icons.shield_rounded,
                      size: 24,
                      color: AppSemanticColors.accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      locale.safetyIsPriority,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppSemanticColors.textPrimaryFor(
                          theme.brightness,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FlatmatesMenuItem(
              icon: Icons.help_outline,
              label: locale.faqTitle,
              subtitle: locale.faqSubtitle,
              onTap: () => _navigateToSubPage(context, '/help-faq'),
            ),
            FlatmatesMenuItem(
              icon: Icons.local_fire_department,
              label: locale.popularTopicsLabel,
              subtitle: locale.popularTopicsSubtitle,
              onTap: () => _navigateToSubPage(context, '/help-popular-topics'),
            ),
            FlatmatesMenuItem(
              icon: Icons.account_balance_wallet_outlined,
              label: locale.paymentsLabel,
              subtitle: locale.paymentsSubtitle,
              onTap: () => _navigateToSubPage(context, '/help-payments'),
            ),
            FlatmatesMenuItem(
              icon: Icons.assignment_outlined,
              label: locale.bookingAgreementsLabel,
              subtitle: locale.bookingAgreementsSubtitle,
              onTap: () => _navigateToSubPage(context, '/help-bookings'),
            ),
            FlatmatesMenuItem(
              icon: Icons.person_outline,
              label: locale.accountProfileLabel,
              subtitle: locale.accountProfileSubtitle,
              onTap: () => _navigateToSubPage(context, '/help-account'),
            ),
            FlatmatesMenuItem(
              icon: Icons.headset_mic,
              label: locale.contactSupport,
              subtitle: locale.contactSupportSubtitle,
              onTap: () => _navigateToSubPage(context, '/help-contact'),
            ),
            const SizedBox(height: AppSpacing.section),
            FlatmatesButton(
              key: const Key('help_chat_with_us_button'),
              label: locale.chatWithUsCta,
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(locale.comingSoon)));
              },
              icon: Icons.chat,
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: FlatmatesTrustBadge(
                variant: FlatmatesTrustBadgeVariant.privacy,
                label: locale.supportAvailable247,
              ),
            ),
            const SizedBox(height: AppSpacing.screen),
          ],
        ),
      ),
    );
  }

  void _navigateToSubPage(BuildContext context, String route) {
    context.push(route);
  }
}
