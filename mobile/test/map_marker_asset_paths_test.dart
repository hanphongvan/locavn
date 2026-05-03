import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:httm_xangdau/core/assets/map_marker_asset_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled map marker PNGs load from the asset bundle', () async {
    for (final path in MapMarkerAssetPaths.all) {
      final data = await rootBundle.load(path);
      expect(
        data.lengthInBytes,
        greaterThan(64),
        reason: 'expected non-trivial PNG payload for $path',
      );
    }
  });
}
