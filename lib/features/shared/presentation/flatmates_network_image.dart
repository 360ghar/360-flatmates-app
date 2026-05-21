import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'flatmates_ui.dart';

class FlatmatesNetworkImage extends ConsumerWidget {
  const FlatmatesNetworkImage({
    required this.imageUrl,
    super.key,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
    this.semanticLabel,
    this.heroTag,
    this.fallbackName,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final String? semanticLabel;
  final String? heroTag;
  final String? fallbackName;

  String _resolveUrl(WidgetRef ref) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    final base = ref.read(appConfigProvider).apiBaseUrl;
    return '$base/$imageUrl';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedUrl = _resolveUrl(ref);
    final theme = Theme.of(context);
    final placeholderColor = theme.brightness == Brightness.dark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;
    final image = CachedNetworkImage(
      imageUrl: resolvedUrl,
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
      errorWidget: (context, url, error) => _PhotoPendingFallback(
        width: width,
        height: height,
        borderRadius: borderRadius,
        fallbackName: fallbackName,
      ),
      fadeInDuration: const Duration(milliseconds: 200),
      memCacheWidth: width != null && width!.isFinite
          ? (width! * 2).toInt().clamp(1, 4096)
          : null,
      memCacheHeight: height != null && height!.isFinite
          ? (height! * 2).toInt().clamp(1, 4096)
          : null,
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

class _PhotoPendingFallback extends StatelessWidget {
  const _PhotoPendingFallback({
    required this.width,
    required this.height,
    required this.borderRadius,
    this.fallbackName,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final String? fallbackName;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.cardBorder;
    final initials = initialsFromName(fallbackName);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          colors: [
            AppSemanticColors.accent.withValues(alpha: 0.85),
            AppSemanticColors.accent.withValues(alpha: 0.45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: (height != null && height! < 100) ? 20 : 36,
            fontWeight: FontWeight.w700,
            fontFamily: AppTypography.fontFamilySerif,
          ),
        ),
      ),
    );
  }
}
