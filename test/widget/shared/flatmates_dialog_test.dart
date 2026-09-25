import 'dart:async';

import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('confirm resolves true once; a double tap never pops the page', (
    tester,
  ) async {
    final results = <bool>[];
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        theme: AppTheme.build(brightness: Brightness.light),
        home: const Scaffold(body: Text('page')),
      ),
    );
    unawaited(
      FlatmatesDialog.confirm(
        navKey.currentContext!,
        title: 'Block user?',
        confirmLabel: 'Block',
        cancelLabel: 'Cancel',
        destructive: true,
      ).then(results.add),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Block'));
    await tester.tap(find.text('Block'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(results, [true]);
    expect(find.text('page'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('cancel resolves false', (tester) async {
    bool? result;
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navKey, home: const Scaffold()),
    );
    unawaited(
      FlatmatesDialog.confirm(
        navKey.currentContext!,
        title: 'Discard?',
        confirmLabel: 'Discard',
        cancelLabel: 'Keep',
      ).then((v) => result = v),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
