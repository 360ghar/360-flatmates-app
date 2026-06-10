import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/compatibility/compatibility_engine.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../../shared/presentation/flatmates_video_tour_player.dart';
import '../../swipe_repository.dart';

// ── Reusable section header (accent bar + label) ────────────────────────

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: const BoxDecoration(
            color: AppSemanticColors.accent,
            borderRadius: AppRadius.smBorder,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppSemanticColors.textSecondaryFor(theme.brightness),
          ),
        ),
      ],
    );
  }
}

// ── Hero photo carousel ─────────────────────────────────────────────────

class HeroCarousel extends StatefulWidget {
  const HeroCarousel({
    super.key,
    required this.images,
    required this.name,
    required this.mode,
    required this.compatibility,
    required this.item,
  });

  final List<String> images;
  final String? name;
  final String mode;
  final CompatibilityResult compatibility;
  final SwipeProfile item;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final hasImages = widget.images.isNotEmpty;
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.card),
            ),
            child: hasImages
                ? PageView.builder(
                    controller: _controller,
                    itemCount: widget.images.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => Stack(
                      fit: StackFit.expand,
                      children: [
                        // Blurred background filling the space
                        ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: 15,
                            sigmaY: 15,
                          ),
                          child: FlatmatesNetworkImage(
                            imageUrl: widget.images[i],
                            fit: BoxFit.cover,
                            fallbackName: widget.name,
                          ),
                        ),
                        Container(color: Colors.black.withValues(alpha: 0.2)),
                        // Sharp uncropped image on top
                        FlatmatesNetworkImage(
                          imageUrl: widget.images[i],
                          fit: BoxFit.contain,
                          fallbackName: widget.name,
                        ),
                      ],
                    ),
                  )
                : PremiumPhotoFallback(name: widget.name),
          ),
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
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            top: AppSpacing.md,
            child: ModeChip(mode: widget.mode, locale: locale),
          ),
          Positioned(
            right: AppSpacing.md,
            top: AppSpacing.md,
            child: MatchPill(percentage: widget.compatibility.percentage),
          ),
          if (hasImages && widget.images.length > 1)
            Positioned(
              top: AppSpacing.md,
              left: 0,
              right: 0,
              child: Center(
                child: PhotoCounterPill(
                  current: _index + 1,
                  total: widget.images.length,
                ),
              ),
            ),
          if (hasImages && widget.images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 90,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.images.length, (i) {
                    final active = i == _index;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(
                          alpha: active ? 1.0 : 0.4,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: HeroInfoOverlay(item: widget.item),
          ),
        ],
      ),
    );
  }
}

// ── Premium photo fallback (gradient + initials) ────────────────────────

class PremiumPhotoFallback extends StatelessWidget {
  const PremiumPhotoFallback({super.key, required this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    final initials = initialsFromName(name);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppSemanticColors.swipeCardFallbackStart,
            AppSemanticColors.swipeCardFallbackMid,
            AppSemanticColors.swipeCardFallbackEnd,
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

class ModeChip extends StatelessWidget {
  const ModeChip({super.key, required this.mode, required this.locale});

  final String mode;
  final AppLocalizations locale;

  @override
  Widget build(BuildContext context) {
    final label = localizedFlatmatesModeLabel(locale, mode);
    return _FrostedPill(icon: _modeIcon(mode), label: label);
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

class MatchPill extends StatelessWidget {
  const MatchPill({super.key, required this.percentage});

  final double percentage;

  @override
  Widget build(BuildContext context) {
    final hasReliableScore = percentage > 0;
    final color = hasReliableScore
        ? compatibilityScoreColor(percentage)
        : AppSemanticColors.accent;
    final label = hasReliableScore ? '${percentage.round()}%' : 'New';

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
            ],
          ),
        ),
      ),
    );
  }
}

// ── Photo counter pill (frosted glass) ──────────────────────────────────

class PhotoCounterPill extends StatelessWidget {
  const PhotoCounterPill({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.pillBorder,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: AppRadius.pillBorder,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Text(
            '$current/$total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Generic frosted pill (used by mode chip) ────────────────────────────

class _FrostedPill extends StatelessWidget {
  const _FrostedPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
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
              Icon(icon, size: 11, color: Colors.white),
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
}

// ── Simplified hero info overlay ────────────────────────────────────────

class HeroInfoOverlay extends StatelessWidget {
  const HeroInfoOverlay({super.key, required this.item});
  final SwipeProfile item;

  @override
  Widget build(BuildContext context) {
    final name = item.fullName ?? '';
    final nameWithAge = item.age != null ? '$name, ${item.age}' : name;
    final location = [
      item.locality,
      item.city,
    ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          nameWithAge,
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
        if (location.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 12,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Quick stats pill row (horizontal scroll) ────────────────────────────

class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({
    super.key,
    required this.item,
    required this.roomType,
    required this.flatConfig,
    required this.furnishing,
  });

  final SwipeProfile item;
  final String? roomType;
  final String? flatConfig;
  final List<String> furnishing;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final pills = <_StatPillData>[];

    if (item.budgetMin != null || item.budgetMax != null) {
      pills.add(
        _StatPillData(
          icon: Icons.currency_rupee_rounded,
          label: _budgetText(item.budgetMin, item.budgetMax),
        ),
      );
    }
    if (roomType != null && roomType!.isNotEmpty) {
      pills.add(
        _StatPillData(
          icon: Icons.bed_outlined,
          label: humanizeFlatmatesToken(roomType!),
        ),
      );
    }
    if (item.moveInTimeline != null) {
      pills.add(
        _StatPillData(
          icon: Icons.event_outlined,
          label: localizedFlatmatesMoveInTimeline(locale, item.moveInTimeline!),
        ),
      );
    }
    if (flatConfig != null && flatConfig!.isNotEmpty) {
      pills.add(_StatPillData(icon: Icons.home_outlined, label: flatConfig!));
    }
    if (furnishing.isNotEmpty) {
      pills.add(
        _StatPillData(
          icon: Icons.chair_outlined,
          label: humanizeFlatmatesToken(furnishing.first),
        ),
      );
    }

    if (pills.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (var i = 0; i < pills.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            CompactPill(icon: pills[i].icon, label: pills[i].label),
          ],
        ],
      ),
    );
  }

  String _budgetText(double? min, double? max) {
    if (min != null && max != null) {
      return '₹${_shortMoney(min)}-₹${_shortMoney(max)}/mo';
    }
    if (min != null) return '₹${_shortMoney(min)}/mo+';
    if (max != null) return 'Up to ₹${_shortMoney(max)}/mo';
    return '';
  }

  String _shortMoney(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}

class _StatPillData {
  const _StatPillData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class CompactPill extends StatelessWidget {
  const CompactPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppSemanticColors.paper2,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: AppSemanticColors.line, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppSemanticColors.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
            ),
          ),
        ],
      ),
    );
  }
}

// ── About section: bio + video tour + match chips ───────────────────────

class AboutSection extends StatelessWidget {
  const AboutSection({
    super.key,
    required this.bio,
    required this.videoTourUrl,
    required this.compatibility,
  });

  final String? bio;
  final String? videoTourUrl;
  final CompatibilityResult compatibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBio = bio != null && bio!.isNotEmpty;
    final hasVideo = videoTourUrl != null && videoTourUrl!.isNotEmpty;
    final chips = compatibility.topMatchChips.take(3).toList();
    if (!hasBio && !hasVideo && chips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasBio)
          Text(
            bio!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              height: 1.6,
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
            ),
          ),
        if (hasBio && hasVideo) const SizedBox(height: AppSpacing.md),
        if (hasVideo)
          ClipRRect(
            borderRadius: AppRadius.mdBorder,
            child: FlatmatesVideoTourPlayer(videoUrl: videoTourUrl!),
          ),
        if (chips.isNotEmpty) ...[
          if (hasBio || hasVideo) const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: chips.map((c) => CompactMatchChip(label: c)).toList(),
          ),
        ],
      ],
    );
  }
}

// ── Compatibility breakdown ─────────────────────────────────────────────

class CompactCompatibilityBreakdown extends StatelessWidget {
  const CompactCompatibilityBreakdown({super.key, required this.result});
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
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  dim.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: score,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 34,
                child: Text(
                  '${dim.score.round()}%',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
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

// ── "The Place" section (consolidated society/room/flat) ────────────────

class ThePlaceSection extends StatelessWidget {
  const ThePlaceSection({
    super.key,
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
    final locale = AppLocalizations.of(context);
    final locationText = [
      locality,
      city,
    ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
    final combinedConfig = [
      flatConfig,
      floor,
    ].whereType<String>().where((e) => e.isNotEmpty).join(' · ');
    final allAmenities = <String>[...societyAmenities, ...flatAmenities];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(label: locale.thePlaceSectionTitle),
        const SizedBox(height: AppSpacing.sm),
        if (locationText.isNotEmpty)
          DetailRow(icon: Icons.location_on_outlined, text: locationText),
        if (societyName != null && societyName!.isNotEmpty)
          DetailRow(icon: Icons.apartment_outlined, text: societyName!),
        if (roomType != null && roomType!.isNotEmpty)
          DetailRow(
            icon: Icons.bed_outlined,
            text: humanizeFlatmatesToken(roomType!),
          ),
        if (combinedConfig.isNotEmpty)
          DetailRow(icon: Icons.home_outlined, text: combinedConfig),
        if (allAmenities.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          AmenitiesChips(labels: allAmenities),
        ],
        if (lat != null && lng != null) ...[
          const SizedBox(height: AppSpacing.md),
          // Imported in parent file via map_widgets.dart
        ],
      ],
    );
  }
}

// ── Detail row (icon + text) ────────────────────────────────────────────

class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: AppSemanticColors.textSecondaryFor(theme.brightness),
          ),
          const SizedBox(width: AppSpacing.sm),
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

// ── Amenities chips with expandable +N more ─────────────────────────────

class AmenitiesChips extends StatefulWidget {
  const AmenitiesChips({super.key, required this.labels});
  final List<String> labels;

  @override
  State<AmenitiesChips> createState() => _AmenitiesChipsState();
}

class _AmenitiesChipsState extends State<AmenitiesChips> {
  static const int _maxCollapsed = 6;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final hasMore = widget.labels.length > _maxCollapsed;
    final visible = (_expanded || !hasMore)
        ? widget.labels
        : widget.labels.sublist(0, _maxCollapsed);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final label in visible)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppSemanticColors.paper2,
              borderRadius: AppRadius.pillBorder,
              border: Border.all(color: AppSemanticColors.line, width: 0.5),
            ),
            child: Text(
              humanizeFlatmatesToken(label),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
          ),
        if (hasMore)
          Listener(
            onPointerDown: (_) => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppSemanticColors.accentSoft,
                borderRadius: AppRadius.pillBorder,
                border: Border.all(
                  color: AppSemanticColors.accent.withValues(alpha: 0.25),
                  width: 0.5,
                ),
              ),
              child: Text(
                _expanded
                    ? locale.showLessCta
                    : locale.andNMore(widget.labels.length - _maxCollapsed),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppSemanticColors.accent,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Existing flatmates horizontal scroll row ────────────────────────────

class ExistingFlatmatesRow extends StatelessWidget {
  const ExistingFlatmatesRow({super.key, required this.flatmates});
  final List<Map<String, String>> flatmates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < flatmates.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            Container(
              width: 110,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppSemanticColors.paper2,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppSemanticColors.line, width: 0.5),
              ),
              child: Column(
                children: [
                  FlatmatesAvatar(name: flatmates[i]['name'] ?? '', size: 36),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    flatmates[i]['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if ((flatmates[i]['profession'] ?? '').isNotEmpty)
                    Text(
                      flatmates[i]['profession'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: AppSemanticColors.textTertiaryFor(
                          theme.brightness,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Costs section ───────────────────────────────────────────────────────

class CostsSection extends StatelessWidget {
  const CostsSection({
    super.key,
    required this.monthlyRent,
    required this.securityDeposit,
    required this.maintenance,
  });

  final double monthlyRent;
  final double? securityDeposit;
  final double? maintenance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = monthlyRent + (maintenance ?? 0);
    final locale = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(label: locale.costsBreakdownSectionTitle),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark
                ? AppSemanticColors.coralSoftDark
                : AppSemanticColors.accentSoft,
            borderRadius: AppRadius.mdBorder,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${locale.estimatedTotalLabel} · ${locale.perMonthSuffix}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppSemanticColors.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CostLineItem(
          label: locale.monthlyRentRow,
          value: '₹${monthlyRent.toStringAsFixed(0)}',
        ),
        if (securityDeposit != null)
          CostLineItem(
            label: locale.securityDepositRow,
            value: '₹${securityDeposit!.toStringAsFixed(0)}',
          ),
        if (maintenance != null)
          CostLineItem(
            label: locale.maintenanceRow,
            value: '₹${maintenance!.toStringAsFixed(0)}',
          ),
      ],
    );
  }
}

class CostLineItem extends StatelessWidget {
  const CostLineItem({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppSemanticColors.textPrimaryFor(theme.brightness),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 0.5, color: AppSemanticColors.line),
        ],
      ),
    );
  }
}

// ── Compact match chip ──────────────────────────────────────────────────

class CompactMatchChip extends StatelessWidget {
  const CompactMatchChip({super.key, required this.label});
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
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
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

// ── Localization helper (kept) ──────────────────────────────────────────

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
