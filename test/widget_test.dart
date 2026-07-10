import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/theme/app_radius.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flatmates_app/core/theme/app_shadows.dart';
import 'package:flatmates_app/core/theme/app_spacing.dart';
import 'package:flatmates_app/core/theme/app_typography.dart';
import 'package:flatmates_app/features/settings/domain/settings_state.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_like_button.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_price_text.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_search_bar.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_ui.dart';

void main() {
  test('Airbnb design tokens match DESIGN.md contract', () {
    expect(AppSemanticColors.primary, const Color(0xFFFF385C));
    expect(AppSemanticColors.primaryActive, const Color(0xFFE00B41));
    expect(AppSemanticColors.primaryDisabled, const Color(0xFFFFD1DA));
    expect(AppSemanticColors.canvas, const Color(0xFFFFFFFF));
    expect(AppSemanticColors.ink, const Color(0xFF222222));
    expect(AppSemanticColors.body, const Color(0xFF3F3F3F));
    expect(AppSemanticColors.muted, const Color(0xFF6A6A6A));
    expect(AppSemanticColors.hairline, const Color(0xFFDDDDDD));
    expect(AppSemanticColors.error, const Color(0xFFC13515));

    // Compat aliases must map to Airbnb values (not old terracotta/paper).
    expect(AppSemanticColors.accent, AppSemanticColors.primary);
    expect(AppSemanticColors.card, AppSemanticColors.canvas);
    expect(AppSemanticColors.ink2, AppSemanticColors.body);
    expect(AppSemanticColors.ink3, AppSemanticColors.muted);
    expect(AppSemanticColors.line, AppSemanticColors.hairline);

    expect(AppRadius.sm, 8);
    expect(AppRadius.md, 14);
    expect(AppRadius.card, 14);
    expect(AppRadius.pill, 9999);
    expect(AppSpacing.base, 16);
    expect(AppSpacing.section, 64);

    expect(AppTypography.fontFamily, 'Inter');
    expect(AppShadows.elevation, hasLength(3));
    expect(AppShadows.elevationFor(Brightness.dark), hasLength(3));
  });

  test('SettingsState has no palette field in product state', () {
    const state = SettingsState();
    expect(state.themeMode, ThemeMode.light);
    expect(
      state.toString().contains('palette'),
      isFalse,
      reason: 'SettingsState must not expose multi-palette product state',
    );
  });

  test('FlatmatesPriceText formats Indian currency groups', () {
    expect(FlatmatesPriceText.formatRupee(999), '₹999');
    expect(FlatmatesPriceText.formatRupee(16500), '₹16,500');
    expect(FlatmatesPriceText.formatRupee(165000), '₹1,65,000');
    expect(FlatmatesPriceText.formatRupee(1000000), '₹10,00,000');
  });

  testWidgets('FlatmatesLikeButton uses Rausch when liked', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FlatmatesLikeButton(liked: true, onTap: () {})),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.favorite_rounded));
    expect(icon.color, AppSemanticColors.primary);
  });

  testWidgets('FlatmatesSearchBar is pill-shaped at 48 height', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FlatmatesSearchBar(hint: 'Search')),
      ),
    );

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(FlatmatesSearchBar),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.borderRadius, AppRadius.pillBorder);
    expect(container.constraints?.minHeight, 48);
    expect(container.constraints?.maxHeight, 48);
    expect(decoration.boxShadow, isNotNull);
  });

  testWidgets('FlatmatesButton primary is 48 tall and Rausch-filled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlatmatesButton(label: 'Continue', onPressed: () {}),
        ),
      ),
    );

    final button = tester.widget<FlatmatesButton>(find.byType(FlatmatesButton));
    expect(button.height, 48);

    final filled = tester.widget<FilledButton>(find.byType(FilledButton));
    final bg = filled.style?.backgroundColor?.resolve(const <WidgetState>{});
    expect(bg, AppSemanticColors.primary);
  });
}
