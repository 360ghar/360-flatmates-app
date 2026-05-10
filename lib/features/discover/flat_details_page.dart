import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/components.dart';
import '../shared/presentation/flatmates_video_tour_player.dart';
import 'discover_repository.dart';
import 'presentation/widgets/flat_details_carousel.dart';
import 'presentation/widgets/flat_details_sections.dart';
import 'share_listing_card.dart';

class FlatDetailsPage extends ConsumerStatefulWidget {
  const FlatDetailsPage({required this.listingId, super.key});

  final int listingId;

  @override
  ConsumerState<FlatDetailsPage> createState() => _FlatDetailsPageState();
}

class _FlatDetailsPageState extends ConsumerState<FlatDetailsPage> {
  int _currentImageIndex = 0;
  bool _isShortlisting = false;
  bool _isContacting = false;
  bool _hasShortlisted = false;

  @override
  Widget build(BuildContext context) {
    final listingState = ref.watch(propertyListingProvider(widget.listingId));
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return listingState.when(
      data: (listing) {
        final images = listing.imageUrls;

        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    FlatDetailsCarousel(
                      images: images,
                      currentIndex: _currentImageIndex,
                      onPageChanged: (index) =>
                          setState(() => _currentImageIndex = index),
                      title: listing.title,
                      onBack: () => context.pop(),
                      onShare: () => _showShareSheet(listing),
                      onFavorite: () => _handleShortlist(),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Expanded(
                                child: Text(
                                  listing.title,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              FlatmatesPriceText.hero(
                                amount: listing.monthlyRent.round(),
                                period: 'month',
                                color: AppSemanticColors.ink,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: AppSemanticColors.textSecondaryFor(
                                  theme.brightness,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  [
                                    listing.locality,
                                    listing.city,
                                  ].whereType<String>().join(', '),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppSemanticColors.textSecondaryFor(
                                      theme.brightness,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              if (listing.bedrooms != null)
                                FlatmatesChip(
                                  variant: FlatmatesChipVariant.info,
                                  label: '${listing.bedrooms} Beds',
                                  icon: Icons.bed_outlined,
                                ),
                              if (listing.features.any(
                                (f) => f.toLowerCase().contains('furnished'),
                              ))
                                FlatmatesChip(
                                  variant: FlatmatesChipVariant.info,
                                  label: locale.featureFurnished,
                                  icon: Icons.chair_outlined,
                                ),
                              if (listing.features.any(
                                (f) =>
                                    f.toLowerCase().contains('wifi') ||
                                    f.toLowerCase().contains('wi_fi'),
                              ))
                                FlatmatesChip(
                                  variant: FlatmatesChipVariant.info,
                                  label: locale.wifiChipLabel,
                                  icon: Icons.wifi_outlined,
                                ),
                              if (listing.features.any(
                                (f) => f.toLowerCase().contains('parking'),
                              ))
                                FlatmatesChip(
                                  variant: FlatmatesChipVariant.info,
                                  label: locale.parkingChipLabel,
                                  icon: Icons.local_parking_outlined,
                                ),
                              if (listing.features.any(
                                (f) =>
                                    f.toLowerCase().contains('lift') ||
                                    f.toLowerCase().contains('elevator'),
                              ))
                                FlatmatesChip(
                                  variant: FlatmatesChipVariant.info,
                                  label: locale.liftChipLabel,
                                  icon: Icons.elevator_outlined,
                                ),
                              if (listing.features.any(
                                (f) => f.toLowerCase().contains('security'),
                              ))
                                FlatmatesChip(
                                  variant: FlatmatesChipVariant.info,
                                  label: locale.securityChipLabel,
                                  icon: Icons.security_outlined,
                                ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          FlatmatesSectionHeader(
                            title: locale.aboutThisFlatSection,
                          ),
                          const SizedBox(height: 8),
                          if (listing.description != null &&
                              listing.description!.trim().isNotEmpty)
                            Text(
                              listing.description!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                                color: AppSemanticColors.textPrimaryFor(
                                  theme.brightness,
                                ).withValues(alpha: 0.85),
                              ),
                            )
                          else
                            Text(
                              locale.noDescriptionAvailable,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppSemanticColors.textSecondaryFor(
                                  theme.brightness,
                                ),
                              ),
                            ),
                          const SizedBox(height: 22),

                          if (listing.videoTourUrl != null &&
                              listing.videoTourUrl!.isNotEmpty) ...[
                            FlatmatesVideoTourPlayer(
                              videoUrl: listing.videoTourUrl!,
                            ),
                            const SizedBox(height: 22),
                          ],

                          // Cost breakdown section
                          if (listing.securityDeposit != null ||
                              listing.maintenanceCharges != null) ...[
                            FlatmatesSectionHeader(
                              title: locale.costsBreakdownSectionTitle,
                            ),
                            const SizedBox(height: 8),
                            FlatmatesCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                children: [
                                  CostRow(
                                    label: locale.monthlyRentRow,
                                    child: FlatmatesPriceText.card(
                                      amount: listing.monthlyRent.round(),
                                      period: 'month',
                                    ),
                                  ),
                                  if (listing.securityDeposit != null) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    CostRow(
                                      label: locale.securityDepositRow,
                                      child: FlatmatesPriceText.inline(
                                        amount: listing.securityDeposit!
                                            .round(),
                                      ),
                                    ),
                                  ],
                                  if (listing.maintenanceCharges != null) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    CostRow(
                                      label: locale.maintenanceRow,
                                      child: FlatmatesPriceText.inline(
                                        amount: listing.maintenanceCharges!
                                            .round(),
                                        period: 'month',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                          ],

                          Row(
                            children: [
                              Expanded(
                                child: AvailabilityTile(
                                  label: locale.availableFromLabel,
                                  value: listing.availableFrom != null
                                      ? DateFormat.yMMMd(
                                          locale.localeName,
                                        ).format(listing.availableFrom!)
                                      : locale.flexibleLabel,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AvailabilityTile(
                                  label: locale.postedOnLabel,
                                  value: listing.createdAt != null
                                      ? DateFormat.yMMMd(
                                          locale.localeName,
                                        ).format(listing.createdAt!)
                                      : locale.recentlyLabel,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          if (listing.isLive)
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                FlatmatesTrustBadge(
                                  variant: FlatmatesTrustBadgeVariant.verified,
                                  label: locale.verifiedListingLabel,
                                ),
                                FlatmatesTrustBadge(
                                  variant: FlatmatesTrustBadgeVariant.safe,
                                  label: locale.safetyCheckedLabel,
                                ),
                              ],
                            ),
                          const SizedBox(height: 100), // space for bottom bar
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              FlatmatesBottomActionBar(
                primaryButtonKey: const Key('flat_contact_button'),
                secondaryButtonKey: const Key('flat_shortlist_button'),
                label: locale.contactCta,
                onPressed: _handleContact,
                icon: Icons.send_rounded,
                secondaryLabel: locale.shortlistCta,
                secondaryOnPressed: _handleShortlist,
                secondaryIcon: Icons.favorite_border,
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.horizontalScreen,
            child: const FlatmatesSkeleton.card(),
          ),
        ),
      ),
      error: (e, _) {
        final message = e is AppFailure
            ? e.userMessage(locale.toUserMessageL10n())
            : locale.couldNotLoadListing;
        return Scaffold(
          appBar: AppBar(),
          body: FlatmatesErrorState(
            message: message,
            onRetry: () =>
                ref.invalidate(propertyListingProvider(widget.listingId)),
          ),
        );
      },
    );
  }

  Future<void> _showShareSheet(PropertyListing listing) async {
    await FlatmatesBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: ShareListingCard(listing: listing),
      ),
    );
  }

  Future<void> _handleShortlist() async {
    if (_isShortlisting) return;
    setState(() => _isShortlisting = true);

    try {
      await ref.read(discoverRepositoryProvider).likeListing(widget.listingId);
      _hasShortlisted = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).profileMenuShortlisted),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).actionFailedRetry),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isShortlisting = false);
    }
  }

  Future<void> _handleContact() async {
    if (_isContacting) return;
    setState(() => _isContacting = true);

    try {
      int? conversationId;
      if (!_hasShortlisted) {
        conversationId = await ref
            .read(discoverRepositoryProvider)
            .likeListing(widget.listingId);
        _hasShortlisted = true;
      } else {
        conversationId = await ref
            .read(discoverRepositoryProvider)
            .likeListing(widget.listingId);
      }
      if (mounted && conversationId != null) {
        context.push('/chats/$conversationId');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).contactRequestSent),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).actionFailedRetry),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isContacting = false);
    }
  }
}
