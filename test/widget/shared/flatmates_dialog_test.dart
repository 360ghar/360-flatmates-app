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

  testWidgets('a delayed close after a dismissal never pops the page', (
    tester,
  ) async {
    final navKey = GlobalKey<NavigatorState>();
    late void Function([bool? value]) delayedClose;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        theme: AppTheme.build(brightness: Brightness.light),
        home: const Scaffold(body: Text('page')),
      ),
    );
    unawaited(
      FlatmatesDialog.custom<bool>(
        navKey.currentContext!,
        title: 'Discard changes?',
        actions: (ctx, setState, close) {
          delayedClose = close;
          return [
            TextButton(
              onPressed: () => close(true),
              child: const Text('Discard'),
            ),
          ];
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    // Barrier dismissal: the dialog route is no longer the current one while
    // it animates out.
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(Dialog), findsOneWidget);

    // A delayed action fires now. Without the route check it pops the page.
    delayedClose();
    await tester.pumpAndSettle();

    expect(find.text('page'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });
}
