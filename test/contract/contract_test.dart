import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/bootstrap/domain/bootstrap_models.dart';
import 'package:flatmates_app/features/chats/domain/chat_models.dart';
import 'package:flatmates_app/features/discover/data/property_listing_dto.dart';
import 'package:flatmates_app/features/notifications/notifications_repository.dart';
import 'package:flatmates_app/features/visits/visits_repository.dart';

/// Contract tests verify that the domain model `fromJson` parsers correctly
/// deserialize the JSON fixtures in `test/fixtures/`. These fixtures represent
/// the backend response shapes and serve as the contract between the Flutter
/// app and the FastAPI backend.
void main() {
  Map<String, dynamic> loadFixture(String name) {
    final file = File('test/fixtures/$name');
    return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  group('BootstrapData contract', () {
    test('parses bootstrap.json fixture correctly', () {
      final json = loadFixture('bootstrap.json');
      final data = BootstrapData.fromJson(json);

      expect(data.profile.id, 1);
      expect(data.profile.fullName, 'Test User');
      expect(data.profile.phone, '+919999999999');
      expect(data.profile.email, 'test@example.com');
      expect(data.profile.mode, 'co_hunter');
      expect(data.profile.profileStatus, 'active');
      expect(data.profile.onboardingCompleted, isTrue);
      expect(data.profile.age, 25);
      expect(data.profile.profession, 'Software Engineer');
      expect(data.profile.budgetMin, 10000.0);
      expect(data.profile.budgetMax, 25000.0);
      expect(data.profile.city, 'Bangalore');
      expect(data.profile.state, 'Karnataka');
      expect(data.profile.locality, 'Koramangala');
      expect(data.profile.gender, 'male');
      expect(data.profile.genderPreference, 'any');

      expect(data.catalogs, hasLength(1));
      expect(data.catalogs.first.key, 'flatmates_modes');
      expect(data.catalogs.first.version, 1);
      expect(data.catalogs.first.payload['items'], isA<List>());

      expect(data.activeListingCount, 2);
      expect(data.conversationCount, 5);
      expect(data.unreadMessageCount, 3);

      expect(data.realtime, isNotNull);
      expect(data.realtime!.provider, 'supabase');
      expect(data.realtime!.channel, 'flatmates:user:1');
      expect(data.realtime!.privateChannel, isTrue);
      expect(data.realtime!.events, contains('new_message'));
      expect(data.realtime!.events, contains('new_match'));
    });

    test('profile preferences are parsed', () {
      final json = loadFixture('bootstrap.json');
      final data = BootstrapData.fromJson(json);

      expect(data.profile.preferences, isNotEmpty);
      expect(data.profile.preferences['profession'], 'Software Engineer');
      expect(data.profile.preferences['pets'], 'no_pets');
    });
  });

  group('PropertyListing contract', () {
    test('parses property_listing.json fixture correctly', () {
      final json = loadFixture('property_listing.json');
      final listing = PropertyListingDto.fromJson(json);

      expect(listing.id, 42);
      expect(listing.ownerId, 1);
      expect(listing.propertyType, 'flatmate');
      expect(listing.title, 'Modern 2BHK in Koramangala');
      expect(listing.description, 'A beautiful flat near Forum Mall');
      expect(listing.city, 'Bangalore');
      expect(listing.state, 'Karnataka');
      expect(listing.locality, 'Koramangala');
      expect(listing.subLocality, '5th Block');
      expect(listing.latitude, 12.9352);
      expect(listing.longitude, 77.6245);
      expect(listing.monthlyRent, 24000.0);
      expect(listing.mainImageUrl, 'https://example.com/photo.jpg');
      expect(listing.imageUrls, contains('https://example.com/photo.jpg'));
      expect(listing.bedrooms, 2);
      expect(listing.bathrooms, 2);
      expect(listing.areaSqft, 1200.0);
      expect(listing.features, containsAll(['wifi', 'parking', 'security']));
      expect(listing.availableFrom, isNotNull);
      expect(listing.availableFrom!.year, 2025);
      expect(listing.availableFrom!.month, 6);
      expect(listing.interestCount, 10);
      expect(listing.viewCount, 3800);
      expect(listing.likeCount, 24);
      expect(listing.isAvailable, isTrue);
      expect(listing.createdAt, isNotNull);
      expect(listing.createdAt!.year, 2025);

      // Preferences from listing_preferences
      expect(listing.sharingType, 'private_room');
      expect(listing.genderPreference, 'any');
      expect(listing.status, 'approved'); // moderation_status overrides
      expect(listing.propertyStatus, 'live'); // raw status field

      // Owner
      expect(listing.owner, isNotNull);
      expect(listing.owner!.id, 1);
      expect(listing.owner!.fullName, 'Rahul Sharma');
      expect(listing.owner!.mode, 'room_poster');
    });

    test('isLive returns true for approved status', () {
      final json = loadFixture('property_listing.json');
      final listing = PropertyListingDto.fromJson(json);

      expect(listing.isLive, isTrue);
    });

    test('isFurnished detects furnished in features', () {
      final json = loadFixture('property_listing.json');
      final listing = PropertyListingDto.fromJson(json);

      // The fixture has "furnished" in furnishing_status but not in features.
      // The isFurnished getter checks features list for "furnished".
      expect(listing.features, isNot(contains('furnished')));
      expect(listing.isFurnished, isFalse);
    });
  });

  group('ChatMessage contract', () {
    test('parses chat_message.json fixture correctly', () {
      final json = loadFixture('chat_message.json');
      final message = ChatMessage.fromJson(json);

      expect(message.id, 100);
      expect(message.conversationId, 10);
      expect(message.senderId, 2);
      expect(message.body, "Hey! I'm interested in the flat");
      expect(message.messageType, 'text');
      expect(message.createdAt, isNotNull);
      expect(message.createdAt.year, 2025);
      expect(message.createdAt.month, 5);
      expect(message.createdAt.day, 15);
      expect(message.readAt, isNull);
      expect(message.attachmentUrl, isNull);
    });
  });

  group('ConversationSummaryModel contract', () {
    test('parses conversation_summary.json fixture correctly', () {
      final json = loadFixture('conversation_summary.json');
      final conv = ConversationSummaryModel.fromJson(json);

      expect(conv.id, 10);
      expect(conv.source, 'match');
      expect(conv.status, 'active');

      // Peer
      expect(conv.peer.id, 2);
      expect(conv.peer.fullName, 'Priya Patel');
      expect(conv.peer.mode, 'co_hunter');
      expect(conv.peer.city, 'Bangalore');
      expect(conv.peer.locality, 'HSR Layout');
      expect(conv.peer.age, 24);
      expect(conv.peer.profession, 'Designer');
      expect(conv.peer.matchPercentage, 85.0);

      // Context property
      expect(conv.contextProperty, isNotNull);
      expect(conv.contextProperty!.id, 42);
      expect(conv.contextProperty!.title, 'Modern 2BHK in Koramangala');
      expect(conv.contextProperty!.locality, 'Koramangala');
      expect(conv.contextProperty!.city, 'Bangalore');
      expect(conv.contextProperty!.monthlyRent, 24000.0);

      // Last message
      expect(conv.lastMessagePreview, "Hey! I'm interested in the flat");
      expect(conv.lastMessageAt, isNotNull);
      expect(conv.lastMessageAt!.year, 2025);
      expect(conv.unreadCount, 2);
      expect(conv.matchedAt, isNotNull);
      expect(conv.matchedAt!.year, 2025);

      // QnA
      expect(conv.qna, isNotNull);
      expect(conv.qna!.currentUser, isNotNull);
      expect(conv.qna!.currentUser!.userId, 1);
      expect(conv.qna!.currentUser!.q1, 'A calm place near work');
      expect(conv.qna!.peer, isNotNull);
      expect(conv.qna!.peer!.userId, 2);
      expect(conv.qna!.peer!.q1, 'Respectful and tidy');
      expect(conv.qna!.bothAnswered, isTrue);
    });
  });

  group('NotificationModel contract', () {
    test('parses notification.json fixture correctly', () {
      final json = loadFixture('notification.json');
      final notification = NotificationModel.fromJson(json);

      expect(notification.id, 'notif-1');
      expect(notification.type, 'booking_confirmed');
      expect(notification.title, 'Visit Confirmed');
      expect(notification.body, 'Your visit with Priya has been confirmed');
      expect(notification.isRead, isFalse);
      expect(notification.createdAt, isNotNull);
      expect(notification.createdAt.year, 2025);
      expect(notification.createdAt.month, 5);
      expect(notification.createdAt.day, 16);
      expect(notification.referenceId, 5);
      expect(notification.route, '/visits/5');
    });
  });

  group('VisitItem contract', () {
    test('parses visit_item.json fixture correctly', () {
      final json = loadFixture('visit_item.json');
      final visit = VisitItem.fromJson(json);

      expect(visit.id, 5);
      expect(visit.propertyTitle, 'Modern 2BHK in Koramangala');
      expect(visit.status, 'confirmed');
      expect(visit.scheduledDate, isNotNull);
      expect(visit.scheduledDate.year, 2025);
      expect(visit.scheduledDate.month, 5);
      expect(visit.scheduledDate.day, 20);
      expect(visit.visitContext, 'flatmate_meet');
      expect(visit.conversationId, 10);
    });
  });

  group('Catalogs contract', () {
    test('parses catalogs.json fixture as a list of mode items', () {
      final json = loadFixture('catalogs.json');
      final items = (json['items'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);

      expect(items, hasLength(3));
      final coHunter = items.firstWhere((i) => i['id'] == 'co_hunter');
      expect(coHunter['label'], 'Find a Flat / Flatmate');
      expect(coHunter['description'], 'I want to find a place');

      final roomPoster = items.firstWhere((i) => i['id'] == 'room_poster');
      expect(roomPoster['label'], 'List My Flat / Find Flatmate');

      final openToBoth = items.firstWhere((i) => i['id'] == 'open_to_both');
      expect(openToBoth['label'], 'Open to Both');
    });
  });

  group('Cross-fixture consistency', () {
    test('property listing ID matches across fixtures', () {
      final listingJson = loadFixture('property_listing.json');
      final listing = PropertyListingDto.fromJson(listingJson);

      final convJson = loadFixture('conversation_summary.json');
      final conv = ConversationSummaryModel.fromJson(convJson);

      expect(conv.contextProperty!.id, listing.id);
      expect(conv.contextProperty!.title, listing.title);
      expect(conv.contextProperty!.monthlyRent, listing.monthlyRent);
    });

    test('visit references the same property listing', () {
      final listingJson = loadFixture('property_listing.json');
      final listing = PropertyListingDto.fromJson(listingJson);

      final visitJson = loadFixture('visit_item.json');
      final visit = VisitItem.fromJson(visitJson);

      expect(visit.propertyTitle, listing.title);
    });

    test('notification references the same visit', () {
      final visitJson = loadFixture('visit_item.json');
      final visit = VisitItem.fromJson(visitJson);

      final notifJson = loadFixture('notification.json');
      final notification = NotificationModel.fromJson(notifJson);

      expect(notification.referenceId, visit.id);
    });

    test('chat message belongs to the same conversation as summary', () {
      final msgJson = loadFixture('chat_message.json');
      final message = ChatMessage.fromJson(msgJson);

      final convJson = loadFixture('conversation_summary.json');
      final conv = ConversationSummaryModel.fromJson(convJson);

      expect(message.conversationId, conv.id);
      expect(message.body, conv.lastMessagePreview);
    });
  });
}
