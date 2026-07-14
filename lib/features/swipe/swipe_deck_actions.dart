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
    final locale = AppLocalizations.of(context);
    pushMatchCelebration(
      context,
      userName: userProfile?.fullName ?? locale.matchSelfFallbackName,
      userImageUrl: userProfile?.profileImageUrl,
      peerName: peerName,
      peerImageUrl: peerImageUrl,
      conversationId: conversationId,
    );
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
          .catchError((Object e, _) {
            debugPrint(
              'SwipeDeckPage.recordProfileView ${sample.profileId}: $e',
            );
          }),
    );
  }

  void _resetAfterSwipe() {
    if (!mounted) return;
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
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
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
}
