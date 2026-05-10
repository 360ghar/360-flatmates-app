import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/components.dart';
import 'listing_form_data.dart';

/// Step 7 — Review & confirm all listing details before publishing.
class StepReviewSection extends StatelessWidget {
  const StepReviewSection({
    required this.data,
    required this.catalogLabel,
    required this.totalMonthlyOutflow,
    required this.onGoToStep,
    super.key,
  });

  final ListingFormData data;
  final String Function(String key, String id) catalogLabel;
  final double totalMonthlyOutflow;
  final void Function(int step) onGoToStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final d = data;
    final rentValue = double.tryParse(d.rentController.text.trim()) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlatmatesCard(
          child: FlatmatesListingMiniCard(
            title: '${d.flatConfig} in ${d.societyController.text.trim()}',
            rent: rentValue.toInt(),
            imageUrl: d.roomPhotoUrls.isNotEmpty ? d.roomPhotoUrls.first : null,
            locality: [
              d.localityController.text.trim(),
              d.cityController.text.trim(),
            ].where((s) => s.isNotEmpty).join(', '),
            subtitle: catalogLabel('flatmates_room_types', d.roomType),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReviewCard(
          title: locale.reviewLocation,
          icon: Icons.location_on_outlined,
          onEdit: () => onGoToStep(0),
          editLabel: locale.editStep,
          children: [
            if (d.societyController.text.trim().isNotEmpty)
              Text(
                d.societyController.text.trim(),
                style: theme.textTheme.bodyLarge,
              ),
            if (d.addressController.text.trim().isNotEmpty)
              Text(
                d.addressController.text.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                ),
              ),
            Text(
              [
                d.cityController.text.trim(),
                d.localityController.text.trim(),
              ].where((s) => s.isNotEmpty).join(', '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReviewCard(
          title: locale.reviewSociety,
          icon: Icons.apartment_outlined,
          onEdit: () => onGoToStep(1),
          editLabel: locale.editStep,
          children: [
            Text(
              catalogLabel('flatmates_society_types', d.societyType),
              style: theme.textTheme.bodyLarge,
            ),
            if (d.societyAmenities.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: d.societyAmenities
                    .map(
                      (a) => Chip(
                        label: Text(
                          catalogLabel('flatmates_listing_amenities', a),
                          style: theme.textTheme.bodySmall,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            if (d.societyVibeTags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: d.societyVibeTags
                    .map(
                      (v) => Chip(
                        label: Text(
                          catalogLabel('flatmates_vibe_tags', v),
                          style: theme.textTheme.bodySmall,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReviewCard(
          title: locale.reviewRoom,
          icon: Icons.bedroom_parent_outlined,
          onEdit: () => onGoToStep(2),
          editLabel: locale.editStep,
          children: [
            Text(
              catalogLabel('flatmates_room_types', d.roomType),
              style: theme.textTheme.bodyLarge,
            ),
            if (d.roomFurnishing.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: d.roomFurnishing
                    .map(
                      (f) => Chip(
                        label: Text(
                          catalogLabel('flatmates_listing_amenities', f),
                          style: theme.textTheme.bodySmall,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            if (d.roomFeatures.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: d.roomFeatures
                    .map(
                      (f) => Chip(
                        label: Text(
                          catalogLabel('flatmates_listing_amenities', f),
                          style: theme.textTheme.bodySmall,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReviewCard(
          title: locale.addPhotosTitle,
          icon: Icons.add_photo_alternate_outlined,
          onEdit: () => onGoToStep(3),
          editLabel: locale.editStep,
          children: [
            Text(
              locale.reviewPhotosAmount(
                d.roomPhotoUrls.length,
                d.roomPhotoUrls.length != 1 ? 's' : '',
              ),
              style: theme.textTheme.bodyLarge,
            ),
            if (d.videoTourUrl != null)
              Text(
                locale.videoTourAdded,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppSemanticColors.accent,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReviewCard(
          title: locale.reviewFlat,
          icon: Icons.home_work_outlined,
          onEdit: () => onGoToStep(4),
          editLabel: locale.editStep,
          children: [
            Text(d.flatConfig, style: theme.textTheme.bodyLarge),
            if (d.floorController.text.trim().isNotEmpty ||
                d.totalFloorsController.text.trim().isNotEmpty)
              Text(
                'Floor ${d.floorController.text.trim()} / ${d.totalFloorsController.text.trim()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                ),
              ),
            if (d.flatAmenities.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: d.flatAmenities
                    .map(
                      (a) => Chip(
                        label: Text(
                          catalogLabel('flatmates_listing_amenities', a),
                          style: theme.textTheme.bodySmall,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReviewCard(
          title: locale.reviewCosts,
          icon: Icons.currency_rupee_rounded,
          onEdit: () => onGoToStep(5),
          editLabel: locale.editStep,
          children: [
            if (d.rentController.text.trim().isNotEmpty)
              Text(
                locale.reviewRentAmount(d.rentController.text.trim()),
                style: theme.textTheme.bodyLarge,
              ),
            if (d.depositController.text.trim().isNotEmpty)
              Text(
                locale.reviewDepositAmount(d.depositController.text.trim()),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                ),
              ),
            if (d.maintenanceController.text.trim().isNotEmpty)
              Text(
                locale.reviewMaintenanceAmount(
                  d.maintenanceController.text.trim(),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                ),
              ),
            if (totalMonthlyOutflow > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  locale.totalMonthlyOutflow(
                    '₹${totalMonthlyOutflow.toStringAsFixed(0)}',
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppSemanticColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReviewCard(
          title: locale.reviewAbout,
          icon: Icons.person_outline,
          onEdit: () => onGoToStep(6),
          editLabel: locale.editStep,
          children: [
            if (d.typicalDayController.text.trim().isNotEmpty)
              Text(
                d.typicalDayController.text.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            Text(
              locale.reviewGenderAmount(
                d.genderPreference == 'any'
                    ? locale.genderAny
                    : d.genderPreference == 'male'
                    ? locale.genderMale
                    : locale.genderFemale,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
            Text(
              locale.reviewAgeAmount(
                d.ageMin.round().toString(),
                d.ageMax.round().toString(),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
            if (d.nonNegotiables.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: d.nonNegotiables
                    .map(
                      (n) => Chip(
                        label: Text(
                          catalogLabel('flatmates_non_negotiables', n),
                          style: theme.textTheme.bodySmall,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            if (d.availableFrom != null)
              Text(
                locale.reviewMoveInAmount(
                  DateFormat(
                    'd MMM yyyy',
                    locale.localeName,
                  ).format(d.availableFrom!),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.editLabel,
    required this.children,
  });

  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final String editLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlatmatesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppSemanticColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FlatmatesButton.tertiary(label: editLabel, onPressed: onEdit),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}
