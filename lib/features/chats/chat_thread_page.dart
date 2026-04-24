import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/storage/image_upload_service.dart';
import '../../core/providers.dart';
import '../../core/utils/debouncer.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../shared/presentation/flatmates_ui.dart';
import '../visits/visits_repository.dart';
import 'chats_repository.dart';
import 'match_qna_nudge.dart';

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
  bool _contextCardExpanded = true;
  Timer? _contextCardCollapseTimer;
  late final Timer _pollTimer;
  final _sendDebouncer = ActionDebouncer(duration: const Duration(milliseconds: 300));

  static const _icebreakers = [
    'Tell me about the room 🏠',
    'What are your flatmates like? 👥',
    'Are you open to negotiating rent? 💰',
    "What's the vibe of the society? 🏘️",
    'What does a typical weekend look like? 🌞',
  ];

  @override
  void initState() {
    super.initState();
    _checkExistingMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      ref.invalidate(messagesProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
    });
    _startContextCardCollapseTimer();
  }

  void _startContextCardCollapseTimer() {
    _contextCardCollapseTimer?.cancel();
    _contextCardCollapseTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _contextCardExpanded = false);
      }
    });
  }

  void _checkExistingMessages() {
    final messages = ref.read(messagesProvider(widget.conversationId)).valueOrNull;
    _hasSentFirstMessage = messages != null && messages.isNotEmpty;
    // Show Q&A nudge for new matches with no messages yet,
    // unless the user already dismissed/completed it for this conversation.
    final isNewMatch = widget.conversation?.source == 'match';
    final prefs = ref.read(appPreferencesProvider);
    final alreadyDismissed = prefs.getBool('qna_nudge_dismissed_${widget.conversationId}');
    _showQnANudge = isNewMatch && !_hasSentFirstMessage && !alreadyDismissed;
  }

  @override
  void dispose() {
    _pollTimer.cancel();
    _contextCardCollapseTimer?.cancel();
    _messageController.dispose();
    _sendDebouncer.dispose();
    super.dispose();
  }

  Future<void> _scheduleVisit(BuildContext context) async {
    final locale = AppLocalizations.of(context);
    final conversation = widget.conversation;
    if (conversation?.contextProperty == null) return;

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 11, minute: 0),
    );
    if (time == null) return;

    final scheduledDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    try {
      await ref
          .read(visitsRepositoryProvider)
          .scheduleFlatmateVisit(
            propertyId: conversation!.contextProperty!.id,
            counterpartyUserId: conversation.peer.id,
            conversationId: conversation.id,
            scheduledDate: scheduledDate,
          );
      ref.invalidate(visitsProvider);

      // Send a visit_request message into the chat
      try {
        await ref.read(chatsRepositoryProvider).sendMessage(
              conversationId: widget.conversationId,
              body: 'Visit requested for ${DateFormat('d MMM, h:mm a', locale.localeName).format(scheduledDate.toLocal())}',
              messageType: 'visit_request',
            );
        ref.invalidate(messagesProvider(widget.conversationId));
      } catch (_) {
        // Best-effort: don't fail the whole flow if inline message fails
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.visitRequested)),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? e.error.toString()
                  : 'Failed to schedule visit. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    if (body.isEmpty) return;

    try {
      await ref
          .read(chatsRepositoryProvider)
          .sendMessage(conversationId: widget.conversationId, body: body);
      _messageController.clear();
      setState(() => _hasSentFirstMessage = true);
      ref.invalidate(messagesProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? e.error.toString()
                  : 'Failed to send message. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _sendPhoto() async {
    final service = ref.read(imageUploadServiceProvider);
    final files = await service.pickImages(limit: 1);
    if (files.isEmpty) return;

    try {
      final url = await service.uploadChatPhoto(files.first);
      if (url == null) return;

      await ref.read(chatsRepositoryProvider).sendMessage(
            conversationId: widget.conversationId,
            body: null,
            attachmentUrl: url,
            messageType: 'image',
          );
      setState(() => _hasSentFirstMessage = true);
      ref.invalidate(messagesProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? e.error.toString()
                  : 'Failed to send photo. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _blockUser() async {
    final locale = AppLocalizations.of(context);
    final peerId = widget.conversation?.peer.id;
    if (peerId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.blockConfirmTitle),
        content: Text(locale.blockConfirmMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(locale.cancelCta)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(locale.blockCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(apiClientProvider).post('/flatmates/blocks', data: {
        'blocked_user_id': peerId,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.userBlocked)));
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? e.error.toString()
                  : 'Failed to block user. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _reportUser() async {
    final locale = AppLocalizations.of(context);
    final peerId = widget.conversation?.peer.id;
    if (peerId == null) return;

    String? selectedReason;
    final reasons = [
      locale.reportFakeProfile,
      locale.reportSpam,
      locale.reportInappropriate,
      locale.reportUncomfortable,
      locale.reportOther,
    ];
    final reasonValues = ['fake_profile', 'spam', 'inappropriate', 'uncomfortable', 'other'];

    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(locale.reportTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(reasons.length, (idx) {
              return ListTile(
                title: Text(reasons[idx]),
                leading: Radio<String>(
                  value: reasonValues[idx],
                  groupValue: selectedReason,
                  onChanged: (v) => setDialogState(() => selectedReason = v),
                ),
                onTap: () => setDialogState(() => selectedReason = reasonValues[idx]),
                contentPadding: EdgeInsets.zero,
              );
            }),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(locale.cancelCta)),
            FilledButton(
              onPressed: selectedReason != null
                  ? () => Navigator.pop(ctx, selectedReason)
                  : null,
              child: Text(locale.reportCta),
            ),
          ],
        ),
      ),
    );
    if (confirmed == null || !mounted) return;

    try {
      await ref.read(apiClientProvider).post('/flatmates/reports', data: {
        'reported_user_id': peerId,
        'reason': confirmed,
        'conversation_id': widget.conversationId,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.reportSubmitted)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? e.error.toString()
                  : 'Failed to report user. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _unmatch() async {
    final locale = AppLocalizations.of(context);
    final peerId = widget.conversation?.peer.id;
    if (peerId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.unmatchConfirmTitle),
        content: Text(locale.unmatchConfirmMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(locale.cancelCta)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(locale.unmatchCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(apiClientProvider).post('/flatmates/blocks', data: {
        'blocked_user_id': peerId,
      });
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? e.error.toString()
                  : 'Failed to unmatch. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _submitQnA(Map<String, String> answers) async {
    try {
      await ref.read(apiClientProvider).post(
        '/flatmates/conversations/${widget.conversationId}/qna',
        data: answers,
      );
    } catch (_) {
      // Best-effort; don't block the user if Q&A save fails
    }
    _markQnANudgeDismissed();
    if (mounted) {
      setState(() => _showQnANudge = false);
    }
  }

  void _markQnANudgeDismissed() {
    ref
        .read(appPreferencesProvider)
        .setBool('qna_nudge_dismissed_${widget.conversationId}', true);
  }

  void _showQnABottomSheet() {
    final peerName = widget.conversation?.peer.fullName ?? 'Flatmate';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MatchQnANudge(
        peerName: peerName,
        onComplete: (answers) {
          _submitQnA(answers);
        },
      ),
    ).whenComplete(() {
      // Mark dismissed whether the user completed the Q&A or skipped it
      _markQnANudgeDismissed();
      if (mounted) {
        setState(() => _showQnANudge = false);
      }
    });
  }

  void _showChatMenu() {
    final locale = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(locale.reportCta),
              onTap: () {
                Navigator.pop(ctx);
                _reportUser();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_off_outlined),
              title: Text(locale.unmatchCta),
              onTap: () {
                Navigator.pop(ctx);
                _unmatch();
              },
            ),
            ListTile(
              leading: Icon(Icons.block_outlined, color: Theme.of(ctx).colorScheme.error),
              title: Text(locale.blockCta, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                _blockUser();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider(widget.conversationId));
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final conversation = widget.conversation;
    final currentUserId =
        ref.watch(bootstrapControllerProvider).valueOrNull?.profile.id ?? -1;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            FlatmatesAvatar(
              name: conversation?.peer.fullName,
              imageUrl: conversation?.peer.profileImageUrl,
              size: 46,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation?.peer.fullName ?? locale.chatsTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                  if (conversation?.peer.mode != null)
                    Text(
                      localizedFlatmatesModeLabel(
                        locale,
                        conversation!.peer.mode!,
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (conversation?.contextProperty != null)
            IconButton(
              key: const Key('chat_schedule_visit_button'),
              onPressed: () => _scheduleVisit(context),
              icon: const Icon(Icons.event_available_outlined),
            ),
          IconButton(
            key: const Key('chat_more_button'),
            onPressed: _showChatMenu,
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (conversation?.contextProperty != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    setState(() => _contextCardExpanded = !_contextCardExpanded);
                    if (_contextCardExpanded) {
                      _startContextCardCollapseTimer();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                conversation!.contextProperty!.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedRotation(
                              turns: _contextCardExpanded ? 0.0 : -0.25,
                              duration: const Duration(milliseconds: 250),
                              child: Icon(
                                Icons.expand_more_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        AnimatedCrossFade(
                          firstChild: Column(
                            children: [
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (conversation.contextProperty!.mainImageUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.network(
                                        conversation.contextProperty!.mainImageUrl!,
                                        width: 88,
                                        height: 88,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => _PropertyContextFallback(
                                          title: conversation.contextProperty!.title,
                                        ),
                                      ),
                                    )
                                  else
                                    _PropertyContextFallback(
                                      title: conversation.contextProperty!.title,
                                    ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          conversation.contextProperty!.title,
                                          style: theme.textTheme.titleLarge,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (conversation.contextProperty!.monthlyRent !=
                                            null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            locale.monthlyRentLabel(
                                              conversation.contextProperty!.monthlyRent!
                                                  .toStringAsFixed(0),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        OutlinedButton(
                                          onPressed: () => _scheduleVisit(context),
                                          child: Text(locale.scheduleVisitCta),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          secondChild: const SizedBox.shrink(),
                          crossFadeState: _contextCardExpanded
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          duration: const Duration(milliseconds: 300),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!_hasSentFirstMessage)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showQnANudge) ...[
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _showQnABottomSheet,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(
                                Icons.quiz_outlined,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locale.qnaNudgeTitle,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      locale.qnaNudgeSubtitle,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(locale.icebreakerTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _icebreakers.map((prompt) {
                      return ActionChip(
                        label: Text(prompt),
                        onPressed: () {
                          _messageController.text = prompt;
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: messages.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(child: Text(locale.chatReady));
                }
                _hasSentFirstMessage = items.any((m) => m.senderId == currentUserId);
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                locale.todayLabel,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final item = items[index - 1];
                    final isMine = item.senderId == currentUserId;
                    return _MessageBubble(
                      message: item,
                      isMine: isMine,
                      peerName: conversation?.peer.fullName,
                      peerImageUrl: conversation?.peer.profileImageUrl,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                IconButton(
                  key: const Key('chat_photo_button'),
                  onPressed: _sendPhoto,
                  icon: Icon(
                    Icons.photo_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    child: TextField(
                      key: const Key('chat_message_input'),
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: locale.messageHint,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        prefixIcon: Icon(
                          Icons.emoji_emotions_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.82),
                        ],
                      ),
                    ),
                    child: IconButton(
                      key: const Key('chat_send_button'),
                      onPressed: () => _sendDebouncer.run(_sendMessage),
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.peerName,
    required this.peerImageUrl,
  });

  final ChatMessage message;
  final bool isMine;
  final String? peerName;
  final String? peerImageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final time = DateFormat(
      'h:mm a',
      locale.localeName,
    ).format(message.createdAt.toLocal());

    // Visit request card
    if (message.messageType == 'visit_request') {
      return _VisitRequestCard(
        message: message,
        isMine: isMine,
        peerName: peerName,
        peerImageUrl: peerImageUrl,
        time: time,
      );
    }

    // Image message
    if (message.messageType == 'image' && message.attachmentUrl != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: isMine
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!isMine) ...[
              FlatmatesAvatar(name: peerName, imageUrl: peerImageUrl, size: 40),
              const SizedBox(width: 10),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  message.attachmentUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 200,
                    height: 150,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 40,
                      ),
                    ),
                  ),
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200,
                      height: 150,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default text message bubble
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            FlatmatesAvatar(name: peerName, imageUrl: peerImageUrl, size: 40),
            const SizedBox(width: 10),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isMine
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.86),
                        ],
                      )
                    : null,
                color: isMine ? null : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(
                      alpha: isMine ? 0.08 : 0.04,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.body ??
                          AppLocalizations.of(context).messageAttachment,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isMine
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isMine
                                ? Colors.white.withValues(alpha: 0.85)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 6),
                          Icon(
                            message.readAt != null
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 18,
                            color: message.readAt != null
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white.withValues(alpha: 0.85),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitRequestCard extends StatelessWidget {
  const _VisitRequestCard({
    required this.message,
    required this.isMine,
    required this.peerName,
    required this.peerImageUrl,
    required this.time,
  });

  final ChatMessage message;
  final bool isMine;
  final String? peerName;
  final String? peerImageUrl;
  final String time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            FlatmatesAvatar(name: peerName, imageUrl: peerImageUrl, size: 40),
            const SizedBox(width: 10),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 270),
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locale.scheduleVisitCta,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.body ?? locale.visitRequested,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                locale.visitStatusRequested,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          time,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyContextFallback extends StatelessWidget {
  const _PropertyContextFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.88),
            theme.colorScheme.primary.withValues(alpha: 0.34),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initialsFromName(title),
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
