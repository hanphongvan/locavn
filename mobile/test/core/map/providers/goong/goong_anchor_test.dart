import 'package:flutter_test/flutter_test.dart';
import 'package:httm_xangdau/core/map/app_map_marker.dart';
import 'package:httm_xangdau/core/map/providers/goong/goong_anchor.dart';

void main() {
  group('goongIconAnchor', () {
    test('canonical 9-point anchors', () {
      expect(goongIconAnchor(const AppMapAnchor(0, 0)), 'top-left');
      expect(goongIconAnchor(const AppMapAnchor(0.5, 0)), 'top');
      expect(goongIconAnchor(const AppMapAnchor(1, 0)), 'top-right');
      expect(goongIconAnchor(const AppMapAnchor(0, 0.5)), 'left');
      expect(goongIconAnchor(AppMapAnchor.center), 'center');
      expect(goongIconAnchor(const AppMapAnchor(1, 0.5)), 'right');
      expect(goongIconAnchor(const AppMapAnchor(0, 1)), 'bottom-left');
      expect(goongIconAnchor(AppMapAnchor.bottom), 'bottom');
      expect(goongIconAnchor(const AppMapAnchor(1, 1)), 'bottom-right');
    });

    test('arbitrary anchor → quy về 9-point gần nhất', () {
      expect(goongIconAnchor(const AppMapAnchor(0.1, 0.9)), 'bottom-left');
      expect(goongIconAnchor(const AppMapAnchor(0.5, 0.95)), 'bottom');
      expect(goongIconAnchor(const AppMapAnchor(0.45, 0.55)), 'center');
    });
  });
}
