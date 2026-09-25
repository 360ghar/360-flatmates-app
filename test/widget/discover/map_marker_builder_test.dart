import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';
import 'package:flatmates_app/features/discover/discover_repository.dart';
import 'package:flatmates_app/features/discover/presentation/widgets/map_marker_builder.dart';

void main() {
  for (final count in [1, 2]) {
    testWidgets(
      '$count listing marker supports semantic and pointer activation',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var tapCount = 0;
        final items = List.generate(
          count,
          (i) => PropertyListing(
            id: i + 1,
            ownerId: 1,
            propertyType: 'apartment',
            title: 'Review',
            description: null,
            city: 'Bangalore',
            state: null,
            locality: 'Review',
            subLocality: null,
            latitude: 12.9,
            longitude: 77.6,
            monthlyRent: 20000,
            mainImageUrl: null,
            imageUrls: [],
            areaSqft: null,
            bedrooms: 2,
            bathrooms: null,
            features: [],
            tags: [],
            ownerName: null,
            availableFrom: null,
            genderPreference: null,
            sharingType: null,
            interestCount: 0,
            viewCount: 0,
            likeCount: 0,
            isAvailable: true,
          ),
        );
        final marker = buildClusteredMarkers(
          items: items,
          theme: ThemeData(),
          onListingTap: (_) => tapCount += 1,
          onClusterTap: (_) => tapCount += 1,
        ).single;
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: Center(child: marker.child)),
          ),
        );
        final labeled = find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.button == true,
        );
        final data = tester.getSemantics(labeled).getSemanticsData();
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        tester.semantics.tap(find.semantics.byLabel(data.label));
        expect(tapCount, 1);
        await tester.tap(find.byType(GestureDetector).last);
        expect(tapCount, 2);
        semantics.dispose();
      },
    );
  }
}
