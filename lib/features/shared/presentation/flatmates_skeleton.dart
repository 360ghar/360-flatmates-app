import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Shimmer/skeleton loading states for feed, chats, cards.
///
/// Replaces `CircularProgressIndicator` on primary surfaces.
class FlatmatesSkeleton extends StatefulWidget {
  const FlatmatesSkeleton({
    super.key,
    this.itemCount = 1,
    this.variant = SkeletonVariant.card,
  });

  /// Card skeleton — approximates a listing card shape.
  const FlatmatesSkeleton.card({super.key})
      : itemCount = 1,
        variant = SkeletonVariant.card;

  /// List item skeleton — single row with avatar circle + text lines.
  const FlatmatesSkeleton.list({super.key})
      : itemCount = 1,
        variant = SkeletonVariant.listItem;

  /// Feed skeleton — multiple cards (legacy, prefer page-specific variants).
  const FlatmatesSkeleton.feed({super.key, this.itemCount = 3})
      : variant = SkeletonVariant.card;

  /// Profile header skeleton — compact horizontal layout matching profile page.
  const FlatmatesSkeleton.profile({super.key})
      : itemCount = 1,
        variant = SkeletonVariant.profile;

  /// Discover feed skeleton — header + horizontal card sections.
  const FlatmatesSkeleton.discoverFeed({super.key})
      : itemCount = 1,
        variant = SkeletonVariant.discoverFeed;

  /// Browse listings skeleton — compact horizontal cards (image left, text right).
  const FlatmatesSkeleton.browseListings({super.key, this.itemCount = 4})
      : variant = SkeletonVariant.browseListings;

  /// Flat details skeleton — carousel image + overlay icons + bottom action bar.
  const FlatmatesSkeleton.flatDetails({super.key})
      : itemCount = 1,
        variant = SkeletonVariant.flatDetails;

  /// Chat messages skeleton — alternating sent/received message bubbles.
  const FlatmatesSkeleton.chatMessages({super.key, this.itemCount = 5})
      : variant = SkeletonVariant.chatMessages;

  /// Swipe card skeleton — tall profile card with image hero + info overlay.
  const FlatmatesSkeleton.swipeCard({super.key})
      : itemCount = 1,
        variant = SkeletonVariant.swipeCard;

  /// Conversation list skeleton — segmented control + conversation cards.
  const FlatmatesSkeleton.conversationList({super.key, this.itemCount = 4})
      : variant = SkeletonVariant.conversationList;

  /// Notification list skeleton — notification items with icon circle + text.
  const FlatmatesSkeleton.notificationList({super.key, this.itemCount = 4})
      : variant = SkeletonVariant.notificationList;

  /// Visit list skeleton — section headers + visit cards.
  const FlatmatesSkeleton.visitList({super.key, this.itemCount = 3})
      : variant = SkeletonVariant.visitList;

  /// Manage listings skeleton — CTA + segmented control + listing cards.
  const FlatmatesSkeleton.manageListings({super.key, this.itemCount = 2})
      : variant = SkeletonVariant.manageListings;

  /// Map explore skeleton — frosted top bar + map + bottom sheet cards.
  const FlatmatesSkeleton.mapExplore({super.key})
      : itemCount = 1,
        variant = SkeletonVariant.mapExplore;

  final int itemCount;
  final SkeletonVariant variant;

  @override
  State<FlatmatesSkeleton> createState() => _FlatmatesSkeletonState();
}

enum SkeletonVariant {
  card,
  listItem,
  profile,
  discoverFeed,
  browseListings,
  flatDetails,
  chatMessages,
  swipeCard,
  conversationList,
  notificationList,
  visitList,
  manageListings,
  mapExplore,
}

class _FlatmatesSkeletonState extends State<FlatmatesSkeleton> {
  @override
  Widget build(BuildContext context) {
    switch (widget.variant) {
      case SkeletonVariant.card:
        if (widget.itemCount <= 1) {
          return const _ShimmerBox(child: _CardSkeleton());
        }
        return SingleChildScrollView(
          child: Column(
            children: List.generate(
              widget.itemCount,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: _ShimmerBox(child: _CardSkeleton()),
              ),
            ),
          ),
        );
      case SkeletonVariant.listItem:
        if (widget.itemCount <= 1) {
          return const _ShimmerBox(child: _ListItemSkeleton());
        }
        return SingleChildScrollView(
          child: Column(
            children: List.generate(
              widget.itemCount,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ShimmerBox(child: _ListItemSkeleton()),
              ),
            ),
          ),
        );
      case SkeletonVariant.profile:
        return const _ShimmerBox(child: _ProfileSkeleton());
      case SkeletonVariant.discoverFeed:
        return const _ShimmerBox(child: _DiscoverFeedSkeleton());
      case SkeletonVariant.browseListings:
        return _ShimmerBox(
          child: _BrowseListingsSkeleton(itemCount: widget.itemCount),
        );
      case SkeletonVariant.flatDetails:
        return const _ShimmerBox(child: _FlatDetailsSkeleton());
      case SkeletonVariant.chatMessages:
        return _ShimmerBox(
          child: _ChatMessagesSkeleton(itemCount: widget.itemCount),
        );
      case SkeletonVariant.swipeCard:
        return const _ShimmerBox(child: _SwipeCardSkeleton());
      case SkeletonVariant.conversationList:
        return _ShimmerBox(
          child: _ConversationListSkeleton(itemCount: widget.itemCount),
        );
      case SkeletonVariant.notificationList:
        return _ShimmerBox(
          child: _NotificationListSkeleton(itemCount: widget.itemCount),
        );
      case SkeletonVariant.visitList:
        return _ShimmerBox(
          child: _VisitListSkeleton(itemCount: widget.itemCount),
        );
      case SkeletonVariant.manageListings:
        return _ShimmerBox(
          child: _ManageListingsSkeleton(itemCount: widget.itemCount),
        );
      case SkeletonVariant.mapExplore:
        return const _ShimmerBox(child: _MapExploreSkeleton());
    }
  }
}

// ── Shimmer wrapper ──────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({required this.child});

  final Widget child;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.skeletonShimmer,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;
    final highlightColor = isDark
        ? AppSemanticColors.darkSurface
        : AppSemanticColors.card;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: Alignment(1 + 2 * _controller.value, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ── Bone primitive ───────────────────────────────────────────────────────

class _Bone extends StatelessWidget {
  const _Bone({
    required this.color,
    this.width,
    this.height = 14,
    this.borderRadius,
  });

  final Color color;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}

// ── Card skeleton ────────────────────────────────────────────────────────

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boneColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: _Bone(
            width: double.infinity,
            color: boneColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.card),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bone(width: 100, height: 16, color: boneColor),
              const SizedBox(height: AppSpacing.xs),
              _Bone(width: 180, color: boneColor),
              const SizedBox(height: AppSpacing.xs),
              _Bone(width: 140, height: 10, color: boneColor),
              const SizedBox(height: AppSpacing.xs),
              _Bone(width: 120, height: 10, color: boneColor),
            ],
          ),
        ),
      ],
    );
  }
}

// ── List item skeleton ──────────────────────────────────────────────────

class _ListItemSkeleton extends StatelessWidget {
  const _ListItemSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boneColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;

    return Row(
      children: [
        _Bone(
          width: 48,
          height: 48,
          color: boneColor,
          borderRadius: BorderRadius.circular(24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bone(width: 180, color: boneColor),
              const SizedBox(height: AppSpacing.sm),
              _Bone(width: 120, height: 10, color: boneColor),
            ],
          ),
        ),
        _Bone(
          width: 28,
          height: 28,
          color: boneColor,
          borderRadius: BorderRadius.circular(7),
        ),
      ],
    );
  }
}

// ── Profile skeleton ─────────────────────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boneColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl,
      ),
      children: [
        // Compact header: avatar 80px left, text right
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _Bone(
                  width: 80,
                  height: 80,
                  color: boneColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                Positioned(
                  right: -2,
                  bottom: 2,
                  child: _Bone(
                    width: 30,
                    height: 30,
                    color: boneColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(width: 160, height: 20, color: boneColor),
                  const SizedBox(height: 6),
                  _Bone(width: 120, height: 28, color: boneColor, borderRadius: AppRadius.pillBorder),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Bone(width: 16, height: 16, color: boneColor, borderRadius: BorderRadius.circular(8)),
                      const SizedBox(width: 4),
                      _Bone(width: 120, color: boneColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.screen),
        // Profile strength card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: boneColor.withValues(alpha: 0.4),
            borderRadius: AppRadius.cardBorder,
          ),
          child: Row(
            children: [
              _Bone(width: 44, height: 44, color: boneColor, borderRadius: BorderRadius.circular(22)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bone(width: 160, color: boneColor),
                    const SizedBox(height: 4),
                    _Bone(width: 120, height: 10, color: boneColor),
                  ],
                ),
              ),
              _Bone(width: 20, height: 20, color: boneColor, borderRadius: BorderRadius.circular(10)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        // Discovery group (4 items)
        _Bone(width: 80, height: 10, color: boneColor),
        const SizedBox(height: AppSpacing.sm),
        _buildMenuCard(boneColor, itemCount: 4),
        const SizedBox(height: AppSpacing.section),
        // Trust group (1 item)
        _Bone(width: 60, height: 10, color: boneColor),
        const SizedBox(height: AppSpacing.sm),
        _buildMenuCard(boneColor, itemCount: 1),
        const SizedBox(height: AppSpacing.section),
        // Account group (2 items)
        _Bone(width: 70, height: 10, color: boneColor),
        const SizedBox(height: AppSpacing.sm),
        _buildMenuCard(boneColor, itemCount: 2),
        const SizedBox(height: AppSpacing.section),
        // Logout
        Center(
          child: _Bone(width: 80, height: 16, color: boneColor),
        ),
      ],
    );
  }

  static Widget _buildMenuCard(Color boneColor, {required int itemCount}) {
    return Container(
      decoration: BoxDecoration(
        color: boneColor.withValues(alpha: 0.3),
        borderRadius: AppRadius.cardBorder,
      ),
      child: Column(
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  _Bone(width: 40, height: 40, color: boneColor, borderRadius: BorderRadius.circular(12)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _Bone(color: boneColor)),
                  _Bone(width: 16, height: 16, color: boneColor, borderRadius: BorderRadius.circular(8)),
                ],
              ),
            ),
            if (i < itemCount - 1)
              Padding(
                padding: const EdgeInsets.only(left: 72),
                child: _Bone(width: double.infinity, height: 1, color: boneColor),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Discover feed skeleton ───────────────────────────────────────────────

class _DiscoverFeedSkeleton extends StatelessWidget {
  const _DiscoverFeedSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boneColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 120,
      ),
      children: [
        // Header: greeting left, 52px avatar right
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(width: 140, height: 24, color: boneColor),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _Bone(width: 14, color: boneColor),
                      const SizedBox(width: 4),
                      _Bone(width: 100, color: boneColor),
                      const SizedBox(width: 4),
                      _Bone(width: 16, height: 16, color: boneColor, borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
                ],
              ),
            ),
            _Bone(width: 52, height: 52, color: boneColor, borderRadius: BorderRadius.circular(12)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        // "Picked for You" section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Bone(width: 120, height: 18, color: boneColor),
            _Bone(width: 60, color: boneColor),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 320,
          child: Row(
            children: [
              _buildFeedCard(boneColor),
              const SizedBox(width: AppSpacing.sm),
              _buildFeedCard(boneColor),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // "New in [City]" section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Bone(width: 100, height: 18, color: boneColor),
            _Bone(width: 60, color: boneColor),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 320,
          child: Row(
            children: [
              _buildFeedCard(boneColor),
              const SizedBox(width: AppSpacing.sm),
              _buildFeedCard(boneColor),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildFeedCard(Color boneColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Bone(width: double.infinity, color: boneColor, borderRadius: AppRadius.cardBorder),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Bone(width: 80, color: boneColor),
          const SizedBox(height: 4),
          _Bone(width: 120, height: 12, color: boneColor),
          const SizedBox(height: 4),
          _Bone(width: 100, height: 10, color: boneColor),
        ],
      ),
    );
  }
}

// ── Browse listings skeleton ─────────────────────────────────────────────

class _BrowseListingsSkeleton extends StatelessWidget {
  const _BrowseListingsSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boneColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 120),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) {
        return Container(
          height: 110,
          decoration: BoxDecoration(
            color: boneColor,
            borderRadius: AppRadius.cardBorder,
          ),
          child: Row(
            children: [
              _Bone(
                width: 110,
                height: 110,
                color: boneColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Bone(width: 80, height: 16, color: boneColor),
                      const SizedBox(height: AppSpacing.xs),
                      _Bone(width: 140, color: boneColor),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _Bone(width: 12, height: 12, color: boneColor, borderRadius: BorderRadius.circular(6)),
                          const SizedBox(width: 2),
                          _Bone(width: 100, height: 10, color: boneColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _Bone(width: 120, height: 10, color: boneColor),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm, top: AppSpacing.sm),
                child: _Bone(width: 28, height: 28, color: boneColor, borderRadius: BorderRadius.circular(7)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Flat details skeleton ────────────────────────────────────────────────

class _FlatDetailsSkeleton extends StatelessWidget {
  const _FlatDetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boneColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Full-width image carousel 220px with overlay icons
              Stack(
                children: [
                  _Bone(width: double.infinity, height: 220, color: boneColor),
                  Positioned(
                    top: AppSpacing.lg, left: AppSpacing.lg,
                    child: _Bone(width: 36, height: 36, color: boneColor, borderRadius: BorderRadius.circular(18)),
                  ),
                  Positioned(
                    top: AppSpacing.lg, right: AppSpacing.lg + 44,
                    child: _Bone(width: 36, height: 36, color: boneColor, borderRadius: BorderRadius.circular(18)),
                  ),
                  Positioned(
                    top: AppSpacing.lg, right: AppSpacing.lg,
                    child: _Bone(width: 36, height: 36, color: boneColor, borderRadius: BorderRadius.circular(18)),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(child: _Bone(width: 200, height: 24, color: boneColor)),
                        const SizedBox(width: AppSpacing.md),
                        _Bone(width: 100, height: 20, color: boneColor),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _Bone(width: 18, height: 18, color: boneColor, borderRadius: BorderRadius.circular(9)),
                        const SizedBox(width: AppSpacing.sm),
                        _Bone(width: 160, color: boneColor),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm, runSpacing: AppSpacing.sm,
                      children: [
                        _Bone(width: 72, height: 32, color: boneColor, borderRadius: AppRadius.pillBorder),
                        _Bone(width: 80, height: 32, color: boneColor, borderRadius: AppRadius.pillBorder),
                        _Bone(width: 56, height: 32, color: boneColor, borderRadius: AppRadius.pillBorder),
                        _Bone(width: 64, height: 32, color: boneColor, borderRadius: AppRadius.pillBorder),
                        _Bone(width: 68, height: 32, color: boneColor, borderRadius: AppRadius.pillBorder),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.screen),
                    _Bone(width: 120, height: 16, color: boneColor),
                    const SizedBox(height: AppSpacing.sm),
                    _Bone(width: double.infinity, color: boneColor),
                    const SizedBox(height: AppSpacing.sm),
                    _Bone(width: double.infinity, color: boneColor),
                    const SizedBox(height: AppSpacing.sm),
                    _Bone(width: 200, color: boneColor),
                    const SizedBox(height: AppSpacing.screen),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: boneColor.withValues(alpha: 0.3),
                              borderRadius: AppRadius.cardBorder,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Bone(width: 80, height: 10, color: boneColor),
                                const SizedBox(height: AppSpacing.sm),
                                _Bone(width: 60, color: boneColor),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: boneColor.withValues(alpha: 0.3),
                              borderRadius: AppRadius.cardBorder,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Bone(width: 80, height: 10, color: boneColor),
                                const SizedBox(height: AppSpacing.sm),
                                _Bone(width: 60, color: boneColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Bottom action bar
        Container(
          padding: EdgeInsets.only(
            left: AppSpacing.xl, right: AppSpacing.xl, top: AppSpacing.md,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppSemanticColors.frostOverlayDark : AppSemanticColors.frostOverlayLight,
          ),
          child: Row(
            children: [
              Expanded(
                child: _Bone(height: 48, color: boneColor, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Bone(height: 48, color: AppSemanticColors.accent.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Chat messages skeleton ───────────────────────────────────────────────

class _ChatMessagesSkeleton extends StatelessWidget {
  const _ChatMessagesSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boneColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      itemCount: itemCount * 2,
      itemBuilder: (_, index) {
        final isTimestampRow = index.isOdd;
        final msgIndex = index ~/ 2;
        final isMine = msgIndex.isEven;

        if (isTimestampRow) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                _Bone(width: 40, height: 8, color: boneColor),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[
                _Bone(width: 32, height: 32, color: boneColor, borderRadius: BorderRadius.circular(16)),
                const SizedBox(width: AppSpacing.sm),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  decoration: BoxDecoration(
                    color: isMine ? AppSemanticColors.accent.withValues(alpha: 0.2) : AppSemanticColors.paper2,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bone(
                        width: msgIndex % 3 == 0 ? double.infinity : 180 + (msgIndex % 3) * 20.0,
                        color: isMine ? AppSemanticColors.accent.withValues(alpha: 0.15) : boneColor,
                      ),
                      if (msgIndex % 2 == 0) ...[
                        const SizedBox(height: 8),
                        _Bone(
                          width: 140,
                          color: isMine ? AppSemanticColors.accent.withValues(alpha: 0.15) : boneColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Swipe card skeleton ──────────────────────────────────────────────────

class _SwipeCardSkeleton extends StatelessWidget {
  const _SwipeCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boneColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        decoration: BoxDecoration(
          color: boneColor.withValues(alpha: 0.3),
          borderRadius: AppRadius.cardBorder,
        ),
        child: Column(
          children: [
            // Fixed-height 300px hero area
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: boneColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.md, left: AppSpacing.md,
                    child: _Bone(width: 60, height: 24, color: boneColor, borderRadius: AppRadius.pillBorder),
                  ),
                  Positioned(
                    top: AppSpacing.md, right: AppSpacing.md,
                    child: _Bone(width: 60, height: 28, color: boneColor, borderRadius: AppRadius.pillBorder),
                  ),
                  Positioned(
                    left: AppSpacing.md, right: AppSpacing.md, bottom: AppSpacing.md,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bone(width: 140, height: 20, color: boneColor),
                        const SizedBox(height: 4),
                        _Bone(width: 100, height: 12, color: boneColor),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _Bone(width: 12, height: 12, color: boneColor, borderRadius: BorderRadius.circular(6)),
                            const SizedBox(width: 4),
                            _Bone(width: 80, height: 10, color: boneColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Detail section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(width: 80, color: boneColor),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _Bone(width: 56, height: 24, color: boneColor, borderRadius: AppRadius.pillBorder),
                      const SizedBox(width: AppSpacing.xs),
                      _Bone(width: 64, height: 24, color: boneColor, borderRadius: AppRadius.pillBorder),
                      const SizedBox(width: AppSpacing.xs),
                      _Bone(width: 56, height: 24, color: boneColor, borderRadius: AppRadius.pillBorder),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Bone(width: double.infinity, height: 6, color: boneColor, borderRadius: AppRadius.pillBorder),
                  const SizedBox(height: AppSpacing.md),
                  _Bone(width: 100, color: boneColor),
                  const SizedBox(height: AppSpacing.sm),
                  _Bone(width: double.infinity, height: 12, color: boneColor),
                  const SizedBox(height: AppSpacing.sm),
                  _Bone(width: double.infinity, height: 12, color: boneColor),
                  const SizedBox(height: AppSpacing.sm),
                  _Bone(width: 160, height: 12, color: boneColor),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _Bone(width: 64, height: 28, color: boneColor, borderRadius: AppRadius.pillBorder),
                      const SizedBox(width: AppSpacing.sm),
                      _Bone(width: 72, height: 28, color: boneColor, borderRadius: AppRadius.pillBorder),
                      const SizedBox(width: AppSpacing.sm),
                      _Bone(width: 56, height: 28, color: boneColor, borderRadius: AppRadius.pillBorder),
                    ],
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

// ── Conversation list skeleton ───────────────────────────────────────────

class _ConversationListSkeleton extends StatelessWidget {
  const _ConversationListSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boneColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        // Segmented control
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: boneColor.withValues(alpha: 0.3),
              borderRadius: AppRadius.pillBorder,
            ),
            child: Row(
              children: [
                Expanded(child: Center(child: _Bone(width: 48, color: boneColor))),
                Expanded(child: Center(child: _Bone(width: 40, color: boneColor))),
                Expanded(child: Center(child: _Bone(width: 40, color: boneColor))),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // Conversation cards
        for (var i = 0; i < itemCount; i++) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: boneColor.withValues(alpha: 0.3),
                borderRadius: AppRadius.cardBorder,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(width: 44, height: 44, color: boneColor, borderRadius: BorderRadius.circular(22)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + unread badge + time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(child: _Bone(width: 120, color: boneColor)),
                                  if (i < 2) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    _Bone(width: 24, height: 16, color: boneColor, borderRadius: AppRadius.pillBorder),
                                  ],
                                ],
                              ),
                            ),
                            _Bone(width: 60, height: 10, color: boneColor),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Mode label
                        _Bone(width: 70, height: 10, color: boneColor),
                        const SizedBox(height: 2),
                        // Location row with icon
                        Row(
                          children: [
                            _Bone(width: 13, height: 13, color: boneColor, borderRadius: BorderRadius.circular(6.5)),
                            const SizedBox(width: 2),
                            _Bone(width: 100, height: 10, color: boneColor),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        // Last message preview
                        _Bone(width: double.infinity, height: 12, color: boneColor),
                        const SizedBox(height: AppSpacing.sm),
                        // Property mini-card
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: boneColor.withValues(alpha: 0.4),
                            borderRadius: AppRadius.sheetBorder,
                          ),
                          child: Row(
                            children: [
                              _Bone(width: 40, height: 40, color: boneColor, borderRadius: AppRadius.cardBorder),
                              const SizedBox(width: AppSpacing.sm),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _Bone(width: 100, height: 10, color: boneColor),
                                  const SizedBox(height: 4),
                                  _Bone(width: 70, height: 10, color: boneColor),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        // Safety banner
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, 120),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: boneColor.withValues(alpha: 0.3),
              borderRadius: AppRadius.mdBorder,
            ),
            child: Row(
              children: [
                _Bone(width: 22, height: 22, color: boneColor, borderRadius: BorderRadius.circular(11)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bone(width: 80, height: 12, color: boneColor),
                      const SizedBox(height: 2),
                      _Bone(width: 140, height: 10, color: boneColor),
                    ],
                  ),
                ),
                _Bone(width: 16, height: 16, color: boneColor, borderRadius: BorderRadius.circular(8)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Notification list skeleton ───────────────────────────────────────────

class _NotificationListSkeleton extends StatelessWidget {
  const _NotificationListSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boneColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;

    return Column(
      children: [
        for (var index = 0; index < itemCount; index++)
          _notificationItem(boneColor, index, index < 2),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  static Widget _notificationItem(Color boneColor, int index, bool isUnread) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: isUnread
            ? const Border(left: BorderSide(color: AppSemanticColors.accent, width: 3))
            : null,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: AppSpacing.edgeLg,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bone(width: 48, height: 48, color: boneColor, borderRadius: BorderRadius.circular(24)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bone(width: 140, height: 16, color: boneColor),
                    const SizedBox(height: 4),
                    _Bone(width: double.infinity, height: 12, color: boneColor),
                    const SizedBox(height: 4),
                    _Bone(width: 180, height: 12, color: boneColor),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _Bone(width: 40, height: 10, color: boneColor),
                  ),
                  if (isUnread) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppSemanticColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Visit list skeleton ──────────────────────────────────────────────────

class _VisitListSkeleton extends StatelessWidget {
  const _VisitListSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boneColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.screen, AppSpacing.xl, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bone(width: 160, height: 20, color: boneColor),
              const SizedBox(height: 4),
              _Bone(width: 120, color: boneColor),
              const SizedBox(height: AppSpacing.lg),
              // Confirmed section
              _sectionLabel(boneColor),
              const SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < itemCount && i < 2; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: _visitCard(boneColor, showActions: i == 0),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              // Requested section
              _sectionLabel(boneColor),
              const SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < itemCount && i < 1; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: _visitCard(boneColor, showActions: true),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              // Completed section
              _sectionLabel(boneColor),
              const SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < itemCount && i < 1; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: _visitCard(boneColor, showActions: false),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }

  static Widget _sectionLabel(Color boneColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: _Bone(width: 90, color: boneColor),
    );
  }

  static Widget _visitCard(Color boneColor, {required bool showActions}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: boneColor.withValues(alpha: 0.3),
        borderRadius: AppRadius.cardBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Bone(width: 32, height: 32, color: boneColor, borderRadius: BorderRadius.circular(8)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bone(width: 140, color: boneColor),
                    const SizedBox(height: 2),
                    _Bone(width: 100, height: 10, color: boneColor),
                  ],
                ),
              ),
              _Bone(width: 64, height: 24, color: boneColor, borderRadius: AppRadius.pillBorder),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Context row with icon bones
          Row(
            children: [
              _Bone(width: 12, height: 12, color: boneColor, borderRadius: BorderRadius.circular(6)),
              const SizedBox(width: 4),
              _Bone(width: 70, height: 10, color: boneColor),
              const SizedBox(width: AppSpacing.sm),
              _Bone(width: 12, height: 12, color: boneColor, borderRadius: BorderRadius.circular(6)),
              const SizedBox(width: 4),
              _Bone(width: 60, height: 10, color: boneColor),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: _Bone(height: 30, color: boneColor, borderRadius: BorderRadius.circular(8))),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: _Bone(height: 30, color: boneColor, borderRadius: BorderRadius.circular(8))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Manage listings skeleton ─────────────────────────────────────────────

class _ManageListingsSkeleton extends StatelessWidget {
  const _ManageListingsSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boneColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.md),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _Bone(width: 200, height: 28, color: boneColor),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: _Bone(width: double.infinity, height: 52, color: boneColor, borderRadius: BorderRadius.circular(10)),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: boneColor.withValues(alpha: 0.3),
              borderRadius: AppRadius.pillBorder,
            ),
            child: Row(
              children: [
                Expanded(child: Center(child: _Bone(width: 80, color: boneColor))),
                Expanded(child: Center(child: _Bone(width: 60, color: boneColor))),
                Expanded(child: Center(child: _Bone(width: 60, color: boneColor))),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, AppSpacing.xl + AppSpacing.md),
            children: [
              for (var i = 0; i < itemCount; i++) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Container(
                    decoration: BoxDecoration(
                      color: boneColor.withValues(alpha: 0.3),
                      borderRadius: AppRadius.cardBorder,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image with status chip overlay
                        Stack(
                          children: [
                            _Bone(
                              width: double.infinity,
                              height: 160,
                              color: boneColor,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
                            ),
                            Positioned(
                              top: AppSpacing.sm, right: AppSpacing.sm,
                              child: _Bone(width: 64, height: 28, color: boneColor, borderRadius: AppRadius.pillBorder),
                            ),
                          ],
                        ),
                        // Info row + quick chips
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Bone(width: 160, height: 16, color: boneColor),
                              const SizedBox(height: AppSpacing.xs),
                              _Bone(width: 80, color: boneColor),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  _Bone(width: 40, height: 20, color: boneColor, borderRadius: AppRadius.pillBorder),
                                  const SizedBox(width: AppSpacing.xs),
                                  _Bone(width: 48, height: 20, color: boneColor, borderRadius: AppRadius.pillBorder),
                                  const SizedBox(width: AppSpacing.xs),
                                  _Bone(width: 44, height: 20, color: boneColor, borderRadius: AppRadius.pillBorder),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _Bone(width: double.infinity, height: 1, color: boneColor),
                        // Owner row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          child: Row(
                            children: [
                              _Bone(width: 28, height: 28, color: boneColor, borderRadius: BorderRadius.circular(14)),
                              const SizedBox(width: AppSpacing.sm),
                              _Bone(width: 100, height: 12, color: boneColor),
                              const Spacer(),
                              _Bone(width: 80, height: 10, color: boneColor),
                            ],
                          ),
                        ),
                        _Bone(width: double.infinity, height: 1, color: boneColor),
                        // Stats grid (2 rows x 3 cols)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  for (var j = 0; j < 3; j++) ...[
                                    Expanded(child: _Bone(width: 56, height: 28, color: boneColor, borderRadius: BorderRadius.circular(8))),
                                    if (j < 2) const SizedBox(width: AppSpacing.sm),
                                  ],
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  for (var j = 0; j < 3; j++) ...[
                                    Expanded(child: _Bone(width: 56, height: 28, color: boneColor, borderRadius: BorderRadius.circular(8))),
                                    if (j < 2) const SizedBox(width: AppSpacing.sm),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Map explore skeleton ─────────────────────────────────────────────────

class _MapExploreSkeleton extends StatelessWidget {
  const _MapExploreSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boneColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;
    final safeAreaTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map placeholder
          Positioned.fill(
            child: Container(color: boneColor.withValues(alpha: 0.5)),
          ),
          // Frosted glass top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              color: isDark ? AppSemanticColors.frostOverlayDark : AppSemanticColors.frostOverlayLight,
              child: Padding(
                padding: EdgeInsets.only(top: safeAreaTop),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.xs),
                  child: Row(
                    children: [
                      _Bone(width: 140, height: 36, color: boneColor, borderRadius: AppRadius.pillBorder),
                      const Spacer(),
                      _Bone(width: 40, height: 40, color: boneColor, borderRadius: BorderRadius.circular(20)),
                      const SizedBox(width: AppSpacing.sm),
                      _Bone(width: 40, height: 40, color: boneColor, borderRadius: BorderRadius.circular(20)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Map control buttons — 4 bones (recenter, fit-bounds, zoom-in, zoom-out)
          Positioned(
            right: AppSpacing.screen,
            top: safeAreaTop + 80,
            child: Column(
              children: [
                _Bone(width: 40, height: 40, color: boneColor, borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: AppSpacing.sm),
                _Bone(width: 40, height: 40, color: boneColor, borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: AppSpacing.sm),
                _Bone(width: 40, height: 40, color: boneColor, borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: AppSpacing.sm),
                _Bone(width: 40, height: 40, color: boneColor, borderRadius: BorderRadius.circular(8)),
              ],
            ),
          ),
          // Bottom sheet with mini cards
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppSemanticColors.frostOverlayDark : AppSemanticColors.frostOverlayLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: _Bone(width: 40, height: 4, color: boneColor, borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _Bone(width: 80, height: 12, color: boneColor),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 24),
                    child: Row(
                      children: [
                        Flexible(child: _miniCard(boneColor)),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(child: _miniCard(boneColor)),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(child: _miniCard(boneColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _miniCard(Color boneColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Bone(height: 100, color: boneColor, borderRadius: AppRadius.cardBorder),
        const SizedBox(height: AppSpacing.sm),
        _Bone(width: 80, height: 12, color: boneColor),
        const SizedBox(height: 4),
        _Bone(width: 110, height: 10, color: boneColor),
      ],
    );
  }
}
