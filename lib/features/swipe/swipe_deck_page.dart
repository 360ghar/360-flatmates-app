import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/compatibility/compatibility_engine.dart';
import '../../core/compatibility/compatibility_ring.dart';
import '../../core/utils/debouncer.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'match_celebration_screen.dart';
import 'swipe_repository.dart';

class SwipeDeckPage extends ConsumerStatefulWidget {
  const SwipeDeckPage({super.key});

  @override
  ConsumerState<SwipeDeckPage> createState() => _SwipeDeckPageState();
}

class _SwipeDeckPageState extends ConsumerState<SwipeDeckPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isExpanded = false;
  bool _isAnimating = false;
  int _superLikesRemaining = 3;
  int _swipesToday = 0;
  static const _swipesPerDayCap = 100;
  final _swipeDebouncer = ActionDebouncer(duration: const Duration(milliseconds: 300));

  // --- Swipe gesture state ---
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  // Animation controllers
  late final AnimationController _flyOffController;
  late final AnimationController _snapBackController;
  late final AnimationController _cardEntranceController;

  // Fly-off animation values
  Offset _flyOffStartOffset = Offset.zero;
  late Animation<double> _flyOffAnimation;

  // Snap-back animation values
  Offset _snapBackStartOffset = Offset.zero;
  late Animation<double> _snapBackAnimation;

  // Card entrance animation
  late Animation<double> _cardScaleAnimation;

  // Direction for fly-off: 1 = right, -1 = left, 0 = up (super like)
  int _flyOffDirectionX = 0;
  int _flyOffDirectionY = 0;

  static const double _maxRotationDegrees = 15;
  static const Duration _snapBackDuration = Duration(milliseconds: 300);
  static const Duration _flyOffDuration = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();

    // Fly-off controller (card exits screen)
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

    // Snap-back controller (card returns to center)
    _snapBackController = AnimationController(
      vsync: this,
      duration: _snapBackDuration,
    );
    _snapBackAnimation = CurvedAnimation(
      parent: _snapBackController,
      curve: Curves.easeOut,
    );
    _snapBackController.addListener(_onSnapBackTick);

    // Card entrance controller (next card scales up)
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
    _flyOffController.dispose();
    _snapBackController.dispose();
    _cardEntranceController.dispose();
    super.dispose();
  }

  // --- Gesture handlers ---

  void _onPanStart(DragStartDetails details) {
    if (_isAnimating || _isExpanded) return;
    _snapBackController.stop();
    setState(() {
      _isDragging = true;
      _dragOffset = Offset.zero;
    });
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
    final dx = _dragOffset.dx;

    // Check for super like (upward swipe)
    if (_dragOffset.dy < -threshold) {
      _triggerFlyOff(superLike: true);
      return;
    }

    // Check for left/right swipe
    if (dx.abs() > threshold) {
      _triggerFlyOff(superLike: false);
      return;
    }

    // Snap back to center
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
    // Determine direction
    if (superLike) {
      _flyOffDirectionX = 0;
      _flyOffDirectionY = -1;
    } else {
      _flyOffDirectionX = _dragOffset.dx > 0 ? 1 : -1;
      _flyOffDirectionY = 0;
    }

    _flyOffStartOffset = _dragOffset;

    _isAnimating = true;
    _flyOffController.forward(from: 0);
  }

  void _onFlyOffTick() {
    final t = _flyOffAnimation.value;
    final screenSize = MediaQuery.of(context).size;

    final targetOffset = Offset(
      _flyOffDirectionX != 0 ? _flyOffDirectionX * screenSize.width * 1.5 : 0.0,
      _flyOffDirectionY != 0 ? _flyOffDirectionY * screenSize.height * 1.5 : 0.0,
    );

    setState(() {
      _dragOffset = Offset.lerp(_flyOffStartOffset, targetOffset, t)!;
    });
  }

  void _onFlyOffStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    // Determine the action from the fly-off direction
    String action;
    if (_flyOffDirectionY < 0) {
      action = 'super_like';
    } else if (_flyOffDirectionX > 0) {
      action = 'like';
    } else {
      action = 'pass';
    }

    // Reset drag state before processing
    _flyOffController.removeListener(_onFlyOffTick);
    _flyOffController.removeStatusListener(_onFlyOffStatus);

    setState(() {
      _dragOffset = Offset.zero;
    });

    // Process the swipe action (API call, state update)
    _processSwipeAction(action);
  }

  Future<void> _processSwipeAction(String action) async {
    // Check caps
    if (action == 'super_like' && _superLikesRemaining <= 0) {
      if (!mounted) return;
      final locale = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.superLikeCapLabel(0))),
      );
      _resetAfterSwipe();
      return;
    }

    if (_swipesToday >= _swipesPerDayCap) {
      if (!mounted) return;
      final locale = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.swipeCounterLabel(0))),
      );
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

    // Haptic feedback on completed swipe
    HapticFeedback.mediumImpact();

    SwipeResult? swipeResult;
    try {
      swipeResult = await ref.read(swipeRepositoryProvider).swipeProfile(
            targetUserId: item.id,
            action: action,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? e.error.toString()
                  : 'Action failed. Please try again.',
            ),
          ),
        );
      }
      _resetAfterSwipe();
      return;
    }

    if (!mounted) return;

    setState(() {
      _currentIndex++;
      _isExpanded = false;
      _swipesToday++;
      if (action == 'super_like') _superLikesRemaining--;
    });

    // Show match celebration if a mutual like was detected
    final isLikeAction = action == 'like' || action == 'super_like';
    if (isLikeAction && swipeResult.didMatch) {
      _showMatchCelebration(
        peerName: item.fullName ?? 'Flatmate',
        peerImageUrl: item.profileImageUrl,
        conversationId: swipeResult.conversationId,
      );
    }

    // Animate next card entrance
    _cardEntranceController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    });

    // Re-attach listeners
    _flyOffController.addListener(_onFlyOffTick);
    _flyOffController.addStatusListener(_onFlyOffStatus);

    ref.invalidate(swipeProfilesProvider);
  }

  void _showMatchCelebration({
    required String peerName,
    required String? peerImageUrl,
    required int? conversationId,
  }) {
    final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
    final userProfile = bootstrap?.profile;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchCelebrationScreen(
          userName: userProfile?.fullName ?? 'You',
          userImageUrl: userProfile?.profileImageUrl,
          peerName: peerName,
          peerImageUrl: peerImageUrl,
          onOpenChat: () {
            Navigator.of(context).pop();
            if (conversationId != null) {
              context.push('/chats/$conversationId');
            } else {
              context.go('/chats');
            }
          },
          onKeepSwiping: () => Navigator.of(context).pop(),
        ),
        fullscreenDialog: true,
      ),
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

  double get _currentRotation {
    if (_dragOffset.dx == 0) return 0;
    final screenWidth = MediaQuery.of(context).size.width;
    // Rotation proportional to horizontal drag, max _maxRotationDegrees
    final rotationFactor = (_dragOffset.dx / screenWidth).clamp(-1.0, 1.0);
    return rotationFactor * _maxRotationDegrees * 3.14159265 / 180;
  }

  double get _dragProgress {
    // 0.0 at center, 1.0 at threshold distance
    final screenWidth = MediaQuery.of(context).size.width;
    return (_dragOffset.dx.abs() / (screenWidth * 0.20)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(swipeProfilesProvider);
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return profiles.when(
      data: (items) {
        if (items.isEmpty) {
          return Scaffold(
            body: Center(child: Text(locale.emptySwipeDeck)),
          );
        }

        final userProfile = bootstrap.valueOrNull?.profile;
        final visible = items.where((i) => i.id != userProfile?.id).toList();

        if (visible.isEmpty || _currentIndex >= visible.length) {
          return Scaffold(
            body: Center(child: Text(locale.emptySwipeDeck)),
          );
        }

        final item = visible[_currentIndex];
        final compatibility = CompatibilityEngine.calculate(
          user: {
            'sleep_schedule': userProfile?.sleepSchedule ?? 'flexible',
            'cleanliness': userProfile?.cleanliness ?? 'tidy',
            'food_habits': userProfile?.foodHabits ?? 'no_preference',
            'smoking_drinking': userProfile?.smokingDrinking ?? 'neither',
            'guests_policy': userProfile?.guestsPolicy ?? 'occasional_ok',
            'work_style': userProfile?.workStyle ?? 'hybrid',
          },
          peer: {
            'sleep_schedule': item.sleepSchedule ?? 'flexible',
            'cleanliness': item.cleanliness ?? 'tidy',
            'food_habits': item.foodHabits ?? 'no_preference',
            'smoking_drinking': item.smokingDrinking ?? 'neither',
            'guests_policy': item.guestsPolicy ?? 'occasional_ok',
            'work_style': item.workStyle ?? 'hybrid',
          },
        );

        // Compute next card compatibility if available
        final hasNextCard = _currentIndex + 1 < visible.length;
        final nextItem = hasNextCard ? visible[_currentIndex + 1] : null;
        final nextCompatibility = hasNextCard
            ? CompatibilityEngine.calculate(
                user: {
                  'sleep_schedule': userProfile?.sleepSchedule ?? 'flexible',
                  'cleanliness': userProfile?.cleanliness ?? 'tidy',
                  'food_habits': userProfile?.foodHabits ?? 'no_preference',
                  'smoking_drinking': userProfile?.smokingDrinking ?? 'neither',
                  'guests_policy': userProfile?.guestsPolicy ?? 'occasional_ok',
                  'work_style': userProfile?.workStyle ?? 'hybrid',
                },
                peer: {
                  'sleep_schedule': nextItem!.sleepSchedule ?? 'flexible',
                  'cleanliness': nextItem.cleanliness ?? 'tidy',
                  'food_habits': nextItem.foodHabits ?? 'no_preference',
                  'smoking_drinking': nextItem.smokingDrinking ?? 'neither',
                  'guests_policy': nextItem.guestsPolicy ?? 'occasional_ok',
                  'work_style': nextItem.workStyle ?? 'hybrid',
                },
              )
            : null;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const FlatmatesLogo(compact: true),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            locale.swipeCounterLabel(_swipesPerDayCap - _swipesToday),
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locale.superLikeCapLabel(_superLikesRemaining),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildCardStack(
                    item: item,
                    compatibility: compatibility,
                    nextItem: nextItem,
                    nextCompatibility: nextCompatibility,
                  ),
                ),
                _ActionBar(
                  onPass: () => _swipeDebouncer.run(() => _handleActionButton('pass')),
                  onSuperLike: () => _swipeDebouncer.run(() => _handleActionButton('super_like')),
                  onLike: () => _swipeDebouncer.run(() => _handleActionButton('like')),
                  isAnimating: _isAnimating,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
    );
  }

  Widget _buildCardStack({
    required SwipeProfile item,
    required CompatibilityResult compatibility,
    required SwipeProfile? nextItem,
    required CompatibilityResult? nextCompatibility,
  }) {
    final progress = _dragProgress;

    // Background card (next card) - slightly scaled and offset behind
    final Widget backgroundCard = nextItem != null && nextCompatibility != null
        ? Positioned(
            top: 8,
            left: 20,
            right: 20,
            bottom: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.5 + 0.5 * progress,
                child: Transform.scale(
                  scale: 0.92 + 0.08 * progress,
                  child: _CollapsedCard(
                    item: nextItem,
                    compatibility: nextCompatibility,
                  ),
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    // Current card (topmost, draggable)
    final Widget currentCard = Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTap: () {
          if (!_isAnimating) {
            setState(() => _isExpanded = !_isExpanded);
          }
        },
        child: AnimatedBuilder(
          animation: _cardScaleAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: _dragOffset,
              child: Transform.rotate(
                angle: _currentRotation,
                child: Transform.scale(
                  scale: _cardScaleAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08 + 0.15 * progress),
                          blurRadius: 12 + 20 * progress,
                          spreadRadius: 2 + 6 * progress,
                          offset: Offset(0, 4 + 8 * progress),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: _isExpanded
              ? _ExpandedCard(
                  item: item,
                  compatibility: compatibility,
                )
              : _CollapsedCard(
                  item: item,
                  compatibility: compatibility,
                ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        backgroundCard,
        currentCard,
      ],
    );
  }

  Future<void> _handleActionButton(String action) async {
    if (_isAnimating) return;

    // Haptic feedback on action bar button press
    HapticFeedback.lightImpact();

    if (action == 'super_like' && _superLikesRemaining <= 0) {
      final locale = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.superLikeCapLabel(0))),
      );
      return;
    }

    if (_swipesToday >= _swipesPerDayCap) {
      final locale = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.swipeCounterLabel(0))),
      );
      return;
    }

    // Determine fly-off direction
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

    setState(() {
      _isAnimating = true;
    });

    // Detach listeners during button-triggered fly-off so we control the flow
    _flyOffController.removeListener(_onFlyOffTick);
    _flyOffController.removeStatusListener(_onFlyOffStatus);
    _flyOffController.addListener(_onButtonFlyOffTick);
    _flyOffController.addStatusListener(_onButtonFlyOffStatus);
    _flyOffController.forward(from: 0);
  }

  void _onButtonFlyOffTick() {
    final t = _flyOffAnimation.value;
    final screenSize = MediaQuery.of(context).size;

    final targetOffset = Offset(
      _flyOffDirectionX != 0 ? _flyOffDirectionX * screenSize.width * 1.5 : 0.0,
      _flyOffDirectionY != 0 ? _flyOffDirectionY * screenSize.height * 1.5 : 0.0,
    );

    setState(() {
      _dragOffset = Offset.lerp(Offset.zero, targetOffset, t)!;
    });
  }

  void _onButtonFlyOffStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    // Determine the action
    String action;
    if (_flyOffDirectionY < 0) {
      action = 'super_like';
    } else if (_flyOffDirectionX > 0) {
      action = 'like';
    } else {
      action = 'pass';
    }

    _flyOffController.removeListener(_onButtonFlyOffTick);
    _flyOffController.removeStatusListener(_onButtonFlyOffStatus);

    setState(() {
      _dragOffset = Offset.zero;
    });

    // Process the swipe action
    _processSwipeAction(action);
  }
}

class _CollapsedCard extends StatelessWidget {
  const _CollapsedCard({
    required this.item,
    required this.compatibility,
  });

  final SwipeProfile item;
  final CompatibilityResult compatibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: item.profileImageUrl != null
                          ? Image.network(
                              item.profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _PhotoFallback(name: item.fullName),
                            )
                          : _PhotoFallback(name: item.fullName),
                    ),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: InfoPill(
                        label: localizedFlatmatesModeLabel(locale, item.mode ?? 'open_to_both'),
                        highlighted: true,
                      ),
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: CompatibilityRing(percentage: compatibility.percentage, size: 56),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.fullName ?? '', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              [item.locality, item.city].whereType<String>().join(', '),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        if (item.budgetMin != null || item.budgetMax != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '₹${(item.budgetMin ?? 0).toStringAsFixed(0)} - ₹${(item.budgetMax ?? 100000).toStringAsFixed(0)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: compatibility.topMatchChips.map((chip) {
                  return InfoPill(icon: Icons.check_circle_outline, label: chip);
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    locale.tapToSeeMore,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedCard extends StatelessWidget {
  const _ExpandedCard({
    required this.item,
    required this.compatibility,
  });

  final SwipeProfile item;
  final CompatibilityResult compatibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final details = item.listingDetails;

    // Helpers to read typed values from listingDetails.
    String? str(String key) {
      final v = details[key];
      return v is String ? v : null;
    }

    List<String> strList(String key) {
      final v = details[key];
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    double? dbl(String key) {
      final v = details[key];
      if (v is num) return v.toDouble();
      return null;
    }

    List<Map<String, String>> flatmates() {
      final v = details['existing_flatmates'];
      if (v is! List) return const [];
      return v
          .whereType<Map>()
          .map((m) => Map<String, String>.from(m.map(
              (k, val) => MapEntry(k.toString(), val?.toString() ?? ''))))
          .toList();
    }

    final societyAmenities = strList('society_amenities');
    final societyVibes = strList('society_vibes');
    final furnishing = strList('furnishing');
    final roomFeatures = strList('room_features');
    final flatAmenities = strList('flat_amenities');
    final existingFlatmates = flatmates();

    final monthlyRent = dbl('monthly_rent') ?? item.budgetMin;
    final securityDeposit = dbl('security_deposit');
    final maintenance = dbl('maintenance');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Header row: avatar + name + compatibility
            Row(
              children: [
                FlatmatesAvatar(name: item.fullName, imageUrl: item.profileImageUrl, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.fullName ?? '', style: theme.textTheme.headlineMedium),
                      InfoPill(
                        label: localizedFlatmatesModeLabel(locale, item.mode ?? 'open_to_both'),
                        highlighted: true,
                      ),
                    ],
                  ),
                ),
                CompatibilityRing(percentage: compatibility.percentage),
              ],
            ),
            const SizedBox(height: 20),

            // About Me
            FlatmatesSectionHeader(title: locale.aboutMeSection),
            const SizedBox(height: 8),
            if (item.bio != null && item.bio!.isNotEmpty)
              Text(item.bio!, style: theme.textTheme.bodyLarge)
            else
              Text(locale.noBioYet, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),

            // Compatibility Breakdown
            FlatmatesSectionHeader(title: locale.compatibilityBreakdown),
            const SizedBox(height: 12),
            CompatibilityBreakdown(result: compatibility),
            const SizedBox(height: 20),

            // --- The Society ---
            FlatmatesSectionHeader(title: locale.societySectionTitle),
            const SizedBox(height: 8),
            if (item.locality != null || item.city != null)
              _DetailRow(
                icon: Icons.location_on_outlined,
                text: [item.locality, item.city].whereType<String>().join(', '),
              ),
            if (str('society_name') != null)
              _DetailRow(
                icon: Icons.apartment_outlined,
                text: str('society_name')!,
              ),
            if (societyAmenities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: societyAmenities.map((a) => InfoPill(
                    icon: Icons.check_circle_outline,
                    label: humanizeFlatmatesToken(a),
                  )).toList(),
                ),
              ),
            if (societyVibes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: societyVibes.map((v) => InfoPill(
                    icon: Icons.wb_sunny_outlined,
                    label: humanizeFlatmatesToken(v),
                  )).toList(),
                ),
              ),
            if (item.locality == null &&
                item.city == null &&
                str('society_name') == null &&
                societyAmenities.isEmpty &&
                societyVibes.isEmpty)
              Text(locale.notAvailable, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),

            // --- The Room ---
            FlatmatesSectionHeader(title: locale.roomSectionTitle),
            const SizedBox(height: 8),
            if (str('room_type') != null)
              _DetailRow(
                icon: Icons.bed_outlined,
                text: humanizeFlatmatesToken(str('room_type')!),
              ),
            if (furnishing.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: furnishing.map((f) => InfoPill(
                    icon: Icons.chair_outlined,
                    label: humanizeFlatmatesToken(f),
                  )).toList(),
                ),
              ),
            if (roomFeatures.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: roomFeatures.map((f) => InfoPill(
                    icon: Icons.window_outlined,
                    label: humanizeFlatmatesToken(f),
                  )).toList(),
                ),
              ),
            if (str('room_type') == null &&
                furnishing.isEmpty &&
                roomFeatures.isEmpty)
              Text(locale.notAvailable, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),

            // --- The Flat & Flatmates ---
            FlatmatesSectionHeader(title: locale.flatAndFlatmatesSectionTitle),
            const SizedBox(height: 8),
            if (str('flat_config') != null)
              _DetailRow(
                icon: Icons.home_outlined,
                text: str('flat_config')!,
              ),
            if (str('floor') != null)
              _DetailRow(
                icon: Icons.stairs_outlined,
                text: str('floor')!,
              ),
            if (flatAmenities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: flatAmenities.map((a) => InfoPill(
                    icon: Icons.kitchen_outlined,
                    label: humanizeFlatmatesToken(a),
                  )).toList(),
                ),
              ),
            if (existingFlatmates.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(locale.existingFlatmatesLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 8),
              ...existingFlatmates.map((fm) => _FlatmateMiniProfile(
                    name: fm['name'] ?? '',
                    profession: fm['profession'] ?? '',
                    lifestyleChips: fm['lifestyle_chips']
                            ?.split(',')
                            .where((c) => c.trim().isNotEmpty)
                            .toList() ??
                        const [],
                  )),
            ],
            if (str('flat_config') == null &&
                flatAmenities.isEmpty &&
                existingFlatmates.isEmpty)
              Text(locale.notAvailable, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),

            // --- Costs Breakdown ---
            FlatmatesSectionHeader(title: locale.costsBreakdownSectionTitle),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    if (monthlyRent != null)
                      _CostRow(
                        label: locale.monthlyRentRow,
                        value: '₹${monthlyRent.toStringAsFixed(0)}',
                      ),
                    if (securityDeposit != null)
                      _CostRow(
                        label: locale.securityDepositRow,
                        value: '₹${securityDeposit.toStringAsFixed(0)}',
                      ),
                    if (maintenance != null)
                      _CostRow(
                        label: locale.maintenanceRow,
                        value: '₹${maintenance.toStringAsFixed(0)}',
                      ),
                    if (monthlyRent != null) ...[
                      const Divider(height: 20),
                      _CostRow(
                        label: locale.estimatedTotalRow,
                        value:
                            '₹${(monthlyRent + (maintenance ?? 0)).toStringAsFixed(0)}',
                        isBold: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Budget (original section, kept for budget range)
            if (item.budgetMin != null || item.budgetMax != null) ...[
              FlatmatesSectionHeader(title: locale.budgetLabel),
              const SizedBox(height: 8),
              InfoPill(
                icon: Icons.currency_rupee_rounded,
                label:
                    '₹${(item.budgetMin ?? 0).toStringAsFixed(0)} - ₹${(item.budgetMax ?? 100000).toStringAsFixed(0)}/mo',
              ),
              const SizedBox(height: 20),
            ],
            if (item.moveInTimeline != null) ...[
              InfoPill(
                icon: Icons.event_outlined,
                label: localizedFlatmatesMoveInTimeline(locale, item.moveInTimeline!),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  locale.tapToCollapse,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Single icon + text row used inside expanded card sections.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Cost row with label on left and value on right.
class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });
  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
          )),
          Text(value, style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: isBold ? theme.colorScheme.primary : null,
          )),
        ],
      ),
    );
  }
}

/// Mini profile card for an existing flatmate shown in the expanded card.
class _FlatmateMiniProfile extends StatelessWidget {
  const _FlatmateMiniProfile({
    required this.name,
    required this.profession,
    required this.lifestyleChips,
  });
  final String name;
  final String profession;
  final List<String> lifestyleChips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          FlatmatesAvatar(name: name, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
                if (profession.isNotEmpty)
                  Text(profession, style: theme.textTheme.bodySmall),
                if (lifestyleChips.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: lifestyleChips.map((c) => InfoPill(label: c)).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onPass,
    required this.onSuperLike,
    required this.onLike,
    required this.isAnimating,
  });

  final VoidCallback onPass;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;
  final bool isAnimating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            key: const Key('swipe_pass'),
            icon: Icons.close_rounded,
            color: const Color(0xFFFF6B6B),
            size: 60,
            onPressed: isAnimating ? null : onPass,
          ),
          _ActionButton(
            key: const Key('swipe_super_like'),
            icon: Icons.star_rounded,
            color: Theme.of(context).colorScheme.tertiary,
            size: 50,
            onPressed: isAnimating ? null : onSuperLike,
          ),
          _ActionButton(
            key: const Key('swipe_like'),
            icon: Icons.favorite_rounded,
            color: const Color(0xFF10B981),
            size: 60,
            onPressed: isAnimating ? null : onLike,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Icon(icon, color: color, size: size * 0.45),
        ),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.9),
            theme.colorScheme.primary.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initialsFromName(name),
          style: theme.textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontSize: 48,
          ),
        ),
      ),
    );
  }
}

String localizedFlatmatesMoveInTimeline(AppLocalizations locale, String value) {
  switch (value.trim().toLowerCase()) {
    case 'immediate':
      return locale.timelineImmediate;
    case 'this_month':
      return locale.timelineThisMonth;
    case 'next_month':
      return locale.timelineNextMonth;
    case 'flexible':
      return locale.timelineFlexible;
    default:
      return humanizeFlatmatesToken(value);
  }
}
