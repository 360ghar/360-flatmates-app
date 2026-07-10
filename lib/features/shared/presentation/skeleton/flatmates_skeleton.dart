import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'skeleton_shimmer.dart';
import 'variants/browse_listings_skeleton.dart';
import 'variants/card_skeleton.dart';
import 'variants/chat_messages_skeleton.dart';
import 'variants/conversation_list_skeleton.dart';
import 'variants/discover_feed_skeleton.dart';
import 'variants/flat_details_skeleton.dart';
import 'variants/form_skeleton.dart';
import 'variants/legal_content_skeleton.dart';
import 'variants/list_skeleton.dart';
import 'variants/manage_listings_skeleton.dart';
import 'variants/map_explore_skeleton.dart';
import 'variants/notification_list_skeleton.dart';
import 'variants/peer_profile_sheet_skeleton.dart';
import 'variants/profile_skeleton.dart';
import 'variants/search_filters_skeleton.dart';
import 'variants/settings_list_skeleton.dart';
import 'variants/swipe_card_skeleton.dart';
import 'variants/visit_list_skeleton.dart';

export 'skeleton_bone.dart';
export 'skeleton_shimmer.dart';
export 'skeleton_tokens.dart';

/// Shimmer/skeleton loading states for feed, chats, cards, and full screens.
///
/// Prefer page-specific factories (`.discoverFeed()`, `.swipeCard()`, …)
/// over generic `.card()` / `.list()`. Use [CircularProgressIndicator] only
/// for in-action progress (button submit, upload, pagination footer).
class FlatmatesSkeleton extends StatelessWidget {
  const FlatmatesSkeleton({
    super.key,
    this.itemCount = 1,
    this.variant = SkeletonVariant.card,
  });

  /// Card skeleton — approximates a listing card shape.
  const FlatmatesSkeleton.card({super.key})
    : itemCount = 1,
      variant = SkeletonVariant.card;

  /// List item skeleton — multi-row avatar + text by default.
  const FlatmatesSkeleton.list({super.key, this.itemCount = 6})
    : variant = SkeletonVariant.listItem;

  /// Feed skeleton — multiple cards (legacy; prefer page-specific variants).
  const FlatmatesSkeleton.feed({super.key, this.itemCount = 3})
    : variant = SkeletonVariant.feed;

  /// Profile header skeleton — compact horizontal layout matching profile page.
  const FlatmatesSkeleton.profile({super.key})
    : itemCount = 1,
      variant = SkeletonVariant.profile;

  /// Discover feed skeleton — header + horizontal card sections.
  const FlatmatesSkeleton.discoverFeed({super.key})
    : itemCount = 1,
      variant = SkeletonVariant.discoverFeed;

  /// Browse listings skeleton — compact horizontal cards.
  const FlatmatesSkeleton.browseListings({super.key, this.itemCount = 4})
    : variant = SkeletonVariant.browseListings;

  /// Flat details skeleton — carousel + chips + bottom action bar.
  const FlatmatesSkeleton.flatDetails({super.key})
    : itemCount = 1,
      variant = SkeletonVariant.flatDetails;

  /// Chat messages skeleton — alternating sent/received bubbles.
  const FlatmatesSkeleton.chatMessages({super.key, this.itemCount = 5})
    : variant = SkeletonVariant.chatMessages;

  /// Swipe card skeleton — tall profile card with hero + info.
  const FlatmatesSkeleton.swipeCard({super.key})
    : itemCount = 1,
      variant = SkeletonVariant.swipeCard;

  /// Conversation list skeleton — segmented control + conversation cards.
  const FlatmatesSkeleton.conversationList({super.key, this.itemCount = 4})
    : variant = SkeletonVariant.conversationList;

  /// Notification list skeleton.
  const FlatmatesSkeleton.notificationList({super.key, this.itemCount = 4})
    : variant = SkeletonVariant.notificationList;

  /// Visit list skeleton — section headers + visit cards.
  const FlatmatesSkeleton.visitList({super.key, this.itemCount = 3})
    : variant = SkeletonVariant.visitList;

  /// Manage listings skeleton — CTA + segmented control + listing cards.
  const FlatmatesSkeleton.manageListings({super.key, this.itemCount = 2})
    : variant = SkeletonVariant.manageListings;

  /// Map explore skeleton — frosted top bar + map + bottom sheet cards.
  const FlatmatesSkeleton.mapExplore({super.key})
    : itemCount = 1,
      variant = SkeletonVariant.mapExplore;

  /// Search filter sheet skeleton.
  const FlatmatesSkeleton.searchFilters({super.key})
    : itemCount = 1,
      variant = SkeletonVariant.searchFilters;

  /// Settings-style rows with switch bones.
  const FlatmatesSkeleton.settingsList({super.key, this.itemCount = 5})
    : variant = SkeletonVariant.settingsList;

  /// Multi-field form with bottom CTA (schedule visit, onboarding).
  const FlatmatesSkeleton.form({super.key, this.itemCount = 5})
    : variant = SkeletonVariant.form;

  /// Peer/owner profile bottom sheet.
  const FlatmatesSkeleton.peerProfileSheet({super.key})
    : itemCount = 1,
      variant = SkeletonVariant.peerProfileSheet;

  /// Legal / markdown content lines.
  const FlatmatesSkeleton.legalContent({super.key})
    : itemCount = 1,
      variant = SkeletonVariant.legalContent;

  final int itemCount;
  final SkeletonVariant variant;

  @override
  Widget build(BuildContext context) {
    final content = switch (variant) {
      SkeletonVariant.card => const CardSkeleton(),
      SkeletonVariant.listItem => ListSkeleton(itemCount: itemCount),
      SkeletonVariant.feed => ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            const CardSkeleton(),
          ],
        ],
      ),
      SkeletonVariant.profile => const ProfileSkeleton(),
      SkeletonVariant.discoverFeed => const DiscoverFeedSkeleton(),
      SkeletonVariant.browseListings => BrowseListingsSkeleton(
        itemCount: itemCount,
      ),
      SkeletonVariant.flatDetails => const FlatDetailsSkeleton(),
      SkeletonVariant.chatMessages => ChatMessagesSkeleton(
        itemCount: itemCount,
      ),
      SkeletonVariant.swipeCard => const SwipeCardSkeleton(),
      SkeletonVariant.conversationList => ConversationListSkeleton(
        itemCount: itemCount,
      ),
      SkeletonVariant.notificationList => NotificationListSkeleton(
        itemCount: itemCount,
      ),
      SkeletonVariant.visitList => VisitListSkeleton(itemCount: itemCount),
      SkeletonVariant.manageListings => ManageListingsSkeleton(
        itemCount: itemCount,
      ),
      SkeletonVariant.mapExplore => const MapExploreSkeleton(),
      SkeletonVariant.searchFilters => const SearchFiltersSkeleton(),
      SkeletonVariant.settingsList => SettingsListSkeleton(
        itemCount: itemCount,
      ),
      SkeletonVariant.form => FormSkeleton(fieldCount: itemCount),
      SkeletonVariant.peerProfileSheet => const PeerProfileSheetSkeleton(),
      SkeletonVariant.legalContent => const LegalContentSkeleton(),
    };

    return FlatmatesSkeletonShimmer(child: content);
  }
}

enum SkeletonVariant {
  card,
  listItem,
  feed,
  profile,
  discoverFeed,
  browseListings,
  flatDetails,
  chatMessages,
  swipeCard,
  conversationList,
  notificationList,
  visitList,
  manageListings,
  mapExplore,
  searchFilters,
  settingsList,
  form,
  peerProfileSheet,
  legalContent,
}
