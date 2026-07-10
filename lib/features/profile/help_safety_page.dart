import 'package:flutter/material.dart';
import 'package:flatmates_app/core/config/constants.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_card.dart';
import '../shared/presentation/flatmates_header.dart';
import '../shared/presentation/flatmates_toast.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
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
                    child: const Icon(
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
              key: const Key('help_faq_item'),
              icon: Icons.help_outline,
              label: locale.faqTitle,
              subtitle: locale.faqSubtitle,
              onTap: () => _navigateToSubPage(context, '/help-safety/faq'),
            ),
            FlatmatesMenuItem(
              icon: Icons.local_fire_department,
              label: locale.popularTopicsLabel,
              subtitle: locale.popularTopicsSubtitle,
              onTap: () =>
                  _navigateToSubPage(context, '/help-safety/popular-topics'),
            ),
            FlatmatesMenuItem(
              icon: Icons.assignment_outlined,
              label: locale.bookingAgreementsLabel,
              subtitle: locale.bookingAgreementsSubtitle,
              onTap: () => _navigateToSubPage(context, '/help-safety/bookings'),
            ),
            FlatmatesMenuItem(
              icon: Icons.person_outline,
              label: locale.accountProfileLabel,
              subtitle: locale.accountProfileSubtitle,
              onTap: () => _navigateToSubPage(context, '/help-safety/account'),
            ),
            FlatmatesMenuItem(
              key: const Key('help_contact_item'),
              icon: Icons.headset_mic,
              label: locale.contactSupport,
              subtitle: locale.contactSupportSubtitle,
              onTap: () => _navigateToSubPage(context, '/help-safety/contact'),
            ),
            FlatmatesMenuItem(
              key: const Key('report_a_bug_menu_item'),
              icon: Icons.bug_report_outlined,
              label: locale.reportABug,
              subtitle: locale.reportABugSubtitle,
              onTap: () =>
                  _navigateToSubPage(context, '/help-safety/report-bug'),
            ),
            FlatmatesMenuItem(
              key: const Key('request_a_feature_menu_item'),
              icon: Icons.lightbulb_outline,
              label: locale.requestAFeature,
              subtitle: locale.requestAFeatureSubtitle,
              onTap: () =>
                  _navigateToSubPage(context, '/help-safety/request-feature'),
            ),
            const SizedBox(height: AppSpacing.xl),
            FlatmatesButton(
              key: const Key('help_chat_with_us_button'),
              label: locale.contactSupport,
              onPressed: () =>
                  _navigateToSubPage(context, '/help-safety/contact'),
              icon: Icons.headset_mic,
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

enum HelpSafetyTopic {
  faq,
  popularTopics,
  bookingAgreements,
  accountProfile,
  contact,
}

class HelpSafetyTopicPage extends StatelessWidget {
  const HelpSafetyTopicPage({required this.topic, super.key});

  final HelpSafetyTopic topic;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final content = _HelpTopicContent.forTopic(topic, locale);

    return Scaffold(
      appBar: FlatmatesHeader.backTitle(title: content.title),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          children: [
            const SizedBox(height: AppSpacing.lg),
            FlatmatesCard.elevated(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(content.icon, color: AppSemanticColors.accent, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      content.summary,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppSemanticColors.textPrimaryFor(
                          theme.brightness,
                        ),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final article in content.articles) ...[
              _HelpArticleCard(article: article),
              const SizedBox(height: AppSpacing.md),
            ],
            if (topic == HelpSafetyTopic.accountProfile) ...[
              _AccountActions(locale: locale),
              const SizedBox(height: AppSpacing.md),
            ],
            if (topic == HelpSafetyTopic.contact) ...[
              _ContactActions(locale: locale),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.screen),
          ],
        ),
      ),
    );
  }
}

class _HelpTopicContent {
  const _HelpTopicContent({
    required this.title,
    required this.summary,
    required this.icon,
    required this.articles,
  });

  final String title;
  final String summary;
  final IconData icon;
  final List<_HelpArticle> articles;

  static _HelpTopicContent forTopic(
    HelpSafetyTopic topic,
    AppLocalizations locale,
  ) {
    return switch (topic) {
      HelpSafetyTopic.faq => _HelpTopicContent(
        title: locale.faqTitle,
        summary: locale.helpFaqIntro,
        icon: Icons.help_outline,
        articles: [
          _HelpArticle(locale.helpFaqStartTitle, locale.helpFaqStartBody),
          _HelpArticle(locale.helpFaqSafetyTitle, locale.helpFaqSafetyBody),
          _HelpArticle(locale.helpFaqReportTitle, locale.helpFaqReportBody),
          _HelpArticle(locale.helpFaqListingTitle, locale.helpFaqListingBody),
        ],
      ),
      HelpSafetyTopic.popularTopics => _HelpTopicContent(
        title: locale.popularTopicsLabel,
        summary: locale.helpPopularIntro,
        icon: Icons.local_fire_department,
        articles: [
          _HelpArticle(
            locale.helpPopularMeetingsTitle,
            locale.helpPopularMeetingsBody,
          ),
          _HelpArticle(
            locale.helpPopularVerifiedTitle,
            locale.helpPopularVerifiedBody,
          ),
          _HelpArticle(
            locale.helpPopularVisitsTitle,
            locale.helpPopularVisitsBody,
          ),
        ],
      ),
      HelpSafetyTopic.bookingAgreements => _HelpTopicContent(
        title: locale.bookingAgreementsLabel,
        summary: locale.helpBookingsIntro,
        icon: Icons.assignment_outlined,
        articles: [
          _HelpArticle(
            locale.helpBookingsDecisionTitle,
            locale.helpBookingsDecisionBody,
          ),
          _HelpArticle(
            locale.helpBookingsAgreementsTitle,
            locale.helpBookingsAgreementsBody,
          ),
          _HelpArticle(
            locale.helpBookingsListingReviewTitle,
            locale.helpBookingsListingReviewBody,
          ),
        ],
      ),
      HelpSafetyTopic.accountProfile => _HelpTopicContent(
        title: locale.accountProfileLabel,
        summary: locale.helpAccountIntro,
        icon: Icons.person_outline,
        articles: [
          _HelpArticle(locale.helpAccountEditTitle, locale.helpAccountEditBody),
          _HelpArticle(
            locale.helpAccountPrivacyTitle,
            locale.helpAccountPrivacyBody,
          ),
          _HelpArticle(
            locale.helpAccountBlockedTitle,
            locale.helpAccountBlockedBody,
          ),
        ],
      ),
      HelpSafetyTopic.contact => _HelpTopicContent(
        title: locale.contactSupport,
        summary: locale.helpContactIntro,
        icon: Icons.headset_mic,
        articles: [
          _HelpArticle(
            locale.helpContactWhatToSendTitle,
            locale.helpContactWhatToSendBody,
          ),
          _HelpArticle(
            locale.helpContactUrgentTitle,
            locale.helpContactUrgentBody,
          ),
        ],
      ),
    };
  }
}

class _HelpArticle {
  const _HelpArticle(this.title, this.body);

  final String title;
  final String body;
}

class _HelpArticleCard extends StatelessWidget {
  const _HelpArticleCard({required this.article});

  final _HelpArticle article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlatmatesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppSemanticColors.textPrimaryFor(theme.brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            article.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountActions extends StatelessWidget {
  const _AccountActions({required this.locale});

  final AppLocalizations locale;

  @override
  Widget build(BuildContext context) {
    return FlatmatesCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlatmatesMenuItem(
            icon: Icons.person_outline,
            label: locale.editProfileCta,
            onTap: () => context.push('/profile/edit'),
          ),
          const Divider(height: 1, indent: 68, endIndent: 16),
          FlatmatesMenuItem(
            icon: Icons.lock_outline,
            label: locale.changePasswordLabel,
            onTap: () => context.push('/change-password'),
          ),
          const Divider(height: 1, indent: 68, endIndent: 16),
          FlatmatesMenuItem(
            icon: Icons.person_off_outlined,
            label: locale.blockedUsersLabel,
            onTap: () => context.push('/blocked-users'),
          ),
        ],
      ),
    );
  }
}

class _ContactActions extends StatelessWidget {
  const _ContactActions({required this.locale});

  final AppLocalizations locale;

  @override
  Widget build(BuildContext context) {
    return FlatmatesCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlatmatesMenuItem(
            icon: Icons.email_outlined,
            label: locale.emailSupportCta,
            subtitle: kSupportEmail,
            onTap: () => _launchSupportEmail(context, locale),
          ),
          const Divider(height: 1, indent: 68, endIndent: 16),
          FlatmatesMenuItem(
            icon: Icons.privacy_tip_outlined,
            label: locale.privacyPolicy,
            onTap: () => context.push('/privacy-policy'),
          ),
          const Divider(height: 1, indent: 68, endIndent: 16),
          FlatmatesMenuItem(
            icon: Icons.description_outlined,
            label: locale.termsOfService,
            onTap: () => context.push('/terms-of-service'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchSupportEmail(
    BuildContext context,
    AppLocalizations locale,
  ) async {
    final uri = Uri(
      scheme: 'mailto',
      path: kSupportEmail,
      queryParameters: {
        'subject': locale.supportEmailSubject,
        'body': locale.supportEmailBody,
      },
    );
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch && await launchUrl(uri)) {
      return;
    }
    if (!context.mounted) return;
    FlatmatesToast.info(context, locale.supportEmailFallback(kSupportEmail));
  }
}
