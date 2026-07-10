import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
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
    // Normalize-join: preserves the full base path (e.g. `/api/v1`) regardless
    // of whether `base` has a trailing slash or `imageUrl` has a leading one.
    // `Uri.resolve` would strip the last path segment of the base when the
    // base lacks a trailing slash, dropping `/api/v1` from the resolved URL.
    final trimmedBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final trimmedPath = imageUrl.startsWith('/')
        ? imageUrl.substring(1)
        : imageUrl;
    return '$trimmedBase/$trimmedPath';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedUrl = _resolveUrl(ref);
    final theme = Theme.of(context);
    final placeholderColor = theme.brightness == Brightness.dark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;

    Widget child = _ResilientImage(
      url: resolvedUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      borderRadius: borderRadius,
      placeholderColor: placeholderColor,
      fallbackName: fallbackName,
    );

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

/// Tries [CachedNetworkImage] first. Falls back to [Image.network] when the
/// cache manager fails (e.g. path_provider FFI issues on newer simulators).
class _ResilientImage extends StatefulWidget {
  const _ResilientImage({
    required this.url,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
    this.placeholderColor,
    this.fallbackName,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final Color? placeholderColor;
  final String? fallbackName;

  @override
  State<_ResilientImage> createState() => _ResilientImageState();
}

class _ResilientImageState extends State<_ResilientImage> {
  bool _useFallback = false;

  @override
  void didUpdateWidget(_ResilientImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the URL changes (e.g. element recycled during list scroll), reset
    // the fallback flag so the new image gets another shot at CachedNetworkImage
    // (and its memCacheWidth/memCacheHeight downscaling) instead of being stuck
    // on the uncached Image.network path.
    if (oldWidget.url != widget.url && _useFallback) {
      setState(() => _useFallback = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_useFallback) {
      return Image.network(
        widget.url,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => _PhotoPendingFallback(
          width: widget.width,
          height: widget.height,
          borderRadius: widget.borderRadius,
          fallbackName: widget.fallbackName,
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _Placeholder(
            width: widget.width,
            height: widget.height,
            borderRadius: widget.borderRadius,
            color: widget.placeholderColor,
          );
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (context, url) => _Placeholder(
        width: widget.width,
        height: widget.height,
        borderRadius: widget.borderRadius,
        color: widget.placeholderColor,
      ),
      errorWidget: (context, url, error) {
        // Silent: _PhotoPendingFallback renders the failure visually; logging
        // here would duplicate the package-level HttpException print.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_useFallback) {
            setState(() => _useFallback = true);
          }
        });
        return _Placeholder(
          width: widget.width,
          height: widget.height,
          borderRadius: widget.borderRadius,
          color: widget.placeholderColor,
        );
      },
      fadeInDuration: const Duration(milliseconds: 200),
      memCacheWidth: widget.width != null && widget.width!.isFinite
          ? (widget.width! * 2).toInt().clamp(1, 4096)
          : null,
      memCacheHeight: widget.height != null && widget.height!.isFinite
          ? (widget.height! * 2).toInt().clamp(1, 4096)
          : null,
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.width, this.height, this.borderRadius, this.color});

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? AppSemanticColors.paper2,
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
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
          ),
        ),
      ),
    );
  }
}
