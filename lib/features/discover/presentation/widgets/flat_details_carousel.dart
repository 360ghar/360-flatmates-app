import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_ui.dart';

class FlatDetailsCarousel extends StatefulWidget {
  const FlatDetailsCarousel({
    required this.images,
    required this.currentIndex,
    required this.onPageChanged,
    required this.title,
    required this.onBack,
    required this.onShare,
    required this.onFavorite,
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
  final VoidCallback onFavorite;
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

    return SizedBox(
      height: heroHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: images.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppSemanticColors.accent.withValues(alpha: 0.9),
                          AppSemanticColors.accent.withValues(alpha: 0.35),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initialsFromName(widget.title),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 48,
                        ),
                      ),
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: widget.onPageChanged,
                    itemBuilder: (context, index) {
                      final delta = (_page - index).clamp(-1.0, 1.0);
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          GestureDetector(
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
                                  scale: 1.12,
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
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.4),
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

          // Frosted glass icon buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FrostedIconButton(
                  key: const Key('flat_back_button'),
                  icon: Icons.arrow_back_rounded,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onTap: widget.onBack,
                ),
                Row(
                  children: [
                    _FrostedIconButton(
                      key: const Key('flat_share_button'),
                      icon: Icons.share_outlined,
                      tooltip: locale.shareListingCta,
                      onTap: widget.onShare,
                    ),
                    const SizedBox(width: 10),
                    _FrostedIconButton(
                      key: const Key('flat_header_shortlist_button'),
                      icon: widget.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: widget.isFavorite ? Colors.red : Colors.white,
                      tooltip: locale.shortlistCta,
                      onTap: widget.onFavorite,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Image counter pill
          if (images.length > 1)
            Positioned(
              bottom: 14 + widget.bottomInset,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${currentIndex + 1} / ${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Page indicator dots
          if (images.length > 1)
            Positioned(
              bottom: 40 + widget.bottomInset,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: currentIndex == index ? 16 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: currentIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FrostedIconButton extends StatelessWidget {
  const _FrostedIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.iconColor,
    super.key,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: AppRadius.mdBorder,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppSemanticColors.surfaceFor(
                  theme.brightness,
                ).withValues(alpha: 0.2),
                borderRadius: AppRadius.mdBorder,
              ),
              child: Icon(icon, color: iconColor ?? Colors.white, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}
