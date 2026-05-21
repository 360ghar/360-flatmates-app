import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/compatibility/compatibility_engine.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../location/presentation/map_widgets.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../../shared/presentation/flatmates_video_tour_player.dart';
import '../../swipe_repository.dart';

// ── Scrollable Swipe Profile Card ───────────────────────────────────────

/// Single scrollable profile card for the swipe deck.
///
/// Shows a fixed-height photo hero area at the top with gradient overlay,
/// mode chip, match pill, and key info overlay. Scrolling down reveals the
/// full profile details (About Me, Compatibility, Society, Room, Flat,
/// Costs, etc.). No separate collapsed/expanded states.
class SwipeProfileCard extends StatelessWidget {
  const SwipeProfileCard({
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
        child: ClipRRect(
          borderRadius: AppRadius.cardBorder,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              // ── Photo hero area (scrolls with content) ──
              _buildPhotoHero(context, locale),
              // ── Detail content ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMatchSection(context, locale),
                    const SizedBox(height: AppSpacing.lg),
                    if (videoTourUrl != null && videoTourUrl.isNotEmpty) ...[
                      FlatmatesVideoTourPlayer(videoUrl: videoTourUrl),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // About Me — no header, just text
                    if (item.bio != null && item.bio!.isNotEmpty)
                      Text(
                        item.bio!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),

                    const SizedBox(height: AppSpacing.lg),

                    // Compatibility Breakdown — mini progress bars
                    _EyebrowLabel(label: locale.compatibilityBreakdown),
                    const SizedBox(height: AppSpacing.sm),
                    _CompactCompatibilityBreakdown(result: compatibility),

                    const SizedBox(height: AppSpacing.lg),

                    // --- The Society ---
                    if (item.locality != null ||
                        item.city != null ||
                        str('society_name') != null ||
                        societyAmenities.isNotEmpty ||
                        societyVibes.isNotEmpty) ...[
                      _EyebrowLabel(label: locale.societySectionTitle),
                      const SizedBox(height: AppSpacing.sm),
                      if (item.locality != null || item.city != null)
                        _CompactDetailRow(
                          icon: Icons.location_on_outlined,
                          text: [
                            item.locality,
                            item.city,
                          ].whereType<String>().join(', '),
                        ),
                      if (str('society_name') != null)
                        _CompactDetailRow(
                          icon: Icons.apartment_outlined,
                          text: str('society_name')!,
                        ),
                      if (societyAmenities.isNotEmpty)
                        _CompactChipRow(labels: societyAmenities),
                      if (societyVibes.isNotEmpty)
                        _CompactChipRow(labels: societyVibes),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // --- Location Map ---
                    if (dbl('latitude') != null &&
                        dbl('longitude') != null) ...[
                      MiniMapView(
                        latitude: dbl('latitude')!,
                        longitude: dbl('longitude')!,
                        height: 140,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      GetDirectionsButton(
                        latitude: dbl('latitude')!,
                        longitude: dbl('longitude')!,
                        label:
                            item.locality ??
                            item.city ??
                            locale.propertyFallbackLabel,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // --- The Room ---
                    if (str('room_type') != null ||
                        furnishing.isNotEmpty ||
                        roomFeatures.isNotEmpty) ...[
                      _EyebrowLabel(label: locale.roomSectionTitle),
                      const SizedBox(height: AppSpacing.sm),
                      if (str('room_type') != null)
                        _CompactDetailRow(
                          icon: Icons.bed_outlined,
                          text: humanizeFlatmatesToken(str('room_type')!),
                        ),
                      if (furnishing.isNotEmpty)
                        _CompactChipRow(labels: furnishing),
                      if (roomFeatures.isNotEmpty)
                        _CompactChipRow(labels: roomFeatures),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // --- The Flat & Flatmates ---
                    if (str('flat_config') != null ||
                        str('floor') != null ||
                        flatAmenities.isNotEmpty ||
                        existingFlatmates.isNotEmpty) ...[
                      _EyebrowLabel(label: locale.flatAndFlatmatesSectionTitle),
                      const SizedBox(height: AppSpacing.sm),
                      if (str('flat_config') != null)
                        _CompactDetailRow(
                          icon: Icons.home_outlined,
                          text: str('flat_config')!,
                        ),
                      if (str('floor') != null)
                        _CompactDetailRow(
                          icon: Icons.stairs_outlined,
                          text: str('floor')!,
                        ),
                      if (flatAmenities.isNotEmpty)
                        _CompactChipRow(labels: flatAmenities),
                      if (existingFlatmates.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          locale.existingFlatmatesLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...existingFlatmates.map(
                          (fm) => _FlatmateMiniProfile(
                            name: fm['name'] ?? '',
                            profession: fm['profession'] ?? '',
                            lifestyleChips: const [],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ],

                    // --- Costs Breakdown ---
                    if (monthlyRent != null) ...[
                      _EyebrowLabel(label: locale.costsBreakdownSectionTitle),
                      const SizedBox(height: AppSpacing.sm),
                      _CompactCostRow(
                        label: locale.monthlyRentRow,
                        value: '₹${monthlyRent.toStringAsFixed(0)}',
                      ),
                      if (securityDeposit != null)
                        _CompactCostRow(
                          label: locale.securityDepositRow,
                          value: '₹${securityDeposit.toStringAsFixed(0)}',
                        ),
                      if (maintenance != null)
                        _CompactCostRow(
                          label: locale.maintenanceRow,
                          value: '₹${maintenance.toStringAsFixed(0)}',
                        ),
                      Divider(height: 20, color: AppSemanticColors.line),
                      _CompactCostRow(
                        label: locale.estimatedTotalRow,
                        value:
                            '₹${(monthlyRent + (maintenance ?? 0)).toStringAsFixed(0)}',
                        isBold: true,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Budget + Move-in as compact info pills
                    if (item.budgetMin != null ||
                        item.budgetMax != null ||
                        item.moveInTimeline != null)
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          if (item.budgetMin != null || item.budgetMax != null)
                            _InfoPill(
                              icon: Icons.currency_rupee_rounded,
                              label:
                                  '₹${(item.budgetMin ?? 0).toStringAsFixed(0)} - ₹${(item.budgetMax ?? 100000).toStringAsFixed(0)}/mo',
                            ),
                          if (item.moveInTimeline != null)
                            _InfoPill(
                              icon: Icons.event_outlined,
                              label: localizedFlatmatesMoveInTimeline(
                                locale,
                                item.moveInTimeline!,
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
      ),
    );
  }

  // ── Photo hero area (fixed height) ──────────────────────────────────

  Widget _buildPhotoHero(BuildContext context, AppLocalizations locale) {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo or premium fallback
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.card),
            ),
            child: _ProfilePhoto(
              imageUrl: item.profileImageUrl,
              name: item.fullName,
            ),
          ),
          // Dark gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),
          // Top-left: mode chip (compact)
          Positioned(
            left: AppSpacing.md,
            top: AppSpacing.md,
            child: _ModeChip(mode: item.mode ?? 'open_to_both', locale: locale),
          ),
          // Top-right: match pill (compact)
          Positioned(
            right: AppSpacing.md,
            top: AppSpacing.md,
            child: _MatchPill(percentage: compatibility.percentage),
          ),
          // Bottom info overlay
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: _InfoOverlay(item: item, locale: locale),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchSection(BuildContext context, AppLocalizations locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale.whyThisMatchWorks,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppSemanticColors.textTertiaryFor(
              Theme.of(context).brightness,
            ),
            fontSize: AppTypography.labelMediumSize,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: compatibility.topMatchChips.take(3).map((chip) {
            return _CompactMatchChip(label: chip);
          }).toList(),
        ),
      ],
    );
  }
}

// ── Photo with premium fallback ─────────────────────────────────────────

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.imageUrl, required this.name});

  final String? imageUrl;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    if (hasImage) {
      return FlatmatesNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        fallbackName: name,
      );
    }

    return _PremiumPhotoFallback(name: name);
  }
}

class _PremiumPhotoFallback extends StatelessWidget {
  const _PremiumPhotoFallback({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final initials = initialsFromName(name);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [
            Color(0xFFD4A574),
            Color(0xFFC96442),
            Color(0xFF8B4513),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTypography.fontFamilySerif,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              name ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontFamily: AppTypography.fontFamilySerif,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mode chip ───────────────────────────────────────────────────────────

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.mode, required this.locale});

  final String mode;
  final AppLocalizations locale;

  @override
  Widget build(BuildContext context) {
    final label = localizedFlatmatesModeLabel(locale, mode);
    return ClipRRect(
      borderRadius: AppRadius.pillBorder,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: AppRadius.pillBorder,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_modeIcon(mode), size: 11, color: Colors.white),
              const SizedBox(width: 3),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _modeIcon(String mode) {
    switch (mode.trim().toLowerCase()) {
      case 'room_poster':
        return Icons.home_outlined;
      case 'seeker':
        return Icons.search_outlined;
      case 'co_hunter':
        return Icons.group_outlined;
      default:
        return Icons.swap_horiz_outlined;
    }
  }
}

// ── Match pill ──────────────────────────────────────────────────────────

class _MatchPill extends StatelessWidget {
  const _MatchPill({required this.percentage});

  final double percentage;

  @override
  Widget build(BuildContext context) {
    final hasReliableScore = percentage > 0;
    final color = hasReliableScore
        ? compatibilityScoreColor(percentage)
        : AppSemanticColors.accent;
    final label = hasReliableScore ? '${percentage.round()}%' : 'New';
    final tier = _matchTier(percentage);

    return ClipRRect(
      borderRadius: AppRadius.pillBorder,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: AppRadius.pillBorder,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: hasReliableScore ? 11 : 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (tier != null) ...[
                const SizedBox(width: 3),
                Text(
                  tier,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _matchTier(double percentage) {
    if (percentage >= 85) return 'Excellent';
    if (percentage >= 70) return 'Great';
    if (percentage >= 50) return 'Good';
    if (percentage > 0) return 'Fair';
    return null;
  }
}

// ── Info overlay on photo ───────────────────────────────────────────────

class _InfoOverlay extends StatelessWidget {
  const _InfoOverlay({required this.item, required this.locale});

  final SwipeProfile item;
  final AppLocalizations locale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name + Age
        Text(
          _nameWithAge(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: AppTypography.fontFamilySerif,
            height: 1.2,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        // Profession
        if (item.profession != null && item.profession!.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(
            item.profession!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        // Location
        _InfoRow(
          icon: Icons.location_on_outlined,
          text: [item.locality, item.city].whereType<String>().join(', '),
        ),
        // Budget + Move-in
        if (item.budgetMin != null || item.budgetMax != null) ...[
          const SizedBox(height: 4),
          _InfoRow(icon: Icons.currency_rupee_rounded, text: _budgetText()),
        ],
        if (item.moveInTimeline != null) ...[
          const SizedBox(height: 4),
          _InfoRow(
            icon: Icons.event_outlined,
            text: localizedFlatmatesMoveInTimeline(
              locale,
              item.moveInTimeline!,
            ),
          ),
        ],
        // Activity status
        const SizedBox(height: AppSpacing.sm),
        _ActivityStatus(),
      ],
    );
  }

  String _nameWithAge() {
    final name = item.fullName ?? '';
    if (item.age != null) {
      return '$name, ${item.age}';
    }
    return name;
  }

  String _budgetText() {
    final min = item.budgetMin;
    final max = item.budgetMax;
    if (min != null && max != null) {
      return '₹${min.toStringAsFixed(0)} – ₹${max.toStringAsFixed(0)}/mo';
    }
    if (min != null) return '₹${min.toStringAsFixed(0)}/mo+';
    if (max != null) return 'Up to ₹${max.toStringAsFixed(0)}/mo';
    return '';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActivityStatus extends StatelessWidget {
  const _ActivityStatus();

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppSemanticColors.ink4,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          locale.activeRecentlyLabel,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Compact match chip ──────────────────────────────────────────────────

class _CompactMatchChip extends StatelessWidget {
  const _CompactMatchChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppSemanticColors.successSoftDark
            : AppSemanticColors.successSoft,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(
          color: AppSemanticColors.success.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: AppSemanticColors.success,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              color: AppSemanticColors.greenInk,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Eyebrow label (quiet section header) ─────────────────────────────────

class _EyebrowLabel extends StatelessWidget {
  const _EyebrowLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppSemanticColors.textTertiaryFor(Theme.of(context).brightness),
      ),
    );
  }
}

// ── Compact detail row (icon + text, smaller) ──────────────────────────

class _CompactDetailRow extends StatelessWidget {
  const _CompactDetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: AppSemanticColors.textSecondaryFor(theme.brightness),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact chip row (no icons, small pills) ────────────────────────────

class _CompactChipRow extends StatelessWidget {
  const _CompactChipRow({required this.labels});
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: labels.map((label) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppSemanticColors.paper2,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppSemanticColors.line, width: 0.5),
            ),
            child: Text(
              humanizeFlatmatesToken(label),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Compact cost row ────────────────────────────────────────────────────

class _CompactCostRow extends StatelessWidget {
  const _CompactCostRow({
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isBold ? AppSemanticColors.accent : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact compatibility breakdown (mini progress bars) ────────────────

class _CompactCompatibilityBreakdown extends StatelessWidget {
  const _CompactCompatibilityBreakdown({required this.result});
  final CompatibilityResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: result.dimensions.map((dim) {
        final score = dim.score / 100;
        final color = compatibilityScoreColor(dim.score);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  dim.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: score,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 32,
                child: Text(
                  '${dim.score.round()}%',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Info pill (compact icon + text) ─────────────────────────────────────

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppSemanticColors.paper2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppSemanticColors.line, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppSemanticColors.accent),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Flatmate mini profile ───────────────────────────────────────────────

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
