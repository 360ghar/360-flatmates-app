import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/components.dart';
import '../../../shared/presentation/flatmates_price_text.dart';
import '../../domain/property_listing.dart';

class FlatDetailsAbout extends StatefulWidget {
  const FlatDetailsAbout({required this.listing, super.key});

  final PropertyListing listing;

  @override
  State<FlatDetailsAbout> createState() => _FlatDetailsAboutState();
}

class _FlatDetailsAboutState extends State<FlatDetailsAbout> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final l = widget.listing;
    final isDark = theme.brightness == Brightness.dark;
    final desc = l.description?.trim();
    final isLong = (desc?.length ?? 0) > 120;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(label: locale.aboutThisFlatSection),
          const SizedBox(height: AppSpacing.sm),
          if (desc != null && desc.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  maxLines: _expanded ? null : 3,
                  overflow: _expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: AppSemanticColors.textPrimaryFor(
                      isDark ? Brightness.dark : Brightness.light,
                    ).withValues(alpha: 0.85),
                  ),
                ),
                if (isLong)
                  TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _expanded ? locale.showLessCta : locale.readMoreCta,
                      style: const TextStyle(
                        color: AppSemanticColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            )
          else
            Text(
              locale.noDescriptionAvailable,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppSemanticColors.textSecondaryFor(
                  isDark ? Brightness.dark : Brightness.light,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.screen),

          // Costs breakdown — accentSoft total card + line items, inspired by
          // the swipe card's CostsSection.
          _CostsBreakdown(listing: l, locale: locale, isDark: isDark),
          const SizedBox(height: AppSpacing.screen),

          // Availability grid
          Row(
            children: [
              Expanded(
                child: _AvailabilityTile(
                  icon: Icons.event_available_outlined,
                  label: locale.availableFromLabel,
                  value: l.availableFrom != null
                      ? DateFormat.yMMMd(
                          locale.localeName,
                        ).format(l.availableFrom!)
                      : locale.flexibleLabel,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _AvailabilityTile(
                  icon: Icons.schedule_outlined,
                  label: locale.postedOnLabel,
                  value: l.createdAt != null
                      ? DateFormat.yMMMd(locale.localeName).format(l.createdAt!)
                      : locale.recentlyLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.screen),
        ],
      ),
    );
  }
}

/// Accent-bar + label section header, matching the swipe card's `SectionHeader`.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
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

/// Costs breakdown with an accentSoft total card + line items.
///
/// Shows the estimated monthly total (rent + maintenance) in a prominent
/// accent-tinted card, followed by individual line items for rent, deposit,
/// and maintenance — matching the swipe card's `CostsSection` pattern.
class _CostsBreakdown extends StatelessWidget {
  const _CostsBreakdown({
    required this.listing,
    required this.locale,
    required this.isDark,
  });

  final PropertyListing listing;
  final AppLocalizations locale;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = listing;
    final hasDeposit = l.securityDeposit != null && l.securityDeposit! > 0;
    final hasMaintenance =
        l.maintenanceCharges != null && l.maintenanceCharges! > 0;

    if (!hasDeposit && !hasMaintenance) return const SizedBox.shrink();

    final totalMonthly = l.monthlyRent + (l.maintenanceCharges ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: locale.costsBreakdownSectionTitle),
        const SizedBox(height: AppSpacing.sm),

        // Total/month — accentSoft card with large accent-coloured amount.
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
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                FlatmatesPriceText.formatRupee(totalMonthly.round()),
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

        // Line items
        _CostLineItem(
          label: locale.monthlyRentRow,
          value: FlatmatesPriceText.formatRupee(l.monthlyRent.round()),
        ),
        if (hasDeposit)
          _CostLineItem(
            label: locale.securityDepositRow,
            value: FlatmatesPriceText.formatRupee(l.securityDeposit!.round()),
          ),
        if (hasMaintenance)
          _CostLineItem(
            label: locale.maintenanceRow,
            value:
                '${FlatmatesPriceText.formatRupee(l.maintenanceCharges!.round())} ${locale.perMonthSuffix}',
          ),
      ],
    );
  }
}

class _CostLineItem extends StatelessWidget {
  const _CostLineItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
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
    );
  }
}

class _AvailabilityTile extends StatelessWidget {
  const _AvailabilityTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: AppSpacing.edgeMd,
      decoration: BoxDecoration(
        color: AppSemanticColors.secondarySurfaceFor(
          isDark ? Brightness.dark : Brightness.light,
        ),
        borderRadius: AppRadius.mdBorder,
        border: Border.all(
          color: AppSemanticColors.hairlineFor(
            theme.brightness,
          ).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppSemanticColors.accent),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(
                      isDark ? Brightness.dark : Brightness.light,
                    ),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
