import 'package:flutter_test/flutter_test.dart';
import 'package:httm_xangdau/core/map/app_lat_lng.dart';
import 'package:httm_xangdau/core/map/app_lat_lng_bounds.dart';
import 'package:httm_xangdau/core/map/app_map_camera.dart';
import 'package:httm_xangdau/core/map/providers/goong/goong_value_codec.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

void main() {
  group('GoongValueCodec', () {
    // ml.LatLng có precision loss nhẹ qua channel codec — dùng closeTo.
    void expectClose(AppLatLng a, AppLatLng b) {
      expect(a.latitude, closeTo(b.latitude, 1e-9));
      expect(a.longitude, closeTo(b.longitude, 1e-9));
    }

    test('LatLng round-trips', () {
      const v = AppLatLng(10.776, 106.700);
      expectClose(GoongValueCodec.fromLatLng(GoongValueCodec.toLatLng(v)), v);
    });

    test('Bounds round-trips', () {
      const b = AppLatLngBounds(
        southwest: AppLatLng(10, 100),
        northeast: AppLatLng(20, 110),
      );
      final r = GoongValueCodec.fromBounds(GoongValueCodec.toBounds(b));
      expectClose(r.southwest, b.southwest);
      expectClose(r.northeast, b.northeast);
    });

    test('CameraPosition round-trips all fields', () {
      const c = AppMapCameraPosition(
        target: AppLatLng(15, 105),
        zoom: 12.5,
        bearing: 45,
        tilt: 30,
      );
      final r = GoongValueCodec.fromCameraPosition(
        GoongValueCodec.toCameraPosition(c),
      );
      expectClose(r.target, c.target);
      expect(r.zoom, c.zoom);
      expect(r.bearing, c.bearing);
      expect(r.tilt, c.tilt);
    });

    test('CameraUpdate covers all sealed variants without throwing', () {
      const updates = <AppMapCameraUpdate>[
        AppMapCameraUpdateNewLatLng(AppLatLng(0, 0)),
        AppMapCameraUpdateNewLatLngZoom(AppLatLng(0, 0), 10),
        AppMapCameraUpdateNewCameraPosition(
          AppMapCameraPosition(target: AppLatLng(0, 0)),
        ),
        AppMapCameraUpdateNewLatLngBounds(
          bounds: AppLatLngBounds(
            southwest: AppLatLng(0, 0),
            northeast: AppLatLng(1, 1),
          ),
        ),
      ];
      for (final u in updates) {
        expect(GoongValueCodec.toCameraUpdate(u), isA<ml.CameraUpdate>());
      }
    });
  });
}
