import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../core/theme/app_radius.dart';
import '../shared/presentation/components.dart';
import '../shared/presentation/paper/paper_scene.dart';

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

  /// Scene prop per page; the last page shows the full neighbourhood.
  static const _pageProps = <PaperProp?>[
    PaperProp.house,
    PaperProp.heart,
    PaperProp.chat,
    null,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final pageCount = _pageProps.length;
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
                prop: _pageProps[index],
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
          duration: AppMotion.durationOrZero(context, AppMotion.standard),
          curve: AppMotion.paperOut,
          margin: EdgeInsets.only(
            right: index < totalSteps - 1 ? AppSpacing.md : 0,
          ),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? AppSemanticColors.clayFor(Theme.of(context).brightness)
                : AppSemanticColors.paperDeepFor(Theme.of(context).brightness),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

/// Per-page content with staggered entry animation.
class _OnboardingContent extends StatefulWidget {
  const _OnboardingContent({
    required this.prop,
    required this.headline,
    required this.subheadline,
    super.key,
  });

  final PaperProp? prop;
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
          // Cut-paper scene: a prop on the hills, or the whole
          // neighbourhood on the last page.
          _StaggeredFadeSlide(
            animation: illustrationAnim,
            child: switch (widget.prop) {
              final prop? => PaperScene.compact(prop: prop, height: 220),
              null => const ClipRRect(
                borderRadius: AppRadius.cardBorder,
                child: PaperScene.hero(height: 220),
              ),
            },
          ),
          const SizedBox(height: AppSpacing.screen + AppSpacing.lg),
          // Headline — Gambarino display
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
              style: TextStyle(
                fontWeight: AppTypography.bodySmWeight,
                fontSize: AppTypography.bodySmSize,
                height: AppTypography.bodySmHeight,
                color: AppSemanticColors.textSecondaryFor(brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Splits headline by **bold** markers.
  /// Base text: Inter display-xl. Emphasized text: Inter medium italic.
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
              ? TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: AppTypography.displayXlSize,
                  height: AppTypography.displayXlHeight,
                  color: textColor,
                )
              : TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontWeight: AppTypography.displayXlWeight,
                  fontSize: AppTypography.displayXlSize,
                  height: AppTypography.displayXlHeight,
                  letterSpacing: AppTypography.displayXlLetterSpacing,
                  color: textColor,
                ),
        ),
      );
    }
    // If no ** markers found, render entire text as Inter display
    if (spans.isEmpty) {
      spans.add(
        TextSpan(
          text: raw,
          style: TextStyle(
            fontFamily: AppTypography.displayFamily,
            fontWeight: AppTypography.displayXlWeight,
            fontSize: AppTypography.displayXlSize,
            height: AppTypography.displayXlHeight,
            letterSpacing: AppTypography.displayXlLetterSpacing,
            color: textColor,
          ),
        ),
      );
    }
    return spans;
  }
}

/// Staggered rise for entry elements. Opacity stays at 1: the content is
/// visible from the first frame even if the animation never runs.
class _StaggeredFadeSlide extends StatelessWidget {
  const _StaggeredFadeSlide({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return child;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, AppMotion.layerRise * (1 - animation.value)),
        child: child,
      ),
      child: child,
    );
  }
}
