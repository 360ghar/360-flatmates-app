import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_presenter.dart';
import '../../../../core/errors/l10n_bridge.dart';
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
/// the flatmate via [ChatActionsController.startConversation].
class FlatmateProfileSheet extends ConsumerStatefulWidget {
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
  ConsumerState<FlatmateProfileSheet> createState() =>
      _FlatmateProfileSheetState();
}

class _FlatmateProfileSheetState extends ConsumerState<FlatmateProfileSheet> {
  bool _isContacting = false;

  Future<void> _handleContact(AppLocalizations locale) async {
    if (_isContacting) return;
    setState(() => _isContacting = true);

    final controller = ref.read(chatActionsControllerProvider);
    try {
      final conversationId = await controller.startConversation(
        peerId: widget.userId,
      );
      if (!mounted) return;
      if (conversationId == null) {
        FlatmatesToast.error(context, locale.matchCreateFailed);
        return;
      }
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      router.go('/chats/$conversationId');
    } catch (e, st) {
      debugPrint('FlatmateProfileSheet._handleContact: $e');
      if (!mounted) return;
      final failure = e is DioException ? ErrorPresenter.fromDio(e, st) : null;
      final message = failure != null
          ? failure.userMessage(locale.toUserMessageL10n())
          : locale.errorUnknown;
      FlatmatesToast.error(context, message);
    } finally {
      if (mounted) setState(() => _isContacting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(peerProfileProvider(widget.userId));
    final locale = AppLocalizations.of(context);
    final currentUserId = ref.watch(
      bootstrapControllerProvider.select((s) => s.valueOrNull?.profile.id),
    );
    final isSelf = currentUserId != null && currentUserId == widget.userId;

    return profileAsync.when(
      loading: () => const FlatmatesSkeleton.peerProfileSheet(),
      error: (_, _) => _LoadError(name: widget.nameFallback ?? 'Flatmate'),
      data: (peerData) {
        if (peerData == null) {
          return _LoadError(name: widget.nameFallback ?? 'Flatmate');
        }
        final peer = SwipeProfile.fromJson(peerData);
        final currentUser = ref.watch(
          bootstrapControllerProvider.select((s) => s.valueOrNull?.profile),
        );
        final compatibility = calculateProfileCompatibility(currentUser, peer);

        Widget? trailing;
        if (currentUserId != null && !isSelf) {
          trailing = SizedBox(
            width: double.infinity,
            child: FlatmatesButton(
              key: const ValueKey('flatmate_contact_cta'),
              label: locale.contactCta,
              onPressed: _isContacting
                  ? null
                  : () => unawaited(_handleContact(locale)),
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
