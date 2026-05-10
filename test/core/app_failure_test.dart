import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/errors/app_failure.dart';

void main() {
  late UserMessageL10n l10n;

  setUp(() {
    l10n = const UserMessageL10n(
      errorNetwork: 'Network error',
      errorAuthExpired: 'Session expired',
      errorServer: 'Server error',
      errorPermission: 'No permission',
      errorNotFound: 'Not found',
      errorValidation: 'Invalid data',
      errorRateLimit: 'Too many requests',
      errorConflict: 'Conflict',
      errorUpload: 'Upload failed',
      errorUnknown: 'Unknown error',
    );
  });

  group('AppFailure', () {
    test('NetworkFailure returns network message', () {
      expect(const NetworkFailure().userMessage(l10n), 'Network error');
    });
    test('AuthExpiredFailure returns auth message', () {
      expect(const AuthExpiredFailure().userMessage(l10n), 'Session expired');
    });
    test('ServerFailure returns server message', () {
      expect(const ServerFailure().userMessage(l10n), 'Server error');
    });
    test('PermissionFailure returns permission message', () {
      expect(const PermissionFailure().userMessage(l10n), 'No permission');
    });
    test('NotFoundFailure returns not found message', () {
      expect(const NotFoundFailure().userMessage(l10n), 'Not found');
    });
    test('ValidationFailure with field messages joins them', () {
      const failure = ValidationFailure(
        fieldMessages: {'email': 'Invalid email', 'name': 'Required'},
      );
      expect(failure.userMessage(l10n), contains('Invalid email'));
      expect(failure.userMessage(l10n), contains('Required'));
    });
    test('ValidationFailure without field messages returns generic', () {
      expect(const ValidationFailure().userMessage(l10n), 'Invalid data');
    });
    test('RateLimitFailure returns rate limit message', () {
      expect(const RateLimitFailure().userMessage(l10n), 'Too many requests');
    });
    test('ConflictFailure returns conflict message', () {
      expect(const ConflictFailure().userMessage(l10n), 'Conflict');
    });
    test('UploadFailure with reason includes it', () {
      const failure = UploadFailure(reason: 'File too large');
      expect(failure.userMessage(l10n), contains('File too large'));
    });
    test('UploadFailure without reason returns generic', () {
      expect(const UploadFailure().userMessage(l10n), 'Upload failed');
    });
    test('UnknownFailure returns unknown message', () {
      expect(const UnknownFailure().userMessage(l10n), 'Unknown error');
    });
  });
}
