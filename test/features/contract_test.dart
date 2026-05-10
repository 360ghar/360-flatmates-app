import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/discover/data/property_listing_dto.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/visits/visits_repository.dart';
import 'package:flatmates_app/features/notifications/notifications_repository.dart';

// Helper to load a JSON fixture as a Map
Map<String, dynamic> loadFixture(String name) {
  final file = File('test/fixtures/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  group('Backend contract tests', () {
    test('BootstrapData parses from fixture', () {
      final json = loadFixture('bootstrap.json');
      final data = BootstrapData.fromJson(json);
      expect(data.profile.id, 1);
      expect(data.profile.fullName, 'Test User');
      expect(data.profile.mode, 'co_hunter');
      expect(data.profile.onboardingCompleted, true);
      expect(data.catalogs.length, 1);
      expect(data.activeListingCount, 2);
      expect(data.conversationCount, 5);
      expect(data.unreadMessageCount, 3);
    });

    test('PropertyListing parses from fixture', () {
      final json = loadFixture('property_listing.json');
      final listing = PropertyListingDto.fromJson(json);
      expect(listing.id, 42);
      expect(listing.title, 'Modern 2BHK in Koramangala');
      expect(listing.monthlyRent, 24000.0);
      expect(listing.city, 'Bangalore');
      expect(listing.bedrooms, 2);
      // sharingType is read from listing_preferences.sharing_type
      expect(listing.sharingType, 'private_room');
    });

    test('ConversationSummaryModel parses from fixture', () {
      final json = loadFixture('conversation_summary.json');
      final conv = ConversationSummaryModel.fromJson(json);
      expect(conv.id, 10);
      expect(conv.peer.fullName, 'Priya Patel');
      expect(conv.peer.matchPercentage, 85.0);
      expect(conv.contextProperty, isNotNull);
      expect(conv.contextProperty!.title, 'Modern 2BHK in Koramangala');
      expect(conv.unreadCount, 2);
      expect(conv.qna?.bothAnswered, isTrue);
      expect(conv.qna?.peer?.q3, 'No smoking indoors');
    });

    test('ChatMessage parses from fixture', () {
      final json = loadFixture('chat_message.json');
      final msg = ChatMessage.fromJson(json);
      expect(msg.id, 100);
      expect(msg.conversationId, 10);
      expect(msg.senderId, 2);
      expect(msg.body, "Hey! I'm interested in the flat");
      expect(msg.messageType, 'text');
    });

    test('VisitItem parses from fixture', () {
      final json = loadFixture('visit_item.json');
      final visit = VisitItem.fromJson(json);
      expect(visit.id, 5);
      expect(visit.propertyTitle, 'Modern 2BHK in Koramangala');
      expect(visit.status, 'confirmed');
      expect(visit.visitContext, 'flatmate_meet');
    });

    test('NotificationModel parses from fixture', () {
      final json = loadFixture('notification.json');
      final notif = NotificationModel.fromJson(json);
      expect(notif.id, 'notif-1');
      expect(notif.type, 'booking_confirmed');
      expect(notif.title, 'Visit Confirmed');
      expect(notif.body, 'Your visit with Priya has been confirmed');
      expect(notif.isRead, false);
      expect(notif.referenceId, 5);
    });

    test('CatalogEntryModel parses from fixture', () {
      final json = loadFixture('catalogs.json');
      final catalog = CatalogEntryModel(
        key: 'flatmates_modes',
        version: 1,
        payload: json,
      );
      expect(catalog.payload['items'], isA<List>());
      expect((catalog.payload['items'] as List).length, 3);
    });
  });
}
