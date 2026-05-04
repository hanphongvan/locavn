import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'map_provider_adapter.dart';
import 'map_provider_config.dart';
import 'map_provider_kind.dart';
import 'map_provider_registry.dart';
import 'providers/google/google_map_adapter.dart';

/// Default registry chỉ có Google (zero-config: chạy mà không cần env nào).
/// `main.dart` override để add Goong khi `GOONG_MAPTILES_KEY` được truyền —
/// xem `lib/core/map/map_provider_bootstrap.dart`.
///
/// Test/widget không cần override — Google adapter là pure-Dart wrapper, không
/// init native sớm.
final mapProviderRegistryProvider = Provider<MapProviderRegistry>((ref) {
  return MapProviderRegistry()..register(GoogleMapAdapter());
});

final currentMapProviderKindProvider = Provider<MapProviderKind>((ref) {
  return MapProviderConfig.resolved;
});

final currentMapProviderAdapterProvider = Provider<MapProviderAdapter>((ref) {
  final registry = ref.watch(mapProviderRegistryProvider);
  final kind = ref.watch(currentMapProviderKindProvider);
  final adapter = registry.get(kind);
  if (adapter == null) {
    throw StateError(
      'Map provider "${kind.configValue}" is not registered in MapProviderRegistry. '
      'Register it in main.dart override before runApp().',
    );
  }
  return adapter;
});
