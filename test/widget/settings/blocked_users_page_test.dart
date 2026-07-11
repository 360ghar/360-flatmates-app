import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/features/settings/blocked_users_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('BlockedUsersPage', () {
    testWidgets('renders page without throwing', (tester) async {
      final widget = await testableWidgetAsync(child: const BlockedUsersPage());
      await tester.pumpWidget(widget);
      // Use pump() instead of pumpAndSettle() to avoid timing out on
      // async loading states that may depend on secure storage.
      await tester.pump();

      // The page should render without error.
      expect(find.byType(BlockedUsersPage), findsOneWidget);
    });
  });
}
