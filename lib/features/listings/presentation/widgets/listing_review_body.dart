import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flatmates_app/core/theme/theme.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../discover/application/property_listing_seed_store.dart';
import '../../../discover/domain/property_listing.dart';
import '../../../shared/presentation/components.dart';

/// Body content for [ListingUnderReviewPage], branched by live / rejected /
/// under-review status.
class ListingReviewBody extends ConsumerWidget {
  const ListingReviewBody({
    required this.listing,
    required this.listingId,
    super.key,
  });

  final PropertyListing listing;
  final int listingId;

  String? get _moderationReason {
    final raw = listing.preferences?['moderation_reason'];
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _openListing(BuildContext context, WidgetRef ref) {
    // Keep seed durable before push so GoRouter rebuilds / lost `extra` still
    // render the under-review preview instead of a 404 error screen.
    ref.read(propertyListingSeedStoreProvider.notifier).put(listing);
    context.push('/flat-details/$listingId', extra: listing);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isLive = listing.isLive;
    final isRejected = listing.isRejected;
    final moderationReason = _moderationReason;

    final title = isLive ? locale.listingLive : locale.listingUnderReviewTitle;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.sm,
          ),
          child: Column(
            children: [
              const FlatmatesLogo(compact: true, centered: true),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.screen,
            ),
            children: [
              _StatusIcon(isLive: isLive, isRejected: isRejected),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Text(
                  isLive
                      ? locale.listingApproved
                      : isRejected
                      ? locale.listingRejectedMessage
                      : locale.reviewSubmittedMessage,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (isLive) ...[
                const SizedBox(height: AppSpacing.md),
                Center(child: FlatmatesTrustBadge(label: locale.listingLive)),
              ] else if (!isRejected) ...[
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text(
                    locale.reviewSupportText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text(
                    locale.pleaseReviewAndResubmit,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppSemanticColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (isLive)
                const _LiveProgress()
              else if (!isRejected)
                const _UnderReviewProgress(),
              if (!isRejected) ...[
                const SizedBox(height: AppSpacing.xl),
                FlatmatesButton.secondary(
                  label: isLive ? locale.viewListing : locale.reviewListingCta,
                  onPressed: () => _openListing(context, ref),
                  icon: Icons.visibility_outlined,
                  fullWidth: true,
                ),
              ],
              if (isRejected) ...[
                const SizedBox(height: AppSpacing.xl),
                _RejectionCard(
                  reason: moderationReason ?? locale.rejectionDetailText,
                ),
              ],
              const SizedBox(height: AppSpacing.section),
              if (!isLive && !isRejected) ...[
                const _EtaBanner(),
                const SizedBox(height: AppSpacing.section),
                Text(
                  locale.whatHappensNext,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _StepItem(number: 1, text: locale.step1Text, theme: theme),
                _StepItem(number: 2, text: locale.step2Text, theme: theme),
                _StepItem(number: 3, text: locale.step3Text, theme: theme),
                const SizedBox(height: AppSpacing.section),
              ],
              Text(
                locale.yourListingLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ListingPreviewCard(listing: listing),
              const SizedBox(height: AppSpacing.screen),
              _ReviewCtas(
                listingId: listingId,
                isLive: isLive,
                isRejected: isRejected,
                onOpenListing: () => _openListing(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.isLive, required this.isRejected});

  final bool isLive;
  final bool isRejected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: AppSpacing.xl * 4 + AppSpacing.sm,
        height: AppSpacing.xl * 4 + AppSpacing.sm,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isLive
              ? AppSemanticColors.success.withValues(alpha: 0.1)
              : isRejected
              ? AppSemanticColors.error.withValues(alpha: 0.1)
              : AppSemanticColors.accent.withValues(alpha: 0.1),
        ),
        child: Icon(
          isLive
              ? Icons.check_circle_outline
              : isRejected
              ? Icons.error_outline
              : Icons.task_alt,
          size: 44,
          color: isLive
              ? AppSemanticColors.success
              : isRejected
              ? AppSemanticColors.error
              : AppSemanticColors.accent,
        ),
      ),
    );
  }
}

class _UnderReviewProgress extends StatelessWidget {
  const _UnderReviewProgress();

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1 / 3),
          duration: AppMotion.durationOrZero(context, AppMotion.fadeInEntry),
          curve: AppMotion.easeOutCubic,
          builder: (context, animatedValue, child) {
            return ClipRRect(
              borderRadius: AppRadius.smBorder,
              child: LinearProgressIndicator(
                value: animatedValue,
                minHeight: 4,
                backgroundColor: AppSemanticColors.hairlineFor(
                  Theme.of(context).brightness,
                ).withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation(
                  AppSemanticColors.accent,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              locale.submittedLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppSemanticColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              locale.underReviewStepLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
            Text(
              locale.liveStepLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: FlatmatesTrustBadge(
            variant: FlatmatesTrustBadgeVariant.reviewed,
            label: locale.underReviewStepLabel,
          ),
        ),
      ],
    );
  }
}

class _LiveProgress extends StatelessWidget {
  const _LiveProgress();

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: AppMotion.durationOrZero(context, AppMotion.fadeInEntry),
          curve: AppMotion.easeOutCubic,
          builder: (context, animatedValue, child) {
            return ClipRRect(
              borderRadius: AppRadius.smBorder,
              child: LinearProgressIndicator(
                value: animatedValue,
                minHeight: 4,
                backgroundColor: AppSemanticColors.hairlineFor(
                  Theme.of(context).brightness,
                ).withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation(
                  AppSemanticColors.success,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              locale.submittedLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppSemanticColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              locale.underReviewStepLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppSemanticColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              locale.liveStepLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppSemanticColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RejectionCard extends StatelessWidget {
  const _RejectionCard({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppSemanticColors.error.withValues(alpha: 0.06),
        borderRadius: AppRadius.mdBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppSemanticColors.error,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                locale.rejectionReasonLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppSemanticColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            reason,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
            ),
          ),
        ],
      ),
    );
  }
}

class _EtaBanner extends StatelessWidget {
  const _EtaBanner();

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppSemanticColors.accent.withValues(alpha: 0.06),
        borderRadius: AppRadius.mdBorder,
        border: Border.all(
          color: AppSemanticColors.accent.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_outlined,
            size: 20,
            color: AppSemanticColors.accent,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              locale.etaHighlight,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppSemanticColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingPreviewCard extends StatelessWidget {
  const _ListingPreviewCard({required this.listing});

  final PropertyListing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlatmatesCard(
      child: Row(
        children: [
          if (listing.effectiveMainImageUrl != null)
            FlatmatesNetworkImage(
              imageUrl: listing.effectiveMainImageUrl!,
              width: 72,
              height: 72,
              borderRadius: AppRadius.mdBorder,
            )
          else
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppSemanticColors.accent.withValues(alpha: 0.15),
                borderRadius: AppRadius.mdBorder,
              ),
              child: const Icon(Icons.apartment_rounded),
            ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '\u{20B9}${listing.monthlyRent.toStringAsFixed(0)}/mo',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppSemanticColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCtas extends StatelessWidget {
  const _ReviewCtas({
    required this.listingId,
    required this.isLive,
    required this.isRejected,
    required this.onOpenListing,
  });

  final int listingId;
  final bool isLive;
  final bool isRejected;
  final VoidCallback onOpenListing;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    if (isRejected) {
      return FlatmatesButton(
        label: locale.editResubmit,
        onPressed: () => context.push('/post/new?listingId=$listingId'),
        icon: Icons.edit_outlined,
      );
    }
    if (isLive) {
      return Column(
        children: [
          FlatmatesButton(
            label: locale.viewListing,
            onPressed: onOpenListing,
            icon: Icons.visibility_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          FlatmatesButton.secondary(
            label: locale.goToHomeFeed,
            onPressed: () => context.go('/discover'),
            fullWidth: true,
          ),
        ],
      );
    }
    return Column(
      children: [
        FlatmatesButton(
          label: locale.goToHomeFeed,
          onPressed: () => context.go('/discover'),
          icon: Icons.home_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        FlatmatesButton.secondary(
          label: locale.viewListing,
          onPressed: onOpenListing,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.text,
    required this.theme,
  });

  final int number;
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.0,
            height: 28.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppSemanticColors.accent.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppSemanticColors.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
