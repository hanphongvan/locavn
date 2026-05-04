import 'package:flutter_test/flutter_test.dart';
import 'package:httm_xangdau/core/map/map_provider_config.dart';
import 'package:httm_xangdau/core/map/map_provider_kind.dart';

void main() {
  group('MapProviderConfig.parse', () {
    test('falls back to default for null/empty/whitespace', () {
      expect(MapProviderConfig.parse(null), MapProviderKind.google);
      expect(MapProviderConfig.parse(''), MapProviderKind.google);
      expect(MapProviderConfig.parse('   '), MapProviderKind.google);
    });

    test('parses each provider value', () {
      expect(MapProviderConfig.parse('google'), MapProviderKind.google);
      expect(MapProviderConfig.parse('goong'), MapProviderKind.goong);
      expect(MapProviderConfig.parse('osm'), MapProviderKind.osm);
    });

    test('respects custom fallback when raw is empty', () {
      expect(
        MapProviderConfig.parse(null, fallback: MapProviderKind.goong),
        MapProviderKind.goong,
      );
      expect(
        MapProviderConfig.parse('', fallback: MapProviderKind.osm),
        MapProviderKind.osm,
      );
    });

    test('throws StateError on unknown value (fail-fast)', () {
      expect(
        () => MapProviderConfig.parse('mapbox'),
        throwsA(isA<StateError>()),
      );
    });

    test('default kind is google for backward compatibility', () {
      expect(MapProviderConfig.defaultKind, MapProviderKind.google);
    });
  });
}
