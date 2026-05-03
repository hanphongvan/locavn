import '../../../../core/network/json_utils.dart';
import 'vehicle_dto.dart';

/// Backend `UserVehicleListResponse`.
class MyVehiclesListResponse {
  const MyVehiclesListResponse({
    required this.items,
    required this.totalCount,
  });

  final List<VehicleDto> items;
  final int totalCount;

  factory MyVehiclesListResponse.fromJson(Map<String, dynamic> json) {
    final raw = JsonUtils.readList(json['items']);
    final list = <VehicleDto>[];
    if (raw != null) {
      for (final e in raw) {
        final m = JsonUtils.readMap(e);
        if (m != null) {
          list.add(VehicleDto.fromJson(m));
        }
      }
    }
    return MyVehiclesListResponse(
      items: list,
      totalCount: JsonUtils.readInt(json['totalCount']) ?? list.length,
    );
  }
}
