import 'dart:math' as math show pi;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';

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
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
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

    return Scaffold(
      body: Stack(
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            blastDirection: math.pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.3,
            colors: const [
              AppSemanticColors.accent,
              AppSemanticColors.success,
              AppSemanticColors.warning,
            ],
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppSemanticColors.accent.withValues(alpha: 0.12),
                  AppSemanticColors.surfaceFor(theme.brightness),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: const Text(
                      '🎉',
                      style: TextStyle(fontSize: 64),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Text(
                      locale.matchItsAMatch,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 36,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    locale.matchLikedEachOther(widget.peerName),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl + AppSpacing.md),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FlatmatesAvatar(
                          name: widget.userName,
                          imageUrl: widget.userImageUrl,
                          size: 100,
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppSemanticColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        FlatmatesAvatar(
                          name: widget.peerName,
                          imageUrl: widget.peerImageUrl,
                          size: 100,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section + AppSpacing.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen + AppSpacing.md,
                    ),
                    child: Column(
                      children: [
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
