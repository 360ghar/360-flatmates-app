import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class ChatPeer {
  const ChatPeer({
    required this.id,
    required this.fullName,
    required this.profileImageUrl,
    required this.mode,
    required this.city,
    required this.locality,
  });

  final int id;
  final String fullName;
  final String? profileImageUrl;
  final String? mode;
  final String? city;
  final String? locality;

  factory ChatPeer.fromJson(Map<String, dynamic> json) {
    return ChatPeer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String? ?? 'Flatmate',
      profileImageUrl: json['profile_image_url'] as String?,
      mode: json['mode'] as String?,
      city: json['city'] as String?,
      locality: json['locality'] as String?,
    );
  }
}

class ChatPropertyContext {
  const ChatPropertyContext({
    required this.id,
    required this.title,
    required this.locality,
    required this.city,
    required this.monthlyRent,
    required this.mainImageUrl,
  });

  final int id;
  final String title;
  final String? locality;
  final String? city;
  final double? monthlyRent;
  final String? mainImageUrl;

  factory ChatPropertyContext.fromJson(Map<String, dynamic> json) {
    return ChatPropertyContext(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Listing',
      locality: json['locality'] as String?,
      city: json['city'] as String?,
      monthlyRent: (json['monthly_rent'] as num?)?.toDouble(),
      mainImageUrl: json['main_image_url'] as String?,
    );
  }
}

class ConversationSummaryModel {
  const ConversationSummaryModel({
    required this.id,
    required this.source,
    required this.status,
    required this.peer,
    required this.contextProperty,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  final int id;
  final String source;
  final String status;
  final ChatPeer peer;
  final ChatPropertyContext? contextProperty;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;

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
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.messageType,
    required this.createdAt,
    this.readAt,
    this.attachmentUrl,
  });

  final int id;
  final int conversationId;
  final int senderId;
  final String? body;
  final String messageType;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? attachmentUrl;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      conversationId: (json['conversation_id'] as num?)?.toInt() ?? 0,
      senderId: (json['sender_id'] as num?)?.toInt() ?? 0,
      body: json['body'] as String?,
      messageType: json['message_type'] as String? ?? 'text',
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      attachmentUrl: json['attachment_url'] as String?,
    );
  }
}

class ChatsRepository {
  const ChatsRepository(this._ref);

  final Ref _ref;

  Future<List<ConversationSummaryModel>> fetchConversations() async {
    final response = await _ref
        .watch(apiClientProvider)
        .get('/flatmates/conversations');
    final rows = (response.data as List? ?? const []);
    return rows
        .map(
          (item) => ConversationSummaryModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<ChatMessage>> fetchMessages(int conversationId) async {
    final response = await _ref
        .watch(apiClientProvider)
        .get('/flatmates/conversations/$conversationId/messages');
    final rows = (response.data as List? ?? const []);
    return rows
        .map(
          (item) =>
              ChatMessage.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> sendMessage({
    required int conversationId,
    String? body,
    String? attachmentUrl,
    String messageType = 'text',
  }) async {
    await _ref
        .watch(apiClientProvider)
        .post(
          '/flatmates/conversations/$conversationId/messages',
          data: {
            if (body != null) 'body': body,
            if (attachmentUrl != null) 'attachment_url': attachmentUrl,
            'message_type': messageType,
          },
        );
  }
}

final chatsRepositoryProvider = Provider<ChatsRepository>(
  (ref) => ChatsRepository(ref),
);

final conversationsProvider = FutureProvider<List<ConversationSummaryModel>>(
  (ref) => ref.watch(chatsRepositoryProvider).fetchConversations(),
);

final messagesProvider = FutureProvider.family<List<ChatMessage>, int>(
  (ref, conversationId) =>
      ref.watch(chatsRepositoryProvider).fetchMessages(conversationId),
);
