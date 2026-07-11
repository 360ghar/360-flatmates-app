import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/core/deep_links/deep_link_service.dart';

void main() {
  group('DeepLinkService.internalPathForUri', () {
    test('/flatmates/listing/{id} parses to listing route', () {
      final path = DeepLinkService.internalPathForUri(
        Uri.parse('https://the360ghar.com/flatmates/listing/123'),
      );
      expect(path, '/flat-details/123');
    });

    test('/flatmates/chat/{id} parses to chat route', () {
      final path = DeepLinkService.internalPathForUri(
        Uri.parse('https://the360ghar.com/flatmates/chat/456'),
      );
      expect(path, '/chats/456');
    });

    test('invalid paths are ignored (return null)', () {
      final path = DeepLinkService.internalPathForUri(
        Uri.parse('https://the360ghar.com/unknown/path'),
      );
      expect(path, isNull);
    });

    test('listing with id 0 is rejected', () {
      final path = DeepLinkService.internalPathForUri(
        Uri.parse('https://the360ghar.com/flatmates/listing/0'),
      );
      expect(path, isNull);
    });

    test('chat with id 0 is rejected', () {
      final path = DeepLinkService.internalPathForUri(
        Uri.parse('https://the360ghar.com/flatmates/chat/0'),
      );
      expect(path, isNull);
    });

    test('listing with leading zeros is rejected', () {
      final path = DeepLinkService.internalPathForUri(
        Uri.parse('https://the360ghar.com/flatmates/listing/007'),
      );
      expect(path, isNull);
    });

    test('listing with non-numeric id is rejected', () {
      final path = DeepLinkService.internalPathForUri(
        Uri.parse('https://the360ghar.com/flatmates/listing/abc'),
      );
      expect(path, isNull);
    });

    test('/flatmates without city maps to /discover', () {
      final path = DeepLinkService.internalPathForUri(
        Uri.parse('https://the360ghar.com/flatmates'),
      );
      expect(path, '/discover');
    });

    test('/flatmates?city=bangalore maps to /waitlist?city=bangalore', () {
      final path = DeepLinkService.internalPathForUri(
        Uri.parse('https://the360ghar.com/flatmates?city=bangalore'),
      );
      expect(path, contains('/waitlist'));
      expect(path, contains('city=bangalore'));
    });

    test('/flatmates?city= (empty) maps to /discover', () {
      final path = DeepLinkService.internalPathForUri(
        Uri.parse('https://the360ghar.com/flatmates?city='),
      );
      expect(path, '/discover');
    });
  });

  group('DeepLinkService URL builders', () {
    test('listingUrl builds correct public URL', () {
      final url = DeepLinkService.listingUrl(123);
      expect(url, 'https://the360ghar.com/flatmates/listing/123');
    });

    test('chatUrl builds correct public URL', () {
      final url = DeepLinkService.chatUrl(456);
      expect(url, 'https://the360ghar.com/flatmates/chat/456');
    });

    test('flatmatesUrl without city builds base URL', () {
      final url = DeepLinkService.flatmatesUrl();
      expect(url, 'https://the360ghar.com/flatmates');
    });

    test('flatmatesUrl with city includes query param', () {
      final url = DeepLinkService.flatmatesUrl(city: 'bangalore');
      expect(url, contains('city=bangalore'));
    });
  });

  group('DeepLinkService.consumePendingDeepLink', () {
    test('returns null when no pending link is set', () {
      // Consume any existing pending link first.
      DeepLinkService.consumePendingDeepLink();
      expect(DeepLinkService.consumePendingDeepLink(), isNull);
    });
  });
}
