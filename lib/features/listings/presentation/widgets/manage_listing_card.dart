import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../discover/domain/property_listing.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_price_text.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import 'manage_stats_widgets.dart';

/// Property card with image, info row, owner info, and stats action grid.
class ManageListingCard extends StatelessWidget {
  const ManageListingCard({
    required this.listing,
    required this.status,
    required this.isPaused,
    this.isPausing = false,
    required this.onTogglePause,
    required this.onShare,
    this.onCopyLink,
    required this.onEdit,
    required this.onViewStats,
    required this.onReview,
    required this.onRenew,
    required this.theme,
    required this.locale,
    super.key,
  });

  final PropertyListing listing;
  final String status;
  final bool isPaused;
  final bool isPausing;
  final void Function(int listingId, bool currentlyPaused) onTogglePause;
  final VoidCallback onShare;
  final VoidCallback? onCopyLink;
  final VoidCallback onEdit;
  final VoidCallback onViewStats;
  final VoidCallback onReview;
  final VoidCallback onRenew;
  final ThemeData theme;
  final AppLocalizations locale;

  @override
  Widget build(BuildContext context) {
    final expiryLabel = _expiryLabel;
    return FlatmatesCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full-width image at top with status chip overlay
          Stack(
            children: [
              if (listing.effectiveMainImageUrl != null)
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: FlatmatesNetworkImage(
                    imageUrl: listing.effectiveMainImageUrl!,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                )
              else
                _buildPlaceholderImage(fullWidth: true),
            ],
          ),

          // Info below image
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status as coloured text above the title (not a tag pinned
                // on the photo).
                Row(
                  children: [
                    Icon(_statusIcon, size: 16, color: _statusColor),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        _statusLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  listing.title,
                  style: theme.textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                FlatmatesPriceText.card(
                  amount: listing.monthlyRent.toInt(),
                  period: AppLocalizations.of(context).perMonthSuffix,
                ),
                if (_facts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  // Plain text, not a row of pills.
                  Text(
                    _facts.join(' · '),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Performance summary strip — replaces the redundant "owner = you"
          // row with actionable engagement + expiry signals.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _PerfStat(
                    icon: Icons.visibility_outlined,
                    value: locale.perfViewsLabel(
                      compactCount(listing.viewCount),
                    ),
                    theme: theme,
                  ),
                ),
                Expanded(
                  child: _PerfStat(
                    icon: Icons.favorite_outline_rounded,
                    value: locale.perfInterestLabel(
                      compactCount(listing.interestCount),
                    ),
                    theme: theme,
                  ),
                ),
                if (expiryLabel != null)
                  Expanded(
                    child: _PerfStat(
                      icon: Icons.schedule_outlined,
                      value: expiryLabel,
                      theme: theme,
                      emphasis: _isExpired,
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Stats action grid (2 rows x 3 cols)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
            child: Column(
              children: [
                // Row 1
                Row(
                  children: [
                    Expanded(
                      child: StatActionItem(
                        icon: Icons.favorite_border_rounded,
                        label: locale.matchCountLabel(listing.interestCount),
                        onTap: onViewStats,
                        theme: theme,
                      ),
                    ),
                    Expanded(
                      child: StatActionItem(
                        icon: Icons.edit_outlined,
                        label: locale.editListingCta,
                        onTap: onEdit,
                        theme: theme,
                      ),
                    ),
                    Expanded(
                      child: StatActionItem(
                        icon: Icons.bar_chart_outlined,
                        label: locale.viewStatsAction(
                          compactCount(listing.viewCount),
                        ),
                        onTap: onViewStats,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs + AppSpacing.xs),
                // Row 2
                Row(
                  children: [
                    Expanded(
                      child: StatActionItem(
                        icon: _primaryStatusActionIcon,
                        label: _primaryStatusActionLabel,
                        onTap: _primaryStatusActionTap,
                        theme: theme,
                      ),
                    ),
                    Expanded(
                      child: StatActionItem(
                        icon: Icons.share_outlined,
                        label: locale.shareAction,
                        onTap: onShare,
                        theme: theme,
                      ),
                    ),
                    if (onCopyLink != null)
                      Expanded(
                        child: StatActionItem(
                          icon: Icons.link,
                          label: locale.copyLinkAction,
                          onTap: onCopyLink!,
                          theme: theme,
                        ),
                      )
                    else
                      const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _statusLabel {
    if (_isPaused) return locale.pausedStatus;
    return switch (status) {
      'active' => locale.activeStatus,
      'live' || 'approved' => locale.listingLive,
      'draft' => locale.draftStatus,
      'expired' => locale.expiredStatus,
      'pending_review' => locale.underReview,
      'under_review' => locale.underReview,
      'paused' => locale.pausedStatus,
      'rejected' => locale.listingRejected,
      // Never show a raw backend value.
      _ => locale.listingStatusUnknown,
    };
  }

  IconData get _statusIcon {
    if (_isPaused) return Icons.pause_circle_outline;
    return switch (status) {
      'active' => Icons.check_circle_outline,
      'live' || 'approved' => Icons.check_circle_outline,
      'draft' => Icons.edit_note_rounded,
      'expired' => Icons.schedule_outlined,
      'pending_review' => Icons.hourglass_top_outlined,
      'under_review' => Icons.hourglass_top_outlined,
      'paused' => Icons.pause_circle_outline,
      'rejected' => Icons.error_outline_rounded,
      _ => Icons.info_outline,
    };
  }

  /// Semantic colour for the status — surfaces urgency at a glance.
  ///
  /// Neutral statuses (paused/draft) use the brightness-aware text tokens so
  /// the chip clears contrast in dark mode; the light-only `textSecondary` /
  /// `textTertiary` constants render at ~1.2:1 over the dark card. (#32)
  Color get _statusColor {
    final brightness = theme.brightness;
    if (_isPaused) return AppSemanticColors.textSecondaryFor(brightness);
    return switch (status) {
      'active' || 'live' || 'approved' => AppSemanticColors.pineFor(brightness),
      'draft' => AppSemanticColors.textTertiaryFor(brightness),
      'expired' || 'rejected' => AppSemanticColors.dangerFor(brightness),
      'pending_review' ||
      'under_review' => AppSemanticColors.warningInkFor(brightness),
      _ => AppSemanticColors.textSecondaryFor(brightness),
    };
  }

  bool get _isPaused => isPaused || status == 'paused';

  bool get _isExpired => status == 'expired';

  bool get _isUnderReview =>
      status == 'pending_review' || status == 'under_review';

  String get _primaryStatusActionLabel {
    if (_isExpired) return locale.renewAction;
    if (_isUnderReview) return locale.reviewAction;
    if (_isPaused) return locale.resumeAction;
    return locale.pauseListingCta;
  }

  IconData get _primaryStatusActionIcon {
    if (_isExpired) return Icons.refresh;
    if (_isUnderReview) return Icons.rate_review_outlined;
    if (_isPaused) return Icons.play_circle_outline;
    return Icons.pause_circle_outline;
  }

  VoidCallback? get _primaryStatusActionTap {
    if (_isExpired) return onRenew;
    if (_isUnderReview) return onReview;
    if (isPausing) return null;
    return () => onTogglePause(listing.id, _isPaused);
  }

  /// Beds, baths and area, when known.
  List<String> get _facts => [
    if (listing.bedrooms != null) locale.bedsCount(listing.bedrooms!),
    if (listing.bathrooms != null) locale.bathsCount(listing.bathrooms!),
    if (listing.areaSqft != null) locale.sqftLabel(listing.areaSqft!.round()),
  ];

  /// Only a real expiry date: the move-in date is not an expiry.
  String? get _expiryLabel {
    final expiresAt = listing.expiresAt;
    if (expiresAt == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(
      expiresAt.toLocal().year,
      expiresAt.toLocal().month,
      expiresAt.toLocal().day,
    );
    final days = expiryDay.difference(today).inDays;
    if (days < 0) return locale.expiredStatus;
    if (days == 0) return locale.expiresToday;
    return locale.expiresInDays(days);
  }

  Widget _buildPlaceholderImage({bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : 80,
      height: fullWidth ? 160 : 80,
      decoration: BoxDecoration(
        color: AppSemanticColors.paperDeepFor(theme.brightness),
        borderRadius: fullWidth ? BorderRadius.zero : AppRadius.mdBorder,
      ),
      child: Icon(
        Icons.apartment_rounded,
        color: AppSemanticColors.textTertiaryFor(theme.brightness),
      ),
    );
  }
}

// ── Performance stat — compact icon + value for the summary strip ────────

class _PerfStat extends StatelessWidget {
  const _PerfStat({
    required this.icon,
    required this.value,
    required this.theme,
    this.emphasis = false,
  });

  final IconData icon;
  final String value;
  final ThemeData theme;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final color = emphasis
        ? AppSemanticColors.dangerFor(theme.brightness)
        : AppSemanticColors.textSecondaryFor(theme.brightness);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
