import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'flatmates_card.dart';

class FlatmatesVideoTourPlayer extends StatefulWidget {
  const FlatmatesVideoTourPlayer({
    required this.videoUrl,
    this.title,
    super.key,
  });

  final String videoUrl;
  final String? title;

  @override
  State<FlatmatesVideoTourPlayer> createState() =>
      _FlatmatesVideoTourPlayerState();
}

class _FlatmatesVideoTourPlayerState extends State<FlatmatesVideoTourPlayer> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _muted = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0);
      await _controller.play();
      if (mounted) setState(() => _ready = true);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    final nextMuted = !_muted;
    await _controller.setVolume(nextMuted ? 0 : 1);
    if (!_controller.value.isPlaying) {
      await _controller.play();
    }
    if (mounted) setState(() => _muted = nextMuted);
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return FlatmatesCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title ?? locale.videoTourLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.mdBorder,
            child: Material(
              color: AppSemanticColors.secondarySurfaceFor(theme.brightness),
              child: InkWell(
                onTap: _ready ? _toggleAudio : null,
                child: AspectRatio(
                  aspectRatio: _ready && _controller.value.aspectRatio > 0
                      ? _controller.value.aspectRatio
                      : 9 / 16,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_ready)
                        VideoPlayer(_controller)
                      else
                        Center(
                          child: _error == null
                              ? const CircularProgressIndicator()
                              : Icon(
                                  Icons.videocam_off_outlined,
                                  color: AppSemanticColors.textTertiaryFor(
                                    theme.brightness,
                                  ),
                                ),
                        ),
                      if (_ready)
                        Positioned(
                          right: AppSpacing.sm,
                          bottom: AppSpacing.sm,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppSemanticColors.ink.withValues(
                                alpha: 0.55,
                              ),
                              borderRadius: AppRadius.pillBorder,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _muted
                                        ? Icons.volume_off_rounded
                                        : Icons.volume_up_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    _muted
                                        ? locale.tapToUnmute
                                        : locale.soundOn,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
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
