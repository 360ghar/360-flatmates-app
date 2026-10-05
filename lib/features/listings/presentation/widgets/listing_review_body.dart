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
    final b = theme.brightness;
    final isLive = listing.isLive;
    final isRejected = listing.isRejected;
    final moderationReason = _moderationReason;

    final title = isLive ? locale.listingLive : locale.listingUnderReviewTitle;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.screen,
        AppSpacing.screen,
      ),
      children: [
        _StatusIcon(isLive: isLive, isRejected: isRejected),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isLive
              ? locale.listingApproved
              : isRejected
              ? locale.listingRejectedMessage
              : locale.reviewSubmittedMessage,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppSemanticColors.textPrimaryFor(b),
          ),
          textAlign: TextAlign.center,
        ),
        // Under review: the ETA banner below carries the timing.
        if (isRejected) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            locale.pleaseReviewAndResubmit,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppSemanticColors.dangerFor(b),
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (isLive)
          const _ReviewProgress(done: 3)
        else if (!isRejected)
          const _ReviewProgress(done: 1),
        if (isRejected) ...[
          const SizedBox(height: AppSpacing.lg),
          _RejectionCard(
            reason: moderationReason ?? locale.rejectionDetailText,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (!isLive && !isRejected) ...[
          const _EtaBanner(),
          const SizedBox(height: AppSpacing.xl),
          Text(locale.whatHappensNext, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          for (final (i, text) in [
            locale.step1Text,
            locale.step2Text,
            locale.step3Text,
          ].indexed)
            _StepItem(number: i + 1, text: text),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(locale.yourListingLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        _ListingPreviewCard(listing: listing),
        const SizedBox(height: AppSpacing.lg),
        _ReviewCtas(
          listingId: listingId,
          isLive: isLive,
          isRejected: isRejected,
          onOpenListing: () => _openListing(context, ref),
        ),
      ],
    );
  }
}

/// The status mark: a bare icon in the status colour (no tinted circle).
class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.isLive, required this.isRejected});

  final bool isLive;
  final bool isRejected;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Icon(
      isLive
          ? Icons.check_circle_outline_rounded
          : isRejected
          ? Icons.error_outline_rounded
          : Icons.task_alt_rounded,
      size: 64,
      color: isLive
          ? AppSemanticColors.pineFor(b)
          : isRejected
          ? AppSemanticColors.dangerFor(b)
          : AppSemanticColors.clayFor(b),
    );
  }
}

/// Submitted → Under review → Live track. [done] is how many of the three
/// stages are complete (1 while under review, 3 once live).
class _ReviewProgress extends StatelessWidget {
  const _ReviewProgress({required this.done});

  final int done;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final b = theme.brightness;
    final live = done >= 3;
    final fill = live
        ? AppSemanticColors.pineFor(b)
        : AppSemanticColors.clayFor(b);
    final labels = [
      locale.submittedLabel,
      locale.underReviewStepLabel,
      locale.liveStepLabel,
    ];
    return Column(
      children: [
        // The bar grows from zero; the labels below are visible at once.
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: done / 3),
          duration: AppMotion.durationOrZero(context, AppMotion.slow),
          curve: AppMotion.paperOut,
          builder: (context, value, _) => ClipRRect(
            borderRadius: AppRadius.smBorder,
            child: LinearProgressIndicator(
              value: value,
              minHeight: 4,
              backgroundColor: AppSemanticColors.paperDeepFor(b),
              valueColor: AlwaysStoppedAnimation(fill),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final (i, label) in labels.indexed)
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: i == 0
                      ? TextAlign.start
                      : i == labels.length - 1
                      ? TextAlign.end
                      : TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: i < done
                        ? AppSemanticColors.textPrimaryFor(b)
                        : AppSemanticColors.textSecondaryFor(b),
                    fontWeight: i < done ? FontWeight.w600 : FontWeight.w400,
                  ),
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
    final b = theme.brightness;
    final danger = AppSemanticColors.dangerFor(b);
    return Container(
      width: double.infinity,
      padding: AppSpacing.edgeLg,
      decoration: BoxDecoration(
        color: AppSemanticColors.errorSoftFor(b),
        borderRadius: AppRadius.mdBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: danger, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  locale.rejectionReasonLabel,
                  style: theme.textTheme.titleMedium?.copyWith(color: danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reason,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppSemanticColors.textPrimaryFor(b),
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
    final b = theme.brightness;
    return Container(
      width: double.infinity,
      padding: AppSpacing.edgeBase,
      decoration: BoxDecoration(
        color: AppSemanticColors.paper1For(b),
        borderRadius: AppRadius.mdBorder,
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 20,
            color: AppSemanticColors.clayFor(b),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              locale.etaHighlight,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppSemanticColors.textPrimaryFor(b),
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
    final locale = AppLocalizations.of(context);
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
                color: AppSemanticColors.paperDeepFor(theme.brightness),
                borderRadius: AppRadius.mdBorder,
              ),
              child: Icon(
                Icons.apartment_rounded,
                color: AppSemanticColors.textTertiaryFor(theme.brightness),
              ),
            ),
          const SizedBox(width: AppSpacing.md),
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
                  '${FlatmatesPriceText.formatRupee(listing.monthlyRent.round())}${locale.perMonthSuffix}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppSemanticColors.textPrimaryFor(theme.brightness),
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
        fullWidth: true,
      );
    }
    if (isLive) {
      return Column(
        children: [
          FlatmatesButton(
            label: locale.viewListing,
            onPressed: onOpenListing,
            icon: Icons.visibility_outlined,
            fullWidth: true,
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
          fullWidth: true,
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

/// One line of "What happens next": the number in clay ink, then the text.
class _StepItem extends StatelessWidget {
  const _StepItem({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = theme.brightness;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSpacing.lg,
            child: Text(
              '$number.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppSemanticColors.clayInkFor(b),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppSemanticColors.textPrimaryFor(b),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
