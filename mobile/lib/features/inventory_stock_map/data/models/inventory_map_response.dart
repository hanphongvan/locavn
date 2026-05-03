import '../../../../core/network/json_utils.dart';
import 'inventory_map_station.dart';

/// Backend: `StoreAdminInventoryMapResponseDto`.
class InventoryMapResponse {
  const InventoryMapResponse({required this.stations});

  final List<InventoryMapStation> stations;

  factory InventoryMapResponse.fromJson(Map<String, dynamic> json) {
    final out = <InventoryMapStation>[];
    // Prefer camelCase; accept PascalCase if serializer differs.
    final raw = JsonUtils.readList(json['stations'] ?? json['Stations']);
    if (raw != null) {
      for (final e in raw) {
        final m = JsonUtils.readMap(e);
        if (m != null) {
          out.add(InventoryMapStation.fromJson(m));
        }
      }
    }
    return InventoryMapResponse(stations: out);
  }
}
