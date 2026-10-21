import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/wire_enums.dart';
import '../../discover/data/property_listing_dto.dart';
import '../../discover/domain/property_listing.dart';

part 'chat_models.freezed.dart';

/// A timestamp the API always sends (`created_at`). A row without a readable
/// one throws, so the list parser skips it: a row stamped with the current time
/// or the epoch would sort and read wrong with no sign of it.
DateTime _requiredTimestamp(Map<String, dynamic> json, String key) {
  final value = DateTime.tryParse(json[key]?.toString() ?? '');
  if (value == null) {
    throw FormatException(
      'row ${json['id']} has no readable $key: ${json[key]}',
    );
  }
  return value;
}

@Freezed()
class ChatPeer with _$ChatPeer {
  const ChatPeer._();

  // No phone and no exact age here: a peer payload never carries them. The
  // phone of a matched peer comes from the match contact route only.
  const factory ChatPeer({
    required int id,
    @Default('Flatmate') String fullName,
    String? profileImageUrl,
    String? mode,
    String? city,
    String? locality,
    String? ageBucket,
    String? profession,
    double? matchPercentage,
  }) = _ChatPeer;

  factory ChatPeer.fromJson(Map<String, dynamic> json) {
    return ChatPeer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String? ?? 'Flatmate',
      profileImageUrl: json['profile_image_url'] as String?,
      mode: json['mode'] as String?,
      city: json['city'] as String?,
      locality: json['locality'] as String?,
      ageBucket: json['age_bucket'] as String?,
      profession: json['profession'] as String?,
      matchPercentage: (json['match_percentage'] as num?)?.toDouble(),
    );
  }
}

@Freezed()
class ChatPropertyContext with _$ChatPropertyContext {
  const ChatPropertyContext._();
  const factory ChatPropertyContext({
    required int id,
    @Default('Listing') String title,
    String? locality,
    String? city,
    double? monthlyRent,
    String? mainImageUrl,
    String? ownerName,
    String? ownerImageUrl,
  }) = _ChatPropertyContext;

  factory ChatPropertyContext.fromJson(Map<String, dynamic> json) {
    return ChatPropertyContext(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Listing',
      locality: json['locality'] as String?,
      city: json['city'] as String?,
      monthlyRent: (json['monthly_rent'] as num?)?.toDouble(),
      mainImageUrl: json['main_image_url'] as String?,
      ownerName: json['owner_name'] as String?,
      ownerImageUrl: json['owner_image_url'] as String?,
    );
  }
}

class ConversationQnAAnswer {
  const ConversationQnAAnswer({
    required this.userId,
    this.q1,
    this.q2,
    this.q3,
  });

  final int userId;
  final String? q1;
  final String? q2;
  final String? q3;

  bool get hasAnyAnswer =>
      (q1?.trim().isNotEmpty ?? false) ||
      (q2?.trim().isNotEmpty ?? false) ||
      (q3?.trim().isNotEmpty ?? false);

  factory ConversationQnAAnswer.fromJson(Map<String, dynamic> json) {
    return ConversationQnAAnswer(
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      q1: json['q1'] as String?,
      q2: json['q2'] as String?,
      q3: json['q3'] as String?,
    );
  }
}

class ConversationQnAState {
  const ConversationQnAState({
    this.currentUser,
    this.peer,
    this.bothAnswered = false,
  });

  final ConversationQnAAnswer? currentUser;
  final ConversationQnAAnswer? peer;
  final bool bothAnswered;

  bool get hasCurrentUserAnswers => currentUser?.hasAnyAnswer ?? false;
  bool get hasPeerAnswers => peer?.hasAnyAnswer ?? false;
  bool get hasAnyAnswers => hasCurrentUserAnswers || hasPeerAnswers;

  factory ConversationQnAState.fromJson(Map<String, dynamic> json) {
    return ConversationQnAState(
      currentUser: json['current_user'] == null
          ? null
          : ConversationQnAAnswer.fromJson(
              Map<String, dynamic>.from(json['current_user'] as Map),
            ),
      peer: json['peer'] == null
          ? null
          : ConversationQnAAnswer.fromJson(
              Map<String, dynamic>.from(json['peer'] as Map),
            ),
      bothAnswered: json['both_answered'] as bool? ?? false,
    );
  }
}

@Freezed()
class ConversationSummaryModel with _$ConversationSummaryModel {
  const ConversationSummaryModel._();

  /// A conversation opened by a mutual like of two profiles. Only these have a
  /// match, so only these can show the peer's phone.
  bool get isProfileMatch => source == ConversationSource.profileMatch;

  /// Whether the peer's phone may be asked for: a mutual match that is still
  /// open. A missing or unknown status is not open: the call is offered only
  /// when the status says `active`. The server still decides; a blocked or
  /// unmatched pair answers 404.
  bool get canCall => isProfileMatch && status == ConversationStatus.active;
  const factory ConversationSummaryModel({
    required int id,
    ConversationSource? source,
    ConversationStatus? status,
    required ChatPeer peer,
    ChatPropertyContext? contextProperty,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    @Default(0) int unreadCount,
    DateTime? matchedAt,
    ConversationQnAState? qna,
  }) = _ConversationSummaryModel;

  factory ConversationSummaryModel.fromJson(Map<String, dynamic> json) {
    return ConversationSummaryModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      source: ConversationSource.fromJson(json['source']),
      status: ConversationStatus.fromJson(json['status']),
      peer: ChatPeer.fromJson(
        Map<String, dynamic>.from(json['peer'] as Map? ?? const {}),
      ),
      contextProperty: json['context_property'] == null
          ? null
          : ChatPropertyContext.fromJson(
              Map<String, dynamic>.from(json['context_property'] as Map),
            ),
      lastMessagePreview: json['last_message_preview'] as String?,
      lastMessageAt: DateTime.tryParse(
        json['last_message_at']?.toString() ?? '',
      ),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      matchedAt: DateTime.tryParse(json['matched_at']?.toString() ?? ''),
      qna: json['qna'] == null
          ? null
          : ConversationQnAState.fromJson(
              Map<String, dynamic>.from(json['qna'] as Map),
            ),
    );
  }
}

/// A row of `GET /flatmates/matches`.
class MatchSummaryModel {
  const MatchSummaryModel({
    required this.id,
    required this.status,
    required this.peer,
  });

  final int id;
  final UserMatchStatus? status;
  final ChatPeer peer;

  factory MatchSummaryModel.fromJson(Map<String, dynamic> json) {
    return MatchSummaryModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: UserMatchStatus.fromJson(json['status']),
      peer: ChatPeer.fromJson(
        Map<String, dynamic>.from(json['peer'] as Map? ?? const {}),
      ),
    );
  }
}

/// `GET /flatmates/matches/{match_id}/contact`: the phone of the other user of
/// an active match. The only place a peer phone is served.
class MatchContactModel {
  const MatchContactModel({
    required this.matchId,
    required this.peerUserId,
    this.phone,
  });

  final int matchId;
  final int peerUserId;
  final String? phone;

  factory MatchContactModel.fromJson(Map<String, dynamic> json) {
    return MatchContactModel(
      matchId: (json['match_id'] as num?)?.toInt() ?? 0,
      peerUserId: (json['peer_user_id'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String?,
    );
  }
}

/// One page of `GET /flatmates/conversations/{id}/messages` (a CursorPage).
///
/// [messages] is chronological (oldest first). [nextCursor] is the opaque
/// cursor of the next OLDER page, or null at the start of the thread.
class MessagesPage {
  const MessagesPage({
    required this.messages,
    required this.hasMore,
    this.nextCursor,
  });

  final List<ChatMessage> messages;

  /// Whether older messages exist before [messages].
  final bool hasMore;

  /// Pass back unchanged as `cursor` to load the older page.
  final String? nextCursor;
}

class IncomingLikeModel {
  const IncomingLikeModel({
    required this.id,
    required this.peer,
    required this.createdAt,
    this.contextProperty,
  });

  final int id;
  final ChatPeer peer;
  final ChatPropertyContext? contextProperty;
  final DateTime createdAt;

  factory IncomingLikeModel.fromJson(Map<String, dynamic> json) {
    return IncomingLikeModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      peer: ChatPeer.fromJson(
        Map<String, dynamic>.from(json['peer'] as Map? ?? const {}),
      ),
      contextProperty: json['context_property'] == null
          ? null
          : ChatPropertyContext.fromJson(
              Map<String, dynamic>.from(json['context_property'] as Map),
            ),
      createdAt: _requiredTimestamp(json, 'created_at'),
    );
  }
}

class OutgoingLikeModel {
  const OutgoingLikeModel({
    required this.id,
    required this.targetType,
    this.peer,
    this.property,
    this.contextProperty,
    required this.createdAt,
  });

  final int id;

  /// Null for a target type this build does not know.
  final SwipeTargetType? targetType;
  final ChatPeer? peer;
  final PropertyListing? property;
  final ChatPropertyContext? contextProperty;
  final DateTime createdAt;

  factory OutgoingLikeModel.fromJson(Map<String, dynamic> json) {
    final targetType = SwipeTargetType.fromJson(json['target_type']);
    PropertyListing? property;
    if (targetType == SwipeTargetType.property && json['property'] is Map) {
      // Outgoing property likes are always liked from the owner's perspective.
      // Force true so Liked-tab hearts and toggle-unlike never depend on a
      // missing/mis-typed `liked` field from the payload.
      property = PropertyListingDto.fromJson(
        Map<String, dynamic>.from(json['property'] as Map),
      ).copyWith(liked: true);
    }
    return OutgoingLikeModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      targetType: targetType,
      peer: targetType == SwipeTargetType.user && json['peer'] is Map
          ? ChatPeer.fromJson(Map<String, dynamic>.from(json['peer'] as Map))
          : null,
      property: property,
      contextProperty: json['context_property'] == null
          ? null
          : ChatPropertyContext.fromJson(
              Map<String, dynamic>.from(json['context_property'] as Map),
            ),
      createdAt: _requiredTimestamp(json, 'created_at'),
    );
  }

  factory OutgoingLikeModel.fromPropertyListing(PropertyListing property) {
    return OutgoingLikeModel(
      id: -property.id,
      targetType: SwipeTargetType.property,
      property: property.copyWith(liked: true),
      createdAt: DateTime.now().toUtc(),
    );
  }
}

@Freezed()
class ChatMessage with _$ChatMessage {
  const ChatMessage._();
  const factory ChatMessage({
    required int id,
    required int conversationId,

    /// Null for a system message or a message whose sender was deleted.
    int? senderId,
    String? body,
    MessageType? messageType,
    required DateTime createdAt,
    DateTime? readAt,
    String? attachmentUrl,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _ChatMessage;

  /// A message with no sender, or of the `system` type, is shown as a notice
  /// and never as a bubble of either side.
  bool get isSystem => senderId == null || messageType == MessageType.system;

  int? get visitId => (metadata['visit_id'] as num?)?.toInt();

  /// A visit-request card. The API accepts only `text` and `image` from a
  /// client (`message_type` `visit_request` is a 422), so the app sends the
  /// request as a text message with the visit in its metadata. A message of
  /// the `visit_request` type (older rows) is a card too.
  bool get isVisitRequest =>
      messageType == MessageType.visitRequest ||
      (messageType == MessageType.text && visitId != null);

  DateTime? get visitScheduledDate =>
      DateTime.tryParse(metadata['scheduled_date']?.toString() ?? '');

  String? get visitStatus => metadata['status']?.toString();

  String? get visitTimeSlotLabel => metadata['time_slot_label']?.toString();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'] ?? json['message_metadata'];
    return ChatMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      conversationId: (json['conversation_id'] as num?)?.toInt() ?? 0,
      senderId: (json['sender_id'] as num?)?.toInt(),
      body: json['body'] as String?,
      messageType: MessageType.fromJson(json['message_type']),
      createdAt: _requiredTimestamp(json, 'created_at'),
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
      attachmentUrl: json['attachment_url'] as String?,
      metadata: rawMetadata is Map
          ? Map<String, dynamic>.from(rawMetadata)
          : const {},
    );
  }
}
