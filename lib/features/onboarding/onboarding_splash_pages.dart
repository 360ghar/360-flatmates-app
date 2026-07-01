import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/components.dart';

class OnboardingSplashPages extends ConsumerStatefulWidget {
  const OnboardingSplashPages({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  ConsumerState<OnboardingSplashPages> createState() =>
      _OnboardingSplashPagesState();
}

class _OnboardingSplashPagesState extends ConsumerState<OnboardingSplashPages> {
  final _controller = PageController();
  int _page = 0;

  static const _illustrationAssets = [
    'assets/illustrations/onboarding_find_flat.png',
    'assets/illustrations/onboarding_lifestyle_match.png',
    'assets/illustrations/onboarding_flatmate_match.png',
    'assets/illustrations/onboarding_get_started.png',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final pageCount = _illustrationAssets.length;
    final isLast = _page == pageCount - 1;

    return FlatmatesScreen(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: pageCount,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) => _OnboardingContent(
                key: ValueKey('onboarding_page_$index'),
                illustrationAsset: _illustrationAssets[index],
                headline: switch (index) {
                  0 => locale.onboardingHeadline1,
                  1 => locale.onboardingHeadline2,
                  2 => locale.onboardingHeadline3,
                  _ => locale.onboardingHeadline4,
                },
                subheadline: switch (index) {
                  0 => locale.onboardingSubheadline1,
                  1 => locale.onboardingSubheadline2,
                  2 => locale.onboardingSubheadline3,
                  _ => locale.onboardingSubheadline4,
                },
              ),
            ),
          ),
          // --- Step progress dots (outline circles, active filled) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.md,
            ),
            child: _OutlineDotsProgress(
              currentStep: _page,
              totalSteps: pageCount,
            ),
          ),
          // --- Action buttons ---
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              0,
              AppSpacing.screen,
              AppSpacing.screen + AppSpacing.lg,
            ),
            child: isLast
                ? FlatmatesButton(
                    key: const Key('onboarding_get_started'),
                    label: locale.onboardingGetStarted,
                    onPressed: widget.onComplete,
                    icon: Icons.arrow_forward_rounded,
                    fullWidth: true,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FlatmatesButton.tertiary(
                        key: const Key('onboarding_skip'),
                        label: locale.onboardingSkip,
                        onPressed: widget.onComplete,
                      ),
                      FlatmatesButton(
                        key: const Key('onboarding_next'),
                        label: locale.onboardingNext,
                        onPressed: () => _controller.nextPage(
                          duration: AppMotion.pageTransition,
                          curve: AppMotion.easeOutCubic,
                        ),
                        icon: Icons.arrow_forward_rounded,
                        height: 44,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Outline-circle dot progress matching Screen 02 spec:
/// "4 dots, outline style, active = filled terracotta circle, centered above buttons."
class _OutlineDotsProgress extends StatelessWidget {
  const _OutlineDotsProgress({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;

        return AnimatedContainer(
          duration: AppMotion.standard,
          curve: AppMotion.easeOutCubic,
          margin: EdgeInsets.only(
            right: index < totalSteps - 1 ? AppSpacing.md : 0,
          ),
          width: 10,
          height: 10,
          decoration: isActive || isCompleted
              ? const BoxDecoration(
                  color: AppSemanticColors.accent,
                  shape: BoxShape.circle,
                )
              : BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppSemanticColors.accent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
        );
      }),
    );
  }
}

/// Per-page content with staggered entry animation.
class _OnboardingContent extends StatefulWidget {
  const _OnboardingContent({
    required this.illustrationAsset,
    required this.headline,
    required this.subheadline,
    super.key,
  });

  final String illustrationAsset;
  final String headline;
  final String subheadline;

  @override
  State<_OnboardingContent> createState() => _OnboardingContentState();
}

class _OnboardingContentState extends State<_OnboardingContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    final illustrationAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.40, curve: AppMotion.easeOutCubic),
    );
    final headlineAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.55, curve: AppMotion.easeOutCubic),
    );
    final subheadlineAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.65, curve: AppMotion.easeOutCubic),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen + AppSpacing.lg,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration — no card wrapper, just the image
          _StaggeredFadeSlide(
            animation: illustrationAnim,
            child: Image.asset(
              widget.illustrationAsset,
              fit: BoxFit.contain,
              height: 260,
            ),
          ),
          const SizedBox(height: AppSpacing.screen + AppSpacing.lg),
          // Headline — Fraunces Regular + Instrument Serif italic for emphasis
          _StaggeredFadeSlide(
            animation: headlineAnim,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: _buildStyledHeadline(widget.headline, brightness),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Sub-headline — Inter Body Medium
          _StaggeredFadeSlide(
            animation: subheadlineAnim,
            child: Text(
              widget.subheadline,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontWeight: AppTypography.bodyMediumWeight,
                fontSize: AppTypography.bodyMediumSize,
                height: AppTypography.bodyMediumHeight,
                color: AppSemanticColors.textSecondaryFor(brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Splits headline by **bold** markers.
  /// Base text: Fraunces Regular (w400), editorial weight.
  /// Emphasized text: Instrument Serif italic.
  List<InlineSpan> _buildStyledHeadline(String raw, Brightness brightness) {
    final parts = raw.split(RegExp(r'\*\*'));
    final spans = <InlineSpan>[];
    final textColor = AppSemanticColors.textPrimaryFor(brightness);

    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final isEmphasis = i.isOdd;

      spans.add(
        TextSpan(
          text: parts[i],
          style: isEmphasis
              ? GoogleFonts.instrumentSerif(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  fontSize: AppTypography.h1Size,
                  height: AppTypography.h1Height,
                  color: textColor,
                )
              : GoogleFonts.fraunces(
                  fontWeight: AppTypography.h1Weight,
                  fontSize: AppTypography.h1Size,
                  height: AppTypography.h1Height,
                  letterSpacing: AppTypography.h1LetterSpacing,
                  color: textColor,
                ).copyWith(
                  fontVariations: const [
                    FontVariation('opsz', 112),
                    FontVariation('SOFT', 40),
                    FontVariation('WONK', 0),
                  ],
                ),
        ),
      );
    }
    // If no ** markers found, render entire text as Fraunces Regular
    if (spans.isEmpty) {
      spans.add(
        TextSpan(
          text: raw,
          style:
              GoogleFonts.fraunces(
                fontWeight: AppTypography.h1Weight,
                fontSize: AppTypography.h1Size,
                height: AppTypography.h1Height,
                letterSpacing: AppTypography.h1LetterSpacing,
                color: textColor,
              ).copyWith(
                fontVariations: const [
                  FontVariation('opsz', 112),
                  FontVariation('SOFT', 40),
                  FontVariation('WONK', 0),
                ],
              ),
        ),
      );
    }
    return spans;
  }
}

/// Staggered fade-in + slide-up for onboarding page elements.
class _StaggeredFadeSlide extends StatelessWidget {
  const _StaggeredFadeSlide({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 14 * (1 - animation.value)),
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}
