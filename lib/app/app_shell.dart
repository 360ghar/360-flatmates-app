import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/domain/enums.dart';
import '../core/providers.dart';
import '../core/storage/app_preferences.dart';
import '../core/theme/app_motion.dart';
import '../features/auth/auth_controller.dart';
import '../features/bootstrap/bootstrap_controller.dart';
import '../features/onboarding/onboarding_completion_banner.dart';
import '../features/shared/presentation/paper/paper_art.dart';
import '../features/shared/presentation/paper/paper_edge_border.dart';
import '../features/shared/presentation/paper/paper_icon.dart';
import '../features/shared/presentation/paper/paper_surface.dart';
import '../l10n/gen/app_localizations.dart';

/// Canonical room-poster check for the backend `profile.mode` string.
///
/// The bottom-nav label ([AppShell]), the `/tab2` body (`ModeTab2Switcher`) and
/// the onboarding soft gate all resolve the mode through [UserMode.fromApi], so
/// they can never disagree about what tab 2 is.
bool isRoomPosterMode(String? mode) =>
    mode != null && UserMode.fromApi(mode) == UserMode.roomPoster;

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    // Use select so AppShell only rebuilds when mode changes,
    // not on every bootstrap async lifecycle event.
    final mode =
        ref.watch(
          bootstrapControllerProvider.select(
            (v) => v.valueOrNull?.profile.mode,
          ),
        ) ??
        'co_hunter';

    // Show the onboarding completion banner when the user's onboarding is
    // incomplete. The soft gate allows access to Discover, Map, and Profile,
    // so the banner reminds them to finish setup.
    final authStage = ref.watch(
      authControllerProvider.select((s) => s.authStage),
    );
    final profileId = ref.watch(
      bootstrapControllerProvider.select((v) => v.valueOrNull?.profile.id),
    );
    final prefs = ref.watch(appPreferencesProvider);
    final completedUserId = prefs.getString(
      PrefKeys.flatmatesOnboardingCompletedUserId,
    );
    final hasCompletedOnboardingLocally =
        completedUserId == profileId?.toString();
    final showOnboardingBanner =
        authStage == AuthStage.appOnboarding && !hasCompletedOnboardingLocally;

    final destinations = _buildDestinations(mode, locale);

    return Scaffold(
      body: Column(
        children: [
          if (showOnboardingBanner) const OnboardingCompletionBanner(),
          // The banner takes the status-bar inset, so the page must not add
          // it again.
          // Builder: the context must be inside the Scaffold body, whose
          // MediaQuery has the keyboard inset removed. The shell's own
          // context would put the inset back, and every page Scaffold would
          // resize for the keyboard a second time.
          Expanded(
            child: Builder(
              builder: (context) => MediaQuery.removePadding(
                context: context,
                removeTop: showOnboardingBanner,
                child: navigationShell,
              ),
            ),
          ),
        ],
      ),
      // Paper tab strip: layer one with a torn top edge; the active tab
      // rises one layer (indicator = paper-2, see navigationBarTheme).
      bottomNavigationBar: PaperSurface(
        layer: PaperLayer.one,
        elevation: PaperElevation.e0,
        edge: PaperEdge.torn,
        borderRadius: BorderRadius.zero,
        child: SafeArea(
          top: false,
          // Labels scale with the user's text size, but capped so five tabs
          // still fit on one row without clipping.
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex.clamp(0, 4),
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              // The indicator slides with the standard paper curve, and not
              // at all under reduce motion (Material's default is 500 ms).
              animationDuration: AppMotion.durationOrZero(
                context,
                AppMotion.standard,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              destinations: destinations,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDestinations(String mode, AppLocalizations locale) {
    final isRoomPoster = isRoomPosterMode(mode);

    // Cut-paper nav icons shared with the web app. Selected vs unselected
    // is colour only (clay vs ink-3, from navigationBarTheme).
    return [
      _tab(
        'nav_home_tab',
        NavigationDestination(
          key: const ValueKey('nav_home'),
          icon: const PaperIcon(PaperArt.navHome),
          label: locale.navHome,
        ),
      ),
      // Slot is shape-stable across modes: the same `NavigationDestination`
      // instance (keyed by `nav_mode`) is always present, only the icon
      // and label change. This stops the destination list from changing
      // shape when the user switches mode, which previously caused the
      // inner semantics widgets to be unmounted+remounted in the same frame
      // as `/tab2`'s body swap — triggering `!semantics.parentDataDirty`.
      // Only the identifier string changes with the mode.
      _tab(
        isRoomPoster ? 'nav_post_tab' : 'nav_explore_tab',
        NavigationDestination(
          key: const ValueKey('nav_mode'),
          icon: isRoomPoster
              ? const PaperIcon(PaperArt.navPost)
              : const PaperIcon(PaperArt.navExplore),
          label: isRoomPoster ? locale.navPost : locale.navExplore,
        ),
      ),
      _tab(
        'nav_swipe_tab',
        NavigationDestination(
          key: const ValueKey('nav_swipe'),
          icon: const PaperIcon(PaperArt.navSwipe),
          label: locale.navSwipe,
        ),
      ),
      _tab(
        'nav_inbox_tab',
        NavigationDestination(
          key: const ValueKey('nav_inbox'),
          icon: const PaperIcon(PaperArt.navChats),
          label: locale.navLikesChat,
        ),
      ),
      _tab(
        'nav_me_tab',
        NavigationDestination(
          key: const ValueKey('nav_me'),
          icon: const PaperIcon(PaperArt.navProfile),
          label: locale.navProfile,
        ),
      ),
    ];
  }

  /// Maestro id on the whole destination. Material merges a destination's
  /// semantics into one node, which drops an identifier set on the icon.
  Widget _tab(String identifier, NavigationDestination destination) =>
      Semantics(identifier: identifier, container: true, child: destination);
}
