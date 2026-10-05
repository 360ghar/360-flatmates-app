import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/core/theme/app_shadows.dart';

const BoxShadow _probe = BoxShadow(blurRadius: 1);

void main() {
  group('AppShadows shared aliases are unmodifiable', () {
    test('elevation rejects every mutation', () {
      expect(AppShadows.elevation, hasLength(2));

      expect(() => AppShadows.elevation.add(_probe), throwsUnsupportedError);
      expect(() => AppShadows.elevation[0] = _probe, throwsUnsupportedError);
      expect(() => AppShadows.elevation.clear(), throwsUnsupportedError);
      expect(() => AppShadows.elevation.removeAt(0), throwsUnsupportedError);
      expect(() => AppShadows.elevation.sort(), throwsUnsupportedError);

      // The failed attempts left the app-wide list untouched.
      expect(AppShadows.elevation, hasLength(2));
    });

    test('elevationDark rejects every mutation', () {
      expect(AppShadows.elevationDark, hasLength(2));

      expect(
        () => AppShadows.elevationDark.add(_probe),
        throwsUnsupportedError,
      );
      expect(
        () => AppShadows.elevationDark[0] = _probe,
        throwsUnsupportedError,
      );
      expect(() => AppShadows.elevationDark.clear(), throwsUnsupportedError);

      expect(AppShadows.elevationDark, hasLength(2));
    });

    test('the aliases mirror e2 for their brightness', () {
      expect(AppShadows.elevation, AppShadows.e2(Brightness.light));
      expect(AppShadows.elevationDark, AppShadows.e2(Brightness.dark));
    });
  });

  group('AppShadows.e1/e2/e3 stay locally growable', () {
    test('each call returns a fresh list', () {
      for (final shadows in <List<BoxShadow> Function(Brightness)>[
        AppShadows.e1,
        AppShadows.e2,
        AppShadows.e3,
      ]) {
        final first = shadows(Brightness.light);
        final second = shadows(Brightness.light);

        expect(identical(first, second), isFalse);
        expect(first, second);

        // A caller may grow its own copy without affecting the next caller.
        first.add(_probe);
        expect(first, hasLength(3));
        expect(shadows(Brightness.light), hasLength(2));
      }
    });

    test('the light and dark lists differ', () {
      expect(
        AppShadows.e2(Brightness.light),
        isNot(AppShadows.e2(Brightness.dark)),
      );
    });
  });
}
