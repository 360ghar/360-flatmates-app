import 'package:flatmates_app/core/theme/app_spacing.dart';
import 'package:flatmates_app/features/bootstrap/catalog_helpers.dart';
import 'package:flatmates_app/features/discover/domain/property_listing.dart';
import 'package:flatmates_app/features/listings/presentation/widgets/manage_listing_card.dart';
import 'package:flatmates_app/features/listings/presentation/widgets/step_room_section.dart';
import 'package:flatmates_app/features/shared/presentation/components.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

/// Folded portrait: the pose these bands were drawn at. The card inside the
/// page gutter is 434 dp wide here.
const Size _foldedPortrait = Size(466, 900);

/// The width a page's card actually gets on the open Duo: the 951 dp viewport
/// minus the 96 dp rail, capped by the 720 dp reading column, minus the 16 dp
/// page gutter on each side.
const double _wideCardWidth = 720 - AppSpacing.screen * 2;

const double _wideViewport = 720;

/// Full-width media in this feature is a photo header on a full-width card.
/// A fixed height flattens into a 3:1..4.5:1 letterbox strip once the card
/// grows to the 688 dp the reading column allows.
PropertyListing _listing({String? mainImageUrl}) => PropertyListing(
  id: 42,
  ownerId: 1,
  propertyType: 'flatmate',
  title: 'Modern 2BHK in Koramangala',
  description: 'A beautiful flat',
  city: 'Bangalore',
  state: 'Karnataka',
  locality: 'Koramangala',
  subLocality: '5th Block',
  latitude: 12.93,
  longitude: 77.62,
  monthlyRent: 24000,
  mainImageUrl: mainImageUrl,
  imageUrls: const [],
  areaSqft: 1200,
  bedrooms: 2,
  bathrooms: 2,
  features: const [],
  tags: const [],
  ownerName: 'Test User',
  availableFrom: null,
  genderPreference: 'any',
  sharingType: 'private_room',
  interestCount: 10,
  viewCount: 3800,
  likeCount: 24,
  isAvailable: true,
  status: 'live',
);

StepRoomSection _photosStep(List<String> photos) => StepRoomSection(
  step: 3,
  roomType: 'single',
  roomFurnishing: const {},
  roomFeatures: const {},
  roomPhotoUrls: photos,
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

/// Pumps [child] the way its page lays it out: the 16 dp page gutter on each
/// side, inside a scroll view, at an exact logical viewport width.
///
/// `pumpAndSettle` is avoided on purpose: `FlatmatesNetworkImage` never
/// finishes loading in a test, so the frame scheduler stays busy.
Future<void> _pumpInPage(
  WidgetTester tester, {
  required Widget child,
  required double width,
}) async {
  tester.view.physicalSize = Size(width, _foldedPortrait.height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    testableWidget(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpCard(WidgetTester tester, {required double width}) async {
  final locale = lookupAppLocalizations(const Locale('en'));
  await _pumpInPage(
    tester,
    width: width,
    child: ManageListingCard(
      listing: _listing(mainImageUrl: 'https://example.com/photo.jpg'),
      status: 'active',
      isPaused: false,
      onTogglePause: (_, _) {},
      onShare: () {},
      onEdit: () {},
      onViewStats: () {},
      onReview: () {},
      onRenew: () {},
      theme: ThemeData.light(),
      locale: locale,
    ),
  );
}

void main() {
  group('ManageListingCard photo band', () {
    testWidgets('466 dp keeps the 160 dp header, unchanged', (tester) async {
      await _pumpCard(tester, width: _foldedPortrait.width);

      expect(tester.takeException(), isNull);
      final photo = tester.getSize(find.byType(FlatmatesNetworkImage));
      expect(photo.height, 160);
      expect(photo.width, closeTo(466 - AppSpacing.screen * 2, 1));
    });

    testWidgets('the 720 dp card gets a photo, not a 4.5:1 letterbox', (
      tester,
    ) async {
      await _pumpCard(tester, width: _wideViewport);

      expect(tester.takeException(), isNull);
      final photo = tester.getSize(find.byType(FlatmatesNetworkImage));
      expect(photo.width, closeTo(_wideCardWidth, 1));
      expect(photo.height, greaterThan(160));
      expect(photo.height, lessThanOrEqualTo(288 + 0.01));
      // 253.6 / 688 = 0.369 now; the fixed 160 dp was 0.233.
      expect(photo.height / photo.width, greaterThan(0.32));
    });
  });

  group('StepRoomSection media bands', () {
    testWidgets('466 dp keeps the 200 dp photo and the 140 dp add tile', (
      tester,
    ) async {
      await _pumpInPage(
        tester,
        width: _foldedPortrait.width,
        child: _photosStep(const [
          'https://example.com/room1.jpg',
          'https://example.com/room2.jpg',
        ]),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(FlatmatesNetworkImage).first).height,
        200,
      );
      expect(
        tester
            .getSize(find.byKey(const Key('listing_add_photos_tile')).first)
            .height,
        140,
      );
    });

    testWidgets('the 720 dp card grows both bands with the width', (
      tester,
    ) async {
      await _pumpInPage(
        tester,
        width: _wideViewport,
        child: _photosStep(const ['https://example.com/room1.jpg']),
      );

      expect(tester.takeException(), isNull);

      // The photo card carries a 1.5 dp border on each side.
      final photo = tester.getSize(find.byType(FlatmatesNetworkImage).first);
      expect(photo.width, closeTo(_wideCardWidth - 3, 2));
      expect(photo.height, greaterThan(200));
      expect(photo.height, lessThanOrEqualTo(288 + 0.01));
      // 288 / 685 = 0.42 now; the fixed 200 dp was 0.29.
      expect(photo.height / photo.width, greaterThan(0.36));

      final tile = tester.getSize(
        find.byKey(const Key('listing_add_photos_tile')).first,
      );
      expect(tile.width, closeTo(_wideCardWidth, 1));
      expect(tile.height, greaterThan(140));
      expect(tile.height, lessThanOrEqualTo(288 + 0.01));
      // 222 / 688 = 0.32 now; the fixed 140 dp was 0.20.
      expect(tile.height / tile.width, greaterThan(0.28));
    });
  });
}
