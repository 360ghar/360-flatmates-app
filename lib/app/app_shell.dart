import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final surface = isDark
        ? AppSemanticColors.darkSurface
        : AppSemanticColors.canvas;
    final hairline = AppSemanticColors.hairlineFor(theme.brightness);

    final destinations = _buildDestinations(mode, locale);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border(top: BorderSide(color: hairline)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 64,
            selectedIndex: navigationShell.currentIndex.clamp(0, 4),
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            backgroundColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: Colors.transparent,
            labelPadding: EdgeInsets.zero,
            destinations: destinations,
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
        key: const ValueKey('nav_home'),
        icon: _navIcon('nav_home_tab', Icons.home_outlined),
        selectedIcon: _navIcon('nav_home_tab_selected', Icons.home_rounded),
        label: locale.navHome,
      ),
      // Slot is shape-stable across modes: the same `NavigationDestination`
      // instance (keyed by `nav_mode`) is always present, only the icon
      // and label change. This stops the destination list from changing
      // shape when the user switches mode, which previously caused the
      // inner `Semantics(identifier:…)` widgets to be unmounted+remounted
      // in the same frame as `/tab2`'s body swap — triggering
      // `!semantics.parentDataDirty`.
      NavigationDestination(
        key: const ValueKey('nav_mode'),
        icon: isRoomPoster
            ? _navIcon('nav_post_tab', Icons.add_home_outlined)
            : _navIcon('nav_explore_tab', Icons.map_outlined),
        selectedIcon: isRoomPoster
            ? _navIcon('nav_post_tab_selected', Icons.add_home_rounded)
            : _navIcon('nav_explore_tab_selected', Icons.map_rounded),
        label: isRoomPoster ? locale.navPost : locale.navExplore,
      ),
      NavigationDestination(
        key: const ValueKey('nav_swipe'),
        icon: _navIcon('nav_swipe_tab', Icons.swap_horiz_rounded),
        selectedIcon: _navIcon(
          'nav_swipe_tab_selected',
          Icons.swap_horiz_rounded,
        ),
        label: locale.navSwipe,
      ),
      NavigationDestination(
        key: const ValueKey('nav_inbox'),
        icon: _navIcon('nav_inbox_tab', Icons.markunread_outlined),
        selectedIcon: _navIcon(
          'nav_inbox_tab_selected',
          Icons.markunread_rounded,
        ),
        label: locale.navLikesChat,
      ),
      NavigationDestination(
        key: const ValueKey('nav_me'),
        icon: _navIcon('nav_me_tab', Icons.person_outline),
        selectedIcon: _navIcon('nav_me_tab_selected', Icons.person_rounded),
        label: locale.navProfile,
      ),
    ];
  }

  /// Semantics.identifier is sufficient for Maestro testing.
  Widget _navIcon(String identifier, IconData icon) {
    return Semantics(identifier: identifier, child: Icon(icon));
  }
}
