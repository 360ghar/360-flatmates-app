import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/theme.dart';
import '../../l10n/gen/app_localizations.dart';
import '../location/presentation/map_widgets.dart';
import '../shared/presentation/components.dart';
import 'discover_repository.dart';
import 'presentation/widgets/flat_details_carousel.dart';
import 'presentation/widgets/flat_details_sections.dart';
import 'presentation/widgets/report_listing_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

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

        return FlatmatesScreen(
          useSafeArea: false,
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
                      onReport: () => _handleReportListing(),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.xl,
                        AppSpacing.xl,
                        AppSpacing.screen,
                      ),
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
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamilyDisplay,
                                    fontSize: AppTypography.h2Size,
                                    fontWeight: AppTypography.h2Weight,
                                    height: AppTypography.h2Height,
                                    letterSpacing:
                                        AppTypography.h2LetterSpacing,
                                    color: AppSemanticColors.textPrimaryFor(
                                      theme.brightness,
                                    ),
                                    fontVariations: const [
                                      FontVariation('opsz', 96),
                                      FontVariation('SOFT', 30),
                                      FontVariation('WONK', 0),
                                    ],
                                  ),
                                ),
                              ),
                              FlatmatesPriceText.hero(
                                amount: listing.monthlyRent.round(),
                                period: 'month',
                                color: AppSemanticColors.ink,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: AppSemanticColors.textSecondaryFor(
                                  theme.brightness,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  [
                                    listing.locality,
                                    listing.city,
                                  ].whereType<String>().join(', '),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppSemanticColors.textSecondaryFor(
                                      theme.brightness,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

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
                          const SizedBox(height: AppSpacing.screen),

                          FlatmatesSectionHeader(
                            title: locale.aboutThisFlatSection,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (listing.description != null &&
                              listing.description!.trim().isNotEmpty)
                            Text(
                              listing.description!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.6,
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
                          const SizedBox(height: AppSpacing.screen),

                          if (listing.effectiveFloorPlanUrl != null) ...[
                            FlatmatesSectionHeader(
                              title: 'Floor Plan',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ClipRRect(
                              borderRadius: AppRadius.mdBorder,
                              child: FlatmatesNetworkImage(
                                imageUrl: listing.effectiveFloorPlanUrl!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.screen),
                          ],

                          if (listing.virtualTourUrl != null &&
                              listing.virtualTourUrl!.isNotEmpty) ...[
                            FlatmatesSectionHeader(
                              title: '360° Virtual Tour',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            FlatmatesCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.view_in_ar_rounded,
                                    size: 48,
                                    color: AppSemanticColors.accent,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Explore this property in 360°',
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      final uri =
                                          Uri.tryParse(listing.virtualTourUrl!);
                                      if (uri != null) {
                                        launchUrl(
                                          uri,
                                          mode:
                                              LaunchMode.externalApplication,
                                        );
                                      }
                                    },
                                    icon:
                                        const Icon(Icons.open_in_new_rounded),
                                    label: const Text('Open Virtual Tour'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.screen),
                          ],

                          if (listing.videoTourUrl != null &&
                              listing.videoTourUrl!.isNotEmpty) ...[
                            FlatmatesVideoTourPlayer(
                              videoUrl: listing.videoTourUrl!,
                            ),
                            const SizedBox(height: AppSpacing.screen),
                          ],

                          // Cost breakdown section
                          if (listing.securityDeposit != null ||
                              listing.maintenanceCharges != null) ...[
                            FlatmatesSectionHeader(
                              title: locale.costsBreakdownSectionTitle,
                            ),
                            const SizedBox(height: AppSpacing.sm),
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
                            const SizedBox(height: AppSpacing.screen),
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
                              const SizedBox(width: AppSpacing.md),
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
                          const SizedBox(height: AppSpacing.screen),

                          if (listing.latitude != null &&
                              listing.longitude != null) ...[
                            FlatmatesSectionHeader(
                              title: locale.locationSectionTitle,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            MiniMapView(
                              latitude: listing.latitude!,
                              longitude: listing.longitude!,
                              height: 220,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            GetDirectionsButton(
                              latitude: listing.latitude!,
                              longitude: listing.longitude!,
                              label:
                                  listing.locality ??
                                  listing.city ??
                                  'Property',
                            ),
                            const SizedBox(height: AppSpacing.screen),
                          ],

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
                          const SizedBox(height: 100),
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
      loading: () => const FlatmatesScreen(
        useSafeArea: true,
        body: Padding(
          padding: AppSpacing.horizontalScreen,
          child: FlatmatesSkeleton.card(),
        ),
      ),
      error: (e, _) {
        final message = e is AppFailure
            ? e.userMessage(locale.toUserMessageL10n())
            : locale.couldNotLoadListing;
        return FlatmatesScreen(
          useSafeArea: true,
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
        padding: const EdgeInsets.all(AppSpacing.xl),
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

  Future<void> _handleReportListing() async {
    final selected = await showReportListingDialog(context);
    if (selected == null || !mounted) return;

    try {
      await ref
          .read(discoverRepositoryProvider)
          .reportListing(widget.listingId, selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).reportListingSubmitted),
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
  }
}
