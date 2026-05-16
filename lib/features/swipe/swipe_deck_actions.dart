part of 'swipe_deck_page.dart';

extension _SwipeDeckActions on _SwipeDeckPageState {
  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    _beginButtonFlyOff();

    _flyOffController.removeListener(_onFlyOffTick);
    _flyOffController.removeStatusListener(_onFlyOffStatus);
    _flyOffController.addListener(_onFlyOffTick);
    _flyOffController.addStatusListener(_onFlyOffStatus);
    _flyOffController.forward(from: 0);
  }
}
