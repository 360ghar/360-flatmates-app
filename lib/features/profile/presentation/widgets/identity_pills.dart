import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_price_text.dart';
import '../../../bootstrap/domain/bootstrap_models.dart';

/// A single scannable identity stat (icon + label) used by the profile
/// header to mirror what the swipe card shows others about this user.
class IdentityStat {
  const IdentityStat({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Builds the identity stat pills (mode · budget · move-in) for a profile.
///
/// Returns an empty list when the profile has no meaningful identity data.
List<IdentityStat> buildIdentityPills(
  FlatmatesProfileModel profile,
  AppLocalizations locale,
) {
  final pills = <IdentityStat>[];

  if (profile.mode != null && profile.mode!.trim().isNotEmpty) {
    pills.add(
      IdentityStat(
        icon: Icons.swap_horiz_rounded,
        label: switch (profile.mode) {
          'co_hunter' => locale.ownerModeCoHunter,
          'room_poster' => locale.ownerModeRoomPoster,
          'open_to_both' => locale.ownerModeOpenToBoth,
          _ => profile.mode!,
        },
      ),
    );
  }

  if (profile.budgetMin != null && profile.budgetMax != null) {
    pills.add(
      IdentityStat(
        icon: Icons.wallet_outlined,
        label:
            '${FlatmatesPriceText.formatRupee(profile.budgetMin!.round())}–'
            '${FlatmatesPriceText.formatRupee(profile.budgetMax!.round())}',
      ),
    );
  }

  if (profile.moveInTimeline != null &&
      profile.moveInTimeline!.trim().isNotEmpty) {
    pills.add(
      IdentityStat(
        icon: Icons.event_available_rounded,
        label: switch (profile.moveInTimeline) {
          'immediate' => locale.timelineImmediate,
          'this_month' => locale.timelineThisMonth,
          'next_month' => locale.timelineNextMonth,
          'flexible' => locale.timelineFlexible,
          _ => profile.moveInTimeline!,
        },
      ),
    );
  }

  return pills;
}

/// Renders a single [IdentityStat] as an accent-tinted pill.
class IdentityPill extends StatelessWidget {
  const IdentityPill({required this.item, required this.brightness, super.key});

  final IdentityStat item;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppSemanticColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.sm + 2),
        border: Border.all(
          color: AppSemanticColors.accent.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 13, color: AppSemanticColors.accent),
          const SizedBox(width: AppSpacing.xs),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppSemanticColors.paper2 : AppSemanticColors.ink2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Uppercase section label for profile menu groups.
class MenuGroupLabel extends StatelessWidget {
  const MenuGroupLabel({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: AppSemanticColors.textTertiaryFor(theme.brightness),
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}

/// Staggered fade-in for profile menu groups.
class StaggeredMenuGroup extends StatefulWidget {
  const StaggeredMenuGroup({
    required this.delayIndex,
    required this.child,
    super.key,
  });

  final int delayIndex;
  final Widget child;

  @override
  State<StaggeredMenuGroup> createState() => _StaggeredMenuGroupState();
}

class _StaggeredMenuGroupState extends State<StaggeredMenuGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow);
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.easeOutCubic,
    );
    _slideUp = Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.easeOutCubic),
    );

    final delay = Duration(
      milliseconds:
          300 + widget.delayIndex * AppMotion.staggerItem.inMilliseconds,
    );
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(position: _slideUp, child: widget.child),
    );
  }
}
