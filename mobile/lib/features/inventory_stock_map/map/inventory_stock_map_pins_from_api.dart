import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/models/inventory_map_station.dart';
import '../domain/stock_map_stock_status.dart';
import 'stock_map_station_pin.dart';

/// Maps API `stockStatus` to marker enum (SQL / DTO: out | low | normal only).
StockMapStockStatus? parseInventoryMapStockStatus(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'out':
      return StockMapStockStatus.out;
    case 'low':
      return StockMapStockStatus.low;
    case 'normal':
      return StockMapStockStatus.normal;
    default:
      return null;
  }
}

/// One pin per plottable station — skips missing coordinates or unknown [InventoryMapStation.stockStatus].
List<StockMapStationPin> pinsFromInventoryMapStations(List<InventoryMapStation> stations) {
  final out = <StockMapStationPin>[];
  for (final s in stations) {
    final lat = s.latitude;
    final lng = s.longitude;
    if (lat == null || lng == null) continue;
    final status = parseInventoryMapStockStatus(s.stockStatus);
    if (status == null) continue;
    out.add(
      StockMapStationPin(
        stationId: s.stationId,
        point: LatLng(lat, lng),
        status: status,
        stationName: s.stationName,
        address: s.address,
        currentQuantity: s.currentQuantity,
        stockStatusRaw: s.stockStatus,
      ),
    );
  }
  return out;
}
