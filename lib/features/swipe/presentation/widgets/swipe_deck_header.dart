import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../shared/presentation/components.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../bootstrap/bootstrap_controller.dart';
import '../../../discover/application/discover_feed_controller.dart';
import '../../../discover/presentation/widgets/filter_sheet.dart';
import '../../../location/application/location_controller.dart';
import '../../../location/presentation/location_picker_modal.dart';

/// Header row for the swipe deck: location chip + filter chrome button.
class SwipeDeckHeader extends ConsumerStatefulWidget {
  const SwipeDeckHeader({super.key});

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
            child: FlatmatesLocationChip(
              locationName: currentLocation.isNotEmpty ? currentLocation : null,
              placeholder: locale.reviewLocation,
              onTap: () => _showLocationPicker(
                context,
                currentLocation: currentLocation,
                currentRadiusKm: currentRadiusKm,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        FlatmatesChromeIconButton(
          key: const Key('swipe_filter_tune'),
          tooltip: locale.searchFiltersTitle,
          onPressed: () => showFiltersSheet(context),
          icon: AppIcons.filter,
        ),
      ],
    );
  }
}
