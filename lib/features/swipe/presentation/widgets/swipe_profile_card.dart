import 'package:flutter/material.dart';

import '../../../../core/compatibility/compatibility_engine.dart';
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
    final sections = _SwipeProfileSections(
      item: item,
      compatibility: compatibility,
    );

    final profileCard = FlatmatesCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(borderRadius: AppRadius.cardBorder, child: sections),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight;
          final forceBelowFold =
              trailing != null && maxHeight.isFinite && maxHeight > 0;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              ConstrainedBox(
                constraints: forceBelowFold
                    ? BoxConstraints(minHeight: maxHeight)
                    : const BoxConstraints(),
                // Column expands to minHeight when content is short, but the
                // card itself stays content-sized at the top — empty space
                // under the card is outside chrome (not padded card surface).
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [profileCard],
                ),
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
class SwipeProfileDetailBody extends StatelessWidget {
  const SwipeProfileDetailBody({
    required this.item,
    required this.compatibility,
    super.key,
  });

  final SwipeProfile item;
  final CompatibilityResult compatibility;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _SwipeProfileSections(item: item, compatibility: compatibility),
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
  });

  final SwipeProfile item;
  final CompatibilityResult compatibility;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final details = item.listingDetails;

    String? str(String key) =>
        details[key] is String ? details[key] as String : null;

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
      return null;
    }

    List<Map<String, String>> flatmatesList() {
      final v = details['existing_flatmates'];
      if (v is! List) return const [];
      return v
          .whereType<Map>()
          .map(
            (m) => Map<String, String>.from(
              m.map((k, val) => MapEntry(k.toString(), val?.toString() ?? '')),
            ),
          )
          .toList();
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
    final societyName = str('society_name');
    final furnishing = strList('furnishing');
    final societyAmenities = strList('society_amenities');
    final flatAmenities = strList('flat_amenities');
    final existingFlatmates = flatmatesList();
    final videoTourUrl = str('video_tour_url');
    final monthlyRent = dbl('monthly_rent') ?? item.budgetMin;
    final securityDeposit = dbl('security_deposit');
    final maintenance = dbl('maintenance');
    final lat = dbl('latitude');
    final lng = dbl('longitude');

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
        ),
        const SizedBox(height: AppSpacing.md),
        QuickStatsRow(
          item: item,
          roomType: roomType,
          flatConfig: flatConfig,
          furnishing: furnishing,
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
              SectionHeader(label: locale.compatibilityBreakdown),
              const SizedBox(height: AppSpacing.sm),
              CompactCompatibilityBreakdown(result: compatibility),
              const SizedBox(height: AppSpacing.xl),
              _PlaceBlock(
                locality: item.locality,
                city: item.city,
                societyName: societyName,
                roomType: roomType,
                flatConfig: flatConfig,
                floor: floor,
                societyAmenities: societyAmenities,
                flatAmenities: flatAmenities,
                lat: lat,
                lng: lng,
                fallbackLabel:
                    item.locality ?? item.city ?? locale.propertyFallbackLabel,
              ),
              if (existingFlatmates.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(label: locale.peopleSectionTitle),
                const SizedBox(height: AppSpacing.sm),
                ExistingFlatmatesRow(flatmates: existingFlatmates),
              ],
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
    required this.societyAmenities,
    required this.flatAmenities,
    required this.lat,
    required this.lng,
    required this.fallbackLabel,
  });

  final String? locality;
  final String? city;
  final String? societyName;
  final String? roomType;
  final String? flatConfig;
  final String? floor;
  final List<String> societyAmenities;
  final List<String> flatAmenities;
  final double? lat;
  final double? lng;
  final String fallbackLabel;

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
          societyAmenities: societyAmenities,
          flatAmenities: flatAmenities,
          lat: lat,
          lng: lng,
          fallbackLabel: fallbackLabel,
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
