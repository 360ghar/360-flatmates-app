import 'package:flutter/material.dart';

import '../../../shared/presentation/flatmates_network_image.dart';

class FullScreenGallery extends StatefulWidget {
  const FullScreenGallery({
    required this.images,
    required this.initialIndex,
    super.key,
  });

  final List<String> images;
  final int initialIndex;

  static Future<void> open({
    required BuildContext context,
    required List<String> images,
    int initialIndex = 0,
  }) {
    if (images.isEmpty) return Future.value();
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenGallery(images: images, initialIndex: initialIndex),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;
  double _dragOffset = 0;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(
        alpha: _dismissing ? (1 - (_dragOffset / 300).clamp(0, 1)) : 1,
      ),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (_dismissing) return;
          setState(() => _dragOffset += details.delta.dy);
          if (_dragOffset > 150) {
            setState(() => _dismissing = true);
            Navigator.of(context).pop();
          }
        },
        onVerticalDragEnd: (details) {
          if (!_dismissing) {
            setState(() => _dragOffset = 0);
          }
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: FlatmatesNetworkImage(
                    imageUrl: widget.images[index],
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 4,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),

            // Counter
            if (widget.images.length > 1)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
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
          ],
        ),
      ),
    );
  }
}
