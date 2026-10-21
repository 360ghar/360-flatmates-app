import 'package:flatmates_app/core/theme/app_breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';

/// Foldable iPhone Duo viewport widths in logical points.
///
/// Folded portrait 466, open portrait 669, folded landscape 678, open
/// landscape 951.
const _duoWidths = <double>[466, 669, 678, 951];

void main() {
  group('AppBreakpoints.isMedium', () {
    test('is half-open at 600', () {
      expect(AppBreakpoints.isMedium(599), isFalse);
      expect(AppBreakpoints.isMedium(600), isTrue);
      expect(AppBreakpoints.isMedium(601), isTrue);
    });

    test('classifies every Duo pose', () {
      // Folded portrait 466 and folded landscape 678 are phones; open
      // portrait 669 and open landscape 951 are not.
      expect(_duoWidths.map(AppBreakpoints.isMedium), [
        false,
        true,
        true,
        true,
      ]);
    });
  });

  group('AppBreakpoints.isExpanded', () {
    test('is half-open at 900', () {
      expect(AppBreakpoints.isExpanded(899), isFalse);
      expect(AppBreakpoints.isExpanded(900), isTrue);
      expect(AppBreakpoints.isExpanded(901), isTrue);
    });

    test('only the open-landscape Duo pose gets the wide chrome', () {
      expect(_duoWidths.map(AppBreakpoints.isExpanded), [
        false,
        false,
        false,
        true,
      ]);
    });
  });

  group('AppBreakpoints.cardGridColumns', () {
    test('boundaries are 600 and 900', () {
      expect(AppBreakpoints.cardGridColumns(599), 2);
      expect(AppBreakpoints.cardGridColumns(600), 3);
      expect(AppBreakpoints.cardGridColumns(899), 3);
      expect(AppBreakpoints.cardGridColumns(900), 4);
    });

    test('Duo widths', () {
      expect(_duoWidths.map(AppBreakpoints.cardGridColumns), [2, 3, 3, 4]);
    });
  });

  group('AppBreakpoints.profileGridColumns', () {
    test('boundaries are 600 and 900', () {
      expect(AppBreakpoints.profileGridColumns(599), 2);
      expect(AppBreakpoints.profileGridColumns(600), 3);
      expect(AppBreakpoints.profileGridColumns(899), 3);
      expect(AppBreakpoints.profileGridColumns(900), 4);
    });

    test('Duo widths', () {
      expect(_duoWidths.map(AppBreakpoints.profileGridColumns), [2, 3, 3, 4]);
    });
  });

  group('AppBreakpoints.lifestyleColumns', () {
    test('boundary is 600', () {
      expect(AppBreakpoints.lifestyleColumns(599), 2);
      expect(AppBreakpoints.lifestyleColumns(600), 4);
    });

    test('a 320 dp phone panel is still exactly 2 columns', () {
      expect(AppBreakpoints.lifestyleColumns(320), 2);
    });

    test('Duo widths', () {
      expect(_duoWidths.map(AppBreakpoints.lifestyleColumns), [2, 4, 4, 4]);
    });
  });

  group('AppBreakpoints.contentMaxWidth', () {
    test('caps at 720 below 1024 and is unbounded from 1024 up', () {
      expect(AppBreakpoints.contentMaxWidth(1023), 720);
      expect(AppBreakpoints.contentMaxWidth(1024), double.infinity);
      expect(AppBreakpoints.contentMaxWidth(1600), double.infinity);
    });

    test('every Duo pose keeps the 720 reading column', () {
      for (final width in _duoWidths) {
        expect(AppBreakpoints.contentMaxWidth(width), 720, reason: '$width');
      }
    });

    test('a narrow phone is inside the cap, so nothing is constrained', () {
      expect(AppBreakpoints.contentMaxWidth(320), greaterThan(320));
    });
  });

  group('AppBreakpoints.chatBubbleMaxWidth', () {
    test('is 75% of the width until the 560 cap bites', () {
      expect(AppBreakpoints.chatBubbleMaxWidth(320), 240);
      expect(AppBreakpoints.chatBubbleMaxWidth(466), 349.5);
      expect(AppBreakpoints.chatBubbleMaxWidth(669), 501.75);
      expect(AppBreakpoints.chatBubbleMaxWidth(678), 508.5);
      // 951 * 0.75 = 713.25, capped to 560.
      expect(AppBreakpoints.chatBubbleMaxWidth(951), 560);
      expect(AppBreakpoints.chatBubbleMaxWidth(1024), 560);
    });

    test('the cap is reached exactly at 746.67 dp', () {
      expect(AppBreakpoints.chatBubbleMaxWidth(560 / 0.75), 560);
      expect(
        AppBreakpoints.chatBubbleMaxWidth(560 / 0.75 - 0.01),
        lessThan(560),
      );
    });
  });

  group('AppBreakpoints chrome caps', () {
    test('sheet and dialog caps are named, not inline magic numbers', () {
      expect(AppBreakpoints.sheetMaxWidth, 640);
      expect(AppBreakpoints.dialogMaxWidth, 560);
    });

    test('both caps stay narrower than the open Duo landscape viewport', () {
      expect(AppBreakpoints.sheetMaxWidth, lessThan(951));
      expect(AppBreakpoints.dialogMaxWidth, lessThan(951));
    });

    test('the reading column never exceeds the sheet cap by more than 720', () {
      // The reading column is the widest chrome cap; the sheet and dialog sit
      // inside it, so a floating sheet can never be wider than the page.
      expect(
        AppBreakpoints.readingColumn,
        greaterThan(AppBreakpoints.sheetMaxWidth),
      );
    });
  });
}
