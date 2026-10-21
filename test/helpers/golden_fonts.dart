import 'dart:io';

import 'package:flutter/services.dart';

/// Loads real fonts for golden tests: Gambarino (app asset), Roboto and
/// Material Icons (Flutter SDK cache). Without this, goldens render Ahem
/// boxes.
Future<void> loadGoldenFonts() async {
  final gambarino = FontLoader('Gambarino')
    ..addFont(rootBundle.load('assets/fonts/Gambarino-Regular.ttf'));
  await gambarino.load();

  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String name) async =>
      ByteData.sublistView(await File('$dir/$name').readAsBytes());

  final roboto = FontLoader('Roboto')
    ..addFont(read('Roboto-Regular.ttf'))
    ..addFont(read('Roboto-Medium.ttf'))
    ..addFont(read('Roboto-Bold.ttf'));
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(read('MaterialIcons-Regular.otf'));
  await icons.load();
}
