import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/compatibility/compatibility_engine.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/lifestyle_labels.dart';
import '../../../shared/presentation/paper/paper_scene.dart';
import '../../../shared/presentation/flatmates_price_text.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../../shared/presentation/flatmates_video_tour_player.dart';
import '../../../shared/presentation/profile_sections.dart';
export '../../../shared/presentation/profile_sections.dart' show SectionHeader;
import '../../swipe_repository.dart';

/// Default hero height for the swipe card and profile sheet.
const double kDefaultHeroHeight = 320;

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
                          // One decode per photo (a blurred copy under it
                          // was never visible).
                          return FlatmatesNetworkImage(
                            key: ValueKey<String>(
                              '${widget.item.id}:$imageUrl',
                            ),
                            imageUrl: imageUrl,
                            width: imageWidth,
                            height: imageHeight,
                            fit: BoxFit.cover,
                            fallbackName: widget.name,
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
                        AppSemanticColors.scrim.withValues(alpha: 0),
                        AppSemanticColors.scrim.withValues(alpha: 0),
                        AppSemanticColors.scrim.withValues(alpha: 0.35),
                        AppSemanticColors.scrim.withValues(alpha: 0.78),
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
              // One photo position indicator: the counter pill above.
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
    // No photo: the paper scene with the heart prop. The name is already in
    // the overlay at the bottom of the card.
    return ColoredBox(
      color: AppSemanticColors.skyFor(Theme.of(context).brightness),
      child: const Align(
        alignment: Alignment(0, -0.4),
        child: PaperScene.compact(prop: PaperProp.heart),
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
        ? compatibilityScoreColor(
            percentage,
            brightness: Theme.of(context).brightness,
          )
        : AppSemanticColors.clayFor(Theme.of(context).brightness);
    final pctLabel = hasReliableScore
        ? '${percentage.round()}%'
        : locale.badgeNew;
    final tone = hasReliableScore && showTone
        ? matchToneLabel(locale, percentage)
        : null;

    final theme = Theme.of(context);
    return _ScrimPill(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_rounded, size: 14, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                pctLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppSemanticColors.onScrim,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (tone != null)
            Text(
              tone,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppSemanticColors.onScrim,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Photo counter pill ──────────────────────────────────────────────────

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
    return _ScrimPill(
      child: Text(
        '$current/$total',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppSemanticColors.onScrim,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Solid scrim pill over the photo: no blur (DESIGN.md forbids frosted
/// chrome), 13 sp text.
class _ScrimPill extends StatelessWidget {
  const _ScrimPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppSemanticColors.scrim.withValues(alpha: 0.6),
        borderRadius: AppRadius.pillBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: child,
      ),
    );
  }
}

class _FrostedPill extends StatelessWidget {
  const _FrostedPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _ScrimPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppSemanticColors.onScrim),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppSemanticColors.onScrim,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

  /// Tight shadow so white text reads on any photo.
  static final _textShadow = [
    Shadow(
      color: AppSemanticColors.scrim.withValues(alpha: 0.5),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = item.fullName ?? '';
    // Backend omits exact age on peer payloads; fall back to the
    // privacy-bucketed range so the hero line still shows an age.
    final ageLabel =
        item.age?.toString() ??
        (item.ageBucket != null && item.ageBucket!.trim().isNotEmpty
            ? localizedFlatmatesAgeBucket(locale, item.ageBucket)
            : null);
    final nameWithAge = ageLabel == null
        ? name
        : name.isEmpty
        ? ageLabel
        : '$name, $ageLabel';
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
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppSemanticColors.onScrim,
            shadows: _textShadow,
          ),
        ),
        if (item.profession != null && item.profession!.isNotEmpty) ...[
          Text(
            item.profession!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppSemanticColors.onScrim,
              shadows: _textShadow,
            ),
          ),
        ],
        if (location.isNotEmpty) ...[
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppSemanticColors.onScrim,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppSemanticColors.onScrim,
                    shadows: _textShadow,
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
        label: budgetRangeText(locale, item.budgetMin, item.budgetMax),
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
        ? DateFormat.yMMMd(locale.localeName).format(dt)
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

class CompactPill extends StatelessWidget {
  const CompactPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppSemanticColors.secondarySurfaceFor(brightness),
        borderRadius: AppRadius.pillBorder,
        border: Border.all(
          color: AppSemanticColors.hairlineFor(brightness),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppSemanticColors.clayFor(brightness)),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppSemanticColors.textSecondaryFor(brightness),
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
    final locale = AppLocalizations.of(context);
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
            style: theme.textTheme.bodyLarge?.copyWith(
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
            children: chips
                .map(
                  (c) => CompactMatchChip(label: compatSummaryLabel(locale, c)),
                )
                .toList(),
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
    final cells = <LifestyleCell>[
      if (_nonEmpty(item.sleepSchedule))
        (
          icon: Icons.bedtime_outlined,
          dim: locale.lifestyleDimSleep,
          value: lifestyleValueLabel(
            locale,
            'sleep_schedule',
            item.sleepSchedule!,
          ),
        ),
      if (_nonEmpty(item.cleanliness))
        (
          icon: Icons.cleaning_services_outlined,
          dim: locale.lifestyleDimCleanliness,
          value: lifestyleValueLabel(locale, 'cleanliness', item.cleanliness!),
        ),
      if (_nonEmpty(item.foodHabits))
        (
          icon: Icons.restaurant_outlined,
          dim: locale.lifestyleDimFood,
          value: lifestyleValueLabel(locale, 'food_habits', item.foodHabits!),
        ),
      if (_nonEmpty(item.smoking))
        (
          icon: Icons.smoking_rooms_outlined,
          dim: locale.smokingLabel,
          value: lifestyleValueLabel(locale, 'smoking', item.smoking!),
        ),
      if (_nonEmpty(item.drinking))
        (
          icon: Icons.local_bar_outlined,
          dim: locale.drinkingLabel,
          value: lifestyleValueLabel(locale, 'drinking', item.drinking!),
        ),
      if (_nonEmpty(item.guestsPolicy))
        (
          icon: Icons.groups_outlined,
          dim: locale.lifestyleDimGuests,
          value: lifestyleValueLabel(
            locale,
            'guests_policy',
            item.guestsPolicy!,
          ),
        ),
      if (_nonEmpty(item.workStyle))
        (
          icon: Icons.work_outline_rounded,
          dim: locale.lifestyleDimWork,
          value: lifestyleValueLabel(locale, 'work_style', item.workStyle!),
        ),
      if (_nonEmpty(item.partyHabit))
        (
          icon: Icons.celebration_outlined,
          dim: locale.lifestyleDimParty,
          value: lifestyleValueLabel(
            locale,
            'parties_at_home',
            item.partyHabit!,
          ),
        ),
    ];

    if (cells.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(label: locale.lifestyleSectionTitle),
        const SizedBox(height: AppSpacing.sm),
        LifestyleGrid(cells: cells),
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
    final rows = <PreferenceRow>[];

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
        PreferencesCard(rows: rows),
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
    final bg = AppSemanticColors.warningSoftFor(theme.brightness);
    final fg = AppSemanticColors.warningInkFor(theme.brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(label: locale.dealBreakersSectionTitle),
        const SizedBox(height: 2),
        Text(
          locale.dealBreakersSectionSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
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
                      Icon(Icons.shield_outlined, size: 13, color: fg),
                      const SizedBox(width: 4),
                      Text(
                        humanizeFlatmatesToken(nn),
                        style: theme.textTheme.bodySmall?.copyWith(
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
    return CompatBreakdownSection(result: result);
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
          ? locale.floorOfLabel(floor!, totalFloors!)
          : locale.floorNumberLabel(floor!);
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
                '${locale.availableFromLabel}: ${_formatAvailable(availableFrom!, locale)}',
          ),
        if (societyVibes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            locale.societyVibesLabel,
            style: theme.textTheme.bodySmall?.copyWith(
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
            style: theme.textTheme.bodySmall?.copyWith(
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

  String _formatAvailable(String raw, AppLocalizations locale) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return humanizeFlatmatesToken(raw);
    return DateFormat.yMMMd(locale.localeName).format(dt);
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
              color: AppSemanticColors.secondarySurfaceFor(theme.brightness),
              borderRadius: AppRadius.pillBorder,
              border: Border.all(
                color: AppSemanticColors.hairlineFor(theme.brightness),
                width: 0.5,
              ),
            ),
            child: Text(
              humanizeFlatmatesToken(label),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
          ),
        if (hasMore)
          // A real 48 dp button (was a pointer-down Listener that also
          // fired when a scroll started).
          Semantics(
            button: true,
            expanded: _expanded,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: AppRadius.mdBorder,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: kMinInteractiveDimension,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppSemanticColors.coralSoftFor(theme.brightness),
                  borderRadius: AppRadius.mdBorder,
                ),
                child: Text(
                  _expanded
                      ? locale.showLessCta
                      : locale.andNMore(widget.labels.length - _maxCollapsed),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppSemanticColors.clayInkFor(theme.brightness),
                  ),
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
                color: AppSemanticColors.secondarySurfaceFor(theme.brightness),
                borderRadius: AppRadius.mdBorder,
                border: Border.all(
                  color: AppSemanticColors.hairlineFor(theme.brightness),
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  FlatmatesAvatar(name: flatmates[i]['name'] ?? '', size: 36),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    flatmates[i]['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if ((flatmates[i]['profession'] ?? '').isNotEmpty)
                    Text(
                      flatmates[i]['profession'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
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
            color: AppSemanticColors.coralSoftFor(theme.brightness),
            borderRadius: AppRadius.mdBorder,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${locale.estimatedTotalLabel} · ${locale.perMonthSuffix}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                FlatmatesPriceText.formatRupee(total.round()),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppSemanticColors.clayInkFor(theme.brightness),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CostLineItem(
          label: locale.monthlyRentRow,
          value: FlatmatesPriceText.formatRupee(monthlyRent.round()),
        ),
        if (securityDeposit != null)
          CostLineItem(
            label: locale.securityDepositRow,
            value: FlatmatesPriceText.formatRupee(securityDeposit!.round()),
          ),
        if (maintenance != null)
          CostLineItem(
            label: locale.maintenanceRow,
            value: FlatmatesPriceText.formatRupee(maintenance!.round()),
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
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppSemanticColors.textPrimaryFor(theme.brightness),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 0.5,
            color: AppSemanticColors.hairlineFor(theme.brightness),
          ),
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
    final brightness = theme.brightness;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppSemanticColors.successSoftFor(brightness),
        borderRadius: AppRadius.pillBorder,
        border: Border.all(
          color: AppSemanticColors.pineFor(brightness).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: AppSemanticColors.pineFor(brightness),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppSemanticColors.greenInkFor(brightness),
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
    case 'immediately':
      return locale.timelineImmediately;
    case 'within_1_week':
      return locale.timelineWithin1Week;
    case 'within_2_weeks':
      return locale.timelineWithin2Weeks;
    case 'this_month':
    case 'within_1_month':
      return locale.timelineWithin1Month;
    case 'next_month':
    case 'within_3_months':
      return locale.timelineWithin3Months;
    case 'within_2_months':
      return locale.timelineWithin2Months;
    case 'just_exploring':
    case 'flexible':
      return locale.timelineFlexible;
    default:
      return humanizeFlatmatesToken(value);
  }
}
