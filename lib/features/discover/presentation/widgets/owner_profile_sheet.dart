import 'package:flutter/material.dart';

import '../../../../core/compatibility/compatibility_ring.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/components.dart';

class OwnerProfileSheet extends StatelessWidget {
  const OwnerProfileSheet({
    required this.peerData,
    required this.listingOwnerName,
    required this.onSendMessage,
    super.key,
  });

  final Map<String, dynamic>? peerData;
  final String listingOwnerName;
  final VoidCallback onSendMessage;

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic>? peerData,
    required String listingOwnerName,
    required VoidCallback onSendMessage,
  }) {
    return FlatmatesBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => OwnerProfileSheet(
        peerData: peerData,
        listingOwnerName: listingOwnerName,
        onSendMessage: onSendMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final name = peerData?['full_name'] as String? ?? listingOwnerName;
    final imageUrl = peerData?['profile_image_url'] as String?;
    final mode = peerData?['mode'] as String?;
    final city = peerData?['city'] as String?;
    final age = peerData?['age'];
    final profession = peerData?['profession'] as String?;
    final matchPercentage =
        (peerData?['match_percentage'] as num?)?.toDouble() ?? 0;

    final locationParts = [
      ?peerData?['locality']?.toString(),
      ?city,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.md),
        FlatmatesAvatar(name: name, imageUrl: imageUrl, size: 80),
        const SizedBox(height: AppSpacing.md),
        Text(
          name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (mode != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _ModeBadge(mode: mode, isDark: isDark),
        ],
        if (age != null || profession != null || locationParts.isNotEmpty)
          const SizedBox(height: AppSpacing.sm),
        if (age != null || profession != null)
          Text(
              [
              if (age != null) '$age years',
              ?profession,
            ].join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppSemanticColors.textSecondaryFor(
                isDark ? Brightness.dark : Brightness.light,
              ),
            ),
          ),
        if (locationParts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppSemanticColors.textTertiaryFor(
                  isDark ? Brightness.dark : Brightness.light,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                locationParts.join(', '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppSemanticColors.textSecondaryFor(
                    isDark ? Brightness.dark : Brightness.light,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),

        // Compatibility ring
        CompatibilityRing(
          percentage: matchPercentage,
          size: 88,
          strokeWidth: 6,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${matchPercentage.round()}% Match',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: _matchColor(matchPercentage),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Send message CTA
        SizedBox(
          width: double.infinity,
          child: FlatmatesButton(
            label: locale.contactCta,
            onPressed: onSendMessage,
            icon: Icons.send_rounded,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Color _matchColor(double pct) {
    if (pct >= 70) return AppSemanticColors.success;
    if (pct >= 40) return AppSemanticColors.warning;
    if (pct > 0) return AppSemanticColors.error;
    return AppSemanticColors.textTertiaryFor(Brightness.light);
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.mode, required this.isDark});
  final String mode;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final label = switch (mode) {
      'co_hunter' => 'Co-Hunter',
      'room_poster' => 'Room Poster',
      'open_to_both' => 'Open to Both',
      _ => mode,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppSemanticColors.accent),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppSemanticColors.accent,
        ),
      ),
    );
  }
}
