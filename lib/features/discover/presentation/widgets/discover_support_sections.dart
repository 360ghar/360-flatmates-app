import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../discover_repository.dart';

class NewInCitySection extends StatelessWidget {
  const NewInCitySection({
    required this.items,
    required this.onExplore,
    super.key,
  });

  final List<PropertyListing> items;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return FlatmatesCard(
      onTap: onExplore,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppSemanticColors.accentSoft,
              borderRadius: AppRadius.smBorder,
            ),
            child: Icon(
              Icons.location_city_rounded,
              size: 18,
              color: AppSemanticColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              locale.homeNewInCity(items.first.city ?? ''),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: onExplore,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  locale.navExplore,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppSemanticColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
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

class MovingSoonSection extends StatelessWidget {
  const MovingSoonSection({required this.items, super.key});

  final List<PropertyListing> items;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));
    final movingSoon = items.where((item) {
      final date = item.availableFrom;
      if (date == null) return false;
      return date.isAfter(now) && date.isBefore(sevenDaysFromNow);
    }).toList();

    if (movingSoon.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(
          locale.homeMovingSoon,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppSemanticColors.textPrimaryFor(theme.brightness),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: movingSoon.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = movingSoon[index];
              final daysLeft = item.availableFrom!.difference(now).inDays;
              final badgeText = daysLeft == 0
                  ? locale.moveInToday
                  : locale.moveInCountdownBadge(daysLeft);
              return SizedBox(
                width: 120,
                child: FlatmatesCard(
                  padding: EdgeInsets.zero,
                  child: Stack(
                    children: [
                      if (item.mainImageUrl != null)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: FlatmatesNetworkImage(
                              imageUrl: item.mainImageUrl!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              badgeText,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppSemanticColors.coralSoftFor(
                                  theme.brightness,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.title,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class WaitlistNudgeCard extends StatefulWidget {
  const WaitlistNudgeCard({
    required this.city,
    required this.listingCount,
    super.key,
  });

  final String city;
  final int listingCount;

  @override
  State<WaitlistNudgeCard> createState() => _WaitlistNudgeCardState();
}

class _WaitlistNudgeCardState extends State<WaitlistNudgeCard> {
  bool _notified = false;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppSemanticColors.accent.withValues(alpha: 0.08),
            AppSemanticColors.accent.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.cardBorder,
        border: Border.all(
          color: AppSemanticColors.accent.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppSemanticColors.coralSoftFor(theme.brightness),
                  borderRadius: AppRadius.smBorder,
                ),
                child: Icon(
                  Icons.group_add_outlined,
                  color: AppSemanticColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.waitlistNudgeTitle(widget.city),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locale.waitlistNudgeSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppSemanticColors.textSecondaryFor(
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
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppSemanticColors.disabledSurfaceFor(theme.brightness),
              borderRadius: AppRadius.pillBorder,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 14,
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                ),
                const SizedBox(width: 4),
                Text(
                  locale.cityCounterShort(widget.listingCount, widget.city),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_notified)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppSemanticColors.coralSoftFor(theme.brightness),
                borderRadius: AppRadius.smBorder,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: AppSemanticColors.accent,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      locale.waitlistConfirmed,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppSemanticColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            FlatmatesButton(
              key: const Key('waitlist_notify_me_button'),
              label: locale.waitlistNotifyMe,
              onPressed: () {
                setState(() => _notified = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(locale.waitlistConfirmed),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Icons.notifications_active_outlined,
              height: 44,
              fullWidth: true,
            ),
        ],
      ),
    );
  }
}
