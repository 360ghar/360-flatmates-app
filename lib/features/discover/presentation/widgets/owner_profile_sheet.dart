import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/compatibility/compatibility_ring.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../chats/chats_repository.dart';
import '../../../shared/presentation/components.dart';

class OwnerProfileSheet extends ConsumerWidget {
  const OwnerProfileSheet({
    required this.ownerId,
    required this.listingOwnerName,
    required this.onSendMessage,
    super.key,
  });

  final int ownerId;
  final String listingOwnerName;
  final VoidCallback onSendMessage;

  static Future<void> show({
    required BuildContext context,
    required int ownerId,
    required String listingOwnerName,
    required VoidCallback onSendMessage,
  }) {
    return FlatmatesBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => OwnerProfileSheet(
        ownerId: ownerId,
        listingOwnerName: listingOwnerName,
        onSendMessage: onSendMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(peerProfileProvider(ownerId));

    return profileAsync.when(
      loading: () => const FlatmatesSkeleton.peerProfileSheet(),
      error: (_, _) => _OwnerProfileBody(
        peerData: null,
        listingOwnerName: listingOwnerName,
        onSendMessage: onSendMessage,
        showError: true,
      ),
      // A null payload is the actual failure path (fetchPeerProfile catches
      // errors and returns null rather than throwing), so treat it like an
      // error: show the "couldn't load" hint and suppress the misleading
      // 0% match ring.
      data: (peerData) => _OwnerProfileBody(
        peerData: peerData,
        listingOwnerName: listingOwnerName,
        onSendMessage: onSendMessage,
        showError: peerData == null,
      ),
    );
  }
}

class _OwnerProfileBody extends StatelessWidget {
  const _OwnerProfileBody({
    required this.peerData,
    required this.listingOwnerName,
    required this.onSendMessage,
    this.showError = false,
  });

  final Map<String, dynamic>? peerData;
  final String listingOwnerName;
  final VoidCallback onSendMessage;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // listingOwnerName is canonical — it's the same owner_name the detail page
    // renders. peerData['full_name'] can diverge (stale cache, backend drift)
    // so it must never override it.
    final name = listingOwnerName;
    final imageUrl = peerData?['profile_image_url'] as String?;
    final mode = peerData?['mode'] as String?;
    final city = peerData?['city'] as String?;
    final age = peerData?['age'];
    final profession = peerData?['profession'] as String?;
    final bio = peerData?['bio'] as String?;
    final matchPercentage =
        (peerData?['match_percentage'] as num?)?.toDouble() ?? 0;
    final budgetMin = (peerData?['budget_min'] as num?)?.toDouble();
    final budgetMax = (peerData?['budget_max'] as num?)?.toDouble();
    final moveIn = peerData?['move_in_timeline'] as String?;
    final nonNegotiables =
        (peerData?['non_negotiables'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList() ??
        const <String>[];

    final locationParts = [?peerData?['locality']?.toString(), ?city];

    // Quick-stat chips (budget range, move-in timeline) — only with peer data.
    final quickStats = <({IconData icon, String label})>[
      if (peerData != null && _budgetText(budgetMin, budgetMax).isNotEmpty)
        (
          icon: Icons.currency_rupee_rounded,
          label: _budgetText(budgetMin, budgetMax),
        ),
      if (moveIn != null && moveIn.trim().isNotEmpty)
        (icon: Icons.event_outlined, label: humanizeFlatmatesToken(moveIn)),
    ];

    // Lifestyle chips — one per non-empty lifestyle token, humanized.
    final lifestyle = <({IconData icon, String label})>[
      for (final entry in <(String?, IconData)>[
        (peerData?['food_habits'] as String?, Icons.restaurant_outlined),
        (peerData?['smoking_drinking'] as String?, Icons.local_bar_outlined),
        (peerData?['guests_policy'] as String?, Icons.groups_outlined),
        (peerData?['cleanliness'] as String?, Icons.cleaning_services_outlined),
        (peerData?['sleep_schedule'] as String?, Icons.bedtime_outlined),
        (peerData?['work_style'] as String?, Icons.work_outline_rounded),
      ])
        if (entry.$1 != null && entry.$1!.trim().isNotEmpty)
          (icon: entry.$2, label: humanizeFlatmatesToken(entry.$1!)),
    ];

    final hasBio = bio != null && bio.trim().isNotEmpty;

    return SingleChildScrollView(
      child: Column(
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
          if (showError) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              locale.couldNotLoadContent,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppSemanticColors.textTertiaryFor(
                  isDark ? Brightness.dark : Brightness.light,
                ),
              ),
            ),
          ],
          if (mode != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _ModeBadge(mode: mode, isDark: isDark),
          ],
          if (age != null || profession != null || locationParts.isNotEmpty)
            const SizedBox(height: AppSpacing.sm),
          if (age != null || profession != null)
            Text(
              [if (age != null) '$age years', ?profession].join(' · '),
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

          // Compatibility ring — only meaningful when we have peer data.
          if (!showError) ...[
            const SizedBox(height: AppSpacing.lg),
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
          ],

          // Quick stats (budget, move-in).
          if (quickStats.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final s in quickStats)
                  FlatmatesChip(
                    icon: s.icon,
                    label: s.label,
                    variant: FlatmatesChipVariant.info,
                  ),
              ],
            ),
          ],

          // About / bio.
          if (hasBio) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(label: locale.aboutLabel),
            const SizedBox(height: AppSpacing.xs),
            Text(
              bio.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppSemanticColors.textSecondaryFor(
                  isDark ? Brightness.dark : Brightness.light,
                ),
              ),
            ),
          ],

          // Lifestyle chips.
          if (lifestyle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(label: locale.lifestyleSectionTitle),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final l in lifestyle)
                    FlatmatesChip(
                      icon: l.icon,
                      label: l.label,
                      variant: FlatmatesChipVariant.info,
                    ),
                ],
              ),
            ),
          ],

          // Non-negotiables / deal-breakers.
          if (nonNegotiables.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(label: locale.dealBreakersSectionTitle),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final n in nonNegotiables)
                    FlatmatesChip(
                      label: humanizeFlatmatesToken(n),
                      variant: FlatmatesChipVariant.info,
                    ),
                ],
              ),
            ),
          ],

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
      ),
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

/// Small accent-bar section header, matching the swipe card's look.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
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

/// Compact budget range, e.g. "₹15k–₹20k/mo". Mirrors the swipe card formatting.
String _budgetText(double? min, double? max) {
  if (min != null && max != null) {
    return '₹${_shortMoney(min)}–₹${_shortMoney(max)}/mo';
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
