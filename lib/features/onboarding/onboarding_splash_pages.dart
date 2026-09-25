import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
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

    // Inside the onboarding FlatmatesScreen, which owns the scaffold.
    return Material(
      type: MaterialType.transparency,
      child: Column(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.md,
            ),
            child: FlatmatesStepProgress.dots(
              currentStep: _page,
              totalSteps: pageCount,
              semanticsLabel: locale.onboardingStepOf(_page + 1, pageCount),
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
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FlatmatesButton.tertiary(
                            key: const Key('onboarding_skip'),
                            label: locale.onboardingSkip,
                            onPressed: widget.onComplete,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Flexible(
                        child: FlatmatesButton(
                          key: const Key('onboarding_next'),
                          label: locale.onboardingNext,
                          onPressed: () => _controller.nextPage(
                            duration: AppMotion.durationOrZero(
                              context,
                              AppMotion.slow,
                            ),
                            curve: AppMotion.paperOut,
                          ),
                          icon: Icons.arrow_forward_rounded,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
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

  /// Page scroll (small phones, large text) drives the scene parallax.
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.staggerTotal(3),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    final illustrationAnim = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.staggerInterval(index: 0, count: 3),
    );
    final headlineAnim = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.staggerInterval(index: 1, count: 3),
    );
    final subheadlineAnim = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.staggerInterval(index: 2, count: 3),
    );

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cut-paper scene: a prop on the hills, or the whole
              // neighbourhood on the last page.
              _StaggeredFadeSlide(
                animation: illustrationAnim,
                child: switch (widget.prop) {
                  final prop? => PaperScene.compact(prop: prop, height: 220),
                  null => ClipRRect(
                    borderRadius: AppRadius.cardBorder,
                    child: PaperScene.hero(height: 220, parallax: _scroll),
                  ),
                },
              ),
              const SizedBox(height: AppSpacing.screen + AppSpacing.lg),
              // Headline — Gambarino display
              _StaggeredFadeSlide(
                animation: headlineAnim,
                // `**` markers in the copy carry no style: emphasis is size
                // and colour, and the headline is one ink colour.
                child: Text(
                  widget.headline.replaceAll('**', ''),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Sub-headline — body font
              _StaggeredFadeSlide(
                animation: subheadlineAnim,
                child: Text(
                  widget.subheadline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(brightness),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
