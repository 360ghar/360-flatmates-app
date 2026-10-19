import 'package:flatmates_app/core/deep_links/deep_link_service.dart';
import 'package:flatmates_app/core/notifications/notification_service.dart';
import 'package:flatmates_app/features/notifications/notification_route_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

import 'api_fixtures.dart';

/// Push data and deep links as the backend builds them: `type_key` and
/// `route` are top-level keys, the link paths come from the deep-link
/// registry, and the Android channel is the one this app creates.
void main() {
  final links = apiFixtureGroup('deeplinks');
  final chat = Map<String, dynamic>.from(links['chat'] as Map);
  final listing = Map<String, dynamic>.from(links['listing'] as Map);

  group('push data', () {
    test('type_key and route are top-level data keys', () {
      final push = apiFixture('notifications', 'push_message');
      final data = Map<String, dynamic>.from(push['data'] as Map);

      expect(data['type_key'], 'flatmate_new_message');
      expect(data['route'], '/flatmates/chat/10');
      expect(data.containsKey('deep_link'), isFalse);
    });

    test('the push channel is the channel the app creates', () {
      final push = apiFixture('notifications', 'push_message');

      expect(push['android_channel_id'], 'flatmates_messages');
    });

    test('the foreground filter reads type_key only', () {
      final message = Map<String, dynamic>.from(
        apiFixture('notifications', 'push_message')['data'] as Map,
      );
      final promotion = Map<String, dynamic>.from(
        apiFixture('notifications', 'push_promotion')['data'] as Map,
      );
      final visit = Map<String, dynamic>.from(
        apiFixture('notifications', 'push_type_only')['data'] as Map,
      );

      expect(
        foregroundPushAllowed(
          message['type_key'] as String?,
          messagesOn: false,
          promotionsOn: true,
        ),
        isFalse,
      );
      expect(
        foregroundPushAllowed(
          promotion['type_key'] as String?,
          messagesOn: true,
          promotionsOn: false,
        ),
        isFalse,
      );
      // No switch for a visit: always shown.
      expect(
        foregroundPushAllowed(
          visit['type_key'] as String?,
          messagesOn: false,
          promotionsOn: false,
        ),
        isTrue,
      );
      // A push with no type_key is shown.
      expect(
        foregroundPushAllowed(null, messagesOn: false, promotionsOn: false),
        isTrue,
      );
    });

    test('_meta is JSON text', () {
      final data = Map<String, dynamic>.from(
        apiFixture('notifications', 'push_message')['data'] as Map,
      );

      expect(data['_meta'], isA<String>());
      expect(data['_meta'] as String, startsWith('{'));
    });
  });

  group('deep links from the registry', () {
    test('the HTTPS chat path opens the chat thread', () {
      final path = DeepLinkService.internalPathForUri(
        Uri.parse('https://the360ghar.com${chat['https_path']}'),
      );

      expect(path, '/chats/42');
    });

    test('the HTTPS listing path opens the listing', () {
      final path = DeepLinkService.internalPathForUri(
        Uri.parse('https://the360ghar.com${listing['https_path']}'),
      );

      expect(path, '/flat-details/17');
    });

    test('the custom-scheme chat link is read by host and path', () {
      final uri = Uri.parse(chat['scheme_url'] as String);

      expect(uri.scheme, links['custom_scheme']);
      expect(uri.host, 'chat');
      expect(DeepLinkService.internalPathForUri(uri), '/chats/42');
    });

    test('the custom-scheme listing link is read by host and path', () {
      final uri = Uri.parse(listing['scheme_url'] as String);

      expect(DeepLinkService.internalPathForUri(uri), '/flat-details/17');
    });

    test('a custom-scheme link with a bad id or entity is ignored', () {
      for (final link in const [
        'com.the360ghar.flatmates360://chat/0',
        'com.the360ghar.flatmates360://chat/abc',
        'com.the360ghar.flatmates360://chat',
        'com.the360ghar.flatmates360://settings/42',
      ]) {
        expect(DeepLinkService.internalPathForUri(Uri.parse(link)), isNull);
      }
    });

    test('a push route of the registry opens the in-app route', () {
      final push = apiFixture('notifications', 'push_message');
      final route = (push['data'] as Map)['route'] as String;

      expect(resolveNotificationDeepLink(route), '/chats/10');
      expect(
        resolveNotificationDeepLink(chat['https_path'] as String),
        '/chats/42',
      );
      expect(
        resolveNotificationDeepLink(listing['https_path'] as String),
        '/flat-details/17',
      );
    });

    test('a notification list row opens its route', () {
      final row = apiFixtureItems('notifications', 'page').first;

      expect(
        resolveNotificationRoute(
          route: row['route'] as String?,
          type: row['type'] as String,
          referenceId: row['reference_id'] as int?,
        ),
        '/chats/10',
      );
    });

    test('legacy shell routes still resolve', () {
      expect(resolveNotificationDeepLink('/visits'), '/profile/visits');
      expect(resolveNotificationDeepLink('/post'), '/post/new');
    });
  });
}
