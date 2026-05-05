import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:httm_xangdau/core/map/app_map_camera.dart';
import 'package:httm_xangdau/core/map/app_map_marker.dart';
import 'package:httm_xangdau/core/map/app_map_polyline.dart';
import 'package:httm_xangdau/core/map/map_capability.dart';
import 'package:httm_xangdau/core/map/map_provider_adapter.dart';
import 'package:httm_xangdau/core/map/map_provider_kind.dart';
import 'package:httm_xangdau/core/map/map_provider_registry.dart';

class _FakeAdapter extends MapProviderAdapter {
  _FakeAdapter(this.kind);

  @override
  final MapProviderKind kind;

  @override
  Set<MapCapability> get capabilities => const {};

  @override
  String get displayName => 'Fake-${kind.configValue}';

  @override
  Widget buildMap({
    required AppMapCameraPosition initialCameraPosition,
    Set<AppMapMarker> markers = const {},
    Set<AppMapPolyline> polylines = const {},
    EdgeInsets padding = EdgeInsets.zero,
    bool myLocationEnabled = false,
    bool myLocationButtonEnabled = false,
    bool zoomControlsEnabled = false,
    bool compassEnabled = true,
    double? minZoom,
    double? maxZoom,
    AppMapCreatedCallback? onMapCreated,
    AppMapTapCallback? onTap,
    AppMapCameraIdleCallback? onCameraIdle,
  }) =>
      const SizedBox.shrink();
}

void main() {
  group('MapProviderRegistry', () {
    test('empty registry exposes no adapters', () {
      final r = MapProviderRegistry();
      expect(r.registered, isEmpty);
      expect(r.get(MapProviderKind.google), isNull);
      expect(r.isRegistered(MapProviderKind.google), isFalse);
    });

    test('register adds an adapter', () {
      final r = MapProviderRegistry();
      r.register(_FakeAdapter(MapProviderKind.google));
      expect(r.isRegistered(MapProviderKind.google), isTrue);
      expect(r.get(MapProviderKind.google), isA<_FakeAdapter>());
      expect(r.registered, {MapProviderKind.google});
    });

    test('register returns this (chainable)', () {
      final r = MapProviderRegistry()
        ..register(_FakeAdapter(MapProviderKind.google))
        ..register(_FakeAdapter(MapProviderKind.goong));
      expect(r.registered, {MapProviderKind.google, MapProviderKind.goong});
    });

    test('duplicate kind overrides earlier registration', () {
      final r = MapProviderRegistry();
      final a1 = _FakeAdapter(MapProviderKind.google);
      final a2 = _FakeAdapter(MapProviderKind.google);
      r.register(a1).register(a2);
      expect(identical(r.get(MapProviderKind.google), a2), isTrue);
      expect(r.registered.length, 1);
    });
  });
}
