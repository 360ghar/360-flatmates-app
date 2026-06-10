import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/components.dart';
import '../../domain/property_listing.dart';
import 'flat_details_sections.dart';

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
          FlatmatesSectionHeader(title: locale.aboutThisFlatSection),
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

          // Costs breakdown
          if (l.securityDeposit != null || l.maintenanceCharges != null) ...[
            FlatmatesSectionHeader(title: locale.costsBreakdownSectionTitle),
            const SizedBox(height: AppSpacing.sm),
            FlatmatesCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  if (l.securityDeposit != null) ...[
                    CostRow(
                      label: locale.securityDepositRow,
                      child: FlatmatesPriceText.inline(
                        amount: l.securityDeposit!.round(),
                      ),
                    ),
                    if (l.maintenanceCharges != null)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                  if (l.maintenanceCharges != null)
                    CostRow(
                      label: locale.maintenanceRow,
                      child: FlatmatesPriceText.inline(
                        amount: l.maintenanceCharges!.round(),
                        period: 'month',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.screen),
          ],

          // Availability grid
          Row(
            children: [
              Expanded(
                child: _AvailabilityTile(
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

class _AvailabilityTile extends StatelessWidget {
  const _AvailabilityTile({required this.label, required this.value});
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppSemanticColors.line.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppSemanticColors.textSecondaryFor(
                isDark ? Brightness.dark : Brightness.light,
              ),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
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
