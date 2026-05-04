import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmf;
import 'package:httm_xangdau/core/map/app_lat_lng.dart';
import 'package:httm_xangdau/core/map/app_lat_lng_bounds.dart';
import 'package:httm_xangdau/core/map/app_map_camera.dart';
import 'package:httm_xangdau/core/map/providers/google/google_value_codec.dart';

void main() {
  group('GoogleValueCodec', () {
    test('LatLng round-trips', () {
      const v = AppLatLng(10.776, 106.700);
      expect(GoogleValueCodec.fromLatLng(GoogleValueCodec.toLatLng(v)), v);
    });

    test('Bounds round-trips', () {
      const b = AppLatLngBounds(
        southwest: AppLatLng(10, 100),
        northeast: AppLatLng(20, 110),
      );
      expect(GoogleValueCodec.fromBounds(GoogleValueCodec.toBounds(b)), b);
    });

    test('CameraPosition round-trips all fields', () {
      const c = AppMapCameraPosition(
        target: AppLatLng(15, 105),
        zoom: 12.5,
        bearing: 45,
        tilt: 30,
      );
      final r = GoogleValueCodec.fromCameraPosition(
        GoogleValueCodec.toCameraPosition(c),
      );
      expect(r.target, c.target);
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
        expect(GoogleValueCodec.toCameraUpdate(u), isA<gmf.CameraUpdate>());
      }
    });
  });
}
