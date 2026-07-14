// This is a basic Flutter widget test for the 360 FlatMates app.
//
// It verifies that the app's core widget infrastructure (ProviderScope,
// MaterialApp, localization) can be set up in a test environment using
// the shared test helpers.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App infrastructure', () {
    testWidgets(
      'testableWidget provides a working ProviderScope + MaterialApp',
      (tester) async {
        await tester.pumpWidget(
          testableWidget(
            child: const Scaffold(
              body: Center(child: Text('Hello 360 FlatMates')),
            ),
          ),
        );

        expect(find.text('Hello 360 FlatMates'), findsOneWidget);
      },
    );

    testWidgets('testableWidgetAsync sets up settings provider', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final widget = await testableWidgetAsync(
        child: const Scaffold(body: Center(child: Text('Settings Ready'))),
      );

      await tester.pumpWidget(widget);

      expect(find.text('Settings Ready'), findsOneWidget);
    });
  });
}
