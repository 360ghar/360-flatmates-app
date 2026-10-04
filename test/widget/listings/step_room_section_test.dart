import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/bootstrap/catalog_helpers.dart';
import 'package:flatmates_app/features/listings/presentation/widgets/step_room_section.dart';
import 'package:flatmates_app/features/shared/presentation/components.dart';

import '../../helpers/test_helpers.dart';

StepRoomSection _photosStep() => StepRoomSection(
  step: 3,
  roomType: 'single',
  roomFurnishing: const {},
  roomFeatures: const {},
  // Fewer than two photos, so the "min photos required" pill is shown.
  roomPhotoUrls: const [],
  videoTourUrl: null,
  videoUploading: false,
  showPhotosValidation: false,
  catalog: (_) => const <CatalogOption>[],
  iconForOption: (_) => Icons.home_outlined,
  onRoomTypeChanged: (_) {},
  onFurnishingToggled: (_, _) {},
  onFeatureToggled: (_, _) {},
  onPickPhotos: () {},
  onRemovePhoto: (_) {},
  onVideoTourUrlChanged: (_) {},
  onVideoUploadingChanged: (_) {},
);

void main() {
  group('StepRoomSection min-photos row', () {
    /// The row used to lay the label out with a `Spacer` and put `InfoPill`
    /// in as a non-flex child, so the pill received unbounded width and ran
    /// off the row: 206 px of overflow at 1x and 676 px at 2x on a 320 dp
    /// phone. Both children are flex children now, so each is bounded.
    testWidgets('fits a 320 dp phone at 2x text scale', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        testableWidget(
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: Theme(
                data: AppTheme.build(brightness: Brightness.light),
                child: Scaffold(
                  body: SingleChildScrollView(child: _photosStep()),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // A RenderFlex overflow is reported as a test exception.
      expect(tester.takeException(), isNull);

      final pill = find.byType(InfoPill);
      expect(pill, findsOneWidget);

      final pillRect = tester.getRect(pill);
      // The pill is bounded by the row and stays inside the viewport instead
      // of running past its right edge.
      expect(pillRect.right, lessThanOrEqualTo(320));
      expect(pillRect.left, greaterThanOrEqualTo(0));
    });
  });
}
