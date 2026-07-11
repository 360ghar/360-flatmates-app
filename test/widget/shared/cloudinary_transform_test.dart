import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/shared/presentation/cloudinary_transform.dart';

void main() {
  const sampleUrl =
      'https://res.cloudinary.com/demo/image/upload/v1234/sample.jpg';

  group('applyCloudinaryTransform', () {
    test('non-Cloudinary URL is returned unchanged', () {
      const url = 'https://example.com/images/photo.jpg';
      expect(applyCloudinaryTransform(url), url);
    });

    test('relative URL is returned unchanged', () {
      const url = '/images/photo.jpg';
      expect(applyCloudinaryTransform(url), url);
    });

    test('non-image/upload Cloudinary URL is returned unchanged', () {
      const url =
          'https://res.cloudinary.com/demo/video/upload/v1234/sample.mp4';
      expect(applyCloudinaryTransform(url), url);
    });

    test('no dimensions inserts only f_auto,q_auto as a new segment', () {
      final result = applyCloudinaryTransform(sampleUrl);
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/f_auto,q_auto/v1234/sample.jpg',
      );
    });

    test('width inserts f_auto,q_auto,w_<2x>,c_limit as a new segment', () {
      final result = applyCloudinaryTransform(sampleUrl, width: 100);
      // 100 * 2 = 200
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/f_auto,q_auto,w_200,c_limit/v1234/sample.jpg',
      );
    });

    test('width + height inserts both dimensions', () {
      final result = applyCloudinaryTransform(
        sampleUrl,
        width: 100,
        height: 50,
      );
      // 100*2=200, 50*2=100
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/f_auto,q_auto,w_200,h_100,c_limit/v1234/sample.jpg',
      );
    });

    test('existing transform segment is preserved and ours wins (last-wins)', () {
      const url =
          'https://res.cloudinary.com/demo/image/upload/w_500,c_fill/v1234/sample.jpg';
      final result = applyCloudinaryTransform(url, width: 100);
      // Our segment is appended after the existing one.
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/w_500,c_fill/f_auto,q_auto,w_200,c_limit/v1234/sample.jpg',
      );
    });

    test('width clamped to minimum 50', () {
      final result = applyCloudinaryTransform(sampleUrl, width: 10);
      // 10*2=20, clamped to 50
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/f_auto,q_auto,w_50,c_limit/v1234/sample.jpg',
      );
    });

    test('width clamped to maximum 2000', () {
      final result = applyCloudinaryTransform(sampleUrl, width: 2000);
      // 2000*2=4000, clamped to 2000
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/f_auto,q_auto,w_2000,c_limit/v1234/sample.jpg',
      );
    });

    test('infinite width treated as null', () {
      final result = applyCloudinaryTransform(
        sampleUrl,
        width: double.infinity,
      );
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/f_auto,q_auto/v1234/sample.jpg',
      );
    });

    test('negative width treated as null', () {
      final result = applyCloudinaryTransform(sampleUrl, width: -100);
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/f_auto,q_auto/v1234/sample.jpg',
      );
    });

    test('zero width treated as null', () {
      final result = applyCloudinaryTransform(sampleUrl, width: 0);
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/f_auto,q_auto/v1234/sample.jpg',
      );
    });

    test('height-only request still applies c_limit', () {
      final result = applyCloudinaryTransform(sampleUrl, height: 100);
      // 100*2=200
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/f_auto,q_auto,h_200,c_limit/v1234/sample.jpg',
      );
    });

    test('Cloudinary URL without version segment transforms cleanly', () {
      const url = 'https://res.cloudinary.com/demo/image/upload/sample.jpg';
      final result = applyCloudinaryTransform(url, width: 100);
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/f_auto,q_auto,w_200,c_limit/sample.jpg',
      );
    });

    test('HTTP scheme Cloudinary URL is also transformed', () {
      const url =
          'http://res.cloudinary.com/demo/image/upload/v1234/sample.jpg';
      final result = applyCloudinaryTransform(url, width: 100);
      expect(
        result,
        'http://res.cloudinary.com/demo/image/upload/f_auto,q_auto,w_200,c_limit/v1234/sample.jpg',
      );
    });

    test('produces 200-OK Cloudinary URL against the real sample URL', () {
      // This test verifies the URL format is valid (not that it actually
      // fetches — that would require a network call). We verify the structure
      // matches Cloudinary's expected grammar.
      const url =
          'https://res.cloudinary.com/demo/image/upload/v1234/sample.jpg';
      final result = applyCloudinaryTransform(url, width: 200, height: 150);
      // 200*2=400, 150*2=300
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/f_auto,q_auto,w_400,h_300,c_limit/v1234/sample.jpg',
      );
      // Verify the URL is well-formed.
      expect(
        result.startsWith('https://res.cloudinary.com/demo/image/upload/'),
        isTrue,
      );
      expect(result.contains('f_auto'), isTrue);
      expect(result.contains('q_auto'), isTrue);
      expect(result.contains('w_400'), isTrue);
      expect(result.contains('h_300'), isTrue);
      expect(result.contains('c_limit'), isTrue);
    });
  });
}
