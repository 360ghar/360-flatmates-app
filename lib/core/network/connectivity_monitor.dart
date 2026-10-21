import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';
import '../../features/shared/presentation/paper/paper_edge_border.dart';
import '../../features/shared/presentation/paper/paper_surface.dart';
import '../../l10n/gen/app_localizations.dart';

/// Whether the device currently has a non-none network interface.
///
/// Seeds the **initial** connectivity state (not only change events), then
/// continues to emit on [Connectivity.onConnectivityChanged].
///
/// Offline transitions are debounced (~1.5s) so brief VPN/Wi‑Fi flaps on
/// Android/Windows do not flash the offline banner or pause realtime.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  bool isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  // Initial snapshot so cold start / offline-at-launch is not treated as online
  // by default (`valueOrNull ?? true`).
  var current = true;
  try {
    current = isOnline(await connectivity.checkConnectivity());
  } catch (e) {
    // Plugin unavailable (tests / desktop) — assume online.
    debugPrint('connectivityProvider.initial: $e');
    current = true;
  }
  yield current;

  await for (final results in connectivity.onConnectivityChanged) {
    final online = isOnline(results);
    if (online) {
      // Coming back online: publish immediately.
      if (!current) {
        current = true;
        yield true;
      }
      continue;
    }

    // Going offline: re-check after a short debounce to ignore blips.
    if (!current) continue;
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    List<ConnectivityResult> recheck;
    try {
      recheck = await connectivity.checkConnectivity();
    } catch (e) {
      // If the plugin fails mid-flight, keep previous "online" state.
      debugPrint('connectivityProvider.recheck: $e');
      continue;
    }
    if (!isOnline(recheck)) {
      current = false;
      yield false;
    }
  }
});

/// Wraps the app and shows an offline strip in the layout flow, above the
/// app, so it pushes content down instead of covering the app bar.
///
/// The strip takes the top safe-area inset; while it is visible the app below
/// gets that inset removed so it is not applied twice.
///
/// The returned tree has the same shape online and offline — only the strip's
/// visibility and the child's top padding change. Returning `child` directly
/// when online and a `Column` when offline would make Flutter deactivate and
/// re-inflate the whole app subtree (Navigator, route state, every open
/// screen's local state) on each connectivity change, because reconciliation
/// at this position compares runtime types.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;

    // The page colour sits behind the strip, so the scallop cut-outs show
    // the page paper instead of the bare window.
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Same slot either way: the strip is only built while offline.
          if (isOnline) const SizedBox.shrink() else const _OfflineStrip(),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              // The strip already consumed the top inset. Without it the app
              // keeps the inset, so app bars and scene art still draw under
              // the status bar exactly as they did before.
              removeTop: !isOnline,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Scallop-edged `warning-soft` strip in the page flow (DESIGN.md §8).
/// [PaperSurface] pads the cut side, so the text clears the scallops.
///
/// No animation: the strip appears and disappears with the connectivity
/// state, so there is nothing for `AppMotion.reduceMotion` to switch off.
class _OfflineStrip extends StatelessWidget {
  const _OfflineStrip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final ink = AppSemanticColors.warningInkFor(theme.brightness);
    return Semantics(
      liveRegion: true,
      child: PaperSurface(
        color: AppSemanticColors.warningSoftFor(theme.brightness),
        elevation: PaperElevation.e0,
        borderRadius: BorderRadius.zero,
        edge: PaperEdge.scallop,
        edgeSide: PaperEdgeSide.bottom,
        edgeDepth: 6,
        grain: false,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off_rounded, size: 18, color: ink),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    locale.youAreOffline,
                    style: theme.textTheme.labelMedium?.copyWith(color: ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
