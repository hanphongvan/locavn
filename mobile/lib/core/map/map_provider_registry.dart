import 'map_provider_adapter.dart';
import 'map_provider_kind.dart';

class MapProviderRegistry {
  final Map<MapProviderKind, MapProviderAdapter> _adapters = {};

  MapProviderRegistry();

  MapProviderRegistry register(MapProviderAdapter adapter) {
    _adapters[adapter.kind] = adapter;
    return this;
  }

  MapProviderAdapter? get(MapProviderKind kind) => _adapters[kind];

  bool isRegistered(MapProviderKind kind) => _adapters.containsKey(kind);

  Set<MapProviderKind> get registered => _adapters.keys.toSet();
}
