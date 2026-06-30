import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../chats/chats_repository.dart';
import '../discover/discover_repository.dart';
import '../shared/presentation/flatmates_error_state.dart';
import '../shared/presentation/flatmates_skeleton.dart';
import 'application/profile_compatibility.dart';
import 'application/profile_view_tracker.dart';
import 'application/swipe_deck_controller.dart';
import 'presentation/match_celebration_route.dart';
import 'presentation/widgets/swipe_action_bar.dart';
import 'presentation/widgets/swipe_card_stack.dart';
import 'presentation/widgets/swipe_deck_header.dart';
import 'presentation/widgets/swipe_empty_state.dart';
import 'swipe_repository.dart';

part 'swipe_deck_actions.dart';

final swipeDeckHasSwipedProvider = Provider<bool>((ref) {
  ref.watch(swipeDeckControllerProvider);
  return ref.read(swipeDeckControllerProvider.notifier).hasSwiped;
});

class SwipeDeckPage extends ConsumerStatefulWidget {
  const SwipeDeckPage({super.key});

  @override
  ConsumerState<SwipeDeckPage> createState() => _SwipeDeckPageState();
}

class _SwipeDeckPageState extends ConsumerState<SwipeDeckPage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isAnimating = false;

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  final _profileViewTracker = ProfileViewTracker();
  int? _trackedProfileId;
  final _compatibilityCache = ProfileCompatibilityCache();

  late final AnimationController _flyOffController;
  late final AnimationController _snapBackController;
  late final AnimationController _cardEntranceController;

  Offset _flyOffStartOffset = Offset.zero;
  late Animation<double> _flyOffAnimation;

  Offset _snapBackStartOffset = Offset.zero;
  late Animation<double> _snapBackAnimation;

  late Animation<double> _cardScaleAnimation;

  int _flyOffDirectionX = 0;

  SwipeProfile? _lastSwipedProfile;

  static const Duration _snapBackDuration = Duration(milliseconds: 300);
  static const Duration _flyOffDuration = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _flyOffController = AnimationController(
      vsync: this,
      duration: _flyOffDuration,
    );
    _flyOffAnimation = CurvedAnimation(
      parent: _flyOffController,
      curve: Curves.easeIn,
    );
    _flyOffController.addListener(_onFlyOffTick);
    _flyOffController.addStatusListener(_onFlyOffStatus);

    _snapBackController = AnimationController(
      vsync: this,
      duration: _snapBackDuration,
    );
    _snapBackAnimation = CurvedAnimation(
      parent: _snapBackController,
      curve: Curves.easeOut,
    );
    _snapBackController.addListener(_onSnapBackTick);

    _cardEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _cardScaleAnimation = CurvedAnimation(
      parent: _cardEntranceController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _profileViewTracker.clear();
    _flyOffController.dispose();
    _snapBackController.dispose();
    _cardEntranceController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_isAnimating) return;
    _snapBackController.stop();
    setState(() {
      _isDragging = true;
      _dragOffset = Offset.zero;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isAnimating) return;
    setState(() {
      _dragOffset = Offset(_dragOffset.dx + details.delta.dx, 0.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging || _isAnimating) return;
    _isDragging = false;
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.20;

    if (_dragOffset.dx.abs() > threshold) {
      _triggerFlyOff();
      return;
    }

    _triggerSnapBack();
  }

  void _triggerSnapBack() {
    _snapBackStartOffset = _dragOffset;
    _snapBackController.forward(from: 0);
  }

  void _onSnapBackTick() {
    final t = _snapBackAnimation.value;
    setState(() {
      _dragOffset = Offset.lerp(_snapBackStartOffset, Offset.zero, t)!;
    });
    if (_snapBackController.isCompleted) {
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
  }

  void _triggerFlyOff() {
    _flyOffDirectionX = _dragOffset.dx > 0 ? 1 : -1;

    _flyOffStartOffset = _dragOffset;
    _isAnimating = true;
    _flyOffController.forward(from: 0);
  }

  void _triggerButtonSwipe(int directionX) {
    if (_isAnimating || _isDragging) return;
    _snapBackController.stop();
    _flyOffDirectionX = directionX;
    final screenWidth = MediaQuery.of(context).size.width;
    _flyOffStartOffset = Offset(directionX * screenWidth * 0.25, 0);
    _isAnimating = true;
    setState(() => _dragOffset = _flyOffStartOffset);
    _flyOffController.forward(from: 0);
  }

  void _onFlyOffTick() {
    final t = _flyOffAnimation.value;
    final screenSize = MediaQuery.of(context).size;

    final targetOffset = Offset(
      _flyOffDirectionX * screenSize.width * 1.5,
      0.0,
    );

    setState(() {
      _dragOffset = Offset.lerp(_flyOffStartOffset, targetOffset, t)!;
    });
  }

  void _onFlyOffStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _flyOffController.removeListener(_onFlyOffTick);
    _flyOffController.removeStatusListener(_onFlyOffStatus);
    _processSwipeAction(_actionFromDirection());
  }

  Future<void> _processSwipeAction(String action) async {
    _recordProfileView();
    final locale = AppLocalizations.of(context);

    final profiles = ref.read(swipeDeckControllerProvider).profiles;
    final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
    final userProfile = bootstrap?.profile;
    final visible = profiles.where((i) => i.id != userProfile?.id).toList();

    if (_currentIndex >= visible.length) {
      _resetAfterSwipe();
      return;
    }

    final item = visible[_currentIndex];
    _lastSwipedProfile = item;
    unawaited(HapticFeedback.mediumImpact());
    SwipeResult? swipeResult;
    try {
      swipeResult = await ref
          .read(swipeRepositoryProvider)
          .swipeProfile(targetUserId: item.id, action: action);
    } catch (e) {
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

    _trackedProfileId = null;

    setState(() {
      _dragOffset = Offset.zero;
    });

    ref.read(swipeDeckControllerProvider.notifier).markSwiped(item.id);

    final isLikeAction = action == 'like';
    final didMatch = swipeResult.didMatch;
    if (isLikeAction) {
      ref.invalidate(conversationsProvider);
      ref.invalidate(outgoingLikesProvider);
      if (didMatch) {
        ref.invalidate(incomingLikesProvider);
      }
    }

    if (isLikeAction && didMatch) {
      _showMatchCelebration(
        peerName: item.fullName ?? locale.matchPeerFallbackName,
        peerImageUrl: item.profileImageUrl,
        conversationId: swipeResult.conversationId,
      );
    }

    unawaited(
      _cardEntranceController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _isAnimating = false;
          });
        }
      }),
    );

    _flyOffController.addListener(_onFlyOffTick);
    _flyOffController.addStatusListener(_onFlyOffStatus);
  }

  void _recordProfileView() {
    final sample = _profileViewTracker.finish();
    if (sample == null) return;
    unawaited(
      ref
          .read(swipeRepositoryProvider)
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
    setState(() {
      _dragOffset = Offset.zero;
      _isAnimating = false;
    });
    _flyOffController.addListener(_onFlyOffTick);
    _flyOffController.addStatusListener(_onFlyOffStatus);
  }

  String _actionFromDirection() {
    if (_flyOffDirectionX > 0) return 'like';
    return 'pass';
  }

  void _undoLastSwipe() {
    if (_isAnimating || _isDragging) return;
    final last = _lastSwipedProfile;
    if (last == null) return;
    unawaited(HapticFeedback.selectionClick());
    ref.read(swipeDeckControllerProvider.notifier).undoSwipe(last);
    _trackedProfileId = null;
    setState(() => _lastSwipedProfile = null);
  }

  void _refreshProfiles() {
    _compatibilityCache.clear();
    setState(() {
      _currentIndex = 0;
      _lastSwipedProfile = null;
    });
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
      setState(() {
        _currentIndex = 0;
        _lastSwipedProfile = null;
      });
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

    if (_currentIndex >= visible.length) {
      return _scaffoldWithHeader(
        SwipeEmptyState(
          reason: SwipeEmptyReason.endOfDeck,
          onRefresh: _refreshProfiles,
        ),
      );
    }

    final item = visible[_currentIndex];

    if (_trackedProfileId != item.id) {
      _recordProfileView();
      _trackedProfileId = item.id;
      _profileViewTracker.start(item.id);
    }

    final compatibility = _compatibilityCache.resultFor(userProfile, item);

    final hasNextCard = _currentIndex + 1 < visible.length;
    final nextItem = hasNextCard ? visible[_currentIndex + 1] : null;
    final nextCompatibility = hasNextCard && nextItem != null
        ? _compatibilityCache.resultFor(userProfile, nextItem)
        : null;

    final hasThirdCard = _currentIndex + 2 < visible.length;
    final thirdItem = hasThirdCard ? visible[_currentIndex + 2] : null;
    final thirdCompatibility = hasThirdCard && thirdItem != null
        ? _compatibilityCache.resultFor(userProfile, thirdItem)
        : null;

    final nearEnd = _currentIndex >= visible.length - 3;
    if (nearEnd && deckState.hasMore && !deckState.isLoadingMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        ref.read(swipeDeckControllerProvider.notifier).loadMore();
      });
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final rotation = calculateRotation(_dragOffset, screenWidth);
    final progress = calculateDragProgress(_dragOffset, screenWidth);

    return _scaffoldWithHeader(
      Column(
        children: [
          Expanded(
            child: SwipeCardStack(
              item: item,
              compatibility: compatibility,
              nextItem: nextItem,
              nextCompatibility: nextCompatibility,
              thirdItem: thirdItem,
              thirdCompatibility: thirdCompatibility,
              dragOffset: _dragOffset,
              dragProgress: progress,
              currentRotation: rotation,
              cardScaleAnimation: _cardScaleAnimation,
              isDragging: _isDragging,
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
            canUndo: _lastSwipedProfile != null,
            enabled: !_isAnimating && !_isDragging,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
