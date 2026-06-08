import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../chats/chats_repository.dart';
import '../shared/presentation/flatmates_error_state.dart';
import '../shared/presentation/flatmates_skeleton.dart';
import 'application/profile_compatibility.dart';
import 'application/profile_view_tracker.dart';
import 'application/swipe_deck_controller.dart';
import 'presentation/match_celebration_route.dart';
import 'presentation/widgets/swipe_card_stack.dart';
import 'presentation/widgets/swipe_empty_state.dart';
import 'swipe_repository.dart';

part 'swipe_deck_actions.dart';

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

  late final AnimationController _flyOffController;
  late final AnimationController _snapBackController;
  late final AnimationController _cardEntranceController;

  Offset _flyOffStartOffset = Offset.zero;
  late Animation<double> _flyOffAnimation;

  Offset _snapBackStartOffset = Offset.zero;
  late Animation<double> _snapBackAnimation;

  late Animation<double> _cardScaleAnimation;

  int _flyOffDirectionX = 0;

  // Undo state
  SwipeProfile? _lastSwipedProfile;
  // ignore: unused_field
  String? _lastSwipedAction;
  bool _showUndo = false;
  Timer? _undoTimer;

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
    _undoTimer?.cancel();
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
    // Keep the card offscreen until the backend accepts the swipe.
    _processSwipeAction(_actionFromDirection());
  }

  Future<void> _processSwipeAction(String action) async {
    _recordProfileView();
    final locale = AppLocalizations.of(context);

    final profiles = ref.read(swipeDeckControllerProvider).valueOrNull ?? [];
    final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
    final userProfile = bootstrap?.profile;
    final visible = profiles.where((i) => i.id != userProfile?.id).toList();

    if (_currentIndex >= visible.length) {
      _resetAfterSwipe();
      return;
    }

    final item = visible[_currentIndex];
    // Save for potential undo
    _lastSwipedProfile = item;
    _lastSwipedAction = action;
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

    // Reset tracked profile since we're moving to the next card.
    _trackedProfileId = null;

    setState(() {
      _dragOffset = Offset.zero;
    });

    // Remove swiped profile so the next rebuild shows the next card.
    // The entrance animation hides the card swap.
    ref.read(swipeDeckControllerProvider.notifier).markSwiped(item.id);

    // Show undo button for 3 seconds
    _undoTimer?.cancel();
    if (mounted) {
      setState(() => _showUndo = true);
      _undoTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showUndo = false);
        }
      });
    }

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
        peerName: item.fullName ?? 'Flatmate',
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
    final last = _lastSwipedProfile;
    if (last == null) return;
    _undoTimer?.cancel();
    setState(() => _showUndo = false);
    ref.read(swipeDeckControllerProvider.notifier).undoSwipe(last);
    _lastSwipedProfile = null;
    _lastSwipedAction = null;
  }

  void _refreshProfiles() {
    setState(() => _currentIndex = 0);
    ref.read(swipeDeckControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(swipeDeckControllerProvider);
    final userProfile = ref.watch(
      bootstrapControllerProvider.select((s) => s.valueOrNull?.profile),
    );
    final locale = AppLocalizations.of(context);

    return profiles.when(
      data: (items) {
        if (items.isEmpty) {
          return Scaffold(
            body: SwipeEmptyState(
              reason: SwipeEmptyReason.noProfiles,
              onRefresh: _refreshProfiles,
            ),
          );
        }

        final visible = items.where((i) => i.id != userProfile?.id).toList();

        if (visible.isEmpty) {
          return Scaffold(
            body: SwipeEmptyState(
              reason: SwipeEmptyReason.allFiltered,
              onRefresh: _refreshProfiles,
            ),
          );
        }

        if (_currentIndex >= visible.length) {
          return Scaffold(
            body: SwipeEmptyState(
              reason: SwipeEmptyReason.endOfDeck,
              onRefresh: _refreshProfiles,
            ),
          );
        }

        final item = visible[_currentIndex];

        // Start view tracking for current card
        if (_trackedProfileId != item.id) {
          _recordProfileView();
          _trackedProfileId = item.id;
          _profileViewTracker.start(item.id);
        }

        final compatibility = calculateProfileCompatibility(userProfile, item);

        final hasNextCard = _currentIndex + 1 < visible.length;
        final nextItem = hasNextCard ? visible[_currentIndex + 1] : null;
        final nextCompatibility = hasNextCard && nextItem != null
            ? calculateProfileCompatibility(userProfile, nextItem)
            : null;

        final hasThirdCard = _currentIndex + 2 < visible.length;
        final thirdItem = hasThirdCard ? visible[_currentIndex + 2] : null;
        final thirdCompatibility = hasThirdCard && thirdItem != null
            ? calculateProfileCompatibility(userProfile, thirdItem)
            : null;

        final screenWidth = MediaQuery.of(context).size.width;
        final rotation = calculateRotation(_dragOffset, screenWidth);
        final progress = calculateDragProgress(_dragOffset, screenWidth);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      SwipeCardStack(
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
                      if (_showUndo)
                        Positioned(
                          top: AppSpacing.md,
                          right: AppSpacing.xl,
                          child: _UndoButton(onPressed: _undoLastSwipe),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: FlatmatesSkeleton.card())),
      error: (e, _) => Scaffold(
        body: FlatmatesErrorState(
          message: locale.failedToLoadProfiles,
          onRetry: () =>
              ref.read(swipeDeckControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }
}

class _UndoButton extends StatelessWidget {
  const _UndoButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Undo',
      child: Listener(
        onPointerDown: (_) => onPressed(),
        child: ClipRRect(
          borderRadius: AppRadius.mdBorder,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: AppRadius.mdBorder,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: const Icon(
                Icons.undo_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
