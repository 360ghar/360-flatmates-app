import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../bootstrap/domain/bootstrap_models.dart';
import '../../../shared/presentation/components.dart';

/// Masks the last token of [fullName] when [hideLastName] is on.
String displayOwnName(
  String? fullName, {
  required bool hideLastName,
  required String fallback,
}) {
  final raw = fullName?.trim() ?? '';
  if (raw.isEmpty) return fallback;
  if (!hideLastName) return raw;
  final parts = raw.split(RegExp(r'\s+'));
  if (parts.length <= 1) return parts.first;
  return parts.sublist(0, parts.length - 1).join(' ');
}

/// City only when [hideExactLocation]; else locality + city + state.
String? displayOwnLocation({
  String? city,
  String? state,
  String? locality,
  required bool hideExactLocation,
}) {
  final cityTrim = city?.trim() ?? '';
  final stateTrim = state?.trim() ?? '';
  final localityTrim = locality?.trim() ?? '';
  if (hideExactLocation) return cityTrim.isEmpty ? null : cityTrim;
  final parts = <String>[
    if (localityTrim.isNotEmpty) localityTrim,
    if (cityTrim.isNotEmpty) cityTrim,
    if (stateTrim.isNotEmpty) stateTrim,
  ];
  return parts.isEmpty ? null : parts.join(', ');
}

int profileStrengthPercent(FlatmatesProfileModel profile) {
  final checks = <bool>[
    profile.fullName?.trim().isNotEmpty ?? false,
    profile.profileImageUrl?.trim().isNotEmpty ?? false,
    profile.city?.trim().isNotEmpty ?? false,
    profile.locality?.trim().isNotEmpty ?? false,
    profile.mode?.trim().isNotEmpty ?? false,
    profile.budgetMin != null && profile.budgetMax != null,
    profile.moveInTimeline?.trim().isNotEmpty ?? false,
    profile.bio?.trim().isNotEmpty ?? false,
    profile.cleanliness?.trim().isNotEmpty ?? false,
    profile.foodHabits?.trim().isNotEmpty ?? false,
  ];
  final completed = checks.where((value) => value).length;
  return ((completed / checks.length) * 100).round().clamp(0, 100);
}

class ProfileStrengthCard extends StatelessWidget {
  const ProfileStrengthCard({
    required this.percent,
    required this.onTap,
    super.key,
  });

  final int percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = theme.brightness;
    final locale = AppLocalizations.of(context);
    final clay = AppSemanticColors.clayFor(b);
    // The ring grows with the text size so "100" never clips at 2x.
    final ring = AppSpacing.scaled(context, 44);

    return FlatmatesCard(
      onTap: onTap,
      child: Row(
        children: [
          Semantics(
            label: locale.profileStrengthTitle(percent),
            value: '$percent%',
            child: ExcludeSemantics(
              child: SizedBox.square(
                dimension: ring,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: percent / 100,
                      strokeWidth: 3.5,
                      backgroundColor: AppSemanticColors.paperDeepFor(b),
                      valueColor: AlwaysStoppedAnimation<Color>(clay),
                    ),
                    Center(
                      child: Text(
                        '$percent',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppSemanticColors.clayInkFor(b),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  locale.profileStrengthTitle(percent),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  locale.profileStrengthSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(b),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppSemanticColors.textTertiaryFor(b),
          ),
        ],
      ),
    );
  }
}
