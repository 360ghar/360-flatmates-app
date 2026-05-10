import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/core/deep_links/deep_link_service.dart';

void main() {
  group('DeepLinkService', () {
    test('builds the public flatmates entry URL with a city hint', () {
      final uri = Uri.parse(
        DeepLinkService.flatmatesUrl(city: 'Bengaluru East'),
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'the360ghar.com');
      expect(uri.path, '/flatmates');
      expect(uri.queryParameters, {'city': 'Bengaluru East'});
    });

    test('omits empty city hints from the public flatmates entry URL', () {
      expect(
        DeepLinkService.flatmatesUrl(city: '  '),
        'https://the360ghar.com/flatmates',
      );
    });

    test('maps public listing and chat links to app routes', () {
      expect(
        DeepLinkService.internalPathForUri(
          Uri.parse('https://the360ghar.com/flatmates/listing/42'),
        ),
        '/flat-details/42',
      );
      expect(
        DeepLinkService.internalPathForUri(
          Uri.parse('https://the360ghar.com/flatmates/chat/7'),
        ),
        '/chats/7',
      );
    });
  });
}
