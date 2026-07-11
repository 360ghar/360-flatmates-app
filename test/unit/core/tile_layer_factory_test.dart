import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:flatmates_app/core/map/tile_layer_factory.dart';

void main() {
  group('TileLayerFactory', () {
    testWidgets('light mode uses OSM standard tiles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(),
            child: Builder(
              builder: (context) {
                final layer = TileLayerFactory.build(context);
                return Scaffold(
                  body: FlutterMap(
                    options: const MapOptions(
                      initialCenter: LatLng(12.97, 77.59),
                      initialZoom: 10,
                    ),
                    children: [layer],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(tileLayer.urlTemplate, contains('tile.openstreetmap.org'));
      expect(tileLayer.subdomains, isEmpty);
    });

    testWidgets('dark mode uses CARTO dark tiles with retina subdomains', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: MediaQuery(
            data: const MediaQueryData(devicePixelRatio: 2.0),
            child: Builder(
              builder: (context) {
                final layer = TileLayerFactory.build(context);
                return Scaffold(
                  body: FlutterMap(
                    options: const MapOptions(
                      initialCenter: LatLng(12.97, 77.59),
                      initialZoom: 10,
                    ),
                    children: [layer],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(tileLayer.urlTemplate, contains('basemaps.cartocdn.com'));
      expect(tileLayer.urlTemplate, contains('dark_all'));
      expect(tileLayer.subdomains, ['a', 'b', 'c', 'd']);
    });

    testWidgets('attributionFor includes CARTO under dark theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              final attribution = TileLayerFactory.attributionFor(context);
              return Scaffold(body: Center(child: Text(attribution)));
            },
          ),
        ),
      );
      await tester.pump();
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, contains('CARTO'));
      expect(text.data, contains('OpenStreetMap'));
    });

    testWidgets('attributionFor does not include CARTO under light theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              final attribution = TileLayerFactory.attributionFor(context);
              return Scaffold(body: Center(child: Text(attribution)));
            },
          ),
        ),
      );
      await tester.pump();
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, contains('OpenStreetMap'));
      expect(text.data, isNot(contains('CARTO')));
    });

    test('default attribution is the light/OSM string', () {
      expect(TileLayerFactory.attribution, contains('OpenStreetMap'));
      expect(TileLayerFactory.attribution, isNot(contains('CARTO')));
    });

    test('styleVersion is a positive integer', () {
      expect(TileLayerFactory.styleVersion, greaterThan(0));
    });
  });
}
