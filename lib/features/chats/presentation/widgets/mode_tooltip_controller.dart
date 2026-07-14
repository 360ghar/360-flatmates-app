import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import 'mode_tooltip_bubble.dart';

/// Manages the floating peer-mode tooltip anchored under the chat app-bar avatar.
class ModeTooltipController {
  ModeTooltipController({required this.avatarLink});

  final LayerLink avatarLink;

  OverlayEntry? _entry;
  Timer? _timer;
  bool dismissed = false;

  void schedule({
    required bool Function() isMounted,
    required String Function() peerModeLabel,
    required BuildContext Function() context,
  }) {
    unawaited(
      Future.delayed(AppMotion.modeTooltipShowDelay, () {
        if (!isMounted() || dismissed || _entry != null) return;
        final label = peerModeLabel();
        if (label.isEmpty) return;
        _insert(label, context());
      }),
    );
  }

  void _insert(String label, BuildContext context) {
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (context) => Positioned(
        // top/left only so the bubble sizes to content (not full screen).
        top: 0,
        left: 0,
        child: CompositedTransformFollower(
          link: avatarLink,
          targetAnchor: Alignment.bottomLeft,
          offset: const Offset(0, 8),
          child: ModeTooltipBubble(label: label, onTapKeepOpen: keepOpen),
        ),
      ),
    );
    overlay.insert(_entry!);
    _timer = Timer(AppMotion.modeTooltipAutoDismiss, remove);
  }

  void keepOpen() => _timer?.cancel();

  void remove() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
    dismissed = true;
  }

  void resetForConversationChange() {
    remove();
    dismissed = false;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
    dismissed = true;
  }
}
