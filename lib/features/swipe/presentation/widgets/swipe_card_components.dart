import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/compatibility/compatibility_engine.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../../shared/presentation/flatmates_video_tour_player.dart';
import '../../swipe_repository.dart';

/// Default hero height for the swipe card and profile sheet.
const double kDefaultHeroHeight = 320;

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
    this.showStatsOverlay = false,
    this.heroHeight = kDefaultHeroHeight,
    this.quickStats = const [],
  });

  final List<String> images;
  final String? name;
  final String mode;
  final CompatibilityResult compatibility;
  final SwipeProfile item;

  /// When true, the quick-stat pills (price range, schedule, etc.) render as a
  /// frosted overlay below the name/address on the image instead of in a row
  /// below the card. Used by the swipe card (not the profile sheet).
  final bool showStatsOverlay;

  /// Image section height. The swipe card uses a taller hero than the sheet.
  final double heroHeight;

  /// Quick-stat pills to surface on the hero image.
  final List<QuickStatPill> quickStats;

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
  void didUpdateWidget(covariant HeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Defensive: the SwipeCardStack identity-keys each profile so this element
    // should never be repurposed for a different profile. But if a parent ever
    // fails to preserve the key, reset the carousel to the first photo so a
    // stale page index (and the wrong image) from the previous profile does
    // not bleed into the new one.
    if (oldWidget.item.id != widget.item.id ||
        !listEquals(oldWidget.images, widget.images)) {
      _index = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
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
      height: widget.heroHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : null;
          final imageHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : null;
          return Stack(
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
                        itemBuilder: (context, i) {
                          final imageUrl = widget.images[i];
                          return Stack(
                            key: ValueKey<String>(
                              '${widget.item.id}:$imageUrl',
                            ),
                            fit: StackFit.expand,
                            children: [
                              ImageFiltered(
                                imageFilter: ui.ImageFilter.blur(
                                  sigmaX: 15,
                                  sigmaY: 15,
                                ),
                                child: FlatmatesNetworkImage(
                                  imageUrl: imageUrl,
                                  width: imageWidth,
                                  height: imageHeight,
                                  fit: BoxFit.cover,
                                  fallbackName: widget.name,
                                ),
                              ),
                              Container(
                                color: Colors.black.withValues(alpha: 0.2),
                              ),
                              FlatmatesNetworkImage(
                                imageUrl: imageUrl,
                                width: imageWidth,
                                height: imageHeight,
                                fit: BoxFit.cover,
                                fallbackName: widget.name,
                              ),
                            ],
                          );
                        },
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ModeChip(mode: widget.mode, locale: locale),
                    if (widget.item.nonNegotiables.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _FrostedPill(
                        icon: Icons.shield_outlined,
                        label: locale.dealBreakersCountBadge(
                          widget.item.nonNegotiables.length,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                right: AppSpacing.md,
                top: AppSpacing.md,
                child: MatchPill(
                  percentage: widget.compatibility.percentage,
                  showTone: true,
                ),
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
                  bottom: widget.showStatsOverlay ? 150 : 90,
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
                child: HeroInfoOverlay(
                  item: widget.item,
                  quickStats: widget.quickStats,
                ),
              ),
            ],
          );
        },
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
  const MatchPill({super.key, required this.percentage, this.showTone = false});

  final double percentage;
  final bool showTone;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final hasReliableScore = percentage > 0;
    final color = hasReliableScore
        ? compatibilityScoreColor(percentage)
        : AppSemanticColors.accent;
    final pctLabel = hasReliableScore ? '${percentage.round()}%' : 'New';
    final tone = hasReliableScore && showTone
        ? matchToneLabel(locale, percentage)
        : null;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    pctLabel,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: hasReliableScore ? 11 : 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (tone != null)
                Text(
                  tone,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 9,
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

/// Tone label for overall match percentage.
String matchToneLabel(AppLocalizations locale, double percentage) {
  if (percentage >= 70) return locale.matchToneGreat;
  if (percentage >= 40) return locale.matchToneWorkable;
  return locale.matchToneGaps;
}

/// Bucket dimension scores into aligned (≥70), workable (≥40), gaps (<40).
({int aligned, int workable, int gaps}) dimensionBuckets(
  List<CompatibilityDimension> dimensions,
) {
  var aligned = 0;
  var workable = 0;
  var gaps = 0;
  for (final d in dimensions) {
    if (d.score >= 70) {
      aligned++;
    } else if (d.score >= 40) {
      workable++;
    } else {
      gaps++;
    }
  }
  return (aligned: aligned, workable: workable, gaps: gaps);
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
  const HeroInfoOverlay({
    super.key,
    required this.item,
    this.quickStats = const [],
  });
  final SwipeProfile item;
  final List<QuickStatPill> quickStats;

  @override
  Widget build(BuildContext context) {
    final name = item.fullName ?? '';
    final nameWithAge = item.age != null ? '$name, ${item.age}' : name;
    final location = [
      item.locality,
      item.city,
    ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
    final showStats = quickStats.isNotEmpty;
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
        if (showStats) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final pill in quickStats)
                _FrostedPill(icon: pill.icon, label: pill.label),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Quick stats pill row (horizontal scroll) ────────────────────────────

/// Builds the quick-stat pills (gender, price range, room type, schedule,
/// furnishing, pets) shown either as a frosted overlay on the hero image
/// (swipe card) or as a wrapped row below the hero (profile sheet).
List<QuickStatPill> buildQuickStatPills({
  required BuildContext context,
  required SwipeProfile item,
  String? roomType,
  String? flatConfig,
  required List<String> furnishing,
  String? availableFrom,
}) {
  final locale = AppLocalizations.of(context);
  final pills = <QuickStatPill>[];

  if (item.gender != null && item.gender!.trim().isNotEmpty) {
    pills.add(
      QuickStatPill(
        icon: Icons.person_outline_rounded,
        label: localizedFlatmatesGenderLabel(locale, item.gender!),
      ),
    );
  }
  if (item.budgetMin != null || item.budgetMax != null) {
    pills.add(
      QuickStatPill(
        icon: Icons.currency_rupee_rounded,
        label: _budgetText(item.budgetMin, item.budgetMax),
      ),
    );
  }
  if (roomType != null && roomType.isNotEmpty) {
    pills.add(
      QuickStatPill(
        icon: Icons.bed_outlined,
        label: humanizeFlatmatesToken(roomType),
      ),
    );
  }
  if (item.moveInTimeline != null) {
    pills.add(
      QuickStatPill(
        icon: Icons.event_outlined,
        label: localizedFlatmatesMoveInTimeline(locale, item.moveInTimeline!),
      ),
    );
  }
  if (availableFrom != null && availableFrom.isNotEmpty) {
    final dt = DateTime.tryParse(availableFrom);
    final label = dt != null
        ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}'
        : humanizeFlatmatesToken(availableFrom);
    pills.add(
      QuickStatPill(icon: Icons.event_available_outlined, label: label),
    );
  }
  if (flatConfig != null && flatConfig.isNotEmpty) {
    pills.add(QuickStatPill(icon: Icons.home_outlined, label: flatConfig));
  }
  if (furnishing.isNotEmpty) {
    pills.add(
      QuickStatPill(
        icon: Icons.chair_outlined,
        label: humanizeFlatmatesToken(furnishing.first),
      ),
    );
  }
  if (item.hasPets) {
    pills.add(
      QuickStatPill(icon: Icons.pets_outlined, label: locale.quizHavePets),
    );
  }

  return pills;
}

class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({
    super.key,
    required this.item,
    required this.roomType,
    required this.flatConfig,
    required this.furnishing,
    this.availableFrom,
  });

  final SwipeProfile item;
  final String? roomType;
  final String? flatConfig;
  final List<String> furnishing;
  final String? availableFrom;

  @override
  Widget build(BuildContext context) {
    final pills = buildQuickStatPills(
      context: context,
      item: item,
      roomType: roomType,
      flatConfig: flatConfig,
      furnishing: furnishing,
      availableFrom: availableFrom,
    );

    if (pills.isEmpty) return const SizedBox.shrink();

    // Wrap grid — all stats visible at once, no hidden horizontal scroll.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final pill in pills)
            CompactPill(icon: pill.icon, label: pill.label),
        ],
      ),
    );
  }
}

class QuickStatPill {
  const QuickStatPill({required this.icon, required this.label});
  final IconData icon;
  final String label;
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

// ── Lifestyle preferences — 2-column icon grid ──────────────────────────

class LifestylePreferencesSection extends StatelessWidget {
  const LifestylePreferencesSection({super.key, required this.item});

  final SwipeProfile item;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cells = <({IconData icon, String dim, String value})>[
      if (_nonEmpty(item.sleepSchedule))
        (
          icon: Icons.bedtime_outlined,
          dim: locale.lifestyleDimSleep,
          value: humanizeFlatmatesToken(item.sleepSchedule!),
        ),
      if (_nonEmpty(item.cleanliness))
        (
          icon: Icons.cleaning_services_outlined,
          dim: locale.lifestyleDimCleanliness,
          value: humanizeFlatmatesToken(item.cleanliness!),
        ),
      if (_nonEmpty(item.foodHabits))
        (
          icon: Icons.restaurant_outlined,
          dim: locale.lifestyleDimFood,
          value: humanizeFlatmatesToken(item.foodHabits!),
        ),
      if (_nonEmpty(item.smokingDrinking))
        (
          icon: Icons.local_bar_outlined,
          dim: locale.lifestyleDimSmoking,
          value: humanizeFlatmatesToken(item.smokingDrinking!),
        ),
      if (_nonEmpty(item.guestsPolicy))
        (
          icon: Icons.groups_outlined,
          dim: locale.lifestyleDimGuests,
          value: humanizeFlatmatesToken(item.guestsPolicy!),
        ),
      if (_nonEmpty(item.workStyle))
        (
          icon: Icons.work_outline_rounded,
          dim: locale.lifestyleDimWork,
          value: humanizeFlatmatesToken(item.workStyle!),
        ),
      if (_nonEmpty(item.partyHabit))
        (
          icon: Icons.celebration_outlined,
          dim: locale.lifestyleDimParty,
          value: humanizeFlatmatesToken(item.partyHabit!),
        ),
    ];

    if (cells.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(label: locale.lifestyleSectionTitle),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppSemanticColors.paper2,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(color: AppSemanticColors.line, width: 0.5),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellW = (constraints.maxWidth - AppSpacing.sm) / 2;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final cell in cells)
                    SizedBox(
                      width: cellW,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppSemanticColors.accentSoft,
                              borderRadius: AppRadius.smBorder,
                            ),
                            child: Icon(
                              cell.icon,
                              size: 16,
                              color: AppSemanticColors.accent,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cell.dim,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: AppSemanticColors.textTertiaryFor(
                                      theme.brightness,
                                    ),
                                  ),
                                ),
                                Text(
                                  cell.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppSemanticColors.textPrimaryFor(
                                      theme.brightness,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  static bool _nonEmpty(String? value) =>
      value != null && value.trim().isNotEmpty;
}

// ── Preferences (gender preference, pets) — labeled cards ───────────────

class PreferencesSection extends StatelessWidget {
  const PreferencesSection({super.key, required this.item});

  final SwipeProfile item;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rows = <({IconData icon, String label, String value})>[];

    if (item.genderPreference != null &&
        item.genderPreference!.trim().isNotEmpty) {
      final pref = item.genderPreference!.trim().toLowerCase();
      final value = pref == 'any'
          ? locale.genderAny
          : localizedFlatmatesGenderLabel(locale, pref);
      rows.add((
        icon: Icons.person_outline_rounded,
        label: locale.genderPreferenceLabel,
        value: value,
      ));
    }
    rows.add((
      icon: Icons.pets_outlined,
      label: locale.petsLabel,
      value: item.hasPets ? locale.quizHavePets : locale.quizNoPets,
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(label: locale.preferencesLabel),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppSemanticColors.paper2,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(color: AppSemanticColors.line, width: 0.5),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      rows[i].icon,
                      size: 16,
                      color: AppSemanticColors.accent,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        rows[i].label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: AppSemanticColors.textTertiaryFor(
                            theme.brightness,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      rows[i].value,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppSemanticColors.textPrimaryFor(
                          theme.brightness,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Deal-breakers ───────────────────────────────────────────────────────

class DealBreakersSection extends StatelessWidget {
  const DealBreakersSection({super.key, required this.nonNegotiables});

  final List<String> nonNegotiables;

  @override
  Widget build(BuildContext context) {
    if (nonNegotiables.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? AppSemanticColors.warningSoftDark
        : AppSemanticColors.warningSoft;
    const fg = AppSemanticColors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(label: locale.dealBreakersSectionTitle),
        const SizedBox(height: 2),
        Text(
          locale.dealBreakersSectionSubtitle,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            color: AppSemanticColors.textTertiaryFor(theme.brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(color: fg.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final nn in nonNegotiables)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.7),
                    borderRadius: AppRadius.pillBorder,
                    border: Border.all(
                      color: fg.withValues(alpha: 0.25),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined, size: 13, color: fg),
                      const SizedBox(width: 4),
                      Text(
                        humanizeFlatmatesToken(nn),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
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
    final locale = AppLocalizations.of(context);
    if (result.dimensions.isEmpty) return const SizedBox.shrink();

    final buckets = dimensionBuckets(result.dimensions);
    final overallColor = compatibilityScoreColor(result.percentage);
    final tone = matchToneLabel(locale, result.percentage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.paper2,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: AppSemanticColors.line, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary strip
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: overallColor, width: 3),
                  color: overallColor.withValues(alpha: 0.08),
                ),
                child: Text(
                  result.percentage > 0 ? '${result.percentage.round()}%' : '—',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: overallColor,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tone,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: overallColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (buckets.aligned > 0)
                          locale.compatAlignedCount(buckets.aligned),
                        if (buckets.workable > 0)
                          locale.compatWorkableCount(buckets.workable),
                        if (buckets.gaps > 0)
                          locale.compatGapCount(buckets.gaps),
                      ].join(' · '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: AppSemanticColors.textTertiaryFor(
                          theme.brightness,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 0.5, color: AppSemanticColors.line),
          const SizedBox(height: AppSpacing.md),
          ...result.dimensions.map((dim) {
            final score = (dim.score / 100).clamp(0.0, 1.0);
            final color = compatibilityScoreColor(dim.score);
            final peerLabel = humanizeFlatmatesToken(dim.peerValue);
            final userLabel = humanizeFlatmatesToken(dim.userValue);
            final icon = _dimensionIcon(dim.key);
            final glyph = dim.score >= 70
                ? Icons.check_circle_rounded
                : dim.score >= 40
                ? Icons.remove_circle_outline
                : Icons.error_outline;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: AppSemanticColors.textSecondaryFor(
                          theme.brightness,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          dim.summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppSemanticColors.textPrimaryFor(
                              theme.brightness,
                            ),
                          ),
                        ),
                      ),
                      Icon(glyph, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        '${dim.score.round()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _ValueChip(label: peerLabel, emphasized: true),
                      const SizedBox(width: 6),
                      Text(
                        '·',
                        style: TextStyle(
                          color: AppSemanticColors.textTertiaryFor(
                            theme.brightness,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _ValueChip(
                        label: '${locale.matchSelfFallbackName}: $userLabel',
                        emphasized: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: score,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static IconData _dimensionIcon(String key) {
    switch (key) {
      case 'sleep_schedule':
        return Icons.bedtime_outlined;
      case 'cleanliness':
        return Icons.cleaning_services_outlined;
      case 'food_habits':
        return Icons.restaurant_outlined;
      case 'smoking_drinking':
        return Icons.local_bar_outlined;
      case 'guests_policy':
        return Icons.groups_outlined;
      case 'work_style':
        return Icons.work_outline_rounded;
      default:
        return Icons.tune_outlined;
    }
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.label, required this.emphasized});
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: emphasized
              ? AppSemanticColors.accentSoft
              : theme.colorScheme.surface,
          borderRadius: AppRadius.pillBorder,
          border: Border.all(
            color: emphasized
                ? AppSemanticColors.accent.withValues(alpha: 0.2)
                : AppSemanticColors.line,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
            color: emphasized
                ? AppSemanticColors.accent
                : AppSemanticColors.textSecondaryFor(theme.brightness),
          ),
        ),
      ),
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
    this.societyVibes = const [],
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
  final List<String> societyAmenities;
  final List<String> flatAmenities;
  final double? lat;
  final double? lng;
  final String fallbackLabel;
  final List<String> societyVibes;
  final List<String> roomFeatures;
  final String? availableFrom;
  final String? totalFloors;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locationText = [
      locality,
      city,
    ].whereType<String>().where((e) => e.isNotEmpty).join(', ');

    String? floorLabel;
    if (floor != null && floor!.isNotEmpty) {
      floorLabel = (totalFloors != null && totalFloors!.isNotEmpty)
          ? 'Floor $floor of $totalFloors'
          : 'Floor $floor';
    }
    final combinedConfig = [
      flatConfig,
      floorLabel,
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
        if (availableFrom != null && availableFrom!.isNotEmpty)
          DetailRow(
            icon: Icons.event_available_outlined,
            text:
                '${locale.availableFromLabel}: ${_formatAvailable(availableFrom!)}',
          ),
        if (societyVibes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            locale.societyVibesLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppSemanticColors.textTertiaryFor(theme.brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AmenitiesChips(labels: societyVibes),
        ],
        if (roomFeatures.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            locale.roomFeaturesLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppSemanticColors.textTertiaryFor(theme.brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AmenitiesChips(labels: roomFeatures),
        ],
        if (allAmenities.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          AmenitiesChips(labels: allAmenities),
        ],
      ],
    );
  }

  String _formatAvailable(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return humanizeFlatmatesToken(raw);
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
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
