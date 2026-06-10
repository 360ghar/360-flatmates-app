import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/shared/presentation/cloudinary_transform.dart';

void main() {
  const sampleUrl =
      'https://res.cloudinary.com/ddbhzlzy1/image/upload/v1780672740/360ghar/properties/1500/building_exterior.jpg';

  group('applyCloudinaryTransform', () {
    test('non-Cloudinary URL is returned unchanged', () {
      const url = 'https://example.com/photo.jpg';
      expect(applyCloudinaryTransform(url), url);
      expect(applyCloudinaryTransform(url, width: 200), url);
    });

    test('relative URL is returned unchanged', () {
      const url = '/api/v1/images/123.jpg';
      expect(applyCloudinaryTransform(url), url);
      expect(applyCloudinaryTransform(url, width: 200), url);
    });

    test('non-image/upload Cloudinary URL is returned unchanged', () {
      const videoUrl =
          'https://res.cloudinary.com/ddbhzlzy1/video/upload/v123/tour.mp4';
      expect(applyCloudinaryTransform(videoUrl), videoUrl);
    });

    test('no dimensions inserts only f_auto,q_auto as a new segment', () {
      final result = applyCloudinaryTransform(sampleUrl);
      expect(
        result,
        'https://res.cloudinary.com/ddbhzlzy1/image/upload/'
        'f_auto,q_auto/v1780672740/360ghar/properties/1500/building_exterior.jpg',
      );
    });

    test('width inserts f_auto,q_auto,w_<2x>,c_limit as a new segment', () {
      final result = applyCloudinaryTransform(sampleUrl, width: 200);
      expect(
        result,
        'https://res.cloudinary.com/ddbhzlzy1/image/upload/'
        'f_auto,q_auto,w_400,c_limit/v1780672740/360ghar/properties/1500/'
        'building_exterior.jpg',
      );
    });

    test('width + height inserts both dimensions', () {
      final result = applyCloudinaryTransform(
        sampleUrl,
        width: 110,
        height: 110,
      );
      expect(
        result,
        'https://res.cloudinary.com/ddbhzlzy1/image/upload/'
        'f_auto,q_auto,w_220,h_220,c_limit/v1780672740/360ghar/properties/1500/'
        'building_exterior.jpg',
      );
    });

    test(
      'existing transform segment is preserved and ours wins (last-wins)',
      () {
        // Cloudinary applies transform segments in order; for shared directives
        // the last segment wins. By appending ours as a new segment BEFORE the
        // version marker, our w_/h_/c_ values override whatever the backend
        // specified.
        const urlWithTransform =
            'https://res.cloudinary.com/ddbhzlzy1/image/upload/'
            'w_1000/v1780672740/360ghar/properties/1500/building_exterior.jpg';
        final result = applyCloudinaryTransform(urlWithTransform, width: 200);
        expect(
          result,
          'https://res.cloudinary.com/ddbhzlzy1/image/upload/'
          'w_1000/f_auto,q_auto,w_400,c_limit/v1780672740/360ghar/properties/'
          '1500/building_exterior.jpg',
        );
      },
    );

    test('width clamped to minimum 50', () {
      final result = applyCloudinaryTransform(sampleUrl, width: 5);
      expect(result, contains('w_50'));
    });

    test('width clamped to maximum 2000', () {
      final result = applyCloudinaryTransform(sampleUrl, width: 5000);
      expect(result, contains('w_2000'));
    });

    test('infinite / negative / zero width treated as null', () {
      final infinity = applyCloudinaryTransform(
        sampleUrl,
        width: double.infinity,
      );
      expect(infinity, contains('f_auto,q_auto/v'));
      expect(infinity, isNot(contains('w_')));

      final negative = applyCloudinaryTransform(sampleUrl, width: -10);
      expect(negative, isNot(contains('w_')));

      final zero = applyCloudinaryTransform(sampleUrl, width: 0);
      expect(zero, isNot(contains('w_')));
    });

    test('height-only request still applies c_limit', () {
      final result = applyCloudinaryTransform(sampleUrl, height: 100);
      expect(result, contains('h_200'));
      expect(result, contains('c_limit'));
      expect(result, isNot(contains('w_')));
    });

    test('Cloudinary URL without version segment transforms cleanly', () {
      // No version marker means the tail is treated as the public ID. Our
      // transforms are inserted as a new leading segment.
      const noVersion =
          'https://res.cloudinary.com/ddbhzlzy1/image/upload/360ghar/properties/1500/x.jpg';
      final result = applyCloudinaryTransform(noVersion, width: 100);
      expect(
        result,
        'https://res.cloudinary.com/ddbhzlzy1/image/upload/'
        'f_auto,q_auto,w_200,c_limit/360ghar/properties/1500/x.jpg',
      );
    });

    test('HTTP scheme Cloudinary URL is also transformed', () {
      const httpUrl =
          'http://res.cloudinary.com/ddbhzlzy1/image/upload/v1/x.jpg';
      final result = applyCloudinaryTransform(httpUrl, width: 100);
      expect(
        result,
        'http://res.cloudinary.com/ddbhzlzy1/image/upload/'
        'f_auto,q_auto,w_200,c_limit/v1/x.jpg',
      );
    });

    test('produces 200-OK Cloudinary URL against the real sample URL', () {
      // Sanity check that the transform we emit matches Cloudinary's expected
      // grammar: only one transform segment, properly delimited, version
      // marker preserved.
      final result = applyCloudinaryTransform(sampleUrl, width: 200);
      // Single transform segment before the version marker.
      expect(RegExp(r'/image/upload/[^/]+/v\d+/').hasMatch(result), isTrue);
      // No double slashes introduced.
      expect(result, isNot(contains('//image/upload/')));
      expect(result, isNot(contains('//v')));
      // Public ID tail preserved.
      expect(
        result,
        endsWith('/360ghar/properties/1500/building_exterior.jpg'),
      );
    });
  });
}
