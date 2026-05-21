import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/image_upload_service.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../bootstrap/catalog_helpers.dart';
import '../../../shared/presentation/components.dart';
import 'dashed_border_container.dart';

/// Step 2 + Step 3 — Room type, furnishing, features, photos, video tour.
///
/// Uses [ConsumerStatefulWidget] because the photos step needs local state
/// for the photo-tips toggle and calls [imageUploadServiceProvider].
class StepRoomSection extends ConsumerStatefulWidget {
  const StepRoomSection({
    required this.step,
    required this.roomType,
    required this.roomFurnishing,
    required this.roomFeatures,
    required this.roomPhotoUrls,
    required this.videoTourUrl,
    required this.videoUploading,
    required this.showPhotosValidation,
    required this.catalog,
    required this.iconForOption,
    required this.onRoomTypeChanged,
    required this.onFurnishingToggled,
    required this.onFeatureToggled,
    required this.onPickPhotos,
    required this.onRemovePhoto,
    required this.onVideoTourUrlChanged,
    required this.onVideoUploadingChanged,
    super.key,
  });

  final int step; // 2 = room details, 3 = photos
  final String roomType;
  final Set<String> roomFurnishing;
  final Set<String> roomFeatures;
  final List<String> roomPhotoUrls;
  final String? videoTourUrl;
  final bool videoUploading;
  final bool showPhotosValidation;
  final List<CatalogOption> Function(String key) catalog;
  final IconData Function(String id) iconForOption;
  final ValueChanged<String> onRoomTypeChanged;
  final void Function(String key, bool selected) onFurnishingToggled;
  final void Function(String key, bool selected) onFeatureToggled;
  final VoidCallback onPickPhotos;
  final void Function(int index) onRemovePhoto;
  final void Function(String? url) onVideoTourUrlChanged;
  final void Function(bool uploading) onVideoUploadingChanged;

  @override
  ConsumerState<StepRoomSection> createState() => _StepRoomSectionState();
}

class _StepRoomSectionState extends ConsumerState<StepRoomSection> {
  bool _showPhotoTips = false;

  @override
  Widget build(BuildContext context) {
    if (widget.step == 2) return _buildRoomDetailsStep();
    return _buildPhotosStep();
  }

  Widget _buildRoomDetailsStep() {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final roomTypes = widget.catalog('flatmates_room_types');
    final amenities = widget.catalog('flatmates_listing_amenities');

    return FlatmatesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.roomTypeLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: roomTypes.map((type) {
              return FlatmatesChip(
                variant: FlatmatesChipVariant.choice,
                label: type.label,
                selected: widget.roomType == type.id,
                onSelected: (_) => widget.onRoomTypeChanged(type.id),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.section - AppSpacing.md),
          Text(
            locale.furnishingLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: amenities.map((opt) {
              final selected = widget.roomFurnishing.contains(opt.id);
              return FlatmatesChip(
                variant: FlatmatesChipVariant.filter,
                icon: widget.iconForOption(opt.id),
                label: opt.label,
                selected: selected,
                onSelected: (v) => widget.onFurnishingToggled(opt.id, v),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.section - AppSpacing.md),
          Text(
            locale.roomFeaturesLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: amenities.map((opt) {
              final selected = widget.roomFeatures.contains(opt.id);
              return FlatmatesChip(
                variant: FlatmatesChipVariant.filter,
                icon: widget.iconForOption(opt.id),
                label: opt.label,
                selected: selected,
                onSelected: (v) => widget.onFeatureToggled(opt.id, v),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosStep() {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Inline validation hint for photos
        if (widget.showPhotosValidation && widget.roomPhotoUrls.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: AppSemanticColors.error,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  locale.listingPhotosRequired,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppSemanticColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        // Tips toggle (top-right aligned)
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => setState(() => _showPhotoTips = !_showPhotoTips),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _showPhotoTips
                    ? AppSemanticColors.coralSoftFor(theme.brightness)
                    : AppSemanticColors.disabledSurfaceFor(theme.brightness),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: _showPhotoTips
                        ? AppSemanticColors.accent
                        : AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    locale.addPhotosTips,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _showPhotoTips
                          ? AppSemanticColors.accent
                          : AppSemanticColors.textSecondaryFor(
                              theme.brightness,
                            ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Instruction text
        Text(
          locale.addPhotosInstruction,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppSemanticColors.textSecondaryFor(theme.brightness),
          ),
        ),
        const SizedBox(height: 20),

        // Tips content (collapsible)
        if (_showPhotoTips) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppSemanticColors.coralSoftFor(
                theme.brightness,
              ).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📸 ${locale.addPhotosTips}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  locale.photoTipNaturalLight,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  locale.photoTipFullRoom,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  locale.photoTipBathroomBalcony,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  locale.photoTipCleanRoom,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Min photos required indicator
        Row(
          children: [
            Text(
              locale.roomPhotosLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (widget.roomPhotoUrls.length < 2)
              InfoPill(label: locale.minPhotosRequired, highlighted: true),
          ],
        ),
        const SizedBox(height: 12),

        // Photo cards — uploaded photos with premium card wrapper
        ...widget.roomPhotoUrls.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: FlatmatesCard(
              borderColor: AppSemanticColors.line,
              padding: EdgeInsets.zero,
              child: Stack(
                children: [
                  FlatmatesNetworkImage(
                    imageUrl: e.value,
                    width: double.infinity,
                    height: 200,
                    borderRadius: AppRadius.cardBorder,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Material(
                      color: AppSemanticColors.error,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => widget.onRemovePhoto(e.key),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        // Add photo tile — dashed border with camera icon
        if (widget.roomPhotoUrls.length < 10)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: GestureDetector(
              onTap: widget.onPickPhotos,
              child: DashedBorderContainer(
                color: AppSemanticColors.line,
                borderRadius: AppRadius.card,
                child: SizedBox(
                  width: double.infinity,
                  height: 140,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppSemanticColors.coralSoftFor(
                            theme.brightness,
                          ).withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: AppSemanticColors.accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        locale.addMorePhotosLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppSemanticColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Pagination dots showing photo progress
        if (widget.roomPhotoUrls.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                (widget.roomPhotoUrls.length / 3).ceil(),
                (i) {
                  final isActive = i == 0;
                  return Container(
                    width: isActive ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppSemanticColors.accent
                          : AppSemanticColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                },
              ),
            ),
          ),

        const SizedBox(height: AppSpacing.lg),

        // Video tour section
        Text(
          locale.videoTourLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          locale.videoTourHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppSemanticColors.textSecondaryFor(theme.brightness),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.videoUploading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (widget.videoTourUrl != null)
          Row(
            children: [
              Icon(
                Icons.videocam_rounded,
                color: AppSemanticColors.accent,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  locale.videoTourAdded,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppSemanticColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => widget.onVideoTourUrlChanged(null),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppSemanticColors.error,
                ),
              ),
            ],
          )
        else
          Material(
            color: AppSemanticColors.disabledSurfaceFor(
              theme.brightness,
            ).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickVideoTour,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_call_outlined,
                      color: AppSemanticColors.accent,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        locale.addVideoCta,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppSemanticColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickVideoTour() async {
    final service = ref.read(imageUploadServiceProvider);
    final file = await service.pickVideo();
    if (file == null) return;

    final validation = await service.validateVideo(file);
    if (!validation.isValid) {
      if (!mounted) return;
      final locale = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            validation.tooLarge
                ? locale.videoTooLarge
                : validation.tooShort
                ? locale.videoTooShort
                : locale.videoTooLong,
          ),
        ),
      );
      return;
    }

    widget.onVideoUploadingChanged(true);
    final result = await service.uploadVideoTour(file);
    if (result is UploadSuccess) {
      widget.onVideoTourUrlChanged(result.url);
    } else if (result is UploadFailure) {
      widget.onVideoTourUrlChanged(null);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.reason)));
      }
    }
    widget.onVideoUploadingChanged(false);
  }
}
