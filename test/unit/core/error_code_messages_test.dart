import 'package:flatmates_app/core/errors/l10n_bridge.dart';
import 'package:flatmates_app/l10n/gen/app_localizations_en.dart';
import 'package:flatmates_app/l10n/gen/app_localizations_hi.dart';
import 'package:flutter_test/flutter_test.dart';

/// The backend codes the app words itself (the backend text is English only).
const _codes = [
  'PROFILE_NOT_FOUND',
  'MATCH_NOT_FOUND',
  'PROFILE_STATUS_LOCKED',
  'LISTING_NOT_FOUND',
  'LISTING_STATUS_CONFLICT',
  'BLOCK_NOT_FOUND',
  'VISIT_CONFLICT',
  'VISIT_NOT_CANCELLABLE',
  'VISIT_NOT_RESCHEDULABLE',
  'USER_INACTIVE',
];

void main() {
  test('every code has English and Hindi copy', () {
    final en = AppLocalizationsEn().toUserMessageL10n();
    final hi = AppLocalizationsHi().toUserMessageL10n();

    for (final code in _codes) {
      final english = en.forCode(code);
      final hindi = hi.forCode(code);
      expect(english, isNotNull, reason: '$code has English copy');
      expect(english, isNotEmpty);
      expect(hindi, isNotNull, reason: '$code has Hindi copy');
      expect(hindi, isNot(english), reason: '$code is translated');
    }
  });

  test('a code the app has no copy for is null', () {
    final en = AppLocalizationsEn().toUserMessageL10n();

    expect(en.forCode('SOME_NEW_CODE'), isNull);
    expect(en.forCode(null), isNull);
  });
}
