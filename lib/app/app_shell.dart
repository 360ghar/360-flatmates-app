import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_semantic_colors.dart';
import '../l10n/gen/app_localizations.dart';
import '../features/bootstrap/bootstrap_controller.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final mode = bootstrap?.profile.mode ?? 'co_hunter';
    final isDark = theme.brightness == Brightness.dark;

    // Build destination list based on user mode (PRD section 4.1)
    final destinations = _buildDestinations(mode, locale, theme);

    final navBarBg = isDark
        ? AppSemanticColors.secondarySurfaceFor(theme.brightness)
        : AppSemanticColors.surfaceFor(theme.brightness);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        height: 76,
        selectedIndex: _mapToVisibleIndex(
          navigationShell.currentIndex,
          mode,
        ),
        onDestinationSelected: (index) {
          final branchIndex = _mapToBranchIndex(index, mode);
          navigationShell.goBranch(branchIndex);
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: navBarBg.withValues(alpha: 0.95),
        destinations: destinations,
      ),
    );
  }

  List<NavigationDestination> _buildDestinations(
    String mode,
    AppLocalizations locale,
    ThemeData theme,
  ) {
    final isRoomPoster = mode.trim().toLowerCase() == 'room_poster';

    return [
      NavigationDestination(
        icon: _navIcon('nav_home_tab', Icons.home_outlined),
        selectedIcon: _navIcon('nav_home_tab_selected', Icons.home_rounded),
        label: locale.navHome,
      ),

      if (isRoomPoster)
        NavigationDestination(
          icon: _navIcon('nav_post_tab', Icons.add_home_outlined),
          selectedIcon: _navIcon(
            'nav_post_tab_selected',
            Icons.add_home_rounded,
          ),
          label: locale.navPost,
        )
      else
        NavigationDestination(
          icon: _navIcon('nav_explore_tab', Icons.map_outlined),
          selectedIcon: _navIcon('nav_explore_tab_selected', Icons.map_rounded),
          label: locale.navExplore,
        ),

      NavigationDestination(
        icon: _navIcon('nav_swipe_tab', Icons.swap_horiz_rounded),
        selectedIcon: _navIcon(
          'nav_swipe_tab_selected',
          Icons.swap_horiz_rounded,
        ),
        label: locale.navSwipe,
      ),

      NavigationDestination(
        icon: _navIcon('nav_likes_chat_tab', Icons.favorite_border_rounded),
        selectedIcon: _navIcon(
          'nav_likes_chat_tab_selected',
          Icons.favorite_rounded,
        ),
        label: locale.navLikesChat,
      ),

      NavigationDestination(
        icon: _navIcon('nav_profile_tab', Icons.person_outline),
        selectedIcon: _navIcon(
          'nav_profile_tab_selected',
          Icons.person_rounded,
        ),
        label: locale.navProfile,
      ),
    ];
  }

  Widget _navIcon(String identifier, IconData icon) {
    return Semantics(
      identifier: identifier,
      child: Icon(icon, key: ValueKey(identifier)),
    );
  }

  int _mapToBranchIndex(int visibleIndex, String mode) {
    if (visibleIndex < 0 || visibleIndex > 4) return 0;
    return visibleIndex;
  }

  int _mapToVisibleIndex(int branchIndex, String mode) {
    if (branchIndex < 0 || branchIndex > 4) return 0;
    return branchIndex;
  }
}
