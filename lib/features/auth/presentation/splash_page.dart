import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../bootstrap/bootstrap_controller.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final logoAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: AppMotion.easeOutCubic),
    );
    final taglineAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.50, curve: AppMotion.easeOutCubic),
    );
    final subtaglineAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.60, curve: AppMotion.easeOutCubic),
    );
    final illustrationAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.80, curve: AppMotion.easeOutCubic),
    );
    final progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.95, curve: AppMotion.easeOutCubic),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.screen * 2),
              // Logo — fade + slide up
              _StaggeredFadeSlide(
                animation: logoAnimation,
                child: const FlatmatesLogo(centered: true),
              ),
              const SizedBox(height: AppSpacing.section),
              // Tagline — Display 32sp Fraunces Regular (not bold)
              _StaggeredFadeSlide(
                animation: taglineAnimation,
                child: Text(
                  locale.splashTagline,
                  textAlign: TextAlign.center,
                  style:
                      GoogleFonts.fraunces(
                        fontWeight: AppTypography.displayWeight,
                        fontSize: AppTypography.displaySize,
                        height: AppTypography.displayHeight,
                        letterSpacing: AppTypography.displayLetterSpacing,
                        color: AppSemanticColors.textPrimaryFor(
                          theme.brightness,
                        ),
                      ).copyWith(
                        fontVariations: const [
                          FontVariation('opsz', 144),
                          FontVariation('SOFT', 50),
                          FontVariation('WONK', 0),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Sub-tagline — Body Large Inter
              _StaggeredFadeSlide(
                animation: subtaglineAnimation,
                child: Text(
                  locale.splashSubtagline,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: AppTypography.bodyMediumWeight,
                    fontSize: 15,
                    height: 1.5,
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height < 560
                    ? AppSpacing.lg
                    : AppSpacing.section,
              ),
              // Illustration — fade in
              _StaggeredFadeSlide(
                animation: illustrationAnimation,
                child: Image.asset(
                  'assets/illustrations/splash_living_room.png',
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width * 0.8,
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height < 560
                    ? AppSpacing.md
                    : AppSpacing.section,
              ),
              // Progress / error area
              _StaggeredFadeSlide(
                animation: progressAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: bootstrap.when(
                    data: (_) => const _SplashProgress(),
                    loading: () => const _SplashProgress(),
                    error: (error, _) {
                      final message = error is AppFailure
                          ? error.userMessage(
                              UserMessageL10n(
                                errorNetwork: locale.errorNetwork,
                                errorAuthExpired: locale.errorAuthExpired,
                                errorServer: locale.errorServer,
                                errorPermission: locale.errorPermission,
                                errorNotFound: locale.errorNotFound,
                                errorValidation: locale.errorValidation,
                                errorRateLimit: locale.errorRateLimit,
                                errorConflict: locale.errorConflict,
                                errorUpload: locale.errorUpload,
                                errorUnknown: locale.errorUnknown,
                              ),
                            )
                          : locale.errorUnknown;
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.screen + AppSpacing.lg,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppSemanticColors.error,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            FlatmatesButton(
                              label: locale.commonRetry,
                              onPressed: () => ref
                                  .read(bootstrapControllerProvider.notifier)
                                  .load(),
                            ),
                          ],
                        ),
                      );
                    },
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

/// Staggered fade-in + slide-up for splash elements.
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
            offset: Offset(0, 12 * (1 - animation.value)),
            child: child,
          );
        },
        child: child,
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
        width: MediaQuery.of(context).size.width * 0.6,
        child: LinearProgressIndicator(
          minHeight: 4,
          borderRadius: BorderRadius.circular(999),
          backgroundColor: AppSemanticColors.disabledSurfaceFor(
            Theme.of(context).brightness,
          ),
          valueColor: AlwaysStoppedAnimation<Color>(AppSemanticColors.accent),
        ),
      ),
    );
  }
}
