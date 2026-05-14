import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/compatibility/compatibility_engine.dart';
import '../../../../core/compatibility/compatibility_ring.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../location/presentation/map_widgets.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_chip.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_trust_badge.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../../shared/presentation/flatmates_video_tour_player.dart';
import '../../swipe_repository.dart';

/// Collapsed (compact) profile card shown in the swipe deck.
///
/// Displays the profile photo with a gradient overlay, compatibility ring,
/// mode chip, and basic info (name, age, profession, location, budget).
/// Bottom section shows compatibility match chips and a "tap to see more" hint.
class CollapsedCard extends StatelessWidget {
  const CollapsedCard({
    required this.item,
    required this.compatibility,
    super.key,
  });

  final SwipeProfile item;
  final CompatibilityResult compatibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: FlatmatesCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Full-bleed photo with gradient overlay
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.card),
                    ),
                    child: item.profileImageUrl != null
                        ? FlatmatesNetworkImage(
                            imageUrl: item.profileImageUrl!,
                            fit: BoxFit.cover,
                          )
                        : _PhotoFallback(name: item.fullName),
                  ),
                  // Dark gradient overlay at the bottom for text readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Top-left: mode chip
                  Positioned(
                    left: AppSpacing.md,
                    top: AppSpacing.md,
                    child: FlatmatesChip(
                      label: localizedFlatmatesModeLabel(
                        locale,
                        item.mode ?? 'open_to_both',
                      ),
                      selected: true,
                      variant: FlatmatesChipVariant.filter,
                    ),
                  ),
                  // Top-right: compatibility ring
                  Positioned(
                    right: AppSpacing.md,
                    top: AppSpacing.md,
                    child: CompatibilityRing(
                      percentage: compatibility.percentage,
                      size: 56,
                    ),
                  ),
                  // Top-right below compat ring: verified trust badge
                  if (item.listingDetails['verified'] == true)
                    Positioned(
                      right: AppSpacing.md,
                      top: 76,
                      child: FlatmatesTrustBadge(
                        label: locale.verifiedFilterLabel,
                        variant: FlatmatesTrustBadgeVariant.verified,
                        compact: true,
                      ),
                    ),
                  // Bottom: profile info overlay (white text on gradient)
                  Positioned(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.fullName ?? '',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            shadows: AppShadows.asList(AppShadows.card),
                          ),
                        ),
                        if (item.age != null || item.profession != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${item.age != null ? '${item.age}' : ''} ${item.profession ?? ''}'
                                .trim(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                [
                                  item.locality,
                                  item.city,
                                ].whereType<String>().join(', '),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (item.budgetMin != null ||
                            item.budgetMax != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '₹${(item.budgetMin ?? 0).toStringAsFixed(0)} - ₹${(item.budgetMax ?? 100000).toStringAsFixed(0)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom section: compatibility chips + tap hint
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ...compatibility.topMatchChips.map((chip) {
                        return FlatmatesChip(
                          icon: Icons.check_circle_outline,
                          label: chip,
                          variant: FlatmatesChipVariant.info,
                        );
                      }),
                      if (item.listingDetails['available_from'] != null) ...[
                        () {
                          final availableFrom = DateTime.tryParse(
                            item.listingDetails['available_from'].toString(),
                          );
                          if (availableFrom != null) {
                            final daysUntilMoveIn = availableFrom
                                .difference(DateTime.now())
                                .inDays;
                            if (daysUntilMoveIn == 0) {
                              return FlatmatesChip(
                                icon: Icons.event_outlined,
                                label: locale.moveInToday,
                                selected: true,
                              );
                            } else if (daysUntilMoveIn >= 1 &&
                                daysUntilMoveIn <= 7) {
                              return FlatmatesChip(
                                icon: Icons.event_outlined,
                                label: locale.moveInCountdownBadge(
                                  daysUntilMoveIn,
                                ),
                                selected: true,
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        }(),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 18,
                        color: AppSemanticColors.textSecondaryFor(
                          theme.brightness,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        locale.tapToSeeMore,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppSemanticColors.textSecondaryFor(
                            theme.brightness,
                          ),
                        ),
                      ),
                    ],
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

/// Expanded (full-detail) profile card shown in the swipe deck.
///
/// Displays the complete profile with sections for About Me, Compatibility
/// Breakdown, The Society, The Room, The Flat & Flatmates, and Costs Breakdown.
class ExpandedCard extends StatelessWidget {
  const ExpandedCard({
    required this.item,
    required this.compatibility,
    super.key,
  });

  final SwipeProfile item;
  final CompatibilityResult compatibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final details = item.listingDetails;

    // Helpers to read typed values from listingDetails.
    String? str(String key) {
      final v = details[key];
      return v is String ? v : null;
    }

    List<String> strList(String key) {
      final v = details[key];
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    double? dbl(String key) {
      final v = details[key];
      if (v is num) return v.toDouble();
      return null;
    }

    List<Map<String, String>> flatmates() {
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

    final societyAmenities = strList('society_amenities');
    final societyVibes = strList('society_vibes');
    final furnishing = strList('furnishing');
    final roomFeatures = strList('room_features');
    final flatAmenities = strList('flat_amenities');
    final existingFlatmates = flatmates();

    final monthlyRent = dbl('monthly_rent') ?? item.budgetMin;
    final securityDeposit = dbl('security_deposit');
    final maintenance = dbl('maintenance');
    final videoTourUrl = str('video_tour_url');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: FlatmatesCard(
        padding: EdgeInsets.zero,
        child: ListView(
          padding: AppSpacing.edgeLg,
          children: [
            // Header row: avatar + name + compatibility
            Row(
              children: [
                FlatmatesAvatar(
                  name: item.fullName,
                  imageUrl: item.profileImageUrl,
                  size: 64,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fullName ?? '',
                        style: theme.textTheme.headlineMedium,
                      ),
                      FlatmatesChip(
                        label: localizedFlatmatesModeLabel(
                          locale,
                          item.mode ?? 'open_to_both',
                        ),
                        selected: true,
                        variant: FlatmatesChipVariant.filter,
                      ),
                    ],
                  ),
                ),
                CompatibilityRing(percentage: compatibility.percentage),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            if (videoTourUrl != null && videoTourUrl.isNotEmpty) ...[
              FlatmatesVideoTourPlayer(videoUrl: videoTourUrl),
              const SizedBox(height: AppSpacing.xl),
            ],

            // About Me
            FlatmatesSectionHeader(title: locale.aboutMeSection),
            const SizedBox(height: AppSpacing.sm),
            if (item.bio != null && item.bio!.isNotEmpty)
              Text(item.bio!, style: theme.textTheme.bodyLarge)
            else
              Text(locale.noBioYet, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xl),

            // Compatibility Breakdown
            FlatmatesSectionHeader(title: locale.compatibilityBreakdown),
            const SizedBox(height: AppSpacing.md),
            CompatibilityBreakdown(result: compatibility),
            const SizedBox(height: AppSpacing.xl),

            // --- The Society ---
            FlatmatesSectionHeader(title: locale.societySectionTitle),
            const SizedBox(height: AppSpacing.sm),
            if (item.locality != null || item.city != null)
              _DetailRow(
                icon: Icons.location_on_outlined,
                text: [item.locality, item.city].whereType<String>().join(', '),
              ),
            if (str('society_name') != null)
              _DetailRow(
                icon: Icons.apartment_outlined,
                text: str('society_name')!,
              ),
            if (societyAmenities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: societyAmenities
                      .map(
                        (a) => FlatmatesChip(
                          icon: Icons.check_circle_outline,
                          label: humanizeFlatmatesToken(a),
                          variant: FlatmatesChipVariant.info,
                        ),
                      )
                      .toList(),
                ),
              ),
            if (societyVibes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: societyVibes
                      .map(
                        (v) => FlatmatesChip(
                          icon: Icons.wb_sunny_outlined,
                          label: humanizeFlatmatesToken(v),
                          variant: FlatmatesChipVariant.info,
                        ),
                      )
                      .toList(),
                ),
              ),
            if (item.locality == null &&
                item.city == null &&
                str('society_name') == null &&
                societyAmenities.isEmpty &&
                societyVibes.isEmpty)
              Text(locale.notAvailable, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xl),

            // --- Location Map ---
            if (dbl('latitude') != null && dbl('longitude') != null) ...[
              FlatmatesSectionHeader(title: locale.locationSectionTitle),
              const SizedBox(height: AppSpacing.sm),
              MiniMapView(
                latitude: dbl('latitude')!,
                longitude: dbl('longitude')!,
                height: 160,
              ),
              const SizedBox(height: AppSpacing.sm),
              GetDirectionsButton(
                latitude: dbl('latitude')!,
                longitude: dbl('longitude')!,
                label: item.locality ?? item.city ?? locale.propertyFallbackLabel,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // --- The Room ---
            FlatmatesSectionHeader(title: locale.roomSectionTitle),
            const SizedBox(height: AppSpacing.sm),
            if (str('room_type') != null)
              _DetailRow(
                icon: Icons.bed_outlined,
                text: humanizeFlatmatesToken(str('room_type')!),
              ),
            if (furnishing.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: furnishing
                      .map(
                        (f) => FlatmatesChip(
                          icon: Icons.chair_outlined,
                          label: humanizeFlatmatesToken(f),
                          variant: FlatmatesChipVariant.info,
                        ),
                      )
                      .toList(),
                ),
              ),
            if (roomFeatures.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: roomFeatures
                      .map(
                        (f) => FlatmatesChip(
                          icon: Icons.window_outlined,
                          label: humanizeFlatmatesToken(f),
                          variant: FlatmatesChipVariant.info,
                        ),
                      )
                      .toList(),
                ),
              ),
            if (str('room_type') == null &&
                furnishing.isEmpty &&
                roomFeatures.isEmpty)
              Text(locale.notAvailable, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xl),

            // --- The Flat & Flatmates ---
            FlatmatesSectionHeader(title: locale.flatAndFlatmatesSectionTitle),
            const SizedBox(height: AppSpacing.sm),
            if (str('flat_config') != null)
              _DetailRow(icon: Icons.home_outlined, text: str('flat_config')!),
            if (str('floor') != null)
              _DetailRow(icon: Icons.stairs_outlined, text: str('floor')!),
            if (flatAmenities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: flatAmenities
                      .map(
                        (a) => FlatmatesChip(
                          icon: Icons.kitchen_outlined,
                          label: humanizeFlatmatesToken(a),
                          variant: FlatmatesChipVariant.info,
                        ),
                      )
                      .toList(),
                ),
              ),
            if (existingFlatmates.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                locale.existingFlatmatesLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...existingFlatmates.map(
                (fm) => _FlatmateMiniProfile(
                  name: fm['name'] ?? '',
                  profession: fm['profession'] ?? '',
                  lifestyleChips:
                      fm['lifestyle_chips']
                          ?.split(',')
                          .where((c) => c.trim().isNotEmpty)
                          .toList() ??
                      const [],
                ),
              ),
            ],
            if (str('flat_config') == null &&
                flatAmenities.isEmpty &&
                existingFlatmates.isEmpty)
              Text(locale.notAvailable, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),

            // --- Costs Breakdown ---
            FlatmatesSectionHeader(title: locale.costsBreakdownSectionTitle),
            const SizedBox(height: 8),
            FlatmatesCard(
              child: Column(
                children: [
                  if (monthlyRent != null)
                    _CostRow(
                      label: locale.monthlyRentRow,
                      value: '₹${monthlyRent.toStringAsFixed(0)}',
                    ),
                  if (securityDeposit != null)
                    _CostRow(
                      label: locale.securityDepositRow,
                      value: '₹${securityDeposit.toStringAsFixed(0)}',
                    ),
                  if (maintenance != null)
                    _CostRow(
                      label: locale.maintenanceRow,
                      value: '₹${maintenance.toStringAsFixed(0)}',
                    ),
                  if (monthlyRent != null) ...[
                    const Divider(height: 20),
                    _CostRow(
                      label: locale.estimatedTotalRow,
                      value:
                          '₹${(monthlyRent + (maintenance ?? 0)).toStringAsFixed(0)}',
                      isBold: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Budget (original section, kept for budget range)
            if (item.budgetMin != null || item.budgetMax != null) ...[
              FlatmatesSectionHeader(title: locale.budgetLabel),
              const SizedBox(height: AppSpacing.sm),
              FlatmatesChip(
                icon: Icons.currency_rupee_rounded,
                label:
                    '₹${(item.budgetMin ?? 0).toStringAsFixed(0)} - ₹${(item.budgetMax ?? 100000).toStringAsFixed(0)}/mo',
                variant: FlatmatesChipVariant.info,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (item.moveInTimeline != null) ...[
              FlatmatesChip(
                icon: Icons.event_outlined,
                label: localizedFlatmatesMoveInTimeline(
                  locale,
                  item.moveInTimeline!,
                ),
                variant: FlatmatesChipVariant.info,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                ),
                const SizedBox(width: 4),
                Text(
                  locale.tapToCollapse,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Single icon + text row used inside expanded card sections.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppSemanticColors.textSecondaryFor(theme.brightness),
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Cost row with label on left and value on right.
class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });
  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: isBold ? AppSemanticColors.accent : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini profile card for an existing flatmate shown in the expanded card.
class _FlatmateMiniProfile extends StatelessWidget {
  const _FlatmateMiniProfile({
    required this.name,
    required this.profession,
    required this.lifestyleChips,
  });
  final String name;
  final String profession;
  final List<String> lifestyleChips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          FlatmatesAvatar(name: name, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (profession.isNotEmpty)
                  Text(profession, style: theme.textTheme.bodySmall),
                if (lifestyleChips.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: lifestyleChips
                          .map((c) => InfoPill(label: c))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fallback widget when a profile has no photo.
/// Shows initials over a gradient background.
class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppSemanticColors.accent.withValues(alpha: 0.9),
            AppSemanticColors.accent.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initialsFromName(name),
          style: theme.textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontSize: 48,
          ),
        ),
      ),
    );
  }
}

/// Localizes a raw move-in timeline token from the backend.
String localizedFlatmatesMoveInTimeline(AppLocalizations locale, String value) {
  switch (value.trim().toLowerCase()) {
    case 'immediate':
      return locale.timelineImmediate;
    case 'this_month':
      return locale.timelineThisMonth;
    case 'next_month':
      return locale.timelineNextMonth;
    case 'flexible':
      return locale.timelineFlexible;
    default:
      return humanizeFlatmatesToken(value);
  }
}
