import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/components.dart';
import '../../domain/property_listing.dart';

class FlatDetailsMedia extends StatelessWidget {
  const FlatDetailsMedia({
    required this.listing,
    super.key,
  });

  final PropertyListing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final l = listing;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Floor Plan
          if (l.effectiveFloorPlanUrl != null) ...[
            FlatmatesSectionHeader(title: locale.floorPlanSectionTitle),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () => _openUrl(l.effectiveFloorPlanUrl!),
              child: ClipRRect(
                borderRadius: AppRadius.mdBorder,
                child: FlatmatesNetworkImage(
                  imageUrl: l.effectiveFloorPlanUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.screen),
          ],

          // Virtual Tour
          if (l.virtualTourUrl != null &&
              l.virtualTourUrl!.isNotEmpty) ...[
            FlatmatesSectionHeader(title: locale.virtualTourSectionTitle),
            const SizedBox(height: AppSpacing.sm),
            FlatmatesCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              onTap: () => _openUrl(l.virtualTourUrl!),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppSemanticColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.view_in_ar_rounded,
                      size: 32,
                      color: AppSemanticColors.accent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    locale.exploreVirtualTourPrompt,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => _openUrl(l.virtualTourUrl!),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(locale.openVirtualTourCta),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.screen),
          ],

          // Video Tour
          if (l.videoTourUrl != null &&
              l.videoTourUrl!.isNotEmpty) ...[
            FlatmatesVideoTourPlayer(
              videoUrl: l.videoTourUrl!,
            ),
            const SizedBox(height: AppSpacing.screen),
          ],

          // Google Street View
          if (l.googleStreetViewUrl != null &&
              l.googleStreetViewUrl!.isNotEmpty) ...[
            FlatmatesSectionHeader(title: locale.locationSectionTitle),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => _openUrl(l.googleStreetViewUrl!),
              icon: const Icon(Icons.streetview_rounded, size: 18),
              label: Text(locale.streetViewCta),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppSemanticColors.accent,
                side: const BorderSide(color: AppSemanticColors.accent),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.smBorder,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.screen),
          ],
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
