import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../bootstrap/bootstrap_controller.dart';
import '../../../chats/application/chat_actions_controller.dart';
import '../../../chats/chats_repository.dart';
import '../../../shared/presentation/components.dart';
import '../../../swipe/application/profile_compatibility.dart';
import '../../../swipe/presentation/widgets/swipe_profile_card.dart';
import '../../../swipe/swipe_repository.dart';

/// Flatmate profile modal with Contact CTA.
///
/// Renders the same rich body the swipe card uses ([SwipeProfileDetailBody]),
/// so a profile opened from the Likes / Liked tabs or "Meet potential
/// flatmates" shows every detail visible on the swipe card (photos, quick
/// stats, about, compatibility breakdown, the place, people, costs).
///
/// A full-width Contact button at the bottom initiates a conversation with
/// the flatmate via [ChatActionsController.matchIncomingLike].
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

  Future<void> _handleContact(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations locale,
  ) async {
    final controller = ref.read(chatActionsControllerProvider);
    try {
      final conversationId = await controller.startConversation(peerId: userId);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      context.go('/chats/$conversationId');
    } catch (e) {
      debugPrint('FlatmateProfileSheet._handleContact: $e');
      if (!context.mounted) return;
      FlatmatesToast.error(context, locale.errorUnknown);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(peerProfileProvider(userId));
    final locale = AppLocalizations.of(context);
    final currentUserId = ref.watch(
      bootstrapControllerProvider.select((s) => s.valueOrNull?.profile.id),
    );
    final isSelf = currentUserId == userId;

    return profileAsync.when(
      loading: () => const FlatmatesSkeleton.peerProfileSheet(),
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

        Widget? trailing;
        if (!isSelf) {
          trailing = SizedBox(
            width: double.infinity,
            child: FlatmatesButton(
              key: const ValueKey('flatmate_contact_cta'),
              label: locale.contactCta,
              onPressed: () => _handleContact(context, ref, locale),
              icon: Icons.send_rounded,
            ),
          );
        }

        return SwipeProfileDetailBody(
          item: peer,
          compatibility: compatibility,
          trailing: trailing,
        );
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
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
