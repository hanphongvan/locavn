import 'package:flutter_test/flutter_test.dart';
import 'package:httm_xangdau/core/map/app_lat_lng.dart';
import 'package:httm_xangdau/core/map/app_lat_lng_bounds.dart';

void main() {
  group('AppLatLngBounds.contains', () {
    const bounds = AppLatLngBounds(
      southwest: AppLatLng(10, 100),
      northeast: AppLatLng(20, 110),
    );

    test('point inside is contained', () {
      expect(bounds.contains(const AppLatLng(15, 105)), isTrue);
    });

    test('points on edges are contained', () {
      expect(bounds.contains(const AppLatLng(10, 100)), isTrue);
      expect(bounds.contains(const AppLatLng(20, 110)), isTrue);
      expect(bounds.contains(const AppLatLng(10, 110)), isTrue);
      expect(bounds.contains(const AppLatLng(20, 100)), isTrue);
    });

    test('point outside latitude range is not contained', () {
      expect(bounds.contains(const AppLatLng(5, 105)), isFalse);
      expect(bounds.contains(const AppLatLng(25, 105)), isFalse);
    });

    test('point outside longitude range is not contained', () {
      expect(bounds.contains(const AppLatLng(15, 90)), isFalse);
      expect(bounds.contains(const AppLatLng(15, 120)), isFalse);
    });

    test('bounds crossing antimeridian (sw.lng > ne.lng)', () {
      const b = AppLatLngBounds(
        southwest: AppLatLng(0, 170),
        northeast: AppLatLng(10, -170),
      );
      expect(b.contains(const AppLatLng(5, 175)), isTrue);
      expect(b.contains(const AppLatLng(5, -175)), isTrue);
      expect(b.contains(const AppLatLng(5, 0)), isFalse);
    });
  });
}
