import 'dart:async';

import 'package:flatmates_app/core/network/connectivity_monitor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
    _AppSubtreeState.inits = 0;
    _AppSubtreeState.disposals = 0;
  });

  testWidgets('keeps the app subtree mounted across connectivity changes', (
    tester,
  ) async {
    final connectivity = StreamController<bool>();
    addTearDown(connectivity.close);

    final widget = await testableWidgetAsync(
      child: const OfflineBanner(child: _AppSubtree()),
      overrides: [
        connectivityProvider.overrideWith((ref) => connectivity.stream),
      ],
    );
    await tester.pumpWidget(widget);

    // Initial snapshot: online, no strip.
    connectivity.add(true);
    await tester.pump();
    expect(find.text('You are offline. Check your connection.'), findsNothing);
    final state = tester.state(find.byType(_AppSubtree));
    final onlineTop = tester.getTopLeft(find.byType(_AppSubtree)).dy;

    // Offline: the strip appears in the layout flow, pushing the app down
    // instead of covering it, and the app subtree is not re-inflated.
    connectivity.add(false);
    await tester.pump();
    await tester.pump();
    expect(
      find.text('You are offline. Check your connection.'),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byType(_AppSubtree)).dy,
      greaterThan(onlineTop),
    );
    expect(tester.state(find.byType(_AppSubtree)), same(state));

    // Back online: the strip goes away and the same State object is still
    // mounted — the tree shape never changed.
    connectivity.add(true);
    await tester.pump();
    await tester.pump();
    expect(find.text('You are offline. Check your connection.'), findsNothing);
    expect(tester.state(find.byType(_AppSubtree)), same(state));
    expect(tester.getTopLeft(find.byType(_AppSubtree)).dy, onlineTop);
    expect(_AppSubtreeState.inits, 1);
    expect(_AppSubtreeState.disposals, 0);
  });
}

/// Records how often Flutter inflates and deactivates the app subtree: a
/// changed root widget type at the [OfflineBanner] position would dispose and
/// recreate it on every connectivity change.
class _AppSubtree extends StatefulWidget {
  const _AppSubtree();

  @override
  State<_AppSubtree> createState() => _AppSubtreeState();
}

class _AppSubtreeState extends State<_AppSubtree> {
  static int inits = 0;
  static int disposals = 0;

  @override
  void initState() {
    super.initState();
    inits++;
  }

  @override
  void dispose() {
    disposals++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 200, width: 200, child: Placeholder());
}
