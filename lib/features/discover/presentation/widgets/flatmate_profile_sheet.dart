import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../bootstrap/bootstrap_controller.dart';
import '../../../chats/chats_repository.dart';
import '../../../shared/presentation/components.dart';
import '../../../swipe/application/profile_compatibility.dart';
import '../../../swipe/presentation/widgets/swipe_profile_card.dart';
import '../../../swipe/swipe_repository.dart';

/// View-only flatmate profile modal. Mirrors [OwnerProfileSheet] but omits the
/// Contact CTA — used when tapping a flatmate profile card to inspect details.
///
/// Renders the same rich body the swipe card uses ([SwipeProfileDetailBody]),
/// so a profile opened from the Likes / Liked tabs shows every detail visible
/// on the swipe card (photos, quick stats, about, compatibility breakdown,
/// the place, people, costs).
class FlatmateProfileSheet extends ConsumerWidget {
  const FlatmateProfileSheet({
    required this.userId,
    this.nameFallback,
    super.key,
  });

  final int userId;
  final String? nameFallback;

  static Future<void> show({
    required BuildContext context,
    required int userId,
    String? nameFallback,
  }) {
    return FlatmatesBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          FlatmateProfileSheet(userId: userId, nameFallback: nameFallback),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(peerProfileProvider(userId));

    return profileAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.section),
        child: Center(child: CircularProgressIndicator()),
      ),
      // A null payload is the actual failure path (fetchPeerProfile catches
      // errors and returns null rather than throwing), so treat null + error
      // alike: show the "couldn't load" hint.
      error: (_, _) => _LoadError(name: nameFallback ?? 'Flatmate'),
      data: (peerData) {
        if (peerData == null) {
          return _LoadError(name: nameFallback ?? 'Flatmate');
        }
        final peer = SwipeProfile.fromJson(peerData);
        final currentUser = ref.watch(
          bootstrapControllerProvider.select((s) => s.valueOrNull?.profile),
        );
        final compatibility = calculateProfileCompatibility(currentUser, peer);
        return SwipeProfileDetailBody(item: peer, compatibility: compatibility);
      },
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.section),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlatmatesAvatar(name: name, size: 80),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            locale.couldNotLoadContent,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppSemanticColors.textTertiaryFor(
                isDark ? Brightness.dark : Brightness.light,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
