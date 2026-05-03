// Writes standard PNGs (valid CRCs) for map markers via package:image.
// Output paths must stay aligned with [MapMarkerAssetPaths] and pubspec.yaml.
// Run from mobile/: dart run tool/write_valid_marker_pngs.dart
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final dir = Directory('assets/map_markers');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  _write(
    '${dir.path}/station_open.png',
    img.ColorRgb8(46, 125, 50),
  );
  _write(
    '${dir.path}/station_closed.png',
    img.ColorRgb8(117, 117, 117),
  );
  _write(
    '${dir.path}/station_cheap.png',
    img.ColorRgb8(255, 179, 0),
  );
  _write(
    '${dir.path}/distributor_safe.png',
    img.ColorRgb8(46, 160, 67),
  );
  _write(
    '${dir.path}/distributor_warning.png',
    img.ColorRgb8(245, 158, 11),
  );
  _write(
    '${dir.path}/distributor_danger.png',
    img.ColorRgb8(220, 38, 38),
  );
  // ignore: avoid_print
  print('Wrote PNGs to assets/map_markers/ (encodePng — Android-safe).');
}

void _write(String path, img.ColorRgb8 fill) {
  const w = 48;
  const h = 56;
  final image = img.Image(width: w, height: h);
  img.fill(image, color: fill);
  File(path).writeAsBytesSync(img.encodePng(image), flush: true);
}
