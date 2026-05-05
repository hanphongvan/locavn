import '../../../core/map/app_lat_lng.dart';
import '../domain/stock_map_stock_status.dart';

/// One station on the stock map: coordinates + marker status + server fields for detail UI.
class StockMapStationPin {
  const StockMapStationPin({
    this.stationId,
    required this.point,
    required this.status,
    required this.stationName,
    this.address,
    required this.currentQuantity,
    required this.stockStatusRaw,
  });

  final int? stationId;
  final AppLatLng point;
  final StockMapStockStatus status;

  /// From API `stationName`.
  final String stationName;

  /// From API `address` (nullable).
  final String? address;

  /// From API `currentQuantity`.
  final double currentQuantity;

  /// From API `stockStatus` (wire value, e.g. out / low / normal).
  final String stockStatusRaw;
}
