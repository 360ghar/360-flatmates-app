import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/debouncer.dart';
import '../../shared/presentation/components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/discover_feed_controller.dart';
import 'widgets/broadened_radius_banner.dart';
import 'widgets/browse_listings_card.dart';
import 'widgets/filter_sheet.dart';

class BrowseListingsPage extends ConsumerStatefulWidget {
  const BrowseListingsPage({super.key});

  @override
  ConsumerState<BrowseListingsPage> createState() => _BrowseListingsPageState();
}

class _BrowseListingsPageState extends ConsumerState<BrowseListingsPage> {
  static const double _loadMoreThreshold = 500;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchDebouncer = ActionDebouncer(
    duration: const Duration(milliseconds: 400),
  );
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final filters = ref.read(discoverFeedControllerProvider).filters;
    _searchController.text = filters.query ?? '';
    if (_searchController.text.isNotEmpty) {
      _isSearchActive = true;
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(discoverFeedControllerProvider.notifier).loadMore();
    }
  }

  void _applySearchQuery(String? query) {
    ref.read(discoverFeedControllerProvider.notifier).updateSearchQuery(query);
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final feedState = ref.watch(discoverFeedControllerProvider);
    final filtered = ref.watch(filteredListingsProvider);
    final isSearchActive = _isSearchActive;

    return Scaffold(
      appBar: FlatmatesHeader.backTitle(
        title: isSearchActive ? null : locale.homePickedForYou,
        titleWidget: isSearchActive
            ? Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: FlatmatesSearchBar(
                  controller: _searchController,
                  hint: locale.searchCityOrAreaHint,
                  onChanged: (query) {
                    _searchDebouncer.run(() {
                      if (!mounted) return;
                      _applySearchQuery(query.isEmpty ? null : query);
                    });
                  },
                  trailingIcon: _searchController.text.isNotEmpty
                      ? Icons.close_rounded
                      : null,
                  onTrailingTap: () {
                    // Cancel any pending debounced query so clear wins.
                    _searchDebouncer.dispose();
                    _searchController.clear();
                    _applySearchQuery(null);
                  },
                  autofocus: _searchController.text.isEmpty,
                ),
              )
            : null,
        onBack: () => context.pop(),
        actions: [
          if (isSearchActive)
            FlatmatesChromeIconButton(
              key: const Key('browse_search_close'),
              tooltip: locale.closeSearch,
              onPressed: () {
                // Cancel any pending debounced query so clear wins.
                _searchDebouncer.dispose();
                _searchController.clear();
                _applySearchQuery(null);
                setState(() => _isSearchActive = false);
              },
              icon: Icons.close_rounded,
            )
          else
            FlatmatesChromeIconButton(
              key: const Key('browse_search_open'),
              tooltip: locale.searchCityOrAreaHint,
              onPressed: () => setState(() => _isSearchActive = true),
              icon: AppIcons.search,
            ),
          FlatmatesChromeIconButton(
            key: const Key('browse_filter_tune'),
            tooltip: locale.searchFiltersTitle,
            onPressed: () => showFiltersSheet(context),
            icon: AppIcons.filter,
          ),
        ],
      ),
      body: feedState.isLoading && filtered.isEmpty
          ? const FlatmatesSkeleton.browseListings()
          : filtered.isEmpty && feedState.hasError
          ? FlatmatesErrorState(
              message: locale.actionFailedRetry,
              onRetry: () =>
                  ref.read(discoverFeedControllerProvider.notifier).refresh(),
            )
          : filtered.isEmpty
          ? FlatmatesEmptyState(
              title: locale.homeNoResults,
              subtitle: locale.homeNoResultsSubtitle,
              icon: Icons.search_off_rounded,
            )
          : Column(
              children: [
                if (feedState.isBroadened)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      0,
                    ),
                    child: BroadenedRadiusBanner(
                      message: locale.homeBroadenedRadius,
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      120,
                    ),
                    // +1 footer row when more pages may still load.
                    itemCount: filtered.length + (feedState.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      if (index >= filtered.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Center(
                            child: feedState.isLoadingMore
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const SizedBox(height: 24),
                          ),
                        );
                      }
                      return BrowseListingsCard(
                        item: filtered[index],
                        index: index,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
