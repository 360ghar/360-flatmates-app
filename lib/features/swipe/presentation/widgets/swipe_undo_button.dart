import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';

/// Frosted-glass undo button shown briefly after a swipe.
class SwipeUndoButton extends StatelessWidget {
  const SwipeUndoButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Undo',
      child: Listener(
        onPointerDown: (_) => onPressed(),
        child: ClipRRect(
          borderRadius: AppRadius.mdBorder,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: AppRadius.mdBorder,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: const Icon(
                Icons.undo_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
