part of 'swipe_deck_page.dart';

extension _SwipeDeckActions on _SwipeDeckPageState {
  Widget _scaffoldWithHeader(Widget body, {VoidCallback? onSafetyMenu}) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                0,
              ),
              child: SwipeDeckHeader(onSafetyMenu: onSafetyMenu),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

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

  List<ChatReportReason> _reportReasons() {
    final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
    final catalogOptions = bootstrap?.catalogOptions(
      'flatmates_report_reasons',
    );
    if (catalogOptions != null && catalogOptions.isNotEmpty) {
      return catalogOptions
          .map(
            (opt) => ChatReportReason(value: opt.id, catalogLabel: opt.label),
          )
          .toList();
    }
    return ChatReportReason.defaults();
  }

  void _showSafetyMenu() {
    final profile = _currentProfile();
    if (profile == null) return;
    final locale = AppLocalizations.of(context);
    FlatmatesBottomSheet.show(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('swipe_report'),
              leading: const Icon(Icons.flag_outlined),
              title: Text(locale.reportCta),
              onTap: () {
                Navigator.pop(ctx);
                unawaited(_reportCurrentProfile(profile.id));
              },
            ),
            ListTile(
              key: const Key('swipe_block'),
              leading: const Icon(
                Icons.block_outlined,
                color: AppSemanticColors.error,
              ),
              title: Text(
                locale.blockCta,
                style: const TextStyle(color: AppSemanticColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                unawaited(_blockCurrentProfile(profile.id));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportCurrentProfile(int peerId) async {
    if (!mounted) return;
    await ChatDialogs.showReportDialog(
      context: context,
      peerId: peerId,
      reasons: _reportReasons(),
      controller: ref.read(chatActionsControllerProvider),
    );
  }

  Future<void> _blockCurrentProfile(int peerId) async {
    if (!mounted) return;
    final blocked = await ChatDialogs.showBlockDialog(
      context: context,
      peerId: peerId,
      controller: ref.read(chatActionsControllerProvider),
      popOnSuccess: false,
    );
    if (!blocked || !mounted) return;
    ref.read(swipeDeckControllerProvider.notifier).removeProfile(peerId);
    _trackedProfileId = null;
    _pendingSwipe = null;
    _interaction.value = const SwipeInteractionState();
  }
}
