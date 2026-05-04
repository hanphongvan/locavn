import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'map_provider_adapter.dart';
import 'map_provider_config.dart';
import 'map_provider_kind.dart';
import 'map_provider_registry.dart';

/// Phải override trong `main.dart` với các adapter đã đăng ký.
/// Không có default — đọc trước khi override sẽ throw để fail-fast.
final mapProviderRegistryProvider = Provider<MapProviderRegistry>((ref) {
  throw UnimplementedError(
    'MapProviderRegistry must be overridden in main.dart with registered adapters. '
    'See mobile/docs/map-provider-architecture.md.',
  );
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
