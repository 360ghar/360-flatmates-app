import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/core/map/tile_layer_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(TileLayerFactory.dispose);

  group('TileLayerFactory', () {
    testWidgets(
      'light mode uses OSM standard tiles (not CARTO/Esri/MapTiler)',
      (tester) async {
        late TileLayer layer;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Builder(
              builder: (context) {
                layer = TileLayerFactory.build(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(layer.urlTemplate, contains('tile.openstreetmap.org'));
        expect(layer.urlTemplate, isNot(contains('cartocdn')));
        expect(layer.urlTemplate, isNot(contains('maptiler')));
        expect(layer.urlTemplate, isNot(contains('arcgisonline')));
        expect(layer.urlTemplate, isNot(contains('voyager')));
        expect(layer.urlTemplate, isNot(contains('light_all')));
        expect(layer.subdomains, isEmpty);
        expect(layer.resolvedRetinaMode, RetinaMode.disabled);
        expect(layer.tileBuilder, isNull);
        expect(TileLayerFactory.attribution, contains('OpenStreetMap'));
        expect(TileLayerFactory.attribution, isNot(contains('CARTO')));
      },
    );

    testWidgets('dark mode uses CARTO dark tiles with retina subdomains', (
      tester,
    ) async {
      late TileLayer layer;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              layer = TileLayerFactory.build(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(layer.urlTemplate, contains('basemaps.cartocdn.com'));
      expect(layer.urlTemplate, contains('dark_all'));
      expect(layer.subdomains, containsAll(['a', 'b', 'c', 'd']));
    });

    test('styleVersion is positive (bump forces tile reload)', () {
      expect(TileLayerFactory.styleVersion, greaterThan(0));
    });

    testWidgets('attributionFor is light/OSM under light theme', (
      tester,
    ) async {
      late String attr;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              attr = TileLayerFactory.attributionFor(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(attr, contains('OpenStreetMap'));
      expect(attr, isNot(contains('CARTO')));
    });

    testWidgets('attributionFor includes CARTO under dark theme', (
      tester,
    ) async {
      late String attr;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              attr = TileLayerFactory.attributionFor(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(attr, contains('CARTO'));
    });
  });
}
