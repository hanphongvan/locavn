import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_map_api.dart';
import 'inventory_map_group_code.dart';
import 'models/inventory_map_response.dart';

/// Active fuel group for the inventory stock map UI (default: Xăng).
final inventoryMapSelectedGroupProvider =
    StateProvider<String>((ref) => InventoryMapGroupCode.xang);

/// Loads [InventoryMapResponse] for [inventoryMapSelectedGroupProvider] — markers clear while loading.
final inventoryMapForSelectedGroupProvider =
    FutureProvider.autoDispose<InventoryMapResponse>((ref) async {
  final groupCode = ref.watch(inventoryMapSelectedGroupProvider);
  return ref.read(inventoryMapApiProvider).loadByGroupCode(groupCode);
});

/// Xăng group — loading / error surface as [AsyncValue] (no local stock fabrication).
final inventoryMapXangProvider =
    FutureProvider.autoDispose<InventoryMapResponse>((ref) {
  return ref.read(inventoryMapApiProvider).loadXangMap();
});

/// Dầu group — loading / error surface as [AsyncValue].
final inventoryMapDauProvider =
    FutureProvider.autoDispose<InventoryMapResponse>((ref) {
  return ref.read(inventoryMapApiProvider).loadDauMap();
});

/// Generic: `groupCode` must be a server-supported value (e.g. [InventoryMapGroupCode]).
final inventoryMapByGroupCodeProvider =
    FutureProvider.autoDispose.family<InventoryMapResponse, String>((ref, groupCode) {
  return ref.read(inventoryMapApiProvider).loadByGroupCode(groupCode);
});
