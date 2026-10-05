import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../location/presentation/map_widgets.dart';
import '../../../shared/presentation/components.dart';
import '../../domain/property_listing.dart';

/// Opens the property location in an external maps app (view-only, distinct
/// from `GetDirectionsButton` which launches turn-by-turn directions).
///
/// Uses the `geo:` URI as the primary scheme (opens the native maps app
/// directly on Android) and falls back to the universal Google Maps HTTPS URL.
/// The launch is NOT gated solely on `canLaunchUrl`, because Android 11+ and
/// iOS frequently report generic https URLs as unlaunchable due to package
/// visibility / query-scheme restrictions, which would silently swallow the
/// tap and make the map appear "broken".
Future<void> _openInMaps(
  double latitude,
  double longitude, {
  String? label,
}) async {
  final encodedLabel = label != null ? Uri.encodeComponent(label) : '';
  final geoUri = Uri.parse(
    'geo:$latitude,$longitude?q=$latitude,$longitude($encodedLabel)',
  );
  final httpsUri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
  );

  // Note: deliberately not gated on canLaunchUrl() — it is unreliable on
  // Android 11+ (package visibility) and silently returns false for https
  // URLs without a matching <queries> entry, making the map tap a no-op.
  // Try the native geo: scheme first.
  try {
    final launched = await launchUrl(
      geoUri,
      mode: LaunchMode.externalApplication,
    );
    if (launched) return;
  } catch (e) {
    debugPrint(
      'FlatDetailsLocation._openInMaps: geo: launch failed, falling back to HTTPS: $e',
    );
  }

  // Fallback: universal Google Maps HTTPS URL in the external browser/app.
  try {
    final launched = await launchUrl(
      httpsUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      debugPrint(
        'FlatDetailsLocation._openInMaps: launchUrl returned false for https',
      );
    }
  } catch (e) {
    debugPrint('FlatDetailsLocation._openInMaps https failed: $e');
  }
}

class FlatDetailsLocation extends StatelessWidget {
  const FlatDetailsLocation({
    required this.listing,
    required this.currentUserId,
    required this.onVoteSocietyTag,
    super.key,
  });

  final PropertyListing listing;
  final int? currentUserId;
  final void Function(String tag, String vote) onVoteSocietyTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final l = listing;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: AppSpacing.horizontalScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map
          if (l.latitude != null && l.longitude != null) ...[
            FlatmatesSectionHeader(title: locale.locationSectionTitle),
            const SizedBox(height: AppSpacing.sm),
            MiniMapView(
              latitude: l.latitude!,
              longitude: l.longitude!,
              height: 220,
              markerLabel: l.locality ?? l.city,
              onTap: () => _openInMaps(
                l.latitude!,
                l.longitude!,
                label: l.locality ?? l.city ?? locale.propertyFallbackLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GetDirectionsButton(
              key: const ValueKey('flat_details_get_directions'),
              latitude: l.latitude!,
              longitude: l.longitude!,
            ),
            const SizedBox(height: AppSpacing.screen),
          ],

          // Society / Vibe tags
          if (l.societyTagVoteCounts.isNotEmpty) ...[
            FlatmatesSectionHeader(title: locale.societyVibeSectionTitle),
            const SizedBox(height: AppSpacing.sm),
            _buildSocietyTagChips(l, isDark),
            const SizedBox(height: AppSpacing.screen),
          ],

          // Social proof: wraps on a narrow phone or at large text.
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              if (l.viewCount > 0)
                _StatItem(
                  icon: Icons.visibility_outlined,
                  value: compactCount(l.viewCount),
                  label: locale.viewsLabel,
                  isDark: isDark,
                ),
              if (l.interestCount > 0)
                _StatItem(
                  icon: Icons.person_outline,
                  value: compactCount(l.interestCount),
                  label: locale.interestedLabel,
                  isDark: isDark,
                ),
              if (l.likeCount > 0)
                _StatItem(
                  icon: Icons.favorite_border,
                  value: compactCount(l.likeCount),
                  label: locale.likesLabel,
                  isDark: isDark,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.screen),

          // Visit state banner
          if (l.userHasScheduledVisit == true &&
              l.userNextVisitDate != null) ...[
            Container(
              width: double.infinity,
              padding: AppSpacing.edgeMd,
              decoration: BoxDecoration(
                color: AppSemanticColors.pineSoftFor(theme.brightness),
                borderRadius: AppRadius.mdBorder,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppSemanticColors.pineFor(
                      Theme.of(context).brightness,
                    ),
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      locale.visitScheduledBanner(
                        DateFormat.yMMMd(
                          locale.localeName,
                        ).format(l.userNextVisitDate!),
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppSemanticColors.greenInkFor(theme.brightness),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.screen),
          ],

          // Safety banner
          Container(
            width: double.infinity,
            padding: AppSpacing.edgeMd,
            decoration: BoxDecoration(
              color: AppSemanticColors.coralSoftFor(theme.brightness),
              borderRadius: AppRadius.mdBorder,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: AppSemanticColors.clayFor(
                    Theme.of(context).brightness,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.safetyBannerTitle,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppSemanticColors.textPrimaryFor(
                            Theme.of(context).brightness,
                          ),
                        ),
                      ),
                      Text(
                        locale.safetyBannerBody,
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
          ),
          // Bottom clearance is now provided by the ListView's bottom padding
          // in FlatDetailsPage (no magic offset here).
          const SizedBox(height: AppSpacing.screen),
        ],
      ),
    );
  }

  Widget _buildSocietyTagChips(PropertyListing l, bool isDark) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: l.societyTagVoteCounts.entries.map((entry) {
        final tag = entry.key;
        final counts = entry.value;
        final up = counts['up'] ?? 0;
        final netVotes = up - (counts['down'] ?? 0);
        final myVote = currentUserId != null
            ? (l.societyTagUserVotes['$currentUserId:$tag'] ??
                  l.societyTagUserVotes[currentUserId.toString()])
            : null;
        final label = humanizeFlatmatesToken(tag);
        return _SocietyTagChip(
          tag: tag,
          label: label,
          netVotes: netVotes,
          myVote: myVote,
          onVote: onVoteSocietyTag,
          isDark: isDark,
        );
      }).toList(),
    );
  }
}

class _SocietyTagChip extends StatelessWidget {
  const _SocietyTagChip({
    required this.tag,
    required this.label,
    required this.netVotes,
    required this.myVote,
    required this.onVote,
    required this.isDark,
  });

  final String tag;
  final String label;
  final int netVotes;
  final String? myVote;
  final void Function(String tag, String vote) onVote;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final selected = myVote == 'up';
    final clay = AppSemanticColors.clayFor(brightness);
    final foreground = selected
        ? AppSemanticColors.clayInkFor(brightness)
        : AppSemanticColors.textPrimaryFor(brightness);
    // Tap votes up, long-press votes down (announced as a long-press hint).
    return Semantics(
      button: true,
      selected: selected,
      onLongPressHint: AppLocalizations.of(context).voteDownHint,
      child: Material(
        color: selected
            ? AppSemanticColors.coralSoftFor(brightness)
            : AppSemanticColors.paper2For(brightness),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdBorder,
          side: BorderSide(
            color: selected ? clay : AppSemanticColors.hairlineFor(brightness),
          ),
        ),
        child: InkWell(
          onTap: () => onVote(tag, 'up'),
          onLongPress: () => onVote(tag, 'down'),
          customBorder: const RoundedRectangleBorder(
            borderRadius: AppRadius.mdBorder,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: kMinInteractiveDimension,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                    size: 16,
                    color: selected
                        ? clay
                        : AppSemanticColors.textSecondaryFor(brightness),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    netVotes.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(brightness),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppSemanticColors.textTertiaryFor(
            Theme.of(context).brightness,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppSemanticColors.textTertiaryFor(theme.brightness),
          ),
        ),
      ],
    );
  }
}
