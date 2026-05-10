import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_ui.dart';

/// Hero image carousel with page indicators and frosted glass icon buttons.
class FlatDetailsCarousel extends StatelessWidget {
  const FlatDetailsCarousel({
    required this.images,
    required this.currentIndex,
    required this.onPageChanged,
    required this.title,
    required this.onBack,
    required this.onShare,
    required this.onFavorite,
    super.key,
  });

  final List<String> images;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final String title;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const heroHeight = 220.0;

    return Column(
      children: [
        SizedBox(
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
                            initialsFromName(title),
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 48,
                            ),
                          ),
                        ),
                      )
                    : PageView.builder(
                        itemCount: images.length,
                        onPageChanged: onPageChanged,
                        itemBuilder: (context, index) => Stack(
                          fit: StackFit.expand,
                          children: [
                            FlatmatesNetworkImage(
                              imageUrl: images[index],
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            // Gradient overlay at bottom of hero image
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: 80,
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
                          ],
                        ),
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
                      onTap: onBack,
                    ),
                    Row(
                      children: [
                        _FrostedIconButton(
                          key: const Key('flat_share_button'),
                          icon: Icons.share_outlined,
                          onTap: onShare,
                        ),
                        const SizedBox(width: 10),
                        _FrostedIconButton(
                          key: const Key('flat_shortlist_button'),
                          icon: Icons.favorite_border_rounded,
                          onTap: onFavorite,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (images.length > 1)
                Positioned(
                  bottom: 14,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: currentIndex == index ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
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
        ),
      ],
    );
  }
}

/// Frosted glass icon button for floating over hero images.
class _FrostedIconButton extends StatelessWidget {
  const _FrostedIconButton({required this.icon, required this.onTap, super.key});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
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
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
