import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_models.freezed.dart';

@Freezed()
class ChatPeer with _$ChatPeer {
  const ChatPeer._();
  const factory ChatPeer({
    required int id,
    @Default('Flatmate') String fullName,
    String? profileImageUrl,
    String? mode,
    String? city,
    String? locality,
    int? age,
    String? profession,
    double? matchPercentage,
    String? phoneNumber,
  }) = _ChatPeer;

  factory ChatPeer.fromJson(Map<String, dynamic> json) {
    return ChatPeer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String? ?? 'Flatmate',
      profileImageUrl: json['profile_image_url'] as String?,
      mode: json['mode'] as String?,
      city: json['city'] as String?,
      locality: json['locality'] as String?,
      age: (json['age'] as num?)?.toInt(),
      profession: json['profession'] as String?,
      matchPercentage: (json['match_percentage'] as num?)?.toDouble(),
      phoneNumber: json['phone_number'] as String?,
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
  const factory ConversationSummaryModel({
    required int id,
    @Default('listing_interest') String source,
    @Default('active') String status,
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
      source: json['source'] as String? ?? 'listing_interest',
      status: json['status'] as String? ?? 'active',
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
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

@Freezed()
class ChatMessage with _$ChatMessage {
  const ChatMessage._();
  const factory ChatMessage({
    required int id,
    required int conversationId,
    required int senderId,
    String? body,
    @Default('text') String messageType,
    required DateTime createdAt,
    DateTime? readAt,
    String? attachmentUrl,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _ChatMessage;

  int? get visitId => (metadata['visit_id'] as num?)?.toInt();

  DateTime? get visitScheduledDate =>
      DateTime.tryParse(metadata['scheduled_date']?.toString() ?? '');

  String? get visitStatus => metadata['status']?.toString();

  String? get visitTimeSlotLabel => metadata['time_slot_label']?.toString();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'] ?? json['message_metadata'];
    return ChatMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      conversationId: (json['conversation_id'] as num?)?.toInt() ?? 0,
      senderId: (json['sender_id'] as num?)?.toInt() ?? 0,
      body: json['body'] as String?,
      messageType: json['message_type'] as String? ?? 'text',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
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
