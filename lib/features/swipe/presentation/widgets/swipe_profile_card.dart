import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/compatibility/compatibility_engine.dart';
import '../../../../core/compatibility/compatibility_ring.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../location/presentation/map_widgets.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_chip.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../../shared/presentation/flatmates_video_tour_player.dart';
import '../../swipe_repository.dart';

// ── Collapsed Card ──────────────────────────────────────────────────────

/// Collapsed (compact) profile card shown in the swipe deck.
///
/// Photo-first design with dark gradient overlay, match pill, mode chip,
/// key info overlay, and a "Why this match works" section.
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
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: FlatmatesCard(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Photo area (~65% of card) ──
            _buildPhotoArea(context, locale, isDark),
            // ── "Why this match works" section ──
            _buildMatchSection(context, locale, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoArea(
    BuildContext context,
    AppLocalizations locale,
    bool isDark,
  ) {
    return Expanded(
      flex: 13,
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
          // Top-left: mode chip
          Positioned(
            left: AppSpacing.md,
            top: AppSpacing.md,
            child: _ModeChip(mode: item.mode ?? 'open_to_both', locale: locale),
          ),
          // Top-right: match pill
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
            child: _InfoOverlay(
              item: item,
              locale: locale,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchSection(
    BuildContext context,
    AppLocalizations locale,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            locale.whyThisMatchWorks,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppSemanticColors.textTertiaryFor(Theme.of(context).brightness),
              fontSize: AppTypography.labelMediumSize,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Compatibility chips
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: compatibility.topMatchChips.take(3).map((chip) {
              return _CompactMatchChip(label: chip);
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          // View full profile CTA
          Listener(
            onPointerDown: (_) {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  locale.tapToSeeMore,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppSemanticColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppSemanticColors.accent,
                ),
              ],
            ),
          ),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: AppRadius.pillBorder,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _modeIcon(mode),
                size: 13,
                color: Colors.white,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: AppRadius.pillBorder,
            border: Border.all(
              color: color.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (tier != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  tier,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
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
            fontSize: AppTypography.h2Size,
            fontWeight: AppTypography.h2Weight,
            fontFamily: AppTypography.fontFamilySerif,
            height: AppTypography.h2Height,
            letterSpacing: AppTypography.h2LetterSpacing,
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
          const SizedBox(height: 2),
          Text(
            item.profession!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: AppTypography.bodyMediumSize,
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
          _InfoRow(
            icon: Icons.currency_rupee_rounded,
            text: _budgetText(),
          ),
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
        Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: AppTypography.bodyMediumSize,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppSemanticColors.ink4,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Active recently',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
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
            style: TextStyle(
              color: isDark
                  ? AppSemanticColors.greenInk
                  : AppSemanticColors.greenInk,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Expanded Card (unchanged structure, minor polish) ───────────────────

/// Expanded (full-detail) profile card shown in the swipe deck.
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
