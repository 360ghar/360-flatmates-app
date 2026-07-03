import 'package:flutter/widgets.dart';

class SwipeInteractionState {
  const SwipeInteractionState({
    this.dragOffset = Offset.zero,
    this.isDragging = false,
    this.isAnimating = false,
  });

  final Offset dragOffset;
  final bool isDragging;
  final bool isAnimating;

  bool get isBusy => isDragging || isAnimating;

  SwipeInteractionState copyWith({
    Offset? dragOffset,
    bool? isDragging,
    bool? isAnimating,
  }) {
    return SwipeInteractionState(
      dragOffset: dragOffset ?? this.dragOffset,
      isDragging: isDragging ?? this.isDragging,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }
}
