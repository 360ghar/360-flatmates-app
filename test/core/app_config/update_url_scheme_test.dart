import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/core/app_config/force_update_page.dart';
import 'package:flatmates_app/core/app_config/optional_update_dialog.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

/// Records every call the app makes on the `url_launcher` platform channel.
///
/// `url_launcher`'s default implementation in `flutter test` is
/// [MethodChannelUrlLauncher], so mocking this one channel is enough to see
/// whether the app asked the platform to open anything. A refused URL is
/// proven by the *absence* of a platform call, not by a log line.
class _LauncherSpy {
  _LauncherSpy(this._tester) {
    _tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (
      MethodCall call,
    ) async {
      calls.add(call);
      return true;
    });
  }

  static const MethodChannel _channel = MethodChannel(
    'plugins.flutter.io/url_launcher',
  );

  final WidgetTester _tester;
  final List<MethodCall> calls = <MethodCall>[];

  List<MethodCall> get launches =>
      calls.where((call) => call.method == 'launch').toList();

  void stop() {
    _tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _channel,
      null,
    );
  }
}

Future<_LauncherSpy> _installSpy(WidgetTester tester) async {
  final spy = _LauncherSpy(tester);
  addTearDown(spy.stop);
  return spy;
}

Widget _app({required Widget home}) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );
}

Future<void> _pumpForceUpdate(WidgetTester tester, String updateUrl) async {
  await tester.pumpWidget(_app(home: ForceUpdatePage(updateUrl: updateUrl)));
  await tester.pump();
}

Future<void> _tapForceUpdateCta(WidgetTester tester) async {
  await tester.tap(find.byType(FilledButton));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _pumpOptionalUpdate(WidgetTester tester, String updateUrl) async {
  await tester.pumpWidget(
    _app(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => OptionalUpdateDialog.show(
                context,
                updateUrl: updateUrl,
                message: 'A newer version is available.',
                onDismiss: () {},
              ),
              child: const Text('open dialog'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open dialog'));
  await tester.pumpAndSettle();
}

void main() {
  group('ForceUpdatePage update URL', () {
    testWidgets('refuses a javascript: URL without touching the platform', (
      tester,
    ) async {
      final spy = await _installSpy(tester);

      await _pumpForceUpdate(tester, 'javascript:alert(1)');
      await _tapForceUpdateCta(tester);

      expect(spy.calls, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('refuses a tel: URL without touching the platform', (
      tester,
    ) async {
      final spy = await _installSpy(tester);

      await _pumpForceUpdate(tester, 'tel:+919999999999');
      await _tapForceUpdateCta(tester);

      expect(spy.calls, isEmpty);
    });

    testWidgets('refuses an empty URL without touching the platform', (
      tester,
    ) async {
      final spy = await _installSpy(tester);

      await _pumpForceUpdate(tester, '');
      await _tapForceUpdateCta(tester);

      expect(spy.calls, isEmpty);
    });

    testWidgets('opens an https store URL externally', (tester) async {
      final spy = await _installSpy(tester);
      const url =
          'https://play.google.com/store/apps/details?id=com.the360ghar.flatmates360';

      await _pumpForceUpdate(tester, url);
      await _tapForceUpdateCta(tester);

      expect(spy.calls.map((call) => call.method), ['canLaunch', 'launch']);
      final args = spy.launches.single.arguments as Map<Object?, Object?>;
      expect(args['url'], url);
    });
  });

  group('OptionalUpdateDialog update URL', () {
    testWidgets('refuses a javascript: URL without touching the platform', (
      tester,
    ) async {
      final spy = await _installSpy(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await _pumpOptionalUpdate(tester, 'javascript:alert(1)');
      await tester.tap(find.text(l10n.optionalUpdateCta));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(spy.calls, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('refuses a tel: URL without touching the platform', (
      tester,
    ) async {
      final spy = await _installSpy(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await _pumpOptionalUpdate(tester, 'tel:+919999999999');
      await tester.tap(find.text(l10n.optionalUpdateCta));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(spy.calls, isEmpty);
    });

    testWidgets('opens an https store URL externally', (tester) async {
      final spy = await _installSpy(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      const url = 'https://apps.apple.com/app/id1234567890';

      await _pumpOptionalUpdate(tester, url);
      await tester.tap(find.text(l10n.optionalUpdateCta));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(spy.calls.map((call) => call.method), ['canLaunch', 'launch']);
      final args = spy.launches.single.arguments as Map<Object?, Object?>;
      expect(args['url'], url);
    });

    testWidgets('the Later action dismisses without launching', (tester) async {
      final spy = await _installSpy(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await _pumpOptionalUpdate(
        tester,
        'https://apps.apple.com/app/id1234567890',
      );
      await tester.tap(find.text(l10n.optionalUpdateLater));
      await tester.pumpAndSettle();

      expect(spy.calls, isEmpty);
      expect(find.text(l10n.optionalUpdateCta), findsNothing);
    });
  });
}
