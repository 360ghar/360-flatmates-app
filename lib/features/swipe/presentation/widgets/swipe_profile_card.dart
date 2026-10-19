import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/compatibility/compatibility_engine.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../location/presentation/map_widgets.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../swipe_repository.dart';
import 'swipe_card_components.dart';

// ── Scrollable Swipe Profile Card ──────────────────────────────────────

/// Profile card for the swipe deck.
///
/// Owns a single vertical [ListView]:
/// 1. [FlatmatesCard] chrome around profile sections only
/// 2. Optional [trailing] (e.g. [SwipeActionBar]) **outside** the card so
///    controls read as floating below the closed card edge
///
/// When [trailing] is set, the card block is min-height constrained to the
/// viewport so actions stay below the fold until the user scrolls.
///
/// Phone hero height: images read edge-to-edge without feeling cropped or
/// letterboxed at the 466 / 669 / 678 dp poses.
const double _swipeCardHeroHeight = 460;

/// Hero *shape* (width / height) once the viewport is wide.
///
/// A wide card kept the phone's fixed 460 dp hero, so the open foldable
/// (951 dp) turned the photo into a 2:1 letterbox that showed only ~37 % of a
/// portrait photo's height. Bounding the aspect ratio instead of the height
/// keeps the hero reading as a photo at every width: 4:3 is the flattest shape
/// that still reads as a photo rather than a strip.
const double _swipeCardHeroAspectRatio = 4 / 3;

/// Hero height for the swipe card, resolved from the card's own width.
///
/// - Below [AppBreakpoints.expanded] (466, 669 and 678 dp — every phone pose)
///   this is [_swipeCardHeroHeight], so the phone layout is unchanged.
/// - From [expanded] up the hero is [cardWidth] at
///   [_swipeCardHeroAspectRatio], so a 919 dp card gets a 689 dp photo instead
///   of a 460 dp strip.
/// - The viewport height caps it, less one [AppSpacing.section] of breathing
///   room: the wide pose is the *landscape* foldable (951 × 669), where a 4:3
///   hero at full card width would be taller than the screen and could never be
///   seen whole. The cap keeps the hero inside the viewport and leaves the top
///   of the profile visible below it, so the card still reads as scrollable.
/// - The phone height is a floor, so a short window never shrinks the hero
///   below what a phone already rendered.
double swipeCardHeroHeight({
  required double viewportWidth,
  required double viewportHeight,
  required double cardWidth,
}) {
  if (!AppBreakpoints.isExpanded(viewportWidth)) {
    return _swipeCardHeroHeight;
  }
  final aspectHeight = cardWidth / _swipeCardHeroAspectRatio;
  final viewportCap = viewportHeight - AppSpacing.section;
  return math.max(_swipeCardHeroHeight, math.min(aspectHeight, viewportCap));
}

class SwipeProfileCard extends StatelessWidget {
  const SwipeProfileCard({
    required this.item,
    required this.compatibility,
    this.trailing,
    super.key,
  });

  final SwipeProfile item;
  final CompatibilityResult compatibility;

  /// Floating actions after the card ends (foreground swipe controls).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight;
          final forceBelowFold =
              trailing != null && maxHeight.isFinite && maxHeight > 0;

          // The hero height depends on the card's own width, which is only
          // known here (the page may cap the card: `FlatmatesScreen` bounds the
          // body at `AppBreakpoints.contentMaxWidth`), so the sections are
          // built inside the builder rather than from the viewport width.
          final profileCard = FlatmatesCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: AppRadius.cardBorder,
              child: _SwipeProfileSections(
                item: item,
                compatibility: compatibility,
                showStatsOnHero: true,
                heroHeight: swipeCardHeroHeight(
                  viewportWidth: viewport.width,
                  viewportHeight: viewport.height,
                  cardWidth: constraints.maxWidth,
                ),
              ),
            ),
          );

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            // ignore: deprecated_member_use
            cacheExtent: forceBelowFold ? maxHeight : null,
            children: [
              ConstrainedBox(
                constraints: forceBelowFold
                    ? BoxConstraints(minHeight: maxHeight)
                    : const BoxConstraints(),
                // Align fills the minHeight box while keeping the card
                // content-sized at the top — empty space under the card stays
                // outside chrome so the action bar remains below the fold.
                child: forceBelowFold
                    ? Align(alignment: Alignment.topCenter, child: profileCard)
                    : profileCard,
              ),
              if (trailing != null) ...[
                const SizedBox(height: AppSpacing.md),
                // Claim horizontal drags on the action strip so the parent
                // card-level swipe GestureDetector does not compete with taps.
                GestureDetector(
                  onHorizontalDragStart: (_) {},
                  onHorizontalDragUpdate: (_) {},
                  onHorizontalDragEnd: (_) {},
                  behavior: HitTestBehavior.opaque,
                  child: trailing,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// The scrollable rich profile body shared with the profile sheet.
///
/// Layout: hero carousel → quick stats pills → about → compatibility →
/// the place → people → costs. Renders a [ListView] so it scrolls natively
/// wherever it is hosted. Does **not** host swipe action controls.
///
/// When [trailing] is set, it renders below the profile sections (e.g. a
/// Contact CTA button).
class SwipeProfileDetailBody extends StatelessWidget {
  const SwipeProfileDetailBody({
    required this.item,
    required this.compatibility,
    this.trailing,
    super.key,
  });

  final SwipeProfile item;
  final CompatibilityResult compatibility;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _SwipeProfileSections(item: item, compatibility: compatibility),
        if (trailing != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: trailing,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }
}

/// Shared profile content used by the swipe card and the profile sheet.
///
/// Renders as a [Column] so a parent [ListView] can place card chrome around
/// it without nesting scrollables.
class _SwipeProfileSections extends StatelessWidget {
  const _SwipeProfileSections({
    required this.item,
    required this.compatibility,
    this.showStatsOnHero = false,
    this.heroHeight = kDefaultHeroHeight,
  });

  final SwipeProfile item;
  final CompatibilityResult compatibility;

  /// When true, quick stats render on the hero image (swipe card). When false,
  /// they render as a row below the hero (profile sheet).
  final bool showStatsOnHero;
  final double heroHeight;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final details = item.listingDetails;

    // Coerce strings and numbers — API may emit floor/total_floors as ints.
    String? str(String key) {
      final v = details[key];
      if (v == null) return null;
      if (v is String) {
        final t = v.trim();
        return t.isEmpty ? null : t;
      }
      if (v is num) return v.toString();
      return null;
    }

    List<String> strList(String key) {
      final v = details[key];
      if (v is List) {
        return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      return const [];
    }

    double? dbl(String key) {
      final v = details[key];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    final allImages = <String>{
      if (item.profileImageUrl != null &&
          item.profileImageUrl!.trim().isNotEmpty)
        item.profileImageUrl!,
      ...item.imageUrls,
    }.toList(growable: false);

    final roomType = str('room_type');
    final flatConfig = str('flat_config');
    final floor = str('floor');
    final totalFloors = str('total_floors');
    final societyName = str('society_name');
    final furnishing = strList('furnishing');
    final flatAmenities = strList('flat_amenities');
    final roomFeatures = strList('room_features');
    final availableFrom = str('available_from');
    final videoTourUrl = str('video_tour_url');
    // Only real listing rent — never fall back to seeker budget (would mislabel costs).
    final monthlyRent = dbl('monthly_rent');
    final securityDeposit = dbl('security_deposit');
    final maintenance = dbl('maintenance');
    final lat = dbl('latitude');
    final lng = dbl('longitude');
    final hasPlaceContent =
        (item.locality != null && item.locality!.trim().isNotEmpty) ||
        (item.city != null && item.city!.trim().isNotEmpty) ||
        (societyName != null && societyName.isNotEmpty) ||
        (roomType != null && roomType.isNotEmpty) ||
        (flatConfig != null && flatConfig.isNotEmpty) ||
        (floor != null && floor.isNotEmpty) ||
        flatAmenities.isNotEmpty ||
        roomFeatures.isNotEmpty ||
        (availableFrom != null && availableFrom.isNotEmpty) ||
        (lat != null && lng != null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeroCarousel(
          images: allImages,
          name: item.fullName,
          mode: item.mode ?? 'open_to_both',
          compatibility: compatibility,
          item: item,
          showStatsOverlay: showStatsOnHero,
          heroHeight: heroHeight,
          quickStats: buildQuickStatPills(
            context: context,
            item: item,
            roomType: roomType,
            flatConfig: flatConfig,
            furnishing: furnishing,
            availableFrom: availableFrom,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (!showStatsOnHero)
          QuickStatsRow(
            item: item,
            roomType: roomType,
            flatConfig: flatConfig,
            furnishing: furnishing,
            availableFrom: availableFrom,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              AboutSection(
                bio: item.bio,
                videoTourUrl: videoTourUrl,
                compatibility: compatibility,
              ),
              const SizedBox(height: AppSpacing.xl),
              LifestylePreferencesSection(item: item),
              if (_hasLifestyle(item)) const SizedBox(height: AppSpacing.xl),
              PreferencesSection(item: item),
              const SizedBox(height: AppSpacing.xl),
              DealBreakersSection(nonNegotiables: item.nonNegotiables),
              if (item.nonNegotiables.isNotEmpty)
                const SizedBox(height: AppSpacing.xl),
              if (compatibility.dimensions.isNotEmpty) ...[
                SectionHeader(label: locale.compatibilityBreakdown),
                const SizedBox(height: AppSpacing.sm),
                CompactCompatibilityBreakdown(result: compatibility),
                const SizedBox(height: AppSpacing.xl),
              ],
              if (hasPlaceContent)
                _PlaceBlock(
                  locality: item.locality,
                  city: item.city,
                  societyName: societyName,
                  roomType: roomType,
                  flatConfig: flatConfig,
                  floor: floor,
                  flatAmenities: flatAmenities,
                  lat: lat,
                  lng: lng,
                  fallbackLabel:
                      item.locality ??
                      item.city ??
                      locale.propertyFallbackLabel,
                  roomFeatures: roomFeatures,
                  availableFrom: availableFrom,
                  totalFloors: totalFloors,
                ),
              if (monthlyRent != null) ...[
                const SizedBox(height: AppSpacing.xl),
                CostsSection(
                  monthlyRent: monthlyRent,
                  securityDeposit: securityDeposit,
                  maintenance: maintenance,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ],
    );
  }
}

bool _hasLifestyle(SwipeProfile item) {
  bool nonEmpty(String? v) => v != null && v.trim().isNotEmpty;
  return nonEmpty(item.sleepSchedule) ||
      nonEmpty(item.cleanliness) ||
      nonEmpty(item.foodHabits) ||
      nonEmpty(item.smoking) ||
      nonEmpty(item.drinking) ||
      nonEmpty(item.guestsPolicy) ||
      nonEmpty(item.workStyle) ||
      nonEmpty(item.partyHabit);
}

/// Wraps [ThePlaceSection] with an optional [MiniMapView] + directions CTA
/// when geo-coordinates are available.
class _PlaceBlock extends StatelessWidget {
  const _PlaceBlock({
    required this.locality,
    required this.city,
    required this.societyName,
    required this.roomType,
    required this.flatConfig,
    required this.floor,
    required this.flatAmenities,
    required this.lat,
    required this.lng,
    required this.fallbackLabel,
    this.roomFeatures = const [],
    this.availableFrom,
    this.totalFloors,
  });

  final String? locality;
  final String? city;
  final String? societyName;
  final String? roomType;
  final String? flatConfig;
  final String? floor;
  final List<String> flatAmenities;
  final double? lat;
  final double? lng;
  final String fallbackLabel;
  final List<String> roomFeatures;
  final String? availableFrom;
  final String? totalFloors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ThePlaceSection(
          locality: locality,
          city: city,
          societyName: societyName,
          roomType: roomType,
          flatConfig: flatConfig,
          floor: floor,
          flatAmenities: flatAmenities,
          lat: lat,
          lng: lng,
          fallbackLabel: fallbackLabel,
          roomFeatures: roomFeatures,
          availableFrom: availableFrom,
          totalFloors: totalFloors,
        ),
        if (lat != null && lng != null) ...[
          const SizedBox(height: AppSpacing.md),
          MiniMapView(latitude: lat!, longitude: lng!, height: 140),
          const SizedBox(height: AppSpacing.sm),
          GetDirectionsButton(
            latitude: lat!,
            longitude: lng!,
            label: fallbackLabel,
          ),
        ],
      ],
    );
  }
}
