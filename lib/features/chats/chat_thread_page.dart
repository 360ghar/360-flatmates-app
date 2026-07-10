import 'dart:async';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/debouncer.dart';
import '../../core/utils/profanity_filter.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/components.dart';
import '../visits/visits_repository.dart';
import 'application/chat_actions_controller.dart';
import 'application/messages_controller.dart';
import 'chats_repository.dart';
import 'domain/chat_report_reason.dart';
import 'match_qna_nudge.dart';
import 'presentation/chat_visit_actions.dart';
import 'presentation/widgets/chat_app_bar.dart';
import 'presentation/widgets/chat_dialogs.dart';
import 'presentation/widgets/chat_input_area.dart';
import 'presentation/widgets/chat_pre_message_area.dart';
import 'presentation/widgets/message_list.dart';
import 'presentation/widgets/mode_tooltip_bubble.dart';
import 'presentation/widgets/chat_qna_answers_card.dart';

/// Local UI state: whether the emoji picker is visible above the input bar.
/// AutoDispose so the panel resets when the chat thread leaves the tree.
final _showEmojiPickerProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class ChatThreadPage extends ConsumerStatefulWidget {
  const ChatThreadPage({
    required this.conversationId,
    required this.conversation,
    super.key,
  });

  final int conversationId;
  final ConversationSummaryModel? conversation;

  @override
  ConsumerState<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends ConsumerState<ChatThreadPage> {
  final _messageController = TextEditingController();
  final _messageFocus = FocusNode();
  bool _showQnANudge = false;
  ConversationSummaryModel? _conversation;

  /// Links the floating mode tooltip to the header avatar so the bubble is
  /// anchored (with a tail) directly beneath the peer's avatar.
  final LayerLink _avatarLink = LayerLink();
  OverlayEntry? _modeTooltipEntry;
  Timer? _modeTooltipTimer;
  bool _modeTooltipDismissed = false;

  final _sendDebouncer = ActionDebouncer(
    duration: const Duration(milliseconds: 300),
  );

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _checkExistingMessages();
    _markMessagesAsRead();
    _scheduleModeTooltip();
  }

  @override
  void didUpdateWidget(ChatThreadPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _removeModeTooltip();
      _modeTooltipDismissed = false;
      _conversation = widget.conversation;
      _checkExistingMessages();
      _markMessagesAsRead();
      _scheduleModeTooltip();
    }
  }

  List<String> get _icebreakers {
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogOptions = bootstrap?.catalogOptions('flatmates_icebreakers');
    if (catalogOptions != null && catalogOptions.isNotEmpty) {
      return catalogOptions.map((opt) => opt.label).toList();
    }
    final locale = AppLocalizations.of(context);
    return [
      locale.icebreakerTellMeRoom,
      locale.icebreakerWhatFlatmates,
      locale.icebreakerNegotiateRent,
      locale.icebreakerSocietyVibe,
      locale.icebreakerWeekendLook,
    ];
  }

  List<ChatReportReason> get _reportReasons {
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
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

  void _checkExistingMessages() {
    final isNewMatch =
        _conversation?.source == 'match' ||
        _conversation?.source == 'profile_match';
    final prefs = ref.read(appPreferencesProvider);
    final alreadyDismissed = prefs.getBool(
      'qna_nudge_dismissed_${widget.conversationId}',
    );
    _showQnANudge = isNewMatch && !alreadyDismissed;
  }

  String _peerModeLabel() {
    final asyncConv = ref.read(conversationProvider(widget.conversationId));
    final conv = _conversation ?? asyncConv.valueOrNull;
    final mode = conv?.peer.mode;
    if (mode == null) return '';
    return localizedFlatmatesModeLabel(AppLocalizations.of(context), mode);
  }

  /// Pops the mode/intent tooltip shortly after the screen opens so the
  /// floating bubble doesn't fight the entrance transition. It shows on every
  /// fresh open of the chat (per-instance state, never persisted).
  void _scheduleModeTooltip() {
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted || _modeTooltipDismissed || _modeTooltipEntry != null) {
        return;
      }
      final label = _peerModeLabel();
      if (label.isEmpty) return;
      _insertModeTooltip(label);
    });
  }

  void _insertModeTooltip(String label) {
    final overlay = Overlay.of(context);
    _modeTooltipEntry = OverlayEntry(
      builder: (context) => Positioned(
        // top/left only (no right/bottom) so the overlay Stack gives the
        // follower loose constraints and the bubble sizes to its content
        // instead of stretching to fill the screen.
        top: 0,
        left: 0,
        child: CompositedTransformFollower(
          link: _avatarLink,
          // Anchor the bubble's top-left to the avatar's bottom-left so it
          // sits in the empty space below the header (not overlapping the
          // avatar or the peer name).
          targetAnchor: Alignment.bottomLeft,
          offset: const Offset(0, 8),
          child: ModeTooltipBubble(
            label: label,
            onTapKeepOpen: _keepModeTooltipOpen,
          ),
        ),
      ),
    );
    overlay.insert(_modeTooltipEntry!);
    // Auto-dismiss after a few seconds unless the user taps the bubble.
    _modeTooltipTimer = Timer(const Duration(seconds: 5), _removeModeTooltip);
  }

  void _keepModeTooltipOpen() => _modeTooltipTimer?.cancel();

  void _removeModeTooltip() {
    _modeTooltipTimer?.cancel();
    _modeTooltipTimer = null;
    _modeTooltipEntry?.remove();
    _modeTooltipEntry = null;
    if (mounted) {
      setState(() => _modeTooltipDismissed = true);
    }
  }

  @override
  void dispose() {
    _modeTooltipTimer?.cancel();
    _modeTooltipEntry?.remove();
    _messageController.dispose();
    _messageFocus.dispose();
    _sendDebouncer.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    await ref
        .read(messagesControllerProvider(widget.conversationId).notifier)
        .markAsRead();
  }

  Future<void> _scheduleVisit() async {
    final conversation = _conversation;
    if (conversation?.contextProperty == null) return;
    if (!mounted) return;
    await context.push(
      '/schedule-visit?conversationId=${widget.conversationId}',
      extra: conversation,
    );
  }

  Future<void> _sendMessage() async {
    var body = _messageController.text.trim();
    if (body.isEmpty) return;
    body = ProfanityFilter.censor(body);
    final locale = AppLocalizations.of(context);
    final previousText = _messageController.text;
    final previousSelection = _messageController.selection;
    _messageController.clear();
    try {
      await ref
          .read(messagesControllerProvider(widget.conversationId).notifier)
          .sendMessage(body: body);
      _removeModeTooltip();
    } catch (e) {
      debugPrint('ChatThreadPage._sendMessage failed: $e');
      _messageController.text = previousText;
      _messageController.selection = previousSelection;
      if (mounted) {
        final msg = e is AppFailure
            ? e.userMessage(locale.toUserMessageL10n())
            : locale.failedToSendMessage;
        FlatmatesToast.error(context, msg);
      }
    }
  }

  // TODO: re-enable file upload later. The paperclip/attachment button was
  // removed from the chat input bar for now. The picker + backend upload
  // logic (ImageUploadService.pickImages / uploadChatPhoto) is intentionally
  // kept so re-enabling is just rewiring onAttachment -> _sendPhoto below.
  //
  // Future<void> _sendPhoto() async {
  //   final service = ref.read(imageUploadServiceProvider);
  //   final locale = AppLocalizations.of(context);
  //   final files = await service.pickImages(limit: 1);
  //   if (files.isEmpty) return;
  //   try {
  //     final result = await service.uploadChatPhoto(files.first);
  //     if (result is! UploadSuccess) {
  //       if (mounted) FlatmatesToast.error(context, locale.failedToSendPhoto);
  //       return;
  //     }
  //     await ref
  //         .read(messagesControllerProvider(widget.conversationId).notifier)
  //         .sendMessage(attachmentUrl: result.url, messageType: 'image');
  //   } catch (e) {
  //     debugPrint('ChatThreadPage._sendPhoto failed: $e');
  //     if (mounted) {
  //       final msg = e is AppFailure
  //           ? e.userMessage(locale.toUserMessageL10n())
  //           : locale.failedToSendPhoto;
  //       FlatmatesToast.error(context, msg);
  //     }
  //   }
  // }

  Future<void> _blockUser() async {
    final peerId = _conversation?.peer.id;
    if (peerId == null) return;
    await ChatDialogs.showBlockDialog(
      context: context,
      peerId: peerId,
      controller: ref.read(chatActionsControllerProvider),
    );
  }

  Future<void> _reportUser() async {
    final peerId = _conversation?.peer.id;
    if (peerId == null) return;
    await ChatDialogs.showReportDialog(
      context: context,
      peerId: peerId,
      reasons: _reportReasons,
      controller: ref.read(chatActionsControllerProvider),
    );
  }

  Future<void> _unmatch() async {
    final peerId = _conversation?.peer.id;
    if (peerId == null) return;
    await ChatDialogs.showUnmatchDialog(
      context: context,
      conversationId: widget.conversationId,
      peerId: peerId,
      controller: ref.read(chatActionsControllerProvider),
    );
  }

  Future<void> _submitQnA(Map<String, String> answers) async {
    final updated = await ref
        .read(chatActionsControllerProvider)
        .submitQnA(widget.conversationId, answers);
    _markQnANudgeDismissed();
    if (mounted) {
      setState(() {
        _showQnANudge = false;
        if (updated != null) {
          _conversation = updated;
        }
      });
    }
  }

  void _markQnANudgeDismissed() {
    ref
        .read(appPreferencesProvider)
        .setBool('qna_nudge_dismissed_${widget.conversationId}', true);
  }

  void _showQnABottomSheet() {
    final peerName = _conversation?.peer.fullName ?? 'Flatmate';
    FlatmatesBottomSheet.show(
      context: context,
      isScrollControlled: true,
      builder: (_) => MatchQnANudge(peerName: peerName, onComplete: _submitQnA),
    ).whenComplete(() {
      _markQnANudgeDismissed();
      if (mounted) setState(() => _showQnANudge = false);
    });
  }

  Future<void> _handleCall() async {
    final locale = AppLocalizations.of(context);
    final phone = _conversation?.peer.phoneNumber;
    if (phone != null && phone.isNotEmpty) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        FlatmatesToast.info(context, locale.phoneNotAvailable);
      }
    } else if (mounted) {
      FlatmatesToast.info(context, locale.phoneNotAvailable);
    }
  }

  void _toggleEmojiPicker() {
    final showEmoji = ref.read(_showEmojiPickerProvider);
    if (showEmoji) {
      _messageFocus.requestFocus();
    } else {
      _messageFocus.unfocus();
    }
    ref.read(_showEmojiPickerProvider.notifier).state = !showEmoji;
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(
      messagesControllerProvider(widget.conversationId),
    );
    final visits = ref.watch(visitsProvider);
    final fetchedConversation = _conversation == null
        ? ref.watch(conversationProvider(widget.conversationId))
        : null;
    final locale = AppLocalizations.of(context);
    final conversation = _conversation ?? fetchedConversation?.valueOrNull;
    final currentUserId =
        ref.watch(
          bootstrapControllerProvider.select((s) => s.valueOrNull?.profile.id),
        ) ??
        -1;
    final hasSentFirstMessage = messagesState.displayMessages.any(
      (m) => m.senderId == currentUserId,
    );

    final showEmoji = ref.watch(_showEmojiPickerProvider);

    if (_conversation == null && fetchedConversation != null) {
      if (fetchedConversation.isLoading) {
        return const FlatmatesScreen(body: FlatmatesSkeleton.chatMessages());
      }
      if (fetchedConversation.hasError) {
        return FlatmatesScreen(
          body: FlatmatesErrorState(
            message: locale.errorUnknown,
            onRetry: () =>
                ref.invalidate(conversationProvider(widget.conversationId)),
          ),
        );
      }
      if (conversation != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _conversation != null) return;
          setState(() {
            _conversation = conversation;
            _checkExistingMessages();
          });
        });
      }
    }

    return FlatmatesScreen(
      appBar: ChatAppBar(
        conversation: conversation,
        avatarLink: _avatarLink,
        reportReasons: _reportReasons,
        onBlock: _blockUser,
        onReport: _reportUser,
        onUnmatch: _unmatch,
        onCall: _handleCall,
        onScheduleVisit: _scheduleVisit,
        onPeerTap: conversation == null
            ? null
            : () => context.push(
                '/user-profile/${conversation.peer.id}',
                extra: conversation,
              ),
      ),
      body: Column(
        children: [
          if ((conversation?.qna?.hasAnyAnswers ?? false) &&
              conversation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                0,
              ),
              child: ChatQnAAnswersCard(
                qna: conversation.qna!,
                peerName: conversation.peer.fullName,
                onAnswer: _showQnABottomSheet,
              ),
            ),
          if (!hasSentFirstMessage && _showQnANudge)
            ChatQnANudgeCard(onTap: _showQnABottomSheet),
          Expanded(
            child: MessageList(
              messagesState: messagesState,
              currentUserId: currentUserId,
              conversation: conversation,
              visitsAsync: visits,
              conversationId: widget.conversationId,
              onConfirmVisit: (visit) => confirmVisitFromChat(
                context: context,
                ref: ref,
                visit: visit,
              ),
              onRescheduleVisit: (visit) => rescheduleVisitFromChat(
                context: context,
                ref: ref,
                visit: visit,
              ),
            ),
          ),
          // Suggested messages sit ABOVE the input bar so they're close to the
          // composer. QnA nudge stays near the top (contextual match banner).
          if (!hasSentFirstMessage)
            ChatIcebreakerRow(
              icebreakers: _icebreakers,
              onSelected: (prompt) {
                _messageController.text = prompt;
                _sendDebouncer.run(_sendMessage);
              },
            ),
          ChatInputArea(
            controller: _messageController,
            focusNode: _messageFocus,
            showEmoji: showEmoji,
            onToggleEmoji: _toggleEmojiPicker,
            onSend: _sendMessage,
          ),
          if (showEmoji) EmojiPicker(textEditingController: _messageController),
        ],
      ),
    );
  }
}
