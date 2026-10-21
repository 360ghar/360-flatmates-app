import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/chats/presentation/widgets/peer_profile_action_button.dart';

import '../../helpers/test_helpers.dart';

/// A scaler whose factor for the label size (12) is 2x but whose factor for
/// 1.0 is 1x — like Android's nonlinear accessibility curve, and unlike
/// `TextScaler.linear`. `scale(1)` therefore cannot stand in for the label
/// multiplier.
class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();

  @override
  double scale(double fontSize) => fontSize <= 1 ? fontSize : fontSize * 2;

  @override
  double get textScaleFactor => 2;
}

Widget _row({required TextScaler scaler, required double width}) {
  return testableWidget(
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: scaler),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: const PeerActionRow(
                children: [
                  PeerActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Message',
                  ),
                  PeerActionButton(icon: Icons.call_outlined, label: 'Call'),
                  PeerActionButton(
                    icon: Icons.event_available_outlined,
                    label: 'Visit',
                  ),
                  PeerActionButton(icon: Icons.flag_outlined, label: 'Report'),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('PeerActionRow breakpoint', () {
    testWidgets('measures the label size, not scale(1)', (tester) async {
      // 4 tiles of 72 dp + 3 gaps of 4 dp fit 400 dp at 1x; at the 2x label
      // multiplier this scaler reports they need 588 dp.
      await tester.pumpWidget(
        _row(scaler: const _NonlinearScaler(), width: 400),
      );
      await tester.pumpAndSettle();

      final tiles = find.byType(PeerActionButton);
      expect(tiles, findsNWidgets(4));
      final first = tester.getRect(tiles.at(0));
      final third = tester.getRect(tiles.at(2));
      // Wrapped into two rows of two.
      expect(third.top, greaterThanOrEqualTo(first.bottom));
    });

    testWidgets('keeps one row at the same width with linear 1x', (
      tester,
    ) async {
      await tester.pumpWidget(_row(scaler: TextScaler.noScaling, width: 400));
      await tester.pumpAndSettle();

      final tiles = find.byType(PeerActionButton);
      expect(tiles, findsNWidgets(4));
      final first = tester.getRect(tiles.at(0));
      final fourth = tester.getRect(tiles.at(3));
      expect(fourth.top, first.top);
    });
  });
}
