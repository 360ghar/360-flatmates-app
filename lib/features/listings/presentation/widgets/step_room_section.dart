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
          const SizedBox(height: AppSpacing.xl - AppSpacing.md),
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
                icon: widget.iconForOption(opt.id),
                label: opt.label,
                selected: selected,
                onSelected: (v) => widget.onFurnishingToggled(opt.id, v),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl - AppSpacing.md),
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
    final clay = AppSemanticColors.clayFor(theme.brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Inline validation hint for photos
        if (widget.showPhotosValidation && widget.roomPhotoUrls.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: FlatmatesInlineError(locale.listingPhotosRequired),
          ),
        // Tips toggle (top-right aligned)
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FlatmatesChip(
            key: const Key('listing_photo_tips_toggle'),
            icon: Icons.lightbulb_outline,
            label: locale.addPhotosTips,
            selected: _showPhotoTips,
            onSelected: (v) => setState(() => _showPhotoTips = v),
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
        const SizedBox(height: AppSpacing.s20),

        // Tips content (collapsible)
        if (_showPhotoTips) ...[
          Container(
            width: double.infinity,
            padding: AppSpacing.edgeLg,
            decoration: BoxDecoration(
              color: AppSemanticColors.paper1For(theme.brightness),
              borderRadius: AppRadius.mdBorder,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.addPhotosTips, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  locale.photoTipNaturalLight,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  locale.photoTipFullRoom,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  locale.photoTipBathroomBalcony,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  locale.photoTipCleanRoom,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
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
        const SizedBox(height: AppSpacing.md),

        // Photo cards — uploaded photos with premium card wrapper
        ...widget.roomPhotoUrls.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: FlatmatesCard(
              borderColor: AppSemanticColors.hairlineFor(theme.brightness),
              padding: EdgeInsets.zero,
              child: Stack(
                children: [
                  FlatmatesNetworkImage(
                    imageUrl: e.value,
                    width: double.infinity,
                    height: 200,
                    borderRadius: AppRadius.cardBorder,
                  ),
                  // 48 dp target around a 32 dp scrim disc: readable on any
                  // photo, in light and dark.
                  Positioned(
                    right: AppSpacing.xs,
                    top: AppSpacing.xs,
                    child: Tooltip(
                      message: locale.removePhotoTooltip,
                      child: Semantics(
                        button: true,
                        label: locale.removePhotoTooltip,
                        excludeSemantics: true,
                        child: InkResponse(
                          key: ValueKey('listing_remove_photo_${e.key}'),
                          onTap: () => widget.onRemovePhoto(e.key),
                          radius: kMinInteractiveDimension / 2,
                          child: SizedBox.square(
                            dimension: kMinInteractiveDimension,
                            child: Center(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppSemanticColors.scrim.withValues(
                                    alpha: 0.6,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const SizedBox.square(
                                  dimension: 32,
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: AppSemanticColors.onScrim,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
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
            child: InkWell(
              key: const Key('listing_add_photos_tile'),
              onTap: widget.onPickPhotos,
              borderRadius: AppRadius.cardBorder,
              child: DashedBorderContainer(
                color: AppSemanticColors.hairlineFor(theme.brightness),
                child: SizedBox(
                  width: double.infinity,
                  height: 140,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: clay, size: 32),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        locale.addMorePhotosLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: clay,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
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
        const SizedBox(height: AppSpacing.xs),
        Text(
          locale.videoTourHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppSemanticColors.textSecondaryFor(theme.brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.videoUploading)
          const Center(
            child: Padding(
              padding: AppSpacing.edgeLg,
              child: CircularProgressIndicator(),
            ),
          )
        else if (widget.videoTourUrl != null)
          Row(
            children: [
              Icon(Icons.videocam_rounded, color: clay, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  locale.videoTourAdded,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppSemanticColors.textPrimaryFor(theme.brightness),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => widget.onVideoTourUrlChanged(null),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppSemanticColors.dangerFor(theme.brightness),
                ),
                tooltip: locale.removeVideoTourTooltip,
              ),
            ],
          )
        else
          Material(
            color: AppSemanticColors.paper1For(theme.brightness),
            borderRadius: AppRadius.mdBorder,
            child: InkWell(
              key: const Key('listing_add_video_tile'),
              borderRadius: AppRadius.mdBorder,
              onTap: _pickVideoTour,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.s20,
                  horizontal: AppSpacing.base,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_call_outlined, color: clay, size: 28),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: Text(
                        locale.addVideoCta,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: clay,
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
      FlatmatesToast.error(
        context,
        validation.tooLarge
            ? locale.videoTooLarge
            : validation.tooShort
            ? locale.videoTooShort
            : locale.videoTooLong,
      );
      return;
    }

    widget.onVideoUploadingChanged(true);
    final UploadResult result;
    try {
      result = await service.uploadVideoTour(file);
    } catch (e) {
      debugPrint('StepRoomSection._pickVideoTour failed: $e');
      if (!mounted) return;
      widget.onVideoUploadingChanged(false);
      FlatmatesToast.error(
        context,
        AppLocalizations.of(context).videoUploadFailed,
      );
      return;
    }
    if (!mounted) return;
    if (result is UploadSuccess) {
      widget.onVideoTourUrlChanged(result.url);
    } else if (result is UploadFailure) {
      debugPrint('StepRoomSection._pickVideoTour: ${result.reason}');
      widget.onVideoTourUrlChanged(null);
      // Never show the raw exception text; it is logged above.
      FlatmatesToast.error(
        context,
        AppLocalizations.of(context).videoUploadFailed,
      );
    }
    widget.onVideoUploadingChanged(false);
  }
}
