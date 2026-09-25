import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/components.dart';
import '../../domain/property_listing.dart';
import 'full_screen_gallery.dart';

class FlatDetailsMedia extends StatelessWidget {
  const FlatDetailsMedia({required this.listing, super.key});

  final PropertyListing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final l = listing;

    return Padding(
      padding: AppSpacing.horizontalScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Floor Plan
          if (l.effectiveFloorPlanUrl != null) ...[
            FlatmatesSectionHeader(title: locale.floorPlanSectionTitle),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              key: const Key('flat_floorplan_image'),
              onTap: () => FullScreenGallery.open(
                context: context,
                images: [l.effectiveFloorPlanUrl!],
                heroTagPrefix: 'flat-floorplan-${l.id}',
              ),
              child: ClipRRect(
                borderRadius: AppRadius.mdBorder,
                child: Stack(
                  children: [
                    // Contrasting frame so white floor-plan PNGs read as a
                    // framed document instead of bleeding into the page.
                    Container(
                      width: double.infinity,
                      color: AppSemanticColors.secondarySurfaceFor(
                        theme.brightness,
                      ),
                      child: FlatmatesNetworkImage(
                        imageUrl: l.effectiveFloorPlanUrl!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.contain,
                        heroTag: 'flat-floorplan-${l.id}-0',
                        semanticLabel: locale.floorPlanSectionTitle,
                      ),
                    ),
                    Positioned(
                      right: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          borderRadius: AppRadius.smBorder,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.zoom_out_map_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              locale.tapToZoomHint,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.screen),
          ],

          // Virtual Tour
          if (l.virtualTourUrl != null && l.virtualTourUrl!.isNotEmpty) ...[
            FlatmatesSectionHeader(title: locale.virtualTourSectionTitle),
            const SizedBox(height: AppSpacing.sm),
            FlatmatesCard(
              padding: AppSpacing.edgeLg,
              onTap: () => _openUrl(context, l.virtualTourUrl!),
              child: Column(
                children: [
                  Icon(
                    Icons.view_in_ar_rounded,
                    size: 32,
                    color: AppSemanticColors.clayFor(theme.brightness),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    locale.exploreVirtualTourPrompt,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FlatmatesButton.secondary(
                    label: locale.openVirtualTourCta,
                    icon: Icons.open_in_new_rounded,
                    fullWidth: true,
                    onPressed: () => _openUrl(context, l.virtualTourUrl!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.screen),
          ],

          // Video Tour
          if (l.videoTourUrl != null && l.videoTourUrl!.isNotEmpty) ...[
            FlatmatesVideoTourPlayer(videoUrl: l.videoTourUrl!),
            const SizedBox(height: AppSpacing.screen),
          ],

          // Google Street View
          if (l.googleStreetViewUrl != null &&
              l.googleStreetViewUrl!.isNotEmpty) ...[
            // The location section below has its own header.
            FlatmatesButton.secondary(
              label: locale.streetViewCta,
              icon: Icons.streetview_rounded,
              onPressed: () => _openUrl(context, l.googleStreetViewUrl!),
            ),
            const SizedBox(height: AppSpacing.screen),
          ],
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return;
    }
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('FlatDetailsMedia._openUrl: $e');
    }
    if (!opened && context.mounted) {
      FlatmatesToast.error(context, AppLocalizations.of(context).errorUnknown);
    }
  }
}
