import 'package:flatmates_app/core/errors/app_failure.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_async_view.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_error_state.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(AsyncValue<List<String>> value) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: FlatmatesAsyncView<List<String>>(
      value: value,
      data: (items) => Text(items.join(',')),
    ),
  ),
);

void main() {
  testWidgets('a failed refresh keeps the loaded data on screen', (
    tester,
  ) async {
    const loaded = AsyncValue<List<String>>.data(['a', 'b']);
    final failedRefresh = const AsyncValue<List<String>>.error(
      NetworkFailure(),
      StackTrace.empty,
    ).copyWithPrevious(loaded);

    await tester.pumpWidget(_wrap(failedRefresh));

    expect(find.text('a,b'), findsOneWidget);
  });

  testWidgets('a first load that fails shows the error state', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AsyncValue<List<String>>.error(
          NetworkFailure(),
          StackTrace.empty,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('a,b'), findsNothing);
    expect(find.byType(FlatmatesErrorState), findsOneWidget);
  });
}
