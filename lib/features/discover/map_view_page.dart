import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../chats/chats_repository.dart';
import '../discover/discover_repository.dart';
import '../discover/application/move_in_filter.dart';
import '../shared/presentation/flatmates_empty_state.dart';
import '../shared/presentation/flatmates_error_state.dart';
import '../shared/presentation/flatmates_search_bar.dart';
import '../shared/presentation/flatmates_skeleton.dart';
import 'presentation/widgets/map_filter_bar.dart';
import 'presentation/widgets/map_listing_sheets.dart';
import 'presentation/widgets/map_marker_builder.dart';

class MapViewPage extends ConsumerStatefulWidget {
  const MapViewPage({super.key});

  @override
  ConsumerState<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends ConsumerState<MapViewPage> {
  double _budgetMin = 5000;
  double _budgetMax = 100000;
  String _roomType = 'all';
  String _moveInFilter = 'all';
  String _genderPref = 'any';
  bool _verifiedOnly = false;
  final _searchController = TextEditingController();

  final Map<int, BitmapDescriptor> _clusterIconCache = {};
  List<PropertyListing>? _previousListings;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(discoverListingsProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Floating search/filter control at top
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.md,
                AppSpacing.screen,
                AppSpacing.xs,
              ),
              child: FlatmatesSearchBar(
                controller: _searchController,
                hint: locale.homeSearchHint,
                readOnly: true,
                onTap: () => _showFilterSheet(context),
                trailingIcon: Icons.tune_rounded,
                onTrailingTap: () => _showFilterSheet(context),
              ),
            ),
            MapFilterBar(
              budgetMin: _budgetMin,
              budgetMax: _budgetMax,
              roomType: _roomType,
              moveInFilter: _moveInFilter,
              genderPref: _genderPref,
              verifiedOnly: _verifiedOnly,
              onBudgetChanged: (min, max) => setState(() {
                _budgetMin = min;
                _budgetMax = max;
              }),
              onRoomTypeChanged: (v) => setState(() => _roomType = v),
              onMoveInChanged: (v) => setState(() => _moveInFilter = v),
              onGenderChanged: (v) => setState(() => _genderPref = v),
              onVerifiedChanged: (v) => setState(() => _verifiedOnly = v),
            ),
            Expanded(
              child: listings.when(
                data: (items) {
                  if (!identical(items, _previousListings)) {
                    _clusterIconCache.clear();
                    _previousListings = items;
                  }
                  final filtered = _applyFilters(items);
                  final markers = buildClusteredMarkers(
                    items: filtered,
                    theme: theme,
                    clusterIconCache: _clusterIconCache,
                    onListingTap: _handleListingTap,
                    onClusterTap: _handleClusterTap,
                  );
                  final sortedMarkers = markers.toList()
                    ..sort(
                      (a, b) =>
                          a.position.latitude.compareTo(b.position.latitude),
                    );
                  final firstPosition = sortedMarkers.isEmpty
                      ? null
                      : sortedMarkers.first.position;
                  if (firstPosition == null) {
                    return FlatmatesEmptyState(
                      title: items.isEmpty
                          ? locale.emptyListings
                          : locale.noListingsMatchFilters,
                      icon: Icons.map_outlined,
                    );
                  }
                  return Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: firstPosition,
                          zoom: 12,
                        ),
                        markers: markers,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                      if (filtered.isEmpty)
                        FlatmatesEmptyState(
                          title: items.isEmpty
                              ? locale.emptyListings
                              : locale.noListingsMatchFilters,
                          icon: Icons.map_outlined,
                        ),
                    ],
                  );
                },
                loading: () => const FlatmatesSkeleton.card(),
                error: (e, _) => FlatmatesErrorState(
                  message: locale.couldNotLoadListing,
                  onRetry: () => ref.invalidate(discoverListingsProvider),
                  retryLabel: locale.commonRetry,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    context.push('/search-filters');
  }

  void _handleListingTap(PropertyListing item) {
    showListingSheet(
      context,
      item: item,
      onLike: () async {
        try {
          final conversationId = await ref
              .read(discoverRepositoryProvider)
              .likeListing(item.id);
          ref.invalidate(discoverListingsProvider);
          ref.invalidate(conversationsProvider);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                conversationId == null
                    ? AppLocalizations.of(context).contactRequestSent
                    : AppLocalizations.of(
                        context,
                      ).contactRequestWithConversation(conversationId),
              ),
            ),
          );
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).actionFailedRetry),
            ),
          );
        }
      },
    );
  }

  void _handleClusterTap(List<PropertyListing> clusterItems) {
    showClusterSheet(
      context,
      clusterItems: clusterItems,
      onListingTap: _handleListingTap,
    );
  }

  List<PropertyListing> _applyFilters(List<PropertyListing> items) {
    return items.where((item) {
      // Budget filter
      if (item.monthlyRent < _budgetMin || item.monthlyRent > _budgetMax) {
        return false;
      }

      // Room type filter
      if (_roomType != 'all') {
        if (item.sharingType != _roomType) return false;
      }

      // Gender preference filter
      if (_genderPref != 'any') {
        if (item.genderPreference != null &&
            item.genderPreference != 'any' &&
            item.genderPreference != _genderPref) {
          return false;
        }
      }

      // Move-in / availability filter
      if (!listingMatchesMoveInFilter(item.availableFrom, _moveInFilter)) {
        return false;
      }

      // Verified filter
      if (_verifiedOnly) {
        final isVerified =
            item.features.contains('verified') ||
            item.features.contains('is_verified');
        if (!isVerified) return false;
      }

      return true;
    }).toList();
  }
}
