import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_chrome_icon_button.dart';
import '../../../shared/presentation/flatmates_network_image.dart';

/// Full-screen, pinch-zoomable media viewer for property photos and
/// floor plans. Supports double-tap zoom, swipe between images at 1x,
/// and drag-to-dismiss (disabled while zoomed so panning wins).
class FullScreenGallery extends StatefulWidget {
  const FullScreenGallery({
    required this.images,
    required this.initialIndex,
    this.heroTagPrefix,
    super.key,
  });

  final List<String> images;
  final int initialIndex;

  /// When set, image at index `i` uses hero tag `'$heroTagPrefix-$i'` so the
  /// viewer animates from the inline image that opened it.
  final String? heroTagPrefix;

  static Future<void> open({
    required BuildContext context,
    required List<String> images,
    int initialIndex = 0,
    String? heroTagPrefix,
  }) {
    if (images.isEmpty) return Future.value();
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenGallery(
              images: images,
              initialIndex: initialIndex,
              heroTagPrefix: heroTagPrefix,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery>
    with SingleTickerProviderStateMixin {
  static const double _dismissDistance = 120;
  static const double _dismissVelocity = 700;

  late final PageController _pageController;
  late final AnimationController _settleController;
  late int _currentIndex;
  bool _zoomed = false;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _settleController = AnimationController(
      vsync: this,
      duration: AppMotion.standard,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _settleController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_settleController.isAnimating) return;
    setState(() => _dragOffset += details.delta.dy);
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset.abs() > _dismissDistance ||
        velocity.abs() > _dismissVelocity) {
      Navigator.of(context).pop();
      return;
    }
    _settleBack();
  }

  void _settleBack() {
    final settle = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _settleController, curve: AppMotion.easeOutCubic),
    );
    void tick() => setState(() => _dragOffset = settle.value);
    settle.addListener(tick);
    _settleController.forward(from: 0).whenCompleteOrCancel(() {
      settle.removeListener(tick);
    });
  }

  void _onZoomChanged(bool zoomed) {
    if (zoomed != _zoomed) {
      setState(() => _zoomed = zoomed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final barrierAlpha = (1 - (_dragOffset.abs() / 300)).clamp(0.0, 1.0);
    final chromeVisible = !_zoomed && _dragOffset == 0;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: barrierAlpha),
      body: GestureDetector(
        // Callbacks become null while zoomed so this recognizer drops out of
        // the gesture arena and InteractiveViewer panning wins.
        onVerticalDragUpdate: _zoomed ? null : _onDragUpdate,
        onVerticalDragEnd: _zoomed ? null : _onDragEnd,
        child: Stack(
          children: [
            Transform.translate(
              offset: Offset(0, _dragOffset),
              child: PageView.builder(
                controller: _pageController,
                physics: _zoomed
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                itemCount: widget.images.length,
                onPageChanged: (i) => setState(() {
                  _currentIndex = i;
                  // A freshly built page always starts at 1x (ValueKey resets
                  // the previous page's transform state).
                  _zoomed = false;
                }),
                itemBuilder: (context, index) => _ZoomablePage(
                  key: ValueKey(index),
                  imageUrl: widget.images[index],
                  // Only the visible page carries the hero tag so the return
                  // flight tracks the image the user is currently viewing.
                  heroTag:
                      widget.heroTagPrefix != null && index == _currentIndex
                      ? '${widget.heroTagPrefix}-$index'
                      : null,
                  semanticLabel: locale.galleryPhotoSemantic(
                    index + 1,
                    widget.images.length,
                  ),
                  onZoomChanged: _onZoomChanged,
                ),
              ),
            ),

            // Close button — solid circular overlay chrome (matches listing carousel)
            Positioned(
              top: MediaQuery.of(context).padding.top + 4,
              left: AppSpacing.base,
              child: _GalleryChrome(
                visible: chromeVisible,
                child: FlatmatesChromeIconButton(
                  key: const Key('gallery_close_button'),
                  icon: Icons.close_rounded,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  style: FlatmatesChromeIconStyle.overlay,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),

            // Counter
            if (widget.images.length > 1)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 0,
                right: 0,
                child: _GalleryChrome(
                  visible: chromeVisible,
                  child: Center(
                    child: _FrostedPill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One zoomable image page. Owns its [TransformationController], handles
/// double-tap zoom, and reports zoom state upward so the gallery can gate
/// page-swipe physics and drag-to-dismiss.
class _ZoomablePage extends StatefulWidget {
  const _ZoomablePage({
    required this.imageUrl,
    required this.onZoomChanged,
    this.heroTag,
    this.semanticLabel,
    super.key,
  });

  final String imageUrl;
  final ValueChanged<bool> onZoomChanged;
  final String? heroTag;
  final String? semanticLabel;

  @override
  State<_ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<_ZoomablePage>
    with SingleTickerProviderStateMixin {
  static const double _doubleTapScale = 2.5;

  final TransformationController _transform = TransformationController();
  late final AnimationController _zoomController;
  Animation<Matrix4>? _zoomAnim;
  TapDownDetails? _doubleTapDetails;
  bool _panEnabled = false;

  bool get _isZoomed => _transform.value.getMaxScaleOnAxis() > 1.01;

  @override
  void initState() {
    super.initState();
    _zoomController = AnimationController(vsync: this, duration: AppMotion.slow)
      ..addListener(() {
        final anim = _zoomAnim;
        if (anim != null) _transform.value = anim.value;
      });
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _reportZoom() {
    // Guards the dispose-time cancel callback from whenCompleteOrCancel.
    if (!mounted) return;
    final zoomed = _isZoomed;
    // panEnabled keeps InteractiveViewer out of the gesture arena at 1x so
    // PageView swipes and drag-to-dismiss work; while zoomed it pans freely.
    if (_panEnabled != zoomed) {
      setState(() => _panEnabled = zoomed);
    }
    widget.onZoomChanged(zoomed);
  }

  void _handleDoubleTap() {
    final position = _doubleTapDetails?.localPosition;
    final Matrix4 target;
    if (_isZoomed || position == null) {
      target = Matrix4.identity();
    } else {
      target = Matrix4.identity()
        ..translateByDouble(
          -position.dx * (_doubleTapScale - 1),
          -position.dy * (_doubleTapScale - 1),
          0,
          1,
        )
        ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1);
    }
    _zoomAnim = Matrix4Tween(begin: _transform.value, end: target).animate(
      CurvedAnimation(parent: _zoomController, curve: AppMotion.easeOutCubic),
    );
    _zoomController.forward(from: 0).whenCompleteOrCancel(_reportZoom);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: 4,
        panEnabled: _panEnabled,
        clipBehavior: Clip.none,
        onInteractionEnd: (_) => _reportZoom(),
        child: Center(
          child: FlatmatesNetworkImage(
            imageUrl: widget.imageUrl,
            width: double.infinity,
            fit: BoxFit.contain,
            heroTag: widget.heroTag,
            semanticLabel: widget.semanticLabel,
          ),
        ),
      ),
    );
  }
}

/// Fades gallery chrome (close button, counter) out while the user is
/// zoomed in or dragging to dismiss.
class _GalleryChrome extends StatelessWidget {
  const _GalleryChrome({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: AppMotion.fast,
      child: IgnorePointer(ignoring: !visible, child: child),
    );
  }
}

/// Frosted-glass pill backdrop matching the carousel's overlay buttons.
class _FrostedPill extends StatelessWidget {
  const _FrostedPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.pillBorder,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: AppRadius.pillBorder,
          ),
          child: child,
        ),
      ),
    );
  }
}
