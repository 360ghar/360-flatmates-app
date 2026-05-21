import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_radius.dart';
import '../core/theme/app_semantic_colors.dart';
import '../features/bootstrap/bootstrap_controller.dart';
import '../l10n/gen/app_localizations.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Use select so AppShell only rebuilds when mode changes,
    // not on every bootstrap async lifecycle event.
    final mode =
        ref.watch(
          bootstrapControllerProvider.select(
            (v) => v.valueOrNull?.profile.mode,
          ),
        ) ??
        'co_hunter';
    final isDark = theme.brightness == Brightness.dark;

    final destinations = _buildDestinations(mode, locale);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppSemanticColors.frostBlur,
            sigmaY: AppSemanticColors.frostBlur,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppSemanticColors.frostOverlayDark
                  : AppSemanticColors.frostOverlayLight,
              border: Border(
                top: BorderSide(
                  color: AppSemanticColors.line.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: NavigationBar(
                height: 76,
                selectedIndex: _mapToVisibleIndex(
                  navigationShell.currentIndex,
                  mode,
                ),
                onDestinationSelected: (index) {
                  final branchIndex = _mapToBranchIndex(index, mode);
                  navigationShell.goBranch(
                    branchIndex,
                    initialLocation:
                        branchIndex == navigationShell.currentIndex,
                  );
                },
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                backgroundColor: Colors.transparent,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                indicatorColor: AppSemanticColors.accent.withValues(
                  alpha: 0.14,
                ),
                indicatorShape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.smBorder,
                ),
                // Tighten icon→label gap so the cluster looks centered
                // in the 76 px bar instead of floating with an invisible
                // 8 px dead-zone (4 px Stack slack + 4 px default padding).
                labelPadding: EdgeInsets.zero,
                destinations: destinations,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<NavigationDestination> _buildDestinations(
    String mode,
    AppLocalizations locale,
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
        icon: _navIcon('nav_inbox_tab', Icons.markunread_outlined),
        selectedIcon: _navIcon(
          'nav_inbox_tab_selected',
          Icons.markunread_rounded,
        ),
        label: locale.navLikesChat,
      ),
      NavigationDestination(
        icon: _navIcon('nav_me_tab', Icons.person_outline),
        selectedIcon: _navIcon('nav_me_tab_selected', Icons.person_rounded),
        label: locale.navProfile,
      ),
    ];
  }

  /// CRITICAL FIX: Removed ValueKey recreation that reset animation state.
  /// Semantics.identifier is sufficient for Maestro testing.
  Widget _navIcon(String identifier, IconData icon) {
    return Semantics(identifier: identifier, child: Icon(icon));
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
