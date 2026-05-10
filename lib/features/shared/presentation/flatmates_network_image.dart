import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_semantic_colors.dart';

/// Shared network image component with caching, placeholder, error fallback, and fade-in.
///
/// Use this instead of raw Image.network everywhere in feature screens.
class FlatmatesNetworkImage extends StatelessWidget {
  const FlatmatesNetworkImage({
    required this.imageUrl,
    super.key,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
    this.semanticLabel,
    this.heroTag,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final String? semanticLabel;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholderColor = theme.brightness == Brightness.dark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;
    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: placeholderColor,
          borderRadius: borderRadius,
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: placeholderColor,
          borderRadius: borderRadius,
        ),
        child: Icon(
          Icons.broken_image_outlined,
          color: AppSemanticColors.ink3,
          size: (width ?? 48) * 0.4,
        ),
      ),
      fadeInDuration: const Duration(milliseconds: 200),
      memCacheWidth: width != null ? (width! * 2).toInt() : null,
      memCacheHeight: height != null ? (height! * 2).toInt() : null,
    );

    Widget child = image;

    if (semanticLabel != null) {
      child = Semantics(label: semanticLabel, child: child);
    }

    if (heroTag != null) {
      child = Hero(tag: heroTag!, child: child);
    }

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }

    return child;
  }
}
