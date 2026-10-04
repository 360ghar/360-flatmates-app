import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/auth/presentation/widgets/terms_checkbox.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

import '../../helpers/test_helpers.dart';

/// Every semantics node in the tree that exposes a tap action, with its label.
List<String> _tapTargets(WidgetTester tester) {
  final root = tester
      .binding
      .renderViews
      .first
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!;
  final labels = <String>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.hasAction(SemanticsAction.tap)) {
      labels.add(data.label);
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return labels;
}

void main() {
  group('TermsCheckbox semantics', () {
    testWidgets('exposes one control for the checkbox action', (tester) async {
      final handle = tester.ensureSemantics();

      var accepted = false;
      await tester.pumpWidget(
        testableWidget(
          child: Theme(
            data: AppTheme.build(brightness: Brightness.light),
            child: Scaffold(
              body: Builder(
                builder: (context) => TermsCheckbox(
                  accepted: accepted,
                  onChanged: (value) => accepted = value,
                  locale: AppLocalizations.of(context),
                  theme: Theme.of(context),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final targets = _tapTargets(tester);
      // The checkbox itself plus the two inline links — nothing else. The
      // row InkWell wraps the checkbox, so without `excludeFromSemantics`
      // assistive technology also gets an unlabelled control that toggles
      // the same setting.
      expect(targets, hasLength(3));
      expect(targets.where((label) => label.isEmpty), isEmpty);

      handle.dispose();
    });
  });
}
