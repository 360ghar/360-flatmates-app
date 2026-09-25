import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_chrome_icon_button.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/paper/paper_scene.dart';

class FlatDetailsCarousel extends StatefulWidget {
  const FlatDetailsCarousel({
    required this.images,
    required this.currentIndex,
    required this.onPageChanged,
    required this.title,
    required this.onBack,
    required this.onShare,
    this.onFavorite,
    this.isFavorite = false,
    this.onImageTap,
    this.heroTagPrefix,
    this.bottomInset = 0,
    super.key,
  });

  final List<String> images;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final String title;
  final VoidCallback onBack;
  final VoidCallback onShare;

  /// Null hides the heart (for example on the viewer's own listing).
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final VoidCallback? onImageTap;

  /// Image at index `i` gets hero tag `'$heroTagPrefix-$i'` so it animates
  /// into [FullScreenGallery] when tapped.
  final String? heroTagPrefix;

  /// Extra space reserved at the bottom of the image (e.g. for an
  /// overlapping content sheet) — indicators shift up by this amount.
  final double bottomInset;

  @override
  State<FlatDetailsCarousel> createState() => _FlatDetailsCarouselState();
}

class _FlatDetailsCarouselState extends State<FlatDetailsCarousel> {
  late final PageController _pageController;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _page = widget.currentIndex.toDouble();
    _pageController = PageController(initialPage: widget.currentIndex)
      ..addListener(_onScroll);
  }

  void _onScroll() {
    final page = _pageController.page;
    if (page != null) setState(() => _page = page);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final heroHeight = (MediaQuery.sizeOf(context).height * 0.42).clamp(
      300.0,
      420.0,
    );
    final images = widget.images;
    final currentIndex = widget.currentIndex;
    final reduce = AppMotion.reduceMotion(context);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        children: [
          Positioned.fill(
            // No photos: the compact paper scene with the house prop
            // (DESIGN.md §6), not a gradient.
            child: images.isEmpty
                ? ColoredBox(
                    color: AppSemanticColors.skyFor(theme.brightness),
                    child: const Center(
                      child: PaperScene.compact(prop: PaperProp.house),
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: widget.onPageChanged,
                    itemBuilder: (context, index) {
                      // Parallax is off under reduce motion.
                      final delta = reduce
                          ? 0.0
                          : (_page - index).clamp(-1.0, 1.0);
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Semantics(
                            button: true,
                            label: locale.galleryPhotoSemantic(
                              index + 1,
                              images.length,
                            ),
                            child: GestureDetector(
                              onTap: widget.onImageTap,
                              child: ClipRect(
                                // Subtle parallax: image is overscaled slightly
                                // and slides slower than the page so edges
                                // never show.
                                child: Transform.translate(
                                  offset: Offset(
                                    -delta *
                                        MediaQuery.sizeOf(context).width *
                                        0.05,
                                    0,
                                  ),
                                  child: Transform.scale(
                                    scale: reduce ? 1.0 : 1.12,
                                    child: FlatmatesNetworkImage(
                                      imageUrl: images[index],
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      heroTag: widget.heroTagPrefix != null
                                          ? '${widget.heroTagPrefix}-$index'
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 96,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppSemanticColors.scrim.withValues(
                                        alpha: 0,
                                      ),
                                      AppSemanticColors.scrim.withValues(
                                        alpha: 0.4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Overlay chrome on the photo.
          Positioned(
            top: MediaQuery.paddingOf(context).top + AppSpacing.xs,
            left: AppSpacing.base,
            right: AppSpacing.base,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FlatmatesChromeIconButton(
                  key: const Key('flat_back_button'),
                  icon: Icons.arrow_back_rounded,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  style: FlatmatesChromeIconStyle.overlay,
                  onPressed: widget.onBack,
                ),
                Row(
                  children: [
                    FlatmatesChromeIconButton(
                      key: const Key('flat_share_button'),
                      icon: Icons.share_outlined,
                      tooltip: locale.shareListingCta,
                      style: FlatmatesChromeIconStyle.overlay,
                      onPressed: widget.onShare,
                    ),
                    if (widget.onFavorite != null)
                      FlatmatesChromeIconButton(
                        key: const Key('flat_header_shortlist_button'),
                        icon: widget.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        iconColor: widget.isFavorite
                            ? AppSemanticColors.clayFor(
                                Theme.of(context).brightness,
                              )
                            : AppSemanticColors.textPrimaryFor(
                                Theme.of(context).brightness,
                              ),
                        tooltip: locale.shortlistCta,
                        style: FlatmatesChromeIconStyle.overlay,
                        onPressed: widget.onFavorite,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Image counter pill
          if (images.length > 1)
            Positioned(
              bottom: AppSpacing.md + widget.bottomInset,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppSemanticColors.scrim.withValues(alpha: 0.6),
                      borderRadius: AppRadius.mdBorder,
                    ),
                    child: Text(
                      '${currentIndex + 1} / ${images.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppSemanticColors.onScrim,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
