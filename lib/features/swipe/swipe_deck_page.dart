import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/debouncer.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../shared/presentation/flatmates_error_state.dart';
import '../shared/presentation/flatmates_skeleton.dart';
import 'application/profile_compatibility.dart';
import 'application/profile_view_tracker.dart';
import 'application/swipe_quota_controller.dart';
import 'presentation/match_celebration_route.dart';
import 'presentation/widgets/swipe_action_buttons.dart';
import 'presentation/widgets/swipe_card_stack.dart';
import 'presentation/widgets/swipe_empty_state.dart';
import 'presentation/widgets/swipe_quota_header.dart';
import 'swipe_repository.dart';

class SwipeDeckPage extends ConsumerStatefulWidget {
  const SwipeDeckPage({super.key});

  @override
  ConsumerState<SwipeDeckPage> createState() => _SwipeDeckPageState();
}

class _SwipeDeckPageState extends ConsumerState<SwipeDeckPage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isExpanded = false;
  bool _isAnimating = false;

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  final _profileViewTracker = ProfileViewTracker();

  late final AnimationController _flyOffController;
  late final AnimationController _snapBackController;
  late final AnimationController _cardEntranceController;

  Offset _flyOffStartOffset = Offset.zero;
  late Animation<double> _flyOffAnimation;

  Offset _snapBackStartOffset = Offset.zero;
  late Animation<double> _snapBackAnimation;

  late Animation<double> _cardScaleAnimation;

  int _flyOffDirectionX = 0;
  int _flyOffDirectionY = 0;
  bool _isButtonTriggered = false;

  final _swipeDebouncer = ActionDebouncer(
    duration: const Duration(milliseconds: 300),
  );

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
    _swipeDebouncer.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isAnimating || _isExpanded) return;
    _snapBackController.stop();
    setState(() { _isDragging = true; _dragOffset = Offset.zero; });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isAnimating) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging || _isAnimating) return;
    _isDragging = false;
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.20;
    if (_dragOffset.dy < -threshold) {
      _triggerFlyOff(superLike: true);
      return;
    }
    if (_dragOffset.dx.abs() > threshold) {
      _triggerFlyOff(superLike: false);
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

  void _triggerFlyOff({required bool superLike}) {
    _recordExpandedProfileView();
    if (superLike) {
      _flyOffDirectionX = 0;
      _flyOffDirectionY = -1;
    } else {
      _flyOffDirectionX = _dragOffset.dx > 0 ? 1 : -1;
      _flyOffDirectionY = 0;
    }

    _flyOffStartOffset = _dragOffset;
    _isButtonTriggered = false;
    _isAnimating = true;
    _flyOffController.forward(from: 0);
  }

  void _onFlyOffTick() {
    final t = _flyOffAnimation.value;
    final screenSize = MediaQuery.of(context).size;
    final start = _isButtonTriggered ? Offset.zero : _flyOffStartOffset;

    final targetOffset = Offset(
      _flyOffDirectionX != 0 ? _flyOffDirectionX * screenSize.width * 1.5 : 0.0,
      _flyOffDirectionY != 0
          ? _flyOffDirectionY * screenSize.height * 1.5
          : 0.0,
    );

    setState(() {
      _dragOffset = Offset.lerp(start, targetOffset, t)!;
    });
  }

  void _onFlyOffStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _flyOffController.removeListener(_onFlyOffTick);
    _flyOffController.removeStatusListener(_onFlyOffStatus);
    setState(() { _dragOffset = Offset.zero; });
    _processSwipeAction(_actionFromDirection());
  }

  Future<void> _processSwipeAction(String action) async {
    _recordExpandedProfileView();
    final locale = AppLocalizations.of(context);
    final quota = ref.read(swipeQuotaControllerProvider);

    if (action == 'super_like' && quota.superLikesRemaining <= 0) {
      if (!mounted) return;
      _showSnack(locale.superLikeCapLabel(0));
      _resetAfterSwipe();
      return;
    }

    if (quota.isCapped) {
      if (!mounted) return;
      _showSnack(locale.swipeCounterLabel(0));
      _resetAfterSwipe();
      return;
    }

    final profiles = ref.read(swipeProfilesProvider).valueOrNull ?? [];
    final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
    final userProfile = bootstrap?.profile;
    final visible = profiles.where((i) => i.id != userProfile?.id).toList();

    if (_currentIndex >= visible.length) {
      _resetAfterSwipe();
      return;
    }

    final item = visible[_currentIndex];
    HapticFeedback.mediumImpact();
    SwipeResult? swipeResult;
    try {
      swipeResult = await ref
          .read(swipeRepositoryProvider)
          .swipeProfile(targetUserId: item.id, action: action);
    } catch (e) {
      if (mounted) {
        _showSnack(locale.actionFailedRetry);
      }
      _resetAfterSwipe();
      return;
    }

    if (!mounted) return;

    ref
        .read(swipeQuotaControllerProvider.notifier)
        .recordSwipe(isSuperLike: action == 'super_like');

    setState(() {
      _currentIndex++;
      _isExpanded = false;
    });

    final isLikeAction = action == 'like' || action == 'super_like';
    if (isLikeAction && swipeResult.didMatch) {
      _showMatchCelebration(
        peerName: item.fullName ?? 'Flatmate',
        peerImageUrl: item.profileImageUrl,
        conversationId: swipeResult.conversationId,
      );
    }

    _cardEntranceController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    });

    _flyOffController.addListener(_onFlyOffTick);
    _flyOffController.addStatusListener(_onFlyOffStatus);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _recordExpandedProfileView() {
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
          .catchError((_) {}),
    );
  }

  void _toggleExpanded(SwipeProfile item) {
    if (_isExpanded) {
      _recordExpandedProfileView();
    } else {
      _profileViewTracker.start(item.id);
    }
    setState(() => _isExpanded = !_isExpanded);
  }

  void _showMatchCelebration({
    required String peerName,
    required String? peerImageUrl,
    required int? conversationId,
  }) {
    final userProfile = ref
        .read(bootstrapControllerProvider)
        .valueOrNull
        ?.profile;
    pushMatchCelebration(
      context,
      userName: userProfile?.fullName ?? 'You',
      userImageUrl: userProfile?.profileImageUrl,
      peerName: peerName,
      peerImageUrl: peerImageUrl,
      conversationId: conversationId,
    );
  }

  void _resetAfterSwipe() {
    setState(() { _dragOffset = Offset.zero; _isAnimating = false; });
    _flyOffController.addListener(_onFlyOffTick);
    _flyOffController.addStatusListener(_onFlyOffStatus);
  }

  String _actionFromDirection() {
    if (_flyOffDirectionY < 0) return 'super_like';
    if (_flyOffDirectionX > 0) return 'like';
    return 'pass';
  }

  void _refreshProfiles() {
    setState(() => _currentIndex = 0);
    ref.invalidate(swipeProfilesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(swipeProfilesProvider);
    final userProfile = ref.watch(
      bootstrapControllerProvider.select((s) => s.valueOrNull?.profile),
    );
    final quota = ref.watch(swipeQuotaControllerProvider);
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
        final compatibility = calculateProfileCompatibility(userProfile, item);

        final hasNextCard = _currentIndex + 1 < visible.length;
        final nextItem = hasNextCard ? visible[_currentIndex + 1] : null;
        final nextCompatibility = hasNextCard && nextItem != null
            ? calculateProfileCompatibility(userProfile, nextItem)
            : null;

        final screenWidth = MediaQuery.of(context).size.width;
        final rotation = calculateRotation(_dragOffset, screenWidth);
        final progress = calculateDragProgress(_dragOffset, screenWidth);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                SwipeQuotaHeader(
                  swipesRemaining: quota.swipesRemaining,
                  superLikesRemaining: quota.superLikesRemaining,
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: SwipeCardStack(
                    item: item,
                    compatibility: compatibility,
                    nextItem: nextItem,
                    nextCompatibility: nextCompatibility,
                    dragOffset: _dragOffset,
                    dragProgress: progress,
                    currentRotation: rotation,
                    cardScaleAnimation: _cardScaleAnimation,
                    isDragging: _isDragging,
                    isExpanded: _isExpanded,
                    onTap: () {
                      if (!_isAnimating) {
                        _toggleExpanded(item);
                      }
                    },
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                  ),
                ),
                SwipeActionBar(
                  onPass: () =>
                      _swipeDebouncer.run(() => _handleActionButton('pass')),
                  onSuperLike: () => _swipeDebouncer.run(
                    () => _handleActionButton('super_like'),
                  ),
                  onLike: () =>
                      _swipeDebouncer.run(() => _handleActionButton('like')),
                  isAnimating: _isAnimating,
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
          onRetry: () => ref.invalidate(swipeProfilesProvider),
        ),
      ),
    );
  }

  Future<void> _handleActionButton(String action) async {
    if (_isAnimating) return;

    HapticFeedback.lightImpact();

    final quota = ref.read(swipeQuotaControllerProvider);
    if (action == 'super_like' && quota.superLikesRemaining <= 0) {
      final locale = AppLocalizations.of(context);
      _showSnack(locale.superLikeCapLabel(0));
      return;
    }

    if (quota.isCapped) {
      final locale = AppLocalizations.of(context);
      _showSnack(locale.swipeCounterLabel(0));
      return;
    }

    switch (action) {
      case 'like':
        _flyOffDirectionX = 1;
        _flyOffDirectionY = 0;
        break;
      case 'pass':
        _flyOffDirectionX = -1;
        _flyOffDirectionY = 0;
        break;
      case 'super_like':
        _flyOffDirectionX = 0;
        _flyOffDirectionY = -1;
        break;
    }

    _flyOffStartOffset = Offset.zero;
    _dragOffset = Offset.zero;
    _isButtonTriggered = true;
    setState(() { _isAnimating = true; });

    _flyOffController.removeListener(_onFlyOffTick);
    _flyOffController.removeStatusListener(_onFlyOffStatus);
    _flyOffController.addListener(_onFlyOffTick);
    _flyOffController.addStatusListener(_onFlyOffStatus);
    _flyOffController.forward(from: 0);
  }
}
