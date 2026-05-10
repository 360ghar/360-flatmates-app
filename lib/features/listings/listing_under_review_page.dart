import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/sse_providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../discover/discover_repository.dart';
import '../shared/presentation/flatmates_card.dart';
import '../shared/presentation/flatmates_step_progress.dart';
import '../shared/presentation/flatmates_trust_badge.dart';
import '../shared/presentation/flatmates_error_state.dart';
import '../shared/presentation/flatmates_skeleton.dart';
import '../shared/presentation/flatmates_ui.dart';
import '../shared/presentation/flatmates_network_image.dart';

final listingReviewProvider = FutureProvider.family<PropertyListing, int>((
  ref,
  listingId,
) {
  return ref.watch(discoverRepositoryProvider).fetchListing(listingId);
});

class ListingUnderReviewPage extends ConsumerStatefulWidget {
  const ListingUnderReviewPage({required this.listingId, super.key});

  final int listingId;

  @override
  ConsumerState<ListingUnderReviewPage> createState() =>
      _ListingUnderReviewPageState();
}

class _ListingUnderReviewPageState
    extends ConsumerState<ListingUnderReviewPage> {
  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingReviewProvider(widget.listingId));

    // Listen for SSE listing status changes and refresh.
    ref.listen(sseEventProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event?.type == 'listing_status_changed') {
        final listingId = event!.data['listing_id'] as int?;
        if (listingId == widget.listingId) {
          ref.invalidate(listingReviewProvider(widget.listingId));
        }
      }
    });
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: listingAsync.when(
          data: (listing) {
            final isRejected = listing.isRejected;

            return Column(
              children: [
                // Custom header — logo at top-left, no separate back arrow (per design spec Screen 16)
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
                        locale.listingUnderReviewTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.screen,
                    ),
                    children: [
                      // Illustration / icon area
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRejected
                                ? AppSemanticColors.error.withValues(alpha: 0.1)
                                : AppSemanticColors.accent.withValues(
                                    alpha: 0.1,
                                  ),
                          ),
                          child: Icon(
                            isRejected ? Icons.error_outline : Icons.task_alt,
                            size: 44,
                            color: isRejected
                                ? AppSemanticColors.error
                                : AppSemanticColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Status message
                      Center(
                        child: Text(
                          isRejected
                              ? locale.listingRejectedMessage
                              : locale.reviewSubmittedMessage,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      if (!isRejected) ...[
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 12),
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

                      // Review progress indicator + trust badge
                      if (!isRejected) ...[
                        FlatmatesStepProgress.linear(
                          currentStep: 1,
                          totalSteps: 3,
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
                                color: AppSemanticColors.textSecondaryFor(
                                  theme.brightness,
                                ),
                              ),
                            ),
                            Text(
                              locale.liveStepLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppSemanticColors.textSecondaryFor(
                                  theme.brightness,
                                ),
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

                      // "Review Listing" button (outlined for non-rejected)
                      if (!isRejected)
                        FlatmatesButton.secondary(
                          label: locale.reviewListingCta,
                          onPressed: () => context.push(
                            '/post/new?listingId=${widget.listingId}',
                          ),
                          icon: Icons.visibility_outlined,
                          fullWidth: true,
                        ),

                      if (isRejected) ...[
                        // Rejection reason card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppSemanticColors.error.withValues(
                              alpha: 0.06,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppSemanticColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    locale.rejectionReasonLabel,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: AppSemanticColors.error,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                locale.rejectionDetailText,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppSemanticColors.textSecondaryFor(
                                    theme.brightness,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],

                      const SizedBox(height: AppSpacing.section),

                      // ETA highlight banner
                      if (!isRejected)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppSemanticColors.accent.withValues(
                              alpha: 0.06,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppSemanticColors.accent.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                size: 20,
                                color: AppSemanticColors.accent,
                              ),
                              const SizedBox(width: 10),
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
                        ),

                      const SizedBox(height: AppSpacing.section),

                      // "What happens next?" section
                      if (!isRejected) ...[
                        Text(
                          locale.whatHappensNext,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        _StepItem(
                          number: 1,
                          text: locale.step1Text,
                          theme: theme,
                        ),
                        _StepItem(
                          number: 2,
                          text: locale.step2Text,
                          theme: theme,
                        ),
                        _StepItem(
                          number: 3,
                          text: locale.step3Text,
                          theme: theme,
                        ),
                        const SizedBox(height: AppSpacing.section),
                      ],

                      // Property preview card
                      Text(
                        locale.yourListingLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FlatmatesCard(
                        child: Row(
                          children: [
                            if (listing.mainImageUrl != null)
                              FlatmatesNetworkImage(
                                imageUrl: listing.mainImageUrl!,
                                width: 72,
                                height: 72,
                                borderRadius: BorderRadius.circular(14),
                              )
                            else
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppSemanticColors.accent.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.apartment_rounded),
                              ),
                            const SizedBox(width: 14),
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
                                  const SizedBox(height: 4),
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
                      ),
                      const SizedBox(height: AppSpacing.screen),

                      // CTAs
                      if (isRejected)
                        FlatmatesButton(
                          label: locale.editResubmit,
                          onPressed: () => context.push(
                            '/post/new?listingId=${widget.listingId}',
                          ),
                          icon: Icons.edit_outlined,
                        )
                      else ...[
                        FlatmatesButton(
                          label: locale.goToHomeFeed,
                          onPressed: () => context.go('/discover'),
                          icon: Icons.home_outlined,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FlatmatesButton.secondary(
                          label: locale.viewListing,
                          onPressed: () => context.push(
                            '/post/new?listingId=${widget.listingId}',
                          ),
                          fullWidth: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const FlatmatesSkeleton.card(),
          error: (e, _) =>
              FlatmatesErrorState(message: 'Could not load review status'),
        ),
      ),
    );
  }
}

/// A single numbered step item in the "What happens next?" section.
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
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
          const SizedBox(width: 12),
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
