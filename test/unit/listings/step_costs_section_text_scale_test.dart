import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/listings/presentation/widgets/step_costs_section.dart';
import 'package:flatmates_app/features/shared/presentation/components.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

const _monthlyTotal = 125000.0;

Widget _harness({
  required double scale,
  required double width,
  required StepCostsSection section,
}) {
  return MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: MaterialApp(
      theme: AppTheme.build(brightness: Brightness.light),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(width: width, child: section),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'the monthly total wraps past two lines without a cap at 320 dp / 2x',
    (tester) async {
      final rent = TextEditingController(
        text: _monthlyTotal.toStringAsFixed(0),
      );
      addTearDown(rent.dispose);
      final deposit = TextEditingController();
      addTearDown(deposit.dispose);
      final maintenance = TextEditingController();
      addTearDown(maintenance.dispose);
      final electricityEst = TextEditingController();
      addTearDown(electricityEst.dispose);
      final cookCost = TextEditingController();
      addTearDown(cookCost.dispose);
      final maidCost = TextEditingController();
      addTearDown(maidCost.dispose);
      final setupCost = TextEditingController();
      addTearDown(setupCost.dispose);
      final otherCharges = TextEditingController();
      addTearDown(otherCharges.dispose);
      final otherChargesDescription = TextEditingController();
      addTearDown(otherChargesDescription.dispose);

      final locale = await AppLocalizations.delegate.load(const Locale('en'));
      final headline = locale.totalMonthlyOutflow(
        FlatmatesPriceText.formatRupee(_monthlyTotal.round()),
      );
      final perPerson = locale.perPersonCostLabel;

      StepCostsSection section() => StepCostsSection(
        rentController: rent,
        depositController: deposit,
        maintenanceController: maintenance,
        electricityIncluded: 'separate',
        electricityEstController: electricityEst,
        cookCostController: cookCost,
        maidCostController: maidCost,
        setupCostController: setupCost,
        otherChargesController: otherCharges,
        otherChargesDescriptionController: otherChargesDescription,
        showRentValidation: false,
        totalMonthlyOutflow: _monthlyTotal,
        flatConfig: '2BHK',
        onElectricityChanged: (_) {},
        onChanged: () {},
      );

      // One line, measured on a wide card, to prove the narrow render wraps.
      await tester.pumpWidget(
        _harness(scale: 2, width: 1000, section: section()),
      );
      final oneLineHeight = tester.getSize(find.text(headline)).height;

      await tester.pumpWidget(
        _harness(scale: 2, width: 288, section: section()),
      );
      expect(tester.takeException(), isNull);

      final headlineSize = tester.getSize(find.text(headline));
      expect(
        headlineSize.height,
        greaterThan(2 * oneLineHeight),
        reason:
            'at 320 dp / 2x the amount needs more than two lines, so a '
            'maxLines cap silently clipped it',
      );
      // Regression guard: no line cap on the amount or the per-person figure.
      expect(tester.widget<Text>(find.text(headline)).maxLines, isNull);
      expect(
        tester.widget<Text>(find.textContaining(perPerson)).maxLines,
        isNull,
      );
    },
  );
}
