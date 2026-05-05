import 'package:flutter_test/flutter_test.dart';
import 'package:httm_xangdau/core/config/environment_config.dart';
import 'package:httm_xangdau/core/map/map_provider_kind.dart';

void main() {
  group('EnvironmentConfig.validateConfig', () {
    test('Google không yêu cầu key Goong → pass', () {
      expect(
        () => EnvironmentConfig.validateConfig(
          kind: MapProviderKind.google,
          goongMapTilesKey: null,
          goongApiKey: null,
        ),
        returnsNormally,
      );
    });

    test('Goong với cả 2 key non-empty → pass', () {
      expect(
        () => EnvironmentConfig.validateConfig(
          kind: MapProviderKind.goong,
          goongMapTilesKey: 'mt-key-123',
          goongApiKey: 'rest-key-456',
        ),
        returnsNormally,
      );
    });

    test('Goong thiếu MAPTILES_KEY → throw StateError', () {
      for (final empty in [null, '', '   ']) {
        expect(
          () => EnvironmentConfig.validateConfig(
            kind: MapProviderKind.goong,
            goongMapTilesKey: empty,
            goongApiKey: 'rest-key',
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('GOONG_MAPTILES_KEY'),
            ),
          ),
          reason: 'mapTilesKey=${empty == null ? "null" : "\"$empty\""}',
        );
      }
    });

    test('Goong thiếu API_KEY → throw StateError', () {
      for (final empty in [null, '', '\t']) {
        expect(
          () => EnvironmentConfig.validateConfig(
            kind: MapProviderKind.goong,
            goongMapTilesKey: 'mt-key',
            goongApiKey: empty,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('GOONG_API_KEY'),
            ),
          ),
        );
      }
    });

    test('Goong thiếu cả 2 key → throw (báo MAPTILES_KEY trước)', () {
      expect(
        () => EnvironmentConfig.validateConfig(
          kind: MapProviderKind.goong,
          goongMapTilesKey: null,
          goongApiKey: null,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('GOONG_MAPTILES_KEY'),
          ),
        ),
      );
    });

    test('OSM chưa hỗ trợ → throw rõ message milestone', () {
      expect(
        () => EnvironmentConfig.validateConfig(
          kind: MapProviderKind.osm,
          goongMapTilesKey: null,
          goongApiKey: null,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('OSM'),
          ),
        ),
      );
    });

    test('Goong fail-fast tránh silent fallback Google', () {
      // Verify error message hint rõ ý đồ "không silent fallback".
      try {
        EnvironmentConfig.validateConfig(
          kind: MapProviderKind.goong,
          goongMapTilesKey: '',
          goongApiKey: 'rest-key',
        );
        fail('expected StateError');
      } on StateError catch (e) {
        expect(e.message, contains('Refusing to fall back'));
      }
    });
  });
}
