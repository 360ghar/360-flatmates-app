import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../discover/discover_repository.dart';
import '../shared/presentation/flatmates_error_state.dart';
import '../shared/presentation/flatmates_skeleton.dart';
import 'application/profile_compatibility.dart';
import 'application/profile_view_tracker.dart';
import 'application/swipe_deck_controller.dart';
import 'presentation/match_celebration_route.dart';
import 'presentation/swipe_interaction_state.dart';
import 'presentation/widgets/swipe_action_bar.dart';
import 'presentation/widgets/swipe_card_stack.dart';
import 'presentation/widgets/swipe_deck_header.dart';
import 'presentation/widgets/swipe_empty_state.dart';
import 'swipe_repository.dart';

part 'swipe_deck_actions.dart';

final swipeDeckHasSwipedProvider = Provider<bool>((ref) {
  return ref.watch(
    swipeDeckControllerProvider.select((state) => state.hasSwiped),
  );
});

class _PendingSwipe {
  const _PendingSwipe({required this.profile, required this.action});

  final SwipeProfile profile;
  final String action;
}

class SwipeDeckPage extends ConsumerStatefulWidget {
  const SwipeDeckPage({super.key});

  @override
  ConsumerState<SwipeDeckPage> createState() => _SwipeDeckPageState();
}

class _SwipeDeckPageState extends ConsumerState<SwipeDeckPage>
    with TickerProviderStateMixin {
  final _interaction = ValueNotifier<SwipeInteractionState>(
    const SwipeInteractionState(),
  );
  final _profileViewTracker = ProfileViewTracker();
  int? _trackedProfileId;
  final _compatibilityCache = ProfileCompatibilityCache();

  late final AnimationController _flyOffController;
  late final AnimationController _snapBackController;

  Offset _flyOffStartOffset = Offset.zero;
  late Animation<double> _flyOffAnimation;

  Offset _snapBackStartOffset = Offset.zero;
  late Animation<double> _snapBackAnimation;

  int _flyOffDirectionX = 0;
  _PendingSwipe? _pendingSwipe;

  static const Duration _snapBackDuration = AppMotion.slow;
  static const Duration _flyOffDuration = AppMotion.tabSwitch;

  @override
  void initState() {
    super.initState();
    _flyOffController = AnimationController(
      vsync: this,
      duration: _flyOffDuration,
    );
    _flyOffAnimation = CurvedAnimation(
      parent: _flyOffController,
      curve: AppMotion.easeOutExpo,
    );
    _flyOffController.addListener(_onFlyOffTick);
    _flyOffController.addStatusListener(_onFlyOffStatus);

    _snapBackController = AnimationController(
      vsync: this,
      duration: _snapBackDuration,
    );
    _snapBackAnimation = CurvedAnimation(
      parent: _snapBackController,
      curve: AppMotion.easeOutCubic,
    );
    _snapBackController.addListener(_onSnapBackTick);
  }

  @override
  void dispose() {
    _profileViewTracker.clear();
    _interaction.dispose();
    _flyOffController.dispose();
    _snapBackController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_interaction.value.isBusy) return;
    _snapBackController.stop();
    _pendingSwipe = null;
    _interaction.value = const SwipeInteractionState(isDragging: true);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final interaction = _interaction.value;
    if (!interaction.isDragging || interaction.isAnimating) return;
    _interaction.value = interaction.copyWith(
      dragOffset: Offset(interaction.dragOffset.dx + details.delta.dx, 0.0),
    );
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final interaction = _interaction.value;
    if (!interaction.isDragging || interaction.isAnimating) return;
    _interaction.value = interaction.copyWith(isDragging: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.20;

    if (interaction.dragOffset.dx.abs() > threshold) {
      _triggerFlyOff(interaction.dragOffset);
      return;
    }

    _triggerSnapBack(interaction.dragOffset);
  }

  void _triggerSnapBack(Offset startOffset) {
    _snapBackStartOffset = startOffset;
    _snapBackController.forward(from: 0);
  }

  void _onSnapBackTick() {
    final t = _snapBackAnimation.value;
    _interaction.value = _interaction.value.copyWith(
      dragOffset: Offset.lerp(_snapBackStartOffset, Offset.zero, t)!,
    );
    if (_snapBackController.isCompleted) {
      _interaction.value = const SwipeInteractionState();
    }
  }

  void _triggerFlyOff(Offset startOffset) {
    _beginSwipe(
      directionX: startOffset.dx > 0 ? 1 : -1,
      startOffset: startOffset,
    );
  }

  void _triggerButtonSwipe(int directionX) {
    if (_interaction.value.isBusy) return;
    _snapBackController.stop();
    final screenWidth = MediaQuery.of(context).size.width;
    final startOffset = Offset(directionX * screenWidth * 0.25, 0);
    _beginSwipe(directionX: directionX, startOffset: startOffset);
  }

  void _beginSwipe({required int directionX, required Offset startOffset}) {
    final profile = _currentProfile();
    if (profile == null) return;
    _flyOffDirectionX = directionX;
    _flyOffStartOffset = startOffset;
    _pendingSwipe = _PendingSwipe(
      profile: profile,
      action: directionX > 0 ? 'like' : 'pass',
    );
    unawaited(HapticFeedback.mediumImpact());
    _interaction.value = SwipeInteractionState(
      dragOffset: startOffset,
      isAnimating: true,
    );
    _flyOffController.forward(from: 0);
  }

  SwipeProfile? _currentProfile() {
    final deckState = ref.read(swipeDeckControllerProvider);
    final userProfile = ref
        .read(bootstrapControllerProvider)
        .valueOrNull
        ?.profile;
    return deckState.currentProfile(userProfile?.id);
  }

  void _onFlyOffTick() {
    final t = _flyOffAnimation.value;
    final screenSize = MediaQuery.of(context).size;

    final targetOffset = Offset(
      _flyOffDirectionX * screenSize.width * 1.5,
      0.0,
    );

    _interaction.value = _interaction.value.copyWith(
      dragOffset: Offset.lerp(_flyOffStartOffset, targetOffset, t)!,
    );
  }

  void _onFlyOffStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    unawaited(_processPendingSwipe());
  }

  Future<void> _processPendingSwipe() async {
    final pending = _pendingSwipe;
    if (pending == null) {
      _resetAfterSwipe();
      return;
    }

    _recordProfileView();
    final locale = AppLocalizations.of(context);
    final controller = ref.read(swipeDeckControllerProvider.notifier);
    controller.advanceAfterSwipe(pending.profile);
    _trackedProfileId = null;
    _interaction.value = _interaction.value.copyWith(
      dragOffset: Offset.zero,
      isDragging: false,
      isAnimating: true,
    );

    late final SwipeResult swipeResult;
    try {
      swipeResult = await controller.persistSwipe(
        profile: pending.profile,
        action: pending.action,
      );
    } catch (e) {
      controller.rollbackSwipe(pending.profile);
      if (mounted) {
        final message = e is AppFailure
            ? e.userMessage(locale.toUserMessageL10n())
            : locale.actionFailedRetry;
        _showSnack(message);
      }
      _resetAfterSwipe();
      return;
    }

    if (!mounted) return;

    final isLikeAction = pending.action == 'like';
    final didMatch = swipeResult.didMatch;

    if (isLikeAction && didMatch) {
      _showMatchCelebration(
        peerName: pending.profile.fullName ?? locale.matchPeerFallbackName,
        peerImageUrl: pending.profile.profileImageUrl,
        conversationId: swipeResult.conversationId,
      );
    }

    _resetAfterSwipe();
  }

  void _recordProfileView() {
    final sample = _profileViewTracker.finish();
    if (sample == null) return;
    unawaited(
      ref
          .read(swipeDeckControllerProvider.notifier)
          .recordProfileView(
            targetUserId: sample.profileId,
            durationSeconds: sample.durationSeconds,
            scrollDepthPercent: 100,
          )
          .catchError((Object e, StackTrace st) {
            debugPrint(
              'SwipeDeckPage.recordProfileView failed for ${sample.profileId}: $e',
            );
          }),
    );
  }

  void _resetAfterSwipe() {
    _pendingSwipe = null;
    _interaction.value = const SwipeInteractionState();
  }

  void _undoLastSwipe() {
    if (_interaction.value.isBusy) return;
    final didUndo = ref
        .read(swipeDeckControllerProvider.notifier)
        .undoLastSwipe();
    if (!didUndo) return;
    unawaited(HapticFeedback.selectionClick());
    _trackedProfileId = null;
    _interaction.value = const SwipeInteractionState();
  }

  void _refreshProfiles() {
    _compatibilityCache.clear();
    _trackedProfileId = null;
    _pendingSwipe = null;
    _interaction.value = const SwipeInteractionState();
    ref.read(swipeDeckControllerProvider.notifier).refresh();
  }

  Widget _scaffoldWithHeader(Widget body) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                0,
              ),
              child: SwipeDeckHeader(),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(discoverFiltersProvider, (previous, next) {
      if (previous == next) return;
      _compatibilityCache.clear();
      _pendingSwipe = null;
      _trackedProfileId = null;
      _flyOffController.stop();
      _snapBackController.stop();
      _interaction.value = const SwipeInteractionState();
    });

    final deckState = ref.watch(swipeDeckControllerProvider);
    final profiles = deckState.profiles;
    final userProfile = ref.watch(
      bootstrapControllerProvider.select((s) => s.valueOrNull?.profile),
    );
    final locale = AppLocalizations.of(context);

    final hasSwiped = ref.watch(swipeDeckHasSwipedProvider);

    if (deckState.isLoading && profiles.isEmpty) {
      return const Scaffold(body: Center(child: FlatmatesSkeleton.card()));
    }
    if (deckState.hasError && profiles.isEmpty) {
      return Scaffold(
        body: FlatmatesErrorState(
          message: locale.failedToLoadProfiles,
          onRetry: () =>
              ref.read(swipeDeckControllerProvider.notifier).refresh(),
        ),
      );
    }

    if (profiles.isEmpty) {
      return _scaffoldWithHeader(
        SwipeEmptyState(
          reason: hasSwiped
              ? SwipeEmptyReason.endOfDeck
              : SwipeEmptyReason.noProfiles,
          onRefresh: _refreshProfiles,
        ),
      );
    }

    final visible = profiles.where((i) => i.id != userProfile?.id).toList();

    if (visible.isEmpty) {
      return _scaffoldWithHeader(
        SwipeEmptyState(
          reason: hasSwiped
              ? SwipeEmptyReason.endOfDeck
              : SwipeEmptyReason.allFiltered,
          onRefresh: _refreshProfiles,
        ),
      );
    }

    final currentIndex = deckState.currentIndex;

    if (currentIndex >= visible.length) {
      return _scaffoldWithHeader(
        SwipeEmptyState(
          reason: SwipeEmptyReason.endOfDeck,
          onRefresh: _refreshProfiles,
        ),
      );
    }

    final item = visible[currentIndex];

    if (_trackedProfileId != item.id) {
      _recordProfileView();
      _trackedProfileId = item.id;
      _profileViewTracker.start(item.id);
    }

    final compatibility = _compatibilityCache.resultFor(userProfile, item);

    final hasNextCard = currentIndex + 1 < visible.length;
    final nextItem = hasNextCard ? visible[currentIndex + 1] : null;
    final nextCompatibility = hasNextCard && nextItem != null
        ? _compatibilityCache.resultFor(userProfile, nextItem)
        : null;

    final hasThirdCard = currentIndex + 2 < visible.length;
    final thirdItem = hasThirdCard ? visible[currentIndex + 2] : null;
    final thirdCompatibility = hasThirdCard && thirdItem != null
        ? _compatibilityCache.resultFor(userProfile, thirdItem)
        : null;

    final nearEnd = currentIndex >= visible.length - 3;
    if (nearEnd && deckState.hasMore && !deckState.isLoadingMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        ref.read(swipeDeckControllerProvider.notifier).loadMore();
      });
    }

    return _scaffoldWithHeader(
      ValueListenableBuilder<SwipeInteractionState>(
        valueListenable: _interaction,
        builder: (context, interaction, _) {
          final screenWidth = MediaQuery.of(context).size.width;
          final rotation = calculateRotation(
            interaction.dragOffset,
            screenWidth,
          );
          final progress = calculateDragProgress(
            interaction.dragOffset,
            screenWidth,
          );
          return Column(
            children: [
              Expanded(
                child: SwipeCardStack(
                  key: const Key('swipe_card'),
                  item: item,
                  compatibility: compatibility,
                  nextItem: nextItem,
                  nextCompatibility: nextCompatibility,
                  thirdItem: thirdItem,
                  thirdCompatibility: thirdCompatibility,
                  dragOffset: interaction.dragOffset,
                  dragProgress: progress,
                  currentRotation: rotation,
                  isDragging: interaction.isDragging,
                  onHorizontalDragStart: _onHorizontalDragStart,
                  onHorizontalDragUpdate: _onHorizontalDragUpdate,
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                ),
              ),
              if (deckState.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              SwipeActionBar(
                onSkip: () => _triggerButtonSwipe(-1),
                onLike: () => _triggerButtonSwipe(1),
                onUndo: _undoLastSwipe,
                canUndo: deckState.lastSwipedProfile != null,
                enabled: !interaction.isBusy,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          );
        },
      ),
    );
  }
}
