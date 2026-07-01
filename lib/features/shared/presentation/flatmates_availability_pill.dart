import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Visual style of an [AvailabilityPill].
enum AvailabilityPillStyle {
  /// Coloured pill for use on solid surfaces (card bodies, lists).
  solid,

  /// Frosted/translucent pill for overlaying images.
  onImage,
}

/// Compact availability status pill shown on property cards and the hero
/// carousel.
///
/// Surfaces the listing's move-in readiness at a glance — "Available now",
/// "From 12 Aug", or "Under review" — instead of burying it in the details
/// page. The variant is derived from [AvailabilityPill.resolve] which inspects
/// the listing's [status] and [availableFrom] date.
class AvailabilityPill extends StatelessWidget {
  const AvailabilityPill({
    required this.variant,
    required this.label,
    required this.color,
    super.key,
    this.style = AvailabilityPillStyle.solid,
    this.icon,
  });

  /// Resolves the pill variant from a listing's status + availability date.
  ///
  /// Returns `null` when there is nothing meaningful to surface.
  static AvailabilityPill? resolve({
    required BuildContext context,
    required String? status,
    required DateTime? availableFrom,
    bool isAvailable = false,
    AvailabilityPillStyle style = AvailabilityPillStyle.solid,
  }) {
    final locale = AppLocalizations.of(context);

    // Under review takes priority — it gates discoverability.
    if (status == 'pending_review' || status == 'under_review') {
      return AvailabilityPill(
        variant: AvailabilityVariant.underReview,
        label: locale.underReview,
        color: AppSemanticColors.warning,
        style: style,
        icon: Icons.hourglass_top_rounded,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (availableFrom != null) {
      final availDay = DateTime(
        availableFrom.toLocal().year,
        availableFrom.toLocal().month,
        availableFrom.toLocal().day,
      );
      if (!availDay.isAfter(today)) {
        return AvailabilityPill(
          variant: AvailabilityVariant.available,
          label: locale.availableNowLabel,
          color: AppSemanticColors.success,
          style: style,
          icon: Icons.check_circle_rounded,
        );
      }
      return AvailabilityPill(
        variant: AvailabilityVariant.fromDate,
        label: locale.availableFromDate(
          DateFormat.MMMd(locale.localeName).format(availDay),
        ),
        color: AppSemanticColors.info,
        style: style,
        icon: Icons.event_rounded,
      );
    }

    // No date, but listing is marked available — show generic "Available now".
    if (isAvailable) {
      return AvailabilityPill(
        variant: AvailabilityVariant.available,
        label: locale.availableNowLabel,
        color: AppSemanticColors.success,
        style: style,
        icon: Icons.check_circle_rounded,
      );
    }

    return null;
  }

  final AvailabilityVariant variant;
  final String label;
  final Color color;
  final AvailabilityPillStyle style;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isOnImage = style == AvailabilityPillStyle.onImage;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isOnImage
            ? Colors.black.withValues(alpha: 0.55)
            : color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillBorder,
        border: isOnImage
            ? null
            : Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: isOnImage ? Colors.white : color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              color: isOnImage ? Colors.white : color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Categorical availability type extended with a "from date" state.
enum AvailabilityVariant { available, fromDate, underReview }
