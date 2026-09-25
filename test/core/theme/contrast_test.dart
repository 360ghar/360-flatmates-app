import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Every text token must reach WCAG AA (4.5:1) on every paper layer.
  // DESIGN.md §1 lists these pairs; the web app runs the same check.
  for (final brightness in Brightness.values) {
    final papers = {
      'sky': AppSemanticColors.skyFor(brightness),
      'paper-1': AppSemanticColors.paper1For(brightness),
      'paper-2': AppSemanticColors.paper2For(brightness),
      'paper-3': AppSemanticColors.paper3For(brightness),
    };
    final texts = {
      'ink': AppSemanticColors.textPrimaryFor(brightness),
      'ink-2': AppSemanticColors.textSecondaryFor(brightness),
      'ink-3': AppSemanticColors.textTertiaryFor(brightness),
      'clay': AppSemanticColors.clayFor(brightness),
      'pine': AppSemanticColors.pineFor(brightness),
      'danger': AppSemanticColors.dangerFor(brightness),
      'warning-ink': AppSemanticColors.warningInkFor(brightness),
    };
    for (final text in texts.entries) {
      for (final paper in papers.entries) {
        test('${brightness.name}: ${text.key} on ${paper.key} passes AA', () {
          expect(_contrast(text.value, paper.value), greaterThanOrEqualTo(4.5));
        });
      }
    }

    test('${brightness.name}: labels on filled controls pass AA', () {
      expect(
        _contrast(
          AppSemanticColors.onClayFor(brightness),
          AppSemanticColors.clayFor(brightness),
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(
          AppSemanticColors.onClayFor(brightness),
          AppSemanticColors.clayPressFor(brightness),
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(
          AppSemanticColors.textPrimaryFor(brightness),
          AppSemanticColors.coralSoftFor(brightness),
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(
          AppSemanticColors.textPrimaryFor(brightness),
          AppSemanticColors.pineSoftFor(brightness),
        ),
        greaterThanOrEqualTo(4.5),
      );
      // Selected chips / tints may carry clay text.
      expect(
        _contrast(
          AppSemanticColors.clayFor(brightness),
          AppSemanticColors.coralSoftFor(brightness),
        ),
        greaterThanOrEqualTo(4.5),
      );
    });
  }
}
