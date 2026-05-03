import '../../../../core/network/json_utils.dart';

/// Backend: `StoreAdminInventoryMapStationDto` (inventory map list row).
class InventoryMapStation {
  const InventoryMapStation({
    required this.stationId,
    required this.stationCode,
    required this.stationName,
    this.address,
    this.latitude,
    this.longitude,
    required this.currentQuantity,
    required this.stockStatus,
  });

  final int stationId;
  final String stationCode;
  final String stationName;
  final String? address;
  final double? latitude;
  final double? longitude;

  /// Aggregated quantity for the requested fuel group (server `decimal`).
  final double currentQuantity;

  /// Server values: `out` | `low` | `normal` (see stored procedure / DTO).
  final String stockStatus;

  factory InventoryMapStation.fromJson(Map<String, dynamic> json) {
    return InventoryMapStation(
      stationId: JsonUtils.readIntRequired(json['stationId'], field: 'stationId'),
      stationCode: JsonUtils.readString(json['stationCode']) ?? '',
      stationName: JsonUtils.readString(json['stationName']) ?? '',
      address: JsonUtils.readString(json['address']),
      latitude: JsonUtils.readDouble(json['latitude']),
      longitude: JsonUtils.readDouble(json['longitude']),
      currentQuantity: JsonUtils.readDoubleRequired(json['currentQuantity'], field: 'currentQuantity'),
      stockStatus: JsonUtils.readString(json['stockStatus']) ?? '',
    );
  }
}
