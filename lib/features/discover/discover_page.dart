import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/utils/debouncer.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../chats/chats_repository.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'discover_repository.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final _searchController = TextEditingController();
  int? _selectedBedrooms;
  String? _selectedFeature;
  String _selectedVibe = 'all';
  final _likeDebouncer = ActionDebouncer(duration: const Duration(milliseconds: 500));

  static const _vibeOptions = [
    ('all', Icons.apps_rounded),
    ('quiet_focused', Icons.nightlight_outlined),
    ('social_lively', Icons.celebration_outlined),
    ('working_prof', Icons.work_outline),
    ('students', Icons.school_outlined),
    ('pet_household', Icons.pets_outlined),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _likeDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(discoverListingsProvider);
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = bootstrap?.profile;
    final currentLocation = [
      if (profile?.locality != null && profile!.locality!.trim().isNotEmpty)
        profile.locality!.trim(),
      if (profile?.city != null && profile!.city!.trim().isNotEmpty)
        profile.city!.trim(),
    ].join(', ');

    return Scaffold(
      body: SafeArea(
        child: listings.when(
          data: (items) {
            final visibleItems = items
                .where((item) => item.ownerId != profile?.id)
                .toList();
            final bedroomOptions =
                visibleItems
                    .map((item) => item.bedrooms)
                    .whereType<int>()
                    .toSet()
                    .toList()
                  ..sort();
            final featureOptions =
                visibleItems
                    .expand((item) => item.features)
                    .map(
                      (feature) =>
                          localizedFlatmatesFeatureLabel(locale, feature),
                    )
                    .where((feature) => feature.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();

            final query = _searchController.text.trim().toLowerCase();
            final filtered = visibleItems.where((item) {
              final matchesBedrooms =
                  _selectedBedrooms == null ||
                  item.bedrooms == _selectedBedrooms;
              final matchesFeature =
                  _selectedFeature == null ||
                  item.features
                      .map(
                        (feature) =>
                            localizedFlatmatesFeatureLabel(locale, feature),
                      )
                      .contains(_selectedFeature);
              final searchable = [
                item.title,
                item.locality,
                item.subLocality,
                item.city,
                item.description,
                item.ownerName,
                ...item.tags,
                ...item.features,
              ].whereType<String>().join(' ').toLowerCase();
              final matchesQuery = query.isEmpty || searchable.contains(query);
              return matchesBedrooms && matchesFeature && matchesQuery;
            }).toList();

            if (visibleItems.isEmpty) {
              return Center(child: Text(locale.emptyListings));
            }

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(discoverListingsProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locale.homeGreeting(
                                profile?.fullName ?? locale.profileFallbackName,
                              ),
                              style: theme.textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    currentLocation.isEmpty
                                        ? locale.homeLocationFallback
                                        : currentLocation,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          IconButton(
                            onPressed: () => context.push('/map'),
                            icon: const Icon(Icons.map_outlined),
                            tooltip: 'Map',
                          ),
                          FlatmatesAvatar(
                            name: profile?.fullName,
                            imageUrl: profile?.profileImageUrl,
                            size: 52,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: locale.homeSearchHint,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (currentLocation.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: FilterChip(
                              label: Text(currentLocation),
                              selected: false,
                              onSelected: (_) {},
                              avatar: const Icon(
                                Icons.near_me_outlined,
                                size: 18,
                              ),
                            ),
                          ),
                        ...bedroomOptions.map((value) {
                          final selected = _selectedBedrooms == value;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: FilterChip(
                              label: Text(locale.homeBedroomsChip(value)),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedBedrooms = selected ? null : value;
                                });
                              },
                            ),
                          );
                        }),
                        ...featureOptions.take(4).map((feature) {
                          final selected = _selectedFeature == feature;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: FilterChip(
                              label: Text(feature),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedFeature = selected ? null : feature;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _vibeOptions.map((opt) {
                        final key = opt.$1;
                        final selected = _selectedVibe == key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: FilterChip(
                            avatar: Icon(opt.$2, size: 16),
                            label: Text(_vibeLabel(locale, key)),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                _selectedVibe = selected ? 'all' : key;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (profile?.city != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InfoPill(
                        icon: Icons.people_outline,
                        label: locale.cityCounter(visibleItems.length, profile!.city!),
                        highlighted: true,
                      ),
                    ),
                  const SizedBox(height: 10),
                  FlatmatesSectionHeader(
                    title: locale.homePickedForYou,
                    subtitle: locale.homePickedSubtitle,
                    actionLabel: filtered.length > 2 ? locale.seeAllCta : null,
                    onActionTap: () {},
                  ),
                  const SizedBox(height: 18),
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(locale.homeNoResults),
                      ),
                    )
                  else
                    SizedBox(
                      height: 370,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final badgeLabel = switch (index) {
                            0 => locale.badgeNew,
                            1 => locale.badgePopular,
                            _ =>
                              item.interestCount > 1 ? locale.badgeTrending : null,
                          };

                          return SizedBox(
                            width: 300,
                            child: _DiscoverCard(
                              item: item,
                              badgeLabel: badgeLabel,
                              onLike: () {
                                _likeDebouncer.run(() {
                                  ref
                                      .read(discoverRepositoryProvider)
                                      .likeListing(item.id)
                                      .then((conversationId) {
                                    ref.invalidate(discoverListingsProvider);
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
                                  });
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  // --- New in [City] section ---
                  if (profile?.city != null) ...[
                    const SizedBox(height: 28),
                    FlatmatesSectionHeader(
                      title: locale.homeNewInCity(profile!.city!),
                    ),
                    const SizedBox(height: 18),
                    _NewInCitySection(
                      items: filtered,
                      onLike: (item) {
                        _likeDebouncer.run(() {
                          ref
                              .read(discoverRepositoryProvider)
                              .likeListing(item.id)
                              .then((conversationId) {
                            ref.invalidate(discoverListingsProvider);
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
                          });
                        });
                      },
                    ),
                  ],
                  // --- Moving Soon section ---
                  const SizedBox(height: 28),
                  FlatmatesSectionHeader(
                    title: locale.homeMovingSoon,
                  ),
                  const SizedBox(height: 18),
                  _MovingSoonSection(
                    items: filtered,
                    onLike: (item) {
                      _likeDebouncer.run(() {
                        ref
                            .read(discoverRepositoryProvider)
                            .likeListing(item.id)
                            .then((conversationId) {
                          ref.invalidate(discoverListingsProvider);
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
                        });
                      });
                    },
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
      ),
    );
  }

  String _vibeLabel(AppLocalizations locale, String key) {
    switch (key) {
      case 'all':
        return locale.vibeAll;
      case 'quiet_focused':
        return locale.vibeQuietFocused;
      case 'social_lively':
        return locale.vibeSocialLively;
      case 'working_prof':
        return locale.vibeWorkingProf;
      case 'students':
        return locale.vibeStudents;
      case 'pet_household':
        return locale.vibePetHousehold;
      default:
        return humanizeFlatmatesToken(key);
    }
  }
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({
    required this.item,
    required this.onLike,
    this.badgeLabel,
  });

  final PropertyListing item;
  final VoidCallback onLike;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final titleLocation = [
      if (item.locality != null && item.locality!.trim().isNotEmpty)
        item.locality!.trim(),
      if (item.subLocality != null && item.subLocality!.trim().isNotEmpty)
        item.subLocality!.trim(),
    ].join(', ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ListingImage(imageUrl: item.mainImageUrl, title: item.title),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badgeLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InfoPill(label: badgeLabel!, highlighted: true),
                    ),
                  Text(
                    item.monthlyRent == null
                        ? item.title
                        : locale.monthlyRentHeadline(
                            item.monthlyRent!.toStringAsFixed(0),
                          ),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 26,
                    ),
                  ),
                  if (item.monthlyRent != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        item.title,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  if (titleLocation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 17,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            titleLocation,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item.bedrooms != null)
                        InfoPill(
                          icon: Icons.bed_outlined,
                          label: locale.homeBedsValue(item.bedrooms!),
                        ),
                      if (item.bathrooms != null)
                        InfoPill(
                          icon: Icons.bathtub_outlined,
                          label: locale.homeBathsValue(item.bathrooms!),
                        ),
                      if (item.areaSqft != null)
                        InfoPill(
                          icon: Icons.straighten_outlined,
                          label: locale.homeAreaValue(
                            item.areaSqft!.toStringAsFixed(0),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      FlatmatesAvatar(name: item.ownerName, size: 34),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.ownerName ?? locale.ownerFallbackLabel,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (item.interestCount > 0)
                        Text(
                          locale.homeInterestCount(item.interestCount),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  if (item.description != null &&
                      item.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item.features.isNotEmpty)
                        InfoPill(
                          icon: Icons.chair_outlined,
                          label: localizedFlatmatesFeatureLabel(
                            locale,
                            item.features.first,
                          ),
                          highlighted: item.isFurnished,
                        ),
                      if (item.availableFrom != null)
                        InfoPill(
                          icon: Icons.event_outlined,
                          label: locale.homeMoveInValue(
                            DateFormat(
                              'd MMM',
                              locale.localeName,
                            ).format(item.availableFrom!.toLocal()),
                          ),
                        ),
                      if (item.genderPreference != null)
                        InfoPill(
                          icon: Icons.group_outlined,
                          label: localizedFlatmatesGenderLabel(
                            locale,
                            item.genderPreference!,
                          ),
                        ),
                      if (item.sharingType != null)
                        InfoPill(
                          icon: Icons.meeting_room_outlined,
                          label: localizedFlatmatesSharingTypeLabel(
                            locale,
                            item.sharingType!,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GradientActionButton(
                    key: Key('discover_like_${item.id}'),
                    label: locale.likeListingCta,
                    onPressed: onLike,
                    icon: Icons.favorite_border_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({required this.imageUrl, required this.title});

  final String? imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return SizedBox(
      width: 148,
      child: AspectRatio(
        aspectRatio: 0.82,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      _ListingImageFallback(title: title),
                )
              else
                _ListingImageFallback(title: title),
              Positioned(
                right: 12,
                top: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.favorite_border_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingImageFallback extends StatelessWidget {
  const _ListingImageFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.9),
            theme.colorScheme.primary.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Icon(Icons.apartment_rounded, color: Colors.white, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _NewInCitySection extends StatelessWidget {
  const _NewInCitySection({required this.items, required this.onLike});

  final List<PropertyListing> items;
  final void Function(PropertyListing) onLike;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 48));
    final newItems = items.where((item) {
      if (item.createdAt != null) {
        return item.createdAt!.isAfter(cutoff);
      }
      return false;
    }).toList();
    // Fallback: if no items have createdAt, use the top 3 as proxy
    final displayItems =
        newItems.isNotEmpty ? newItems : items.take(3).toList();

    if (displayItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 370,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = displayItems[index];
          return SizedBox(
            width: 300,
            child: _DiscoverCard(
              item: item,
              badgeLabel: AppLocalizations.of(context).badgeNew,
              onLike: () => onLike(item),
            ),
          );
        },
      ),
    );
  }
}

class _MovingSoonSection extends StatelessWidget {
  const _MovingSoonSection({required this.items, required this.onLike});

  final List<PropertyListing> items;
  final void Function(PropertyListing) onLike;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sevenDays = now.add(const Duration(days: 7));
    final movingSoon = items.where((item) {
      if (item.availableFrom == null) return false;
      final date = item.availableFrom!;
      return date.isAfter(now) && date.isBefore(sevenDays);
    }).toList();

    if (movingSoon.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            AppLocalizations.of(context).homeNoResults,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 370,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: movingSoon.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = movingSoon[index];
          final daysLeft =
              item.availableFrom!.toLocal().difference(now.toLocal()).inDays;
          return SizedBox(
            width: 300,
            child: _DiscoverCard(
              item: item,
              badgeLabel: '$daysLeft d left',
              onLike: () => onLike(item),
            ),
          );
        },
      ),
    );
  }
}
