import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_semantic_colors.dart';
import '../../l10n/gen/app_localizations.dart';

/// Whether the device currently has a non-none network interface.
///
/// Seeds the **initial** connectivity state (not only change events), then
/// continues to emit on [Connectivity.onConnectivityChanged].
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  bool isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  // Initial snapshot so cold start / offline-at-launch is not treated as online
  // by default (`valueOrNull ?? true`).
  try {
    yield isOnline(await connectivity.checkConnectivity());
  } catch (_) {
    // Plugin unavailable (tests / desktop) — assume online.
    yield true;
  }

  yield* connectivity.onConnectivityChanged.map(isOnline);
});

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final isOnline = connectivity.valueOrNull ?? true;

    if (isOnline) return const SizedBox.shrink();

    final locale = AppLocalizations.of(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Material(
          color: AppSemanticColors.error,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 18,
                  color: AppSemanticColors.paper,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locale.youAreOffline,
                    style: const TextStyle(
                      color: AppSemanticColors.paper,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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
