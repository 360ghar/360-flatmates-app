import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/domain/wire_enums.dart';
import '../core/providers.dart';
import '../core/storage/app_preferences.dart';
import '../core/theme/app_breakpoints.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_semantic_colors.dart';
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
/// the onboarding soft gate all resolve the mode through [FlatmatesMode.fromJson],
/// so they can never disagree about what tab 2 is. A mode this build does not
/// know is not a room poster.
bool isRoomPosterMode(String? mode) =>
    FlatmatesMode.fromJson(mode) == FlatmatesMode.roomPoster;

/// One navigation slot, independent of the chrome that renders it.
///
/// The bottom [NavigationBar] and the wide-viewport [NavigationRail] are built
/// from the same list, so the two can never disagree about order, icon, label
/// or Maestro identifier. [key] is kept on the bottom bar only: it is what
/// makes slot 2 shape-stable across a mode switch.
typedef _NavSlot = ({Key key, String id, Widget icon, String label});

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

    final slots = _slots(mode, locale);

    // 669 dp (open Duo portrait) and 678 dp (folded landscape) stay on the
    // bottom bar; only the 951 dp open-landscape pose gets the rail.
    final useRail = AppBreakpoints.isExpanded(MediaQuery.sizeOf(context).width);

    return Scaffold(
      body: Column(
        children: [
          if (showOnboardingBanner) const OnboardingCompletionBanner(),
          Expanded(
            child: useRail
                ? _wideBody(context, slots, showOnboardingBanner)
                : _shellBody(showOnboardingBanner),
          ),
        ],
      ),
      // Paper tab strip: layer one with a torn top edge; the active tab
      // rises one layer (indicator = paper-2, see navigationBarTheme).
      bottomNavigationBar: useRail ? null : _bar(context, slots),
    );
  }

  /// The five shell branches. `Builder` because the context must be inside the
  /// Scaffold body, whose MediaQuery has the keyboard inset removed: the
  /// shell's own context would put the inset back, and every page Scaffold
  /// would resize for the keyboard a second time.
  Widget _shellBody(bool showOnboardingBanner) => Builder(
    builder: (context) => MediaQuery.removePadding(
      context: context,
      removeTop: showOnboardingBanner,
      child: navigationShell,
    ),
  );

  /// Wide-viewport shell body: the rail on the left, the branch content beside
  /// it.
  ///
  /// A [Stack] rather than a [Row], and that is load-bearing. go_router wraps
  /// every inactive shell branch in an `Offstage`, and an offstage node blocks
  /// the semantics of everything painted *before* it. In a `Row` the rail is
  /// painted first, so all five Maestro identifiers disappeared from the
  /// accessibility tree — verified: at 951 dp `find.bySemanticsIdentifier`
  /// found none of them, and a bare `Semantics(identifier:)` probe in that slot
  /// was dropped too. Painting the page first and the rail over it keeps both
  /// trees intact: the page keeps its route scope, the rail keeps its ids.
  ///
  /// [SizedBox.expand] is required because a [Stack] whose children are all
  /// positioned takes its size from `constraints.minWidth/minHeight`, and the
  /// enclosing `Expanded` leaves the width loose.
  Widget _wideBody(
    BuildContext context,
    List<_NavSlot> slots,
    bool showOnboardingBanner,
  ) => SizedBox.expand(
    child: Stack(
      children: [
        Positioned(
          left: AppBreakpoints.railWidth,
          top: 0,
          right: 0,
          bottom: 0,
          child: _shellBody(showOnboardingBanner),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: AppBreakpoints.railWidth,
          child: _rail(context, slots),
        ),
      ],
    ),
  );

  Widget _bar(BuildContext context, List<_NavSlot> slots) => PaperSurface(
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
          onDestinationSelected: _select,
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
          destinations: [
            for (final slot in slots)
              _tab(
                slot.id,
                NavigationDestination(
                  key: slot.key,
                  icon: slot.icon,
                  label: slot.label,
                ),
              ),
          ],
        ),
      ),
    ),
  );

  /// Wide-viewport chrome: a vertical rail on the left, same destinations.
  ///
  /// DESIGN.md has no vertical torn edge ([PaperEdgeSide] is top / bottom /
  /// left only), so the rail is a plain solid `PaperSurface` at layer one with
  /// a hairline border on the side that faces the content — the same "solid
  /// surface + hairline, no frost" rule the bottom bar follows. It is the one
  /// piece of shell chrome with no paper-art cut; that is a deliberate gap, not
  /// an oversight.
  ///
  /// The caller pins this to `AppBreakpoints.railWidth`, so the reading column
  /// beside it is deterministic. `SafeArea` handles only the bottom inset:
  /// [NavigationRail] applies the outer left safe area itself (in LTR), and the
  /// page handles any right inset. In open portrait the Duo measures zero on
  /// both sides (the 82 dp inset is on top); the open-landscape pose that shows
  /// this rail has not been measured, so the rail keeps managing its own edge
  /// instead of relying on those values.
  Widget _rail(BuildContext context, List<_NavSlot> slots) {
    final brightness = Theme.of(context).brightness;
    return PaperSurface(
      layer: PaperLayer.one,
      elevation: PaperElevation.e0,
      borderRadius: BorderRadius.zero,
      // The hairline is the child, not an outer decoration: `PaperSurface`
      // paints its own layer colour over the whole rect, which would hide a
      // border drawn outside it.
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: AppSemanticColors.hairlineFor(brightness)),
          ),
        ),
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          // Same 1.3 cap as the bar. The rail has vertical room to spare, but
          // a larger scale makes labels wrap to more lines, and the rail is a
          // fixed width, so the extra lines buy nothing.
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: NavigationRail(
              selectedIndex: navigationShell.currentIndex.clamp(0, 4),
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              // PaperSurface paints the layer; the rail's own Material must
              // not paint over it. `elevation` is left to the theme (0) — the
              // widget asserts a positive value.
              backgroundColor: Colors.transparent,
              destinations: [
                for (final slot in slots)
                  NavigationRailDestination(
                    icon: _railTab(slot.id, slot.icon),
                    // NavigationRail takes a label widget and wraps it in a
                    // DefaultTextStyle carrying the rail's label style.
                    label: Text(slot.label),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _select(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  List<_NavSlot> _slots(String mode, AppLocalizations locale) {
    final isRoomPoster = isRoomPosterMode(mode);

    // Cut-paper nav icons shared with the web app. Selected vs unselected
    // is colour only (clay vs ink-3, from navigationBarTheme / the rail theme).
    return [
      (
        key: const ValueKey('nav_home'),
        id: 'nav_home_tab',
        icon: const PaperIcon(PaperArt.navHome),
        label: locale.navHome,
      ),
      // Slot is shape-stable across modes: the same destination (keyed by
      // `nav_mode`) is always present, only the icon and label change. This
      // stops the destination list from changing shape when the user switches
      // mode, which previously caused the inner semantics widgets to be
      // unmounted+remounted in the same frame as `/tab2`'s body swap —
      // triggering `!semantics.parentDataDirty`.
      // Only the identifier string changes with the mode.
      (
        key: const ValueKey('nav_mode'),
        id: isRoomPoster ? 'nav_post_tab' : 'nav_explore_tab',
        icon: isRoomPoster
            ? const PaperIcon(PaperArt.navPost)
            : const PaperIcon(PaperArt.navExplore),
        label: isRoomPoster ? locale.navPost : locale.navExplore,
      ),
      (
        key: const ValueKey('nav_swipe'),
        id: 'nav_swipe_tab',
        icon: const PaperIcon(PaperArt.navSwipe),
        label: locale.navSwipe,
      ),
      (
        key: const ValueKey('nav_inbox'),
        id: 'nav_inbox_tab',
        icon: const PaperIcon(PaperArt.navChats),
        label: locale.navLikesChat,
      ),
      (
        key: const ValueKey('nav_me'),
        id: 'nav_me_tab',
        icon: const PaperIcon(PaperArt.navProfile),
        label: locale.navProfile,
      ),
    ];
  }

  /// Maestro id on the whole destination. Material merges a destination's
  /// semantics into one node, which drops an identifier set on the icon.
  ///
  /// `NavigationBar` and `NavigationRail` destinations both need this, so the
  /// wrapper takes the destination widget rather than either concrete type.
  Widget _tab(String identifier, Widget destination) =>
      Semantics(identifier: identifier, container: true, child: destination);

  /// Maestro id for a rail destination.
  ///
  /// [NavigationRailDestination] is not a widget, so there is no node to wrap
  /// the way [_tab] wraps a [NavigationDestination]. Material's own
  /// `_RailDestination` root is a `Semantics(container: true, selected: ...)`
  /// node that already carries the label and the tap action, so this identifier
  /// is left non-container and merges *into* it: one node with the id, the
  /// label and the tap, exactly like the bottom bar. `container: true` here
  /// would instead create a second, unlabelled node that a screen reader would
  /// stop on.
  Widget _railTab(String identifier, Widget icon) =>
      Semantics(identifier: identifier, child: icon);
}
