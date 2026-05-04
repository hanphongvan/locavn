import 'package:flutter_test/flutter_test.dart';
import 'package:httm_xangdau/core/map/map_provider_kind.dart';

void main() {
  group('MapProviderKind.fromConfigValue', () {
    test('returns kind for canonical values', () {
      expect(MapProviderKind.fromConfigValue('google'), MapProviderKind.google);
      expect(MapProviderKind.fromConfigValue('goong'), MapProviderKind.goong);
      expect(MapProviderKind.fromConfigValue('osm'), MapProviderKind.osm);
    });

    test('case-insensitive', () {
      expect(MapProviderKind.fromConfigValue('GOONG'), MapProviderKind.goong);
      expect(MapProviderKind.fromConfigValue('Google'), MapProviderKind.google);
    });

    test('trims whitespace', () {
      expect(
        MapProviderKind.fromConfigValue('  goong  '),
        MapProviderKind.goong,
      );
    });

    test('returns null for null/empty/unknown', () {
      expect(MapProviderKind.fromConfigValue(null), isNull);
      expect(MapProviderKind.fromConfigValue(''), isNull);
      expect(MapProviderKind.fromConfigValue('   '), isNull);
      expect(MapProviderKind.fromConfigValue('mapbox'), isNull);
    });

    test('configValue is the canonical id', () {
      expect(MapProviderKind.google.configValue, 'google');
      expect(MapProviderKind.goong.configValue, 'goong');
      expect(MapProviderKind.osm.configValue, 'osm');
    });
  });
}
