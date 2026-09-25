import 'dart:math' as math show pi;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/components.dart';
import '../shared/presentation/paper/paper_scene.dart';

class MatchCelebrationScreen extends StatefulWidget {
  const MatchCelebrationScreen({
    required this.userName,
    required this.userImageUrl,
    required this.peerName,
    required this.peerImageUrl,
    required this.onOpenChat,
    required this.onKeepSwiping,
    super.key,
  });

  final String userName;
  final String? userImageUrl;
  final String peerName;
  final String? peerImageUrl;
  final VoidCallback onOpenChat;
  final VoidCallback onKeepSwiping;

  @override
  State<MatchCelebrationScreen> createState() => _MatchCelebrationScreenState();
}

class _MatchCelebrationScreenState extends State<MatchCelebrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.matchCelebration,
    );
    // Starts at 92 % scale, never 0: the match content is readable from the
    // first frame even if the animation never runs.
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.paperSettle),
    );
    _confettiController = ConfettiController(duration: AppMotion.confettiBurst);
  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
      return;
    }
    _controller.forward();
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    final brightness = theme.brightness;

    // Content scrolls (small phones, large text); confetti is painted last so
    // nothing covers it, from the top centre.
    return FlatmatesScreen(
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.lg * 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: const PaperScene.compact(
                        prop: PaperProp.heart,
                        height: 140,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Text(
                        locale.matchItsAMatch,
                        style: theme.textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      locale.matchLikedEachOther(widget.peerName),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppSemanticColors.textSecondaryFor(brightness),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.s40),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: FlatmatesAvatar(
                              name: widget.userName,
                              imageUrl: widget.userImageUrl,
                              size: 96,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Icon(
                            Icons.favorite_rounded,
                            size: 32,
                            color: AppSemanticColors.clayFor(brightness),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Flexible(
                            child: FlatmatesAvatar(
                              name: widget.peerName,
                              imageUrl: widget.peerImageUrl,
                              size: 96,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s56),
                    FlatmatesButton(
                      key: const Key('match_open_chat'),
                      label: locale.matchSendMessage,
                      onPressed: widget.onOpenChat,
                      fullWidth: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FlatmatesButton.secondary(
                      key: const Key('match_keep_swiping'),
                      label: locale.matchKeepSwiping,
                      onPressed: widget.onKeepSwiping,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              blastDirection: math.pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.3,
              colors: [
                AppSemanticColors.clayFor(brightness),
                AppSemanticColors.pineFor(brightness),
                AppSemanticColors.marigoldFor(brightness),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
