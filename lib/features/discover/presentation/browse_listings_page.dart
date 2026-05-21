import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../chats/chats_repository.dart';
import '../../shared/presentation/flatmates_empty_state.dart';
import '../../shared/presentation/flatmates_error_state.dart';
import '../../shared/presentation/flatmates_network_image.dart';
import '../../shared/presentation/flatmates_price_text.dart';
import '../../shared/presentation/flatmates_search_bar.dart';
import '../../shared/presentation/flatmates_skeleton.dart';
import '../discover_repository.dart';
import '../application/discover_feed_controller.dart';

class BrowseListingsPage extends ConsumerStatefulWidget {
  const BrowseListingsPage({super.key});

  @override
  ConsumerState<BrowseListingsPage> createState() => _BrowseListingsPageState();
}

class _BrowseListingsPageState extends ConsumerState<BrowseListingsPage> {
  final _searchController = TextEditingController();
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(discoverFeedControllerProvider).filters;
    _searchController.text = filters.query ?? '';
    if (_searchController.text.isNotEmpty) _isSearchActive = true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final feedState = ref.watch(discoverFeedControllerProvider);
    final filtered = ref.watch(filteredListingsProvider(locale));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(locale.homePickedForYou),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                if (_isSearchActive) ...[
                  Expanded(
                    child: FlatmatesSearchBar(
                      controller: _searchController,
                      hint: locale.searchCityOrAreaHint,
                      onChanged: (query) {
                        ref
                            .read(discoverFeedControllerProvider.notifier)
                            .updateSearchQuery(query.isEmpty ? null : query);
                        setState(() {});
                      },
                      trailingIcon: _searchController.text.isNotEmpty
                          ? Icons.close_rounded
                          : null,
                      onTrailingTap: () {
                        _searchController.clear();
                        ref
                            .read(discoverFeedControllerProvider.notifier)
                            .updateSearchQuery(null);
                        setState(() {});
                      },
                      autofocus: _searchController.text.isEmpty,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ] else ...[
                  IconButton.outlined(
                    onPressed: () => setState(() => _isSearchActive = true),
                    icon: const Icon(Icons.search_rounded),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                IconButton.filledTonal(
                  key: const Key('browse_filter_tune'),
                  onPressed: () => context.push('/search-filters'),
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: feedState.isLoading && filtered.isEmpty
                ? const Center(child: FlatmatesSkeleton.feed())
                : filtered.isEmpty && feedState.hasError
                ? FlatmatesErrorState(
                    message: locale.actionFailedRetry,
                    onRetry: () => ref
                        .read(discoverFeedControllerProvider.notifier)
                        .refresh(),
                  )
                : filtered.isEmpty
                ? FlatmatesEmptyState(
                    title: locale.homeNoResults,
                    subtitle: locale.homeNoResultsSubtitle,
                    icon: Icons.search_off_rounded,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      120,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      return _BrowseListingsCard(
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

class _BrowseListingsCard extends ConsumerStatefulWidget {
  const _BrowseListingsCard({required this.item, required this.index});

  final PropertyListing item;
  final int index;

  @override
  ConsumerState<_BrowseListingsCard> createState() =>
      _BrowseListingsCardState();
}

class _BrowseListingsCardState extends ConsumerState<_BrowseListingsCard> {
  bool _pressed = false;
  final Set<int> _pendingLikeIds = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final item = widget.item;
    final isDark = theme.brightness == Brightness.dark;

    final titleLocation = [
      if (item.locality != null && item.locality!.trim().isNotEmpty)
        item.locality!.trim(),
      if (item.subLocality != null && item.subLocality!.trim().isNotEmpty)
        item.subLocality!.trim(),
    ].join(', ');

    final metaParts = <String>[
      if (item.bedrooms != null) locale.homeBedsValue(item.bedrooms!),
      if (item.bathrooms != null) locale.homeBathsValue(item.bathrooms!),
    ];
    final genderSuffix = switch (item.genderPreference) {
      'male' => locale.genderSuffixMaleOnly,
      'female' => locale.genderSuffixFemaleOnly,
      _ => locale.genderSuffixAny,
    };
    metaParts.add(genderSuffix);

    final hasImage =
        item.mainImageUrl != null && item.mainImageUrl!.trim().isNotEmpty;

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.easeOutCubic,
        height: 110,
        decoration: BoxDecoration(
          color: isDark
              ? AppSemanticColors.darkSurface
              : AppSemanticColors.card,
          borderRadius: AppRadius.cardBorder,
          boxShadow: [
            AppShadows.cardFor(theme.brightness),
            if (_pressed) AppShadows.subtleGlowFor(theme.brightness),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.cardBorder,
          child: InkWell(
            onTap: () => context.push('/flat-details/${item.id}'),
            borderRadius: AppRadius.cardBorder,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.card),
                  ),
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: hasImage
                        ? FlatmatesNetworkImage(
                            imageUrl: item.mainImageUrl!,
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppSemanticColors.accent.withValues(
                                    alpha: 0.85,
                                  ),
                                  AppSemanticColors.accent.withValues(
                                    alpha: 0.45,
                                  ),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.apartment_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatRent(item.monthlyRent.round()),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppSemanticColors.textPrimaryFor(
                              theme.brightness,
                            ),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (titleLocation.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: AppSemanticColors.textSecondaryFor(
                                  theme.brightness,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  titleLocation,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: AppSemanticColors.textSecondaryFor(
                                      theme.brightness,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (metaParts.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            metaParts.join(' \u00b7 '),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: AppSemanticColors.textTertiaryFor(
                                theme.brightness,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    right: AppSpacing.sm,
                    top: AppSpacing.sm,
                  ),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      key: Key('browse_like_${item.id}'),
                      onPressed: () {
                        if (_pendingLikeIds.contains(item.id)) return;
                        _pendingLikeIds.add(item.id);
                        ref
                            .read(discoverRepositoryProvider)
                            .likeListing(item.id)
                            .then((conversationId) {
                              _pendingLikeIds.remove(item.id);
                              ref
                                  .read(discoverFeedControllerProvider.notifier)
                                  .refresh();
                              ref.invalidate(conversationsProvider);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    conversationId == null
                                        ? locale.contactRequestSent
                                        : locale.contactRequestWithConversation(
                                            conversationId,
                                          ),
                                  ),
                                ),
                              );
                            })
                            .catchError((_) {
                              _pendingLikeIds.remove(item.id);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(locale.actionFailedRetry),
                                ),
                              );
                            });
                      },
                      icon: const Icon(Icons.favorite_border_rounded, size: 14),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: AppSemanticColors.accentSoft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatRent(int amount) {
    if (amount >= 100000) {
      final lakhs = amount / 100000;
      final value = lakhs.toStringAsFixed(lakhs >= 10 ? 1 : 2);
      final compact = value.replaceAll(RegExp(r'\.?0+$'), '');
      return '\u20b9${compact}L';
    }
    return FlatmatesPriceText.formatRupee(amount);
  }
}
