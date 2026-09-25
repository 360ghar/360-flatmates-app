import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../bootstrap/bootstrap_controller.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../shared/presentation/components.dart';
import '../../shared/presentation/paper/paper_edge_border.dart';
import '../../shared/presentation/paper/paper_scene.dart';
import '../../shared/presentation/paper/paper_surface.dart';
import '../auth_controller.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Bootstrap-recovery guards (ephemeral, page-local).
  bool _recoveryQueued = false;
  bool _recoveryAttempted = false;

  /// Entrance layers, back to front: scene, logo, tagline, subtagline,
  /// progress strip.
  static const _layers = 5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.staggerTotal(_layers),
    );
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _queueBootstrapRecoveryIfNeeded(
        ref.read(authControllerProvider),
        ref.read(bootstrapControllerProvider),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final bootstrapRecoveryAttempted = _recoveryAttempted;

    ref.listen<AuthState>(authControllerProvider, (_, next) {
      _queueBootstrapRecoveryIfNeeded(
        next,
        ref.read(bootstrapControllerProvider),
      );
    });
    ref.listen<AsyncValue<BootstrapData?>>(bootstrapControllerProvider, (
      _,
      next,
    ) {
      _queueBootstrapRecoveryIfNeeded(ref.read(authControllerProvider), next);
    });

    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final logoAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.staggerInterval(index: 1, count: _layers),
    );
    final taglineAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.staggerInterval(index: 2, count: _layers),
    );
    final subtaglineAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.staggerInterval(index: 3, count: _layers),
    );
    final illustrationAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.staggerInterval(index: 0, count: _layers),
    );
    final progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.staggerInterval(index: 4, count: _layers),
    );

    final status = bootstrap.when(
      data: (data) {
        if (auth.isLoggedIn && data == null && bootstrapRecoveryAttempted) {
          return _SplashRetry(
            message: locale.errorUnknown,
            onPressed: _retryBootstrap,
          );
        }
        return const _SplashProgress();
      },
      loading: () => const _SplashProgress(),
      error: (error, _) {
        final message = error is AppFailure
            ? error.userMessage(locale.toUserMessageL10n())
            : locale.errorUnknown;
        return _SplashRetry(message: message, onPressed: _retryBootstrap);
      },
    );

    // Composition: brand and tagline in the sky, the cut-paper
    // neighbourhood across the lower screen, and a torn paper strip at the
    // bottom that carries progress (or Retry).
    return FlatmatesScreen(
      useSafeArea: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sceneHeight = (constraints.maxHeight * 0.36).clamp(
            180.0,
            340.0,
          );
          return Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screen + AppSpacing.sm,
                        vertical: AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          _StaggeredFadeSlide(
                            animation: logoAnimation,
                            child: const FlatmatesLogo(centered: true),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _StaggeredFadeSlide(
                            animation: taglineAnimation,
                            child: Text(
                              '${locale.splashTaglineLine1}\n'
                              '${locale.splashTaglineLine2}',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.displayMedium,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _StaggeredFadeSlide(
                            animation: subtaglineAnimation,
                            child: Text(
                              locale.splashSubtagline,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppSemanticColors.textSecondaryFor(
                                  theme.brightness,
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
              _StaggeredFadeSlide(
                animation: illustrationAnimation,
                child: PaperScene.hero(height: sceneHeight),
              ),
              // The strip overlaps the scene's ground by its torn edge.
              Transform.translate(
                offset: const Offset(0, -10),
                child: PaperSurface(
                  layer: PaperLayer.one,
                  elevation: PaperElevation.e0,
                  edge: PaperEdge.torn,
                  borderRadius: BorderRadius.zero,
                  padding: const EdgeInsets.only(
                    top: AppSpacing.base,
                    bottom: AppSpacing.lg,
                  ),
                  child: SafeArea(
                    top: false,
                    child: _StaggeredFadeSlide(
                      animation: progressAnimation,
                      child: status,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _queueBootstrapRecoveryIfNeeded(
    AuthState auth,
    AsyncValue<BootstrapData?> bootstrap,
  ) {
    // Called from ref.listen and post-frame callbacks, never during build,
    // so setState is safe here.
    if (!auth.isLoggedIn || bootstrap.valueOrNull != null) {
      _recoveryQueued = false;
      if (_recoveryAttempted) setState(() => _recoveryAttempted = false);
      return;
    }
    if (bootstrap.isLoading || _recoveryAttempted || _recoveryQueued) {
      return;
    }

    _recoveryQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _recoveryQueued = false;

      final latestAuth = ref.read(authControllerProvider);
      final latestBootstrap = ref.read(bootstrapControllerProvider);
      if (!latestAuth.isLoggedIn ||
          latestBootstrap.isLoading ||
          latestBootstrap.valueOrNull != null) {
        return;
      }

      setState(() => _recoveryAttempted = true);
      unawaited(
        ref.read(bootstrapControllerProvider.notifier).refresh().catchError((
          Object error,
          StackTrace stackTrace,
        ) {
          debugPrint('SplashPage.bootstrap recovery failed: $error');
        }),
      );
    });
  }

  void _retryBootstrap() {
    unawaited(ref.read(bootstrapControllerProvider.notifier).refresh());
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

class _SplashRetry extends StatelessWidget {
  const _SplashRetry({required this.message, required this.onPressed});

  final String message;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppSemanticColors.dangerFor(theme.brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FlatmatesButton(
            key: const Key('splash_retry_button'),
            label: locale.commonRetry,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _SplashProgress extends StatelessWidget {
  const _SplashProgress();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.6,
        child: LinearProgressIndicator(
          semanticsLabel: AppLocalizations.of(context).loadingLabel,
          minHeight: 4,
          borderRadius: AppRadius.pillBorder,
          backgroundColor: AppSemanticColors.disabledSurfaceFor(
            Theme.of(context).brightness,
          ),
          valueColor: AlwaysStoppedAnimation<Color>(
            AppSemanticColors.clayFor(Theme.of(context).brightness),
          ),
        ),
      ),
    );
  }
}
