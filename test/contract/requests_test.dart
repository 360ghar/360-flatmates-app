import 'dart:ui' show Locale;

import 'package:flatmates_app/core/app_config/app_config_service.dart';
import 'package:flatmates_app/core/domain/wire_enums.dart';
import 'package:flatmates_app/core/notifications/notification_service.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/discover/discover_repository.dart';
import 'package:flatmates_app/features/feedback/data/feedback_repository.dart';
import 'package:flatmates_app/features/listings/listings_repository.dart';
import 'package:flatmates_app/features/notifications/notifications_repository.dart';
import 'package:flatmates_app/features/settings/data/settings_repository.dart';
import 'package:flatmates_app/features/swipe/application/match_qna_controller.dart';
import 'package:flatmates_app/features/swipe/swipe_repository.dart';
import 'package:flatmates_app/features/visits/visits_repository.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/recording_api.dart';
import 'api_fixtures.dart';
import 'contract_checks.dart';

/// Every request the app builds is checked against the contract the backend
/// publishes: write bodies reject unknown keys, so each key must be declared;
/// every query key must be declared; numbers must be inside their bounds.
void main() {
  RecordingApi api() => RecordingApi((options) {
    // A visit route answers with the visit the backend sends.
    if (options.path.startsWith('/visits/') ||
        (options.path == '/visits' && options.method == 'POST')) {
      return ok(apiFixture('visits', 'created'));
    }
    if (options.method == 'GET') {
      return ok({
        'items': <dynamic>[],
        'next_cursor': null,
        'has_more': false,
        'limit': 20,
        'total': null,
      });
    }
    return ok(<String, dynamic>{'id': 1}, status: 201);
  });

  const listing = ListingCreateRequest(
    title: 'Sunny room',
    description: 'Corner room',
    city: 'Bengaluru',
    locality: 'Koramangala',
    subLocality: '5th Block',
    monthlyRent: 24000,
    securityDeposit: 48000,
    maintenanceCharges: null,
    areaSqft: null,
    bedrooms: 2,
    features: ['furnished', 'wifi'],
    tags: ['quiet'],
    mainImageUrl: 'https://cdn.example.com/a.jpg',
    imageUrls: [
      'https://cdn.example.com/a.jpg',
      'https://cdn.example.com/b.jpg',
    ],
    availableFrom: null,
    genderPreference: 'female',
    sharingType: 'private_room',
    societyType: 'gated',
    societyAmenities: ['Gym'],
    societyVibeTags: ['quiet'],
    furnishingLevel: FurnishingLevel.furnished,
    videoTourUrl: 'https://cdn.example.com/tour.mp4',
    kitchenType: 'vegetarian',
    ventilationType: 'good',
    windowsCount: 2,
    ageMin: 22,
    ageMax: 35,
    nonNegotiables: ['no_smoking'],
    electricityIncluded: 'included',
    electricityEst: 800,
    setupCost: 5000,
    otherCharges: 500,
    otherChargesDescription: 'Maid',
    floorNumber: 3,
    totalFloors: 8,
    fullAddress: '12 5th Block',
  );

  group('Listings', () {
    test('create sends only keys PropertyCreate declares', () async {
      final recorder = api();
      await recorder.container
          .read(listingsRepositoryProvider)
          .createListing(listing);

      expect(recorder.last.method, 'POST');
      expect(recorder.last.path, '/properties');
      expectBodyMatchesContract(recorder.lastBody, 'PropertyCreate');
      final body = recorder.lastBody;
      expect(body['society_vibe_tags'], ['quiet']);
      expect(body.containsKey('society_vibes'), isFalse);
      expect(body.containsKey('bathrooms'), isFalse);
      expect(body['available_from'], isNull);
      // The street is the typed `full_address`, not a listing preference.
      expect(body['full_address'], '12 5th Block');
      expect(
        (body['listing_preferences'] as Map).containsKey('full_address'),
        isFalse,
      );
    });

    test('update sends only keys PropertyUpdate declares', () async {
      final recorder = api();
      await recorder.container
          .read(listingsRepositoryProvider)
          .updateListing(7, listing);

      expect(recorder.last.method, 'PUT');
      expect(recorder.last.path, '/properties/7');
      expectBodyMatchesContract(recorder.lastBody, 'PropertyUpdate');
    });

    test(
      'update clears a field the owner emptied with an explicit null',
      () async {
        final recorder = api();
        await recorder.container
            .read(listingsRepositoryProvider)
            .updateListing(7, listing);

        final body = recorder.lastBody;
        // maintenance_charges is blank in the form: the key is sent as null.
        expect(body.containsKey('maintenance_charges'), isTrue);
        expect(body['maintenance_charges'], isNull);
        // area_sqft has no form control: the key is left out.
        expect(body.containsKey('area_sqft'), isFalse);
      },
    );

    test(
      'the owner pause and resume toggle sends the moderation status',
      () async {
        final recorder = api();
        final repo = recorder.container.read(listingsRepositoryProvider);

        await repo.togglePause(7, paused: false);
        expectBodyMatchesContract(recorder.lastBody, 'PropertyUpdate');
        expect(recorder.lastBody, {
          'listing_preferences': {'moderation_status': 'paused'},
        });

        await repo.togglePause(7, paused: true);
        expect(recorder.lastBody, {
          'listing_preferences': {'moderation_status': 'live'},
        });
        // The status the toggle sends is one of the backend's.
        expect(
          backendEnum('ListingModerationStatus'),
          containsAll(['live', 'paused']),
        );
      },
    );

    test('the owner list asks only for declared keys', () async {
      final recorder = api();
      await recorder.container
          .read(listingsRepositoryProvider)
          .fetchMyListings();

      for (final request in recorder.requests) {
        expectQueryMatchesContract(
          request.queryParameters,
          'GET /api/v1/properties/me',
        );
      }
    });
  });

  group('Discover and swipe feeds', () {
    test('the listing feed with every filter asks for declared keys', () async {
      final recorder = api();
      await recorder.container
          .read(discoverRepositoryProvider)
          .fetchListingsPage(
            filters: const DiscoverFilters(
              query: 'quiet',
              location: 'Koramangala',
              priceMin: 10000,
              priceMax: 30000,
              sharingType: 'private_room',
              genderPreference: 'female',
              features: ['wifi'],
              furnishing: ['furnished'],
              kitchenType: ['vegetarian'],
              ventilationType: ['good'],
              amenities: ['Gym'],
              windowsMin: 2,
              hasLift: true,
              bedrooms: 2,
              moveInTimeline: 'within_1_month',
              latitude: 12.93,
              longitude: 77.62,
              radiusKm: 250,
            ),
          );

      expectQueryMatchesContract(
        recorder.last.queryParameters,
        'GET /api/v1/properties',
      );
      // The radius is limited to what the API accepts.
      expect(recorder.last.queryParameters['radius'], 100);
    });

    test('an enum filter this build does not know is not sent', () async {
      final recorder = api();
      await recorder.container
          .read(discoverRepositoryProvider)
          .fetchListingsPage(
            filters: const DiscoverFilters(
              sharingType: 'dorm',
              furnishing: ['posh'],
              moveInTimeline: 'whenever',
            ),
          );

      final query = recorder.last.queryParameters;
      expect(query.containsKey('sharing_type'), isFalse);
      expect(query.containsKey('furnishing'), isFalse);
      expect(query.containsKey('move_in'), isFalse);
    });

    test('the peer feed asks for declared keys, gender included', () async {
      final recorder = api();
      await recorder.container
          .read(swipeRepositoryProvider)
          .fetchSwipeProfilesPage(
            filters: const DiscoverFilters(
              moveInTimeline: 'this_month',
              ageMin: 5,
              ageMax: 140,
              latitude: 12.93,
              longitude: 77.62,
              radiusKm: 5,
            ),
          );

      expectQueryMatchesContract(
        recorder.last.queryParameters,
        'GET /api/v1/flatmates/profiles',
      );
      // age_min and age_max are limited to 18..100.
      expect(recorder.last.queryParameters['age_min'], 18);
      expect(recorder.last.queryParameters['age_max'], 100);
    });

    test('swipes send a SwipeRequest', () async {
      final recorder = api();
      final swipes = recorder.container.read(swipeRepositoryProvider);
      final discover = recorder.container.read(discoverRepositoryProvider);

      await swipes.swipeProfile(targetUserId: 2, action: SwipeAction.like);
      expectBodyMatchesContract(recorder.lastBody, 'SwipeRequest');
      await discover.setLiked(42, true);
      expectBodyMatchesContract(recorder.lastBody, 'SwipeRequest');
      expect(recorder.lastBody['target_type'], 'property');
      await recorder.container
          .read(chatsRepositoryProvider)
          .matchIncomingLike(peerId: 3, contextPropertyId: 42);
      expectBodyMatchesContract(recorder.lastBody, 'SwipeRequest');
    });

    test('a profile view is limited to 3600 seconds', () async {
      final recorder = api();
      await recorder.container
          .read(swipeRepositoryProvider)
          .recordProfileView(
            targetUserId: 2,
            durationSeconds: 7200,
            scrollDepthPercent: 140,
          );

      expectBodyMatchesContract(recorder.lastBody, 'ProfileViewEventCreate');
      expect(recorder.lastBody['duration_seconds'], 3600);
      expect(recorder.lastBody['scroll_depth_percent'], 100);
    });

    test('a society tag vote sends a SocietyTagVoteCreate', () async {
      final recorder = api();
      await recorder.container
          .read(discoverRepositoryProvider)
          .voteSocietyTag(listingId: 42, tag: 'quiet', vote: 'up');

      expectBodyMatchesContract(recorder.lastBody, 'SocietyTagVoteCreate');
    });
  });

  group('Chats', () {
    test('messages, conversations, blocks, reports and QnA', () async {
      final recorder = api();
      final chats = recorder.container.read(chatsRepositoryProvider);

      await chats.sendMessage(conversationId: 10, body: 'Hello');
      expectBodyMatchesContract(recorder.lastBody, 'MessageCreate');
      expect(recorder.lastBody['message_type'], 'text');

      await chats.sendMessage(
        conversationId: 10,
        attachmentUrl: 'https://cdn.example.com/p.jpg',
        messageType: MessageType.image,
      );
      expectBodyMatchesContract(recorder.lastBody, 'MessageCreate');

      await chats.startConversation(peerId: 2, initialMessage: 'Hi');
      expectBodyMatchesContract(recorder.lastBody, 'ConversationCreate');

      await chats.blockUser(3);
      expectBodyMatchesContract(recorder.lastBody, 'BlockCreate');

      await chats.unmatchConversation(10, 3);
      expectBodyMatchesContract(recorder.lastBody, 'UnmatchPairRequest');

      await chats.reportUser(3, 'abuse');
      expectBodyMatchesContract(recorder.lastBody, 'ReportCreate');

      await chats.submitQnA(10, {'q1': 'A', 'q2': 'B', 'q3': 'C'});
      expectBodyMatchesContract(recorder.lastBody, 'QnAAnswers');
    });

    test('the match Q&A sheet sends the same QnAAnswers body', () async {
      final recorder = api();

      final ok = await recorder.container
          .read(matchQnAControllerProvider.notifier)
          .submitAnswers(
            conversationId: 9,
            q1: ' Early riser ',
            q2: '4',
            q3: '',
          );

      expect(ok, isTrue);
      expect(recorder.last.path, '/flatmates/conversations/9/qna');
      expectBodyMatchesContract(recorder.lastBody, 'QnAAnswers');
      // Keys "0", "1", "2"; a blank answer is left out.
      expect(recorder.lastBody['answers'], {'0': 'Early riser', '1': '4'});
    });

    test('the visit request chat message is a text message', () async {
      final recorder = api();
      final locale = await AppLocalizations.delegate.load(const Locale('en'));
      await recorder.container
          .read(visitsRepositoryProvider)
          .scheduleVisitAndNotify(
            propertyId: 42,
            counterpartyUserId: 2,
            conversationId: 10,
            scheduledDate: DateTime.utc(2026, 10, 4, 5, 30),
            locale: locale,
            timeSlotLabel: 'Morning (9 to 12)',
          );

      final message = recorder
          .to('POST', '/flatmates/conversations/10/messages')
          .single;
      final body = Map<String, dynamic>.from(message.data as Map);
      expectBodyMatchesContract(body, 'MessageCreate');
      // The API takes `text` or `image` from a client: `visit_request` is a
      // 422 (the schema lists it, the validator refuses it).
      expect(body['message_type'], 'text');
      // The visit the server created (fixture visits.created has id 8).
      expect((body['metadata'] as Map)['visit_id'], 8);
    });

    test('the lists ask for declared keys and at most 100 rows', () async {
      final recorder = api();
      final chats = recorder.container.read(chatsRepositoryProvider);

      await chats.fetchConversations();
      await chats.fetchIncomingLikes();
      await chats.fetchOutgoingLikes();
      await chats.fetchMessages(10, limit: 100);

      for (final request in recorder.requests) {
        final path = request.path;
        final operation = switch (path) {
          '/flatmates/conversations' => 'GET /api/v1/flatmates/conversations',
          '/flatmates/likes' => 'GET /api/v1/flatmates/likes',
          '/flatmates/outgoing-likes' => 'GET /api/v1/flatmates/outgoing-likes',
          _ => 'GET /api/v1/flatmates/conversations/{conversation_id}/messages',
        };
        expectQueryMatchesContract(request.queryParameters, operation);
      }
    });
  });

  group('Visits', () {
    test('create, confirm, reschedule and cancel send declared keys', () async {
      final recorder = api();
      final visits = recorder.container.read(visitsRepositoryProvider);

      await visits.scheduleFlatmateVisit(
        propertyId: 42,
        counterpartyUserId: 2,
        conversationId: 10,
        scheduledDate: DateTime.utc(2026, 10, 4, 5, 30),
        note: 'See you',
        timeSlotLabel: 'Morning (9 to 12)',
      );
      expectBodyMatchesContract(recorder.lastBody, 'VisitCreate');

      await visits.confirmVisit(5);
      expect(recorder.last.method, 'PUT');
      expectBodyMatchesContract(recorder.lastBody, 'VisitUpdate');

      await visits.rescheduleVisit(
        5,
        DateTime.utc(2026, 10, 6, 9),
        reason: 'Traffic',
      );
      expect(recorder.last.path, '/visits/5/reschedule');
      expectBodyMatchesContract(recorder.lastBody, 'VisitReschedule');

      await visits.cancelVisit(5, reason: 'Plans changed');
      expect(recorder.last.path, '/visits/5/cancel');
      expectBodyMatchesContract(recorder.lastBody, 'VisitCancel');
    });

    test(
      'the visit list asks for declared keys and at most 100 rows',
      () async {
        final recorder = api();
        await recorder.container.read(visitsRepositoryProvider).fetchVisits();

        for (final request in recorder.requests) {
          expectQueryMatchesContract(
            request.queryParameters,
            'GET /api/v1/visits',
          );
        }
      },
    );

    test('a flatmates visit PUT never carries the removed keys', () async {
      final recorder = api();
      await recorder.container.read(visitsRepositoryProvider).confirmVisit(5);

      for (final removed in const [
        'scheduled_date',
        'cancellation_reason',
        'visit_context',
        'counterparty_user_id',
        'conversation_id',
        'match_id',
      ]) {
        expect(recorder.lastBody.containsKey(removed), isFalse);
      }
    });
  });

  group('Settings, notifications, feedback', () {
    test('notification settings send the four contract keys', () async {
      final recorder = api();
      await recorder.container
          .read(settingsRepositoryProvider)
          .updateNotificationSettings(const RemoteNotificationSettings());

      expectBodyMatchesContract(recorder.lastBody, 'NotificationSettingsWrite');
      expect(recorder.lastBody.keys.toSet(), {
        'push_notifications',
        'email_notifications',
        'sms_notifications',
        'promotional_emails',
      });
    });

    test('privacy settings go to the typed route as a partial patch', () async {
      final recorder = api();
      await recorder.container
          .read(settingsRepositoryProvider)
          .updatePrivacySettings({'hide_last_name': true});

      expect(recorder.last.path, '/users/privacy-settings');
      expectBodyMatchesContract(recorder.lastBody, 'PrivacySettingsPatch');
      expect(recorder.lastBody, {'hide_last_name': true});
    });

    test('marking notifications read sends declared bodies', () async {
      final recorder = api();
      final repo = recorder.container.read(notificationsRepositoryProvider);

      await repo.markAsRead('n-1');
      expectBodyMatchesContract(
        recorder.lastBody,
        'FlatmatesNotificationUpdate',
      );
      await repo.markAllAsRead();
      expectBodyMatchesContract(
        recorder.lastBody,
        'FlatmatesNotificationBulkUpdate',
      );
      await repo.fetchNotificationsPage();
      expectQueryMatchesContract(
        recorder.last.queryParameters,
        'GET /api/v1/flatmates/notifications',
      );
    });

    test('a bug report sends device_info as an object', () async {
      final recorder = api();
      await recorder.container
          .read(feedbackRepositoryProvider)
          .submitBugReport(
            title: 'Crash',
            description: 'It crashed',
            bugType: 'crash',
            severity: 'high',
            appVersion: '1.0.9',
            deviceInfo: const {'os': 'ios', 'model': 'iPhone 15'},
          );

      expectBodyMatchesContract(recorder.lastBody, 'BugReportCreate');
      expect(recorder.lastBody['device_info'], isA<Map<dynamic, dynamic>>());
    });

    test('the version check sends ios or android and a numeric build', () {
      final ios = versionCheckBody(
        version: '1.0.9',
        buildNumber: '18',
        platform: TargetPlatform.iOS,
      );
      final android = versionCheckBody(
        version: '1.0.9',
        buildNumber: '18',
        platform: TargetPlatform.android,
      );

      expectBodyMatchesContract(ios, 'AppVersionCheckRequest');
      expectBodyMatchesContract(android, 'AppVersionCheckRequest');
      // Never the Dart enum name ("iOS").
      expect(ios['platform'], 'ios');
      expect(android['platform'], 'android');
      expect(ios['build_number'], 18);
      expect(ios['app'], 'flatmates');
    });

    test('a build number that is not numeric is left out', () {
      final body = versionCheckBody(
        version: '1.0.9',
        buildNumber: '18-beta',
        platform: TargetPlatform.iOS,
      );

      expect(body.containsKey('build_number'), isFalse);
      expectBodyMatchesContract(body, 'AppVersionCheckRequest');
    });

    test('device register carries app_key, unregister a JSON token', () {
      final register = deviceRegisterBody('fcm-token', isIOS: true);
      final unregister = deviceUnregisterBody('fcm-token');

      expectBodyMatchesContract(register, 'DeviceRegisterIn');
      expectBodyMatchesContract(unregister, 'DeviceUnregisterIn');
      expect(register['app_key'], 'flatmates');
      expect(register['platform'], 'ios');
      expect(deviceRegisterBody('t', isIOS: false)['platform'], 'android');
    });
  });
}
