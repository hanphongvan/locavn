import 'package:flutter_test/flutter_test.dart';
import 'package:httm_xangdau/core/map/map_provider_bootstrap.dart';
import 'package:httm_xangdau/core/map/map_provider_kind.dart';

void main() {
  group('buildMapProviderRegistry', () {
    test('luôn đăng ký Google', () {
      final r = buildMapProviderRegistry();
      expect(r.isRegistered(MapProviderKind.google), isTrue);
    });

    test('không đăng ký Goong khi key null/empty/whitespace', () {
      for (final key in [null, '', '   ', '\t\n']) {
        final r = buildMapProviderRegistry(goongMapTilesKey: key);
        expect(
          r.isRegistered(MapProviderKind.goong),
          isFalse,
          reason: 'key=${key == null ? "null" : "\"$key\""}',
        );
      }
    });

    test('đăng ký Goong khi mapTilesKey non-empty', () {
      final r = buildMapProviderRegistry(goongMapTilesKey: 'abc123');
      expect(r.isRegistered(MapProviderKind.goong), isTrue);
      expect(r.registered, {MapProviderKind.google, MapProviderKind.goong});
    });

    test('trim mapTilesKey trước khi check', () {
      final r = buildMapProviderRegistry(goongMapTilesKey: '  abc123  ');
      expect(r.isRegistered(MapProviderKind.goong), isTrue);
    });

    test('restApiKey rỗng/whitespace → adapter nhận null', () {
      // Smoke: chỉ verify không throw — adapter giữ restApiKey = null.
      expect(
        () => buildMapProviderRegistry(
          goongMapTilesKey: 'abc',
          goongRestApiKey: '',
        ),
        returnsNormally,
      );
      expect(
        () => buildMapProviderRegistry(
          goongMapTilesKey: 'abc',
          goongRestApiKey: '   ',
        ),
        returnsNormally,
      );
    });
  });
}
