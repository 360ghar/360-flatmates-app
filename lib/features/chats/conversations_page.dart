import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'chats_repository.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  bool _showLikes = true;

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: conversations.when(
          data: (items) {
            final likes = items
                .where(
                  (item) =>
                      (item.lastMessagePreview == null ||
                      item.lastMessagePreview!.isEmpty),
                )
                .toList();
            final chats = items
                .where(
                  (item) =>
                      item.lastMessagePreview != null &&
                      item.lastMessagePreview!.isNotEmpty,
                )
                .toList();
            final visible = _showLikes ? likes : chats;

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(conversationsProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                children: [
                  const FlatmatesLogo(),
                  const SizedBox(height: 18),
                  Text(
                    locale.likesChatTitle,
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SegmentButton(
                            key: const Key('likes_tab_button'),
                            label: locale.likesTabLabel,
                            selected: _showLikes,
                            onTap: () => setState(() => _showLikes = true),
                          ),
                        ),
                        Expanded(
                          child: _SegmentButton(
                            key: const Key('chats_tab_button'),
                            label: locale.chatsTabLabel,
                            selected: !_showLikes,
                            onTap: () => setState(() => _showLikes = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 44),
                      child: Center(
                        child: Text(
                          _showLikes ? locale.emptyLikes : locale.emptyChats,
                        ),
                      ),
                    )
                  else
                    ...visible.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ConversationCard(
                          item: item,
                          highlightMode: _showLikes,
                          onTap: () =>
                              context.push('/chats/${item.id}', extra: item),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      leading: Icon(
                        Icons.shield_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(locale.safetyFirstTitle),
                      subtitle: Text(locale.safetyFirstSubtitle),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/help-safety'),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.82),
                ],
              )
            : null,
        color: selected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.item,
    required this.highlightMode,
    required this.onTap,
  });

  final ConversationSummaryModel item;
  final bool highlightMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final location = [
      if (item.peer.locality != null && item.peer.locality!.trim().isNotEmpty)
        item.peer.locality!.trim(),
      if (item.peer.city != null && item.peer.city!.trim().isNotEmpty)
        item.peer.city!.trim(),
    ].join(', ');
    final timestamp = item.lastMessageAt == null
        ? locale.chatReady
        : DateFormat(
            'd MMM, h:mm a',
            locale.localeName,
          ).format(item.lastMessageAt!.toLocal());

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  highlightMode && item.peer.profileImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(58 / 2),
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 8,
                              sigmaY: 8,
                            ),
                            child: FlatmatesAvatar(
                              name: item.peer.fullName,
                              imageUrl: item.peer.profileImageUrl,
                              size: 58,
                            ),
                          ),
                        )
                      : FlatmatesAvatar(
                          name: item.peer.fullName,
                          imageUrl: item.peer.profileImageUrl,
                          size: 58,
                        ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.peer.fullName,
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            if (item.unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${item.unreadCount}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (item.peer.mode != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            localizedFlatmatesModeLabel(
                              locale,
                              item.peer.mode!,
                            ),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  location,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (item.contextProperty != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      if (item.contextProperty!.mainImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            item.contextProperty!.mainImageUrl!,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _PropertyPreviewFallback(
                              title: item.contextProperty!.title,
                            ),
                          ),
                        )
                      else
                        _PropertyPreviewFallback(
                          title: item.contextProperty!.title,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.contextProperty!.title,
                              style: theme.textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            if (item.contextProperty!.monthlyRent != null)
                              Text(
                                locale.monthlyRentLabel(
                                  item.contextProperty!.monthlyRent!
                                      .toStringAsFixed(0),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.lastMessagePreview ?? locale.likesIncomingLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(timestamp, style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 14),
              highlightMode
                  ? GradientActionButton(
                      label: locale.openConversationCta,
                      onPressed: onTap,
                      icon: Icons.chat_bubble_outline_rounded,
                    )
                  : Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: onTap,
                        child: Text(locale.openConversationCta),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyPreviewFallback extends StatelessWidget {
  const _PropertyPreviewFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.9),
            theme.colorScheme.primary.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initialsFromName(title),
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
