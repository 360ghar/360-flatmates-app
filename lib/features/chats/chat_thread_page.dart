import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/storage/image_upload_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/debouncer.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/components.dart';
import '../visits/visits_repository.dart';
import 'chats_repository.dart';
import 'domain/chat_report_reason.dart';
import 'match_qna_nudge.dart';
import 'presentation/chat_visit_actions.dart';
import 'presentation/widgets/chat_app_bar.dart';
import 'presentation/widgets/chat_dialogs.dart';
import 'presentation/widgets/chat_input_area.dart';
import 'presentation/widgets/chat_pre_message_area.dart';
import 'presentation/widgets/message_list.dart';
import 'presentation/widgets/chat_property_card.dart';
import 'presentation/widgets/chat_qna_answers_card.dart';

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
  bool _hasSentFirstMessage = false;
  bool _showQnANudge = false;
  bool _propertyCardExpanded = true;
  ConversationSummaryModel? _conversation;
  final _sendDebouncer = ActionDebouncer(
    duration: const Duration(milliseconds: 300),
  );

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _checkExistingMessages();
    _markMessagesAsRead();
  }

  @override
  void didUpdateWidget(ChatThreadPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _conversation = widget.conversation;
      _checkExistingMessages();
      _markMessagesAsRead();
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

  @override
  void dispose() {
    _messageController.dispose();
    _sendDebouncer.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await ref
          .read(chatsRepositoryProvider)
          .markMessagesAsRead(widget.conversationId);
    } catch (_) {}
  }

  Future<void> _scheduleVisit() async {
    final conversation = _conversation;
    if (conversation?.contextProperty == null) return;
    await context.push(
      '/schedule-visit?conversationId=${widget.conversationId}',
      extra: conversation,
    );
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    if (body.isEmpty) return;
    final locale = AppLocalizations.of(context);
    final previousText = _messageController.text;
    final previousSelection = _messageController.selection;
    _messageController.clear();
    try {
      await ref
          .read(chatsRepositoryProvider)
          .sendMessage(conversationId: widget.conversationId, body: body);
      setState(() => _hasSentFirstMessage = true);
      ref.invalidate(conversationsProvider);
    } catch (_) {
      _messageController.text = previousText;
      _messageController.selection = previousSelection;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locale.failedToSendMessage)));
      }
    }
  }

  Future<void> _sendPhoto() async {
    final service = ref.read(imageUploadServiceProvider);
    final locale = AppLocalizations.of(context);
    final files = await service.pickImages(limit: 1);
    if (files.isEmpty) return;

    try {
      final result = await service.uploadChatPhoto(files.first);
      if (result is! UploadSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(locale.failedToSendPhoto)));
        }
        return;
      }
      await ref
          .read(chatsRepositoryProvider)
          .sendMessage(
            conversationId: widget.conversationId,
            body: null,
            attachmentUrl: result.url,
            messageType: 'image',
          );
      setState(() => _hasSentFirstMessage = true);
      ref.invalidate(conversationsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locale.failedToSendPhoto)));
      }
    }
  }

  Future<void> _blockUser() async {
    final peerId = _conversation?.peer.id;
    if (peerId == null) return;
    await ChatDialogs.showBlockDialog(
      context: context,
      peerId: peerId,
      repository: ref.read(chatsRepositoryProvider),
    );
  }

  Future<void> _reportUser() async {
    final peerId = _conversation?.peer.id;
    if (peerId == null) return;
    await ChatDialogs.showReportDialog(
      context: context,
      peerId: peerId,
      reasons: _reportReasons,
      repository: ref.read(chatsRepositoryProvider),
    );
  }

  Future<void> _unmatch() async {
    final peerId = _conversation?.peer.id;
    if (peerId == null) return;
    await ChatDialogs.showUnmatchDialog(
      context: context,
      conversationId: widget.conversationId,
      peerId: peerId,
      repository: ref.read(chatsRepositoryProvider),
    );
  }

  Future<void> _submitQnA(Map<String, String> answers) async {
    ConversationSummaryModel? updatedConversation;
    try {
      final repository = ref.read(chatsRepositoryProvider);
      await repository.submitQnA(widget.conversationId, answers);
      updatedConversation = await repository.fetchConversation(
        widget.conversationId,
      );
    } catch (_) {}
    _markQnANudgeDismissed();
    if (mounted) {
      setState(() {
        _showQnANudge = false;
        if (updatedConversation != null) {
          _conversation = updatedConversation;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locale.phoneNotAvailable)));
      }
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.phoneNotAvailable)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesStreamProvider(widget.conversationId));
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

    ref.listen(messagesStreamProvider(widget.conversationId), (prev, next) {
      final msgs = next.valueOrNull;
      if (msgs != null && msgs.isNotEmpty) {
        final hasSent = msgs.any((m) => m.senderId == currentUserId);
        if (hasSent != _hasSentFirstMessage) {
          setState(() => _hasSentFirstMessage = hasSent);
        }
      }
    });

    if (_conversation == null && fetchedConversation != null) {
      if (fetchedConversation.isLoading) {
        return const FlatmatesScreen(
          useSafeArea: true,
          body: Center(child: FlatmatesSkeleton.card()),
        );
      }
      if (fetchedConversation.hasError) {
        return FlatmatesScreen(
          useSafeArea: true,
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
      useSafeArea: true,
      appBar: ChatAppBar(
        conversationId: widget.conversationId,
        conversation: conversation,
        reportReasons: _reportReasons,
        onBlock: _blockUser,
        onReport: _reportUser,
        onUnmatch: _unmatch,
        onCall: _handleCall,
        onScheduleVisit: _scheduleVisit,
      ),
      body: Column(
        children: [
          if (conversation?.contextProperty != null && conversation != null)
            ChatPropertyCard(
              conversation: conversation,
              isExpanded: _propertyCardExpanded,
              onToggleExpand: () => setState(
                () => _propertyCardExpanded = !_propertyCardExpanded,
              ),
              onViewListing: () => context.push(
                '/flat-details/${conversation.contextProperty!.id}',
              ),
              onMiniCardTap: () => context.push(
                '/flat-details/${conversation.contextProperty!.id}',
              ),
            ),
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
          if (!_hasSentFirstMessage)
            ChatPreMessageArea(
              showQnANudge: _showQnANudge,
              onQnATap: _showQnABottomSheet,
              icebreakers: _icebreakers,
              onIcebreakerSelected: (prompt) {
                _messageController.text = prompt;
                _sendDebouncer.run(_sendMessage);
              },
            ),
          Expanded(
            child: MessageList(
              messagesAsync: messages,
              currentUserId: currentUserId,
              conversation: conversation,
              visitsAsync: visits,
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
          ChatInputArea(
            controller: _messageController,
            onSend: _sendMessage,
            onAttachment: _sendPhoto,
          ),
        ],
      ),
    );
  }
}
