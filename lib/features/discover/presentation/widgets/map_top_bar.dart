import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/components.dart';

/// Map page top bar: the location chip on the left and the filter button on
/// the right, on a flat tinted surface (de-frosted, DESIGN.md §8).
///
/// Extracted verbatim from `map_view_page.dart` to keep that page under the
/// 500-line cap.
class MapTopBar extends StatelessWidget {
  const MapTopBar({
    required this.backgroundColor,
    required this.safeAreaTop,
    this.safeAreaRight = 0,
    required this.locationName,
    required this.onLocationTap,
    required this.onFilterTap,
    super.key,
  });

  final Color backgroundColor;
  final double safeAreaTop;

  /// Right-edge safe area, read from the platform. It measures 0 on the Duo
  /// (whose real inset is 82 dp on top), but a landscape notch does carry one,
  /// so the bar keeps clearing it. The bar's tinted surface stays full-bleed;
  /// only its content — the filter button above all — moves clear of the inset.
  final double safeAreaRight;

  /// Empty means "no location selected" — the chip shows its placeholder.
  final String locationName;

  final VoidCallback onLocationTap;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);

    return Container(
      color: backgroundColor,
      child: Padding(
        padding: EdgeInsets.only(top: safeAreaTop),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.md,
                AppSpacing.screen + safeAreaRight,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FlatmatesLocationChip(
                        locationName: locationName.isEmpty
                            ? null
                            : locationName,
                        placeholder: locale.selectLocationLabel,
                        dense: true,
                        onTap: onLocationTap,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // The map page has no standalone text-search surface —
                  // search lives inside the filter sheet (its top field) — so
                  // we expose a single filter affordance rather than two
                  // duplicate buttons. Kept on the right of the location chip.
                  FlatmatesChromeIconButton(
                    onPressed: onFilterTap,
                    icon: AppIcons.filter,
                    tooltip: locale.searchFiltersTitle,
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
