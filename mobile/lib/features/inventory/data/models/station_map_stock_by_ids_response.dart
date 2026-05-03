import '../../../../core/network/json_utils.dart';

class StationMapStockByIdsResponse {
  StationMapStockByIdsResponse({required this.items});

  factory StationMapStockByIdsResponse.fromJson(Object? data) {
    final m = JsonUtils.readMap(data);
    if (m == null) {
      throw const FormatException('Expected map for StationMapStockByIdsResponse');
    }
    final list = m['items'];
    final out = <StationMapStockItem>[];
    if (list is List) {
      for (final e in list) {
        final m = JsonUtils.readMap(e);
        if (m != null) {
          out.add(StationMapStockItem.fromJson(m));
        }
      }
    }
    return StationMapStockByIdsResponse(items: out);
  }

  final List<StationMapStockItem> items;
}

class StationMapStockItem {
  StationMapStockItem({required this.stationId, required this.totalStockQuantity});

  factory StationMapStockItem.fromJson(Map<String, dynamic> m) {
    return StationMapStockItem(
      stationId: JsonUtils.readInt(m['stationId']) ?? 0,
      totalStockQuantity: JsonUtils.readDouble(m['totalStockQuantity']) ?? 0,
    );
  }

  final int stationId;
  final double totalStockQuantity;
}
