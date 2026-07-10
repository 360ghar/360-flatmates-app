import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../shared/presentation/components.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../bootstrap/bootstrap_controller.dart';
import '../../../discover/application/discover_feed_controller.dart';
import '../../../discover/presentation/widgets/filter_sheet.dart';
import '../../../location/application/location_controller.dart';
import '../../../location/presentation/location_picker_modal.dart';

/// Header row for the swipe deck: location pill (opens the location picker),
/// optional safety menu, and a filters button (opens the shared search filters).
class SwipeDeckHeader extends ConsumerStatefulWidget {
  const SwipeDeckHeader({super.key, this.onSafetyMenu});

  /// Opens Report / Block for the current foreground profile.
  /// When null, the more-options button is hidden.
  final VoidCallback? onSafetyMenu;

  @override
  ConsumerState<SwipeDeckHeader> createState() => _SwipeDeckHeaderState();
}

class _SwipeDeckHeaderState extends ConsumerState<SwipeDeckHeader> {
  final _locationRadiusDebouncer = ActionDebouncer();

  @override
  void dispose() {
    _locationRadiusDebouncer.dispose();
    super.dispose();
  }

  void _showLocationPicker(
    BuildContext context, {
    required String currentLocation,
    required double currentRadiusKm,
  }) {
    var selectedRadiusKm = currentRadiusKm;
    var didSelectLocation = false;

    showLocationPickerModal(
      context,
      currentLocationName: currentLocation,
      currentRadius: currentRadiusKm,
      onRadiusChanged: (radiusKm) {
        selectedRadiusKm = radiusKm;
        _locationRadiusDebouncer.run(() {
          if (!mounted || didSelectLocation) return;

          final activeLocation = ref
              .read(locationControllerProvider)
              .selectedLocation;
          if (activeLocation == null) return;

          ref
              .read(discoverFeedControllerProvider.notifier)
              .updateLocationFilter(
                latitude: activeLocation.latitude,
                longitude: activeLocation.longitude,
                radiusKm: radiusKm,
              );
        });
      },
      onLocationSelected: (location) {
        didSelectLocation = true;
        ref.read(locationControllerProvider.notifier).selectLocation(location);
        ref
            .read(discoverFeedControllerProvider.notifier)
            .updateLocationFilter(
              latitude: location.latitude,
              longitude: location.longitude,
              radiusKm: selectedRadiusKm,
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final profile = ref.watch(
      bootstrapControllerProvider.select((s) => s.valueOrNull?.profile),
    );
    final selectedLocation = ref.watch(
      locationControllerProvider.select((state) => state.selectedLocation),
    );
    final currentRadiusKm =
        ref.watch(
          discoverFeedControllerProvider.select((s) => s.filters.radiusKm),
        ) ??
        DiscoverFeedController.defaultLocationRadiusKm;

    final locality = profile?.locality?.trim();
    final city = profile?.city?.trim();
    final profileLocation = [
      if (locality != null && locality.isNotEmpty) locality,
      if (city != null && city.isNotEmpty) city,
    ].join(', ');
    final selectedDisplayText = selectedLocation?.displayText ?? '';
    final currentLocation = selectedDisplayText.isNotEmpty
        ? selectedDisplayText
        : profileLocation;

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: _InteractivePressScale(
              onTap: () => _showLocationPicker(
                context,
                currentLocation: currentLocation,
                currentRadiusKm: currentRadiusKm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppSemanticColors.textPrimaryFor(theme.brightness),
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      currentLocation.isNotEmpty
                          ? currentLocation
                          : locale.reviewLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppSemanticColors.textPrimaryFor(
                          theme.brightness,
                        ),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppSemanticColors.textPrimaryFor(theme.brightness),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (widget.onSafetyMenu != null)
          IconButton(
            key: const Key('swipe_safety_menu'),
            tooltip: locale.moreOptionsTooltip,
            onPressed: widget.onSafetyMenu,
            icon: const Icon(Icons.more_vert_rounded),
          ),
        IconButton.filledTonal(
          key: const Key('swipe_filter_tune'),
          tooltip: locale.searchFiltersTitle,
          onPressed: () => showFiltersSheet(context),
          icon: const Icon(AppIcons.filter),
        ),
      ],
    );
  }
}

/// Applies premium scale-down on press using Listener and AnimatedScale.
class _InteractivePressScale extends StatefulWidget {
  const _InteractivePressScale({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_InteractivePressScale> createState() => _InteractivePressScaleState();
}

class _InteractivePressScaleState extends State<_InteractivePressScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.97),
      onPointerUp: (_) => setState(() => _scale = 1.0),
      onPointerCancel: (_) => setState(() => _scale = 1.0),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
